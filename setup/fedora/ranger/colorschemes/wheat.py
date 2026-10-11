# Wheat paper from setup/fedora/kitty.conf and lua/highlight.lua.
# Ranger only paints palette indexes. These slots are set to the same hex
# values, then restored when Ranger exits.

import atexit

import curses
from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import default, normal, bold, yellow, red, green, cyan, magenta, white, black, BRIGHT

_BASE = 200
_HEX = (
    "#f7f1e3",  # paper, kitty background
    "#5d5140",  # ink, kitty foreground
    "#c49a2e",  # accent, directories and titles
    "#e5d5a6",  # selection, kitty selection_background
    "#9b8a72",  # muted
    "#8b7d6d",  # inactive
    "#765613",  # deep brown, text on a wheat highlight
    "#fff7e8",  # cream, kitty active tab text
    "#e53935",  # red
    "#91b859",  # green
    "#39adb5",  # cyan
    "#a37acc",  # magenta
    "#d8c8aa",  # border
)
_saved = []
_installed = False


def _milli(hex_color):
    value = int(hex_color[1:], 16)
    red_part = (value >> 16) & 255
    green_part = (value >> 8) & 255
    blue_part = value & 255
    return (red_part * 1000 // 255, green_part * 1000 // 255, blue_part * 1000 // 255)


def _restore_palette():
    for slot, previous in _saved:
        try:
            curses.init_color(slot, *previous)
        except curses.error:
            pass


def _install_palette():
    global _installed
    if _installed:
        return True
    if not curses.has_colors() or not curses.can_change_color():
        return False
    saved = []
    try:
        for offset, hex_color in enumerate(_HEX):
            slot = _BASE + offset
            saved.append((slot, curses.color_content(slot)))
            curses.init_color(slot, *_milli(hex_color))
    except curses.error:
        for slot, previous in saved:
            try:
                curses.init_color(slot, *previous)
            except curses.error:
                pass
        return False
    _saved.extend(saved)
    _installed = True
    atexit.register(_restore_palette)
    return True


class Scheme(ColorScheme):
    progress_bar_color = yellow

    def __init__(self):
        self.paper = default
        self.ink = default
        self.accent = yellow
        self.selection = 187
        self.muted = white
        self.inactive = black + BRIGHT
        self.deep = white + BRIGHT
        self.cream = default
        self.red = red
        self.green = green
        self.cyan = cyan
        self.magenta = magenta
        self.border = white
        self._ready = False

    def _colors(self):
        if self._ready:
            return
        try:
            ready = curses.has_colors()
        except curses.error:
            return
        if not ready:
            return
        self._ready = True
        if not _install_palette():
            return
        self.paper = _BASE
        self.ink = _BASE + 1
        self.accent = _BASE + 2
        self.selection = _BASE + 3
        self.muted = _BASE + 4
        self.inactive = _BASE + 5
        self.deep = _BASE + 6
        self.cream = _BASE + 7
        self.red = _BASE + 8
        self.green = _BASE + 9
        self.cyan = _BASE + 10
        self.magenta = _BASE + 11
        self.border = _BASE + 12
        self.progress_bar_color = self.accent

    def use(self, context):
        self._colors()
        fg, bg, attr = self.ink, self.paper, normal

        if context.reset:
            return fg, bg, attr

        if context.in_browser:
            if context.empty or context.error:
                fg = self.red
            elif context.directory:
                attr |= bold
                fg = self.accent
            elif context.executable and not any(
                (context.media, context.container, context.fifo, context.socket)
            ):
                attr |= bold
                fg = self.green
            elif context.socket or context.media:
                fg = self.magenta
            elif context.container or context.device:
                fg = self.red
            elif context.fifo:
                fg = self.deep
            elif context.link:
                fg = self.cyan if context.good else self.magenta
            elif context.border:
                fg = self.border

            if context.infostring and not context.selected:
                fg = self.muted
            if context.tag_marker and not context.selected:
                attr |= bold
                fg = self.red
            if not context.selected and (context.cut or context.copied):
                fg = self.inactive
            if context.main_column and context.marked and not context.selected:
                attr |= bold
                fg = self.accent
            if context.badinfo:
                fg = self.magenta
            if context.inactive_pane:
                fg = self.inactive
            if context.selected:
                fg = self.deep if context.directory else self.ink
                bg = self.selection
                if context.directory or context.marked:
                    attr |= bold

        elif context.in_titlebar:
            attr |= bold
            if context.hostname:
                fg = self.red if context.bad else self.green
            elif context.directory:
                fg = self.accent
            elif context.tab and context.good:
                fg = self.cream
                bg = self.accent
            elif context.link:
                fg = self.cyan
            else:
                fg = self.inactive

        elif context.in_statusbar:
            if context.permissions:
                fg = self.green if context.good else self.magenta
            if context.marked:
                attr |= bold
                fg = self.deep
                bg = self.selection
            if context.frozen:
                attr |= bold
                fg = self.cyan
            if context.message and context.bad:
                attr |= bold
                fg = self.red
            if context.loaded:
                bg = self.progress_bar_color
                fg = self.cream
            if context.vcsinfo:
                fg = self.muted
            if context.vcscommit:
                fg = self.accent
            if context.vcsdate:
                fg = self.inactive

        if context.text and context.highlight:
            fg = self.ink
            bg = self.selection

        if context.in_taskview:
            if context.title:
                fg = self.accent
            if context.selected:
                fg = self.ink
                bg = self.selection
            if context.loaded:
                bg = self.progress_bar_color
                fg = self.cream

        if context.vcsfile and not context.selected:
            attr &= ~bold
            if context.vcsconflict:
                fg = self.magenta
            elif context.vcsuntracked:
                fg = self.cyan
            elif context.vcschanged or context.vcsunknown:
                fg = self.red
            elif context.vcsstaged or context.vcssync:
                fg = self.green
            elif context.vcsignored:
                fg = self.inactive

        elif context.vcsremote and not context.selected:
            attr &= ~bold
            if context.vcssync or context.vcsnone:
                fg = self.green
            elif context.vcsbehind or context.vcsunknown:
                fg = self.red
            elif context.vcsahead:
                fg = self.accent
            elif context.vcsdiverged:
                fg = self.magenta

        return fg, bg, attr
