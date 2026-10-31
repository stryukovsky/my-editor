import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const IFACE = `<node><interface name="org.gnome.Shell.Extensions.KittyTop">
<method name="Focus"><arg type="u" direction="in" name="pid"/>
<arg type="s" direction="in" name="title"/>
<arg type="b" direction="out" name="focused"/></method>
</interface></node>`;

export default class KittyTop extends Extension {
    enable() {
        this._pending = new Set();
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/KittyTop');
    }

    FocusAsync([pid, title], invocation) {
        // Kitty's title update arrives asynchronously over Wayland.
        let attempts = 0;
        const pending = {id: 0, invocation};
        pending.id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
            const target = global.get_window_actors().map(actor => actor.meta_window)
                .find(window => window.get_pid() === pid &&
                    window.get_wm_class()?.toLowerCase() === 'kitty' &&
                    window.get_title() === title);
            if (target) {
                target.unminimize();
                Main.activateWindow(target);
            }
            if (target || ++attempts >= 20) {
                invocation.return_value(new GLib.Variant('(b)', [Boolean(target)]));
                this._pending.delete(pending);
                return GLib.SOURCE_REMOVE;
            }
            return GLib.SOURCE_CONTINUE;
        });
        this._pending.add(pending);
    }

    disable() {
        for (const pending of this._pending) {
            GLib.source_remove(pending.id);
            pending.invocation.return_value(new GLib.Variant('(b)', [false]));
        }
        this._pending.clear();
        this._dbus.unexport();
        this._dbus = null;
    }
}
