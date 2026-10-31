"""Native popup/LSP integration: uv run --with pynvim python tests/native_completion_integration.py [root]."""
import json
import os
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import time


def server():
    options = {}
    while True:
        headers = {}
        while True:
            line = sys.stdin.buffer.readline()
            if not line:
                return
            if line == b"\r\n":
                break
            key, value = line.decode().split(":", 1)
            headers[key.lower()] = value.strip()
        msg = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
        method, params = msg.get("method"), msg.get("params", {})
        if method == "exit":
            return
        if method == "initialize":
            options = params.get("initializationOptions") or {}
            result = {"capabilities": {
                "textDocumentSync": 1,
                "completionProvider": {"resolveProvider": True, "triggerCharacters": ["."]},
                "executeCommandProvider": {"commands": ["fixture.accepted"]},
            }}
        elif method == "textDocument/completion":
            mode = options.get("mode", "ranking")
            if mode == "ranking":
                items = [{"label": "createCat", "kind": 6, "sortText": "0"},
                         {"label": "createUser", "kind": 3, "sortText": "1"}]
            elif mode == "many":
                items = [{"label": "imported" + str(i) + "界" * 60, "kind": 3,
                          "detail": "module\n" + "x" * 100} for i in range(100)]
            elif mode == "empty":
                items = []
            else:
                row = params["position"]["line"]
                end = params["position"]["character"]
                items = [{
                    "label": "importedFunction" + "Long" * 30,
                    "kind": 15,
                    "detail": "fixture/module" + "x" * 50,
                    "textEdit": {"range": {"start": {"line": row, "character": 0},
                                           "end": {"line": row, "character": end}},
                                 "newText": "imported(${1:value})$0"},
                    "insertTextFormat": 2,
                    "additionalTextEdits": [{"range": {"start": {"line": 0, "character": 0},
                                                       "end": {"line": 0, "character": 0}},
                                             "newText": 'import { imported } from "fixture";\n'}],
                    "command": {"title": "Fixture accepted", "command": "fixture.accepted"},
                    "data": {"module": "fixture"},
                }]
                if mode == "duplicate":
                    other = json.loads(json.dumps(items[0]))
                    other["detail"] = "other/module"
                    other["additionalTextEdits"][0]["newText"] = 'import { imported } from "other";\n'
                    other["data"]["module"] = "other"
                    items.append(other)
            result = {"isIncomplete": False, "items": items}
        elif method == "completionItem/resolve":
            result = dict(params, documentation={"kind": "markdown", "value": "Resolved fixture documentation"})
            with open(options["events"], "a") as log:
                log.write("resolve\n")
        elif method == "workspace/executeCommand":
            with open(options["events"], "a") as log:
                log.write("accepted\n")
            result = None
        elif method == "shutdown":
            result = None
        elif "id" in msg:
            result = None
        else:
            continue
        response = json.dumps({"jsonrpc": "2.0", "id": msg["id"], "result": result}).encode()
        sys.stdout.buffer.write(f"Content-Length: {len(response)}\r\n\r\n".encode() + response)
        sys.stdout.buffer.flush()


if "--server" in sys.argv:
    server()
    sys.exit(0)

import pynvim

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parents[1])
CONFIG = Path(os.environ.get("NVIM_CONFIG_ROOT", ROOT))
with tempfile.TemporaryDirectory(prefix="native-completion-") as temp:
    TEMP = Path(temp)
    (TEMP / "state/nvim").mkdir(parents=True)
    os.environ["XDG_STATE_HOME"] = str(TEMP / "state")
    os.environ["NVIM_LOG_FILE"] = str(TEMP / "nvim.log")
    nvim = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"])

    def lua(code, *args):
        return nvim.exec_lua(code, *args)

    def wait(check, label, seconds=8):
        until = time.monotonic() + seconds
        while time.monotonic() < until:
            if check():
                return
            time.sleep(0.025)
        raise AssertionError(label + ": " + repr(lua("return {mode=vim.fn.mode(), lines=vim.api.nvim_buf_get_lines(0,0,-1,false), info=vim.fn.complete_info(), err=vim.v.errmsg}")))

    def keys(text):
        nvim.input(text)
        time.sleep(0.07)

    def normal():
        keys("<Esc>")
        wait(lambda: lua("return vim.fn.mode()") == "n", "normal mode")

    def edit(name, ft, lines):
        normal()
        path = TEMP / name
        path.write_text("\n".join(lines) + "\n")
        nvim.command("edit! " + str(path))
        nvim.current.buffer.options["filetype"] = ft
        lua("vim.api.nvim_win_set_cursor(0,{...,#vim.api.nvim_get_current_line()})", len(lines))
        return nvim.current.buffer.number

    def fake(mode):
        events = str(TEMP / (mode + ".events"))
        client = lua("""
          local script,python,mode,events = ...
          return vim.lsp.start {name='completion-fixture-'..mode, cmd={python,script,'--server'},
            root_dir=vim.fn.getcwd(), init_options={mode=mode,events=events}}
        """, str(Path(__file__).resolve()), sys.executable, mode, events)
        wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "LSP initialize")
        time.sleep(0.1)
        return client, Path(events)

    def stop(client):
        normal()
        lua("vim.lsp.stop_client(...,true)", client)
        wait(lambda: not lua("return vim.lsp.get_client_by_id(...) ~= nil", client), "LSP stop")

    def popup(seconds=8):
        keys("<C-Space>")
        wait(lambda: lua("return vim.fn.pumvisible()") == 1, "popup", seconds)

    try:
        lua("""
          local root,config=...
          vim.opt.rtp:prepend(root);vim.opt.rtp:append(config)
          vim.opt.rtp:append(config..'/data/tree-sitter')
          vim.opt.rtp:append(config..'/data/lazy/langmapper.nvim')
          vim.opt.rtp:append(config..'/data/lazy/material.nvim')
          vim.opt.rtp:append(config..'/data/lazy/friendly-snippets')
          vim.o.virtualedit='onemore';vim.o.timeoutlen=50;vim.o.ttimeoutlen=10
          require('langmapper').setup {hack_keymap=false}
        """, str(ROOT), str(CONFIG))
        # Load exactly one completion configuration so autocmds and native options agree.
        lua("""
          local root,config=...
          local path=root..'/lua/configs/completion.lua'
          local completion=dofile(path)
          completion.setup_mappings()
          dofile(config..'/lua/configs/material-theme.lua')
          vim.o.background='light';vim.cmd.colorscheme('material-lighter')
        """, str(ROOT), str(CONFIG))
        nvim.api.ui_attach(90, 28, {"rgb": True, "ext_linegrid": True})
        edit("ranking.ts", "typescript", ["const user: User = create"])
        client, _ = fake("ranking")
        keys("A")
        popup()
        assert lua("return vim.fn.complete_info().items[1].word") == "createUser"
        assert nvim.options["pumheight"] == 10 and nvim.options["pummaxwidth"] == 70
        assert lua("return vim.api.nvim_get_hl(0,{name='Pmenu',link=false}).bg") == int("fcf6e9", 16)
        keys("<C-e>")
        lua("""
          local id=...
          vim.lsp.completion.enable(false,id,0)
          vim.lsp.completion.enable(true,id,0,{cmp=function(a,b)
            local ia=a.user_data.nvim.lsp.completion_item
            local ib=b.user_data.nvim.lsp.completion_item
            return ia.kind==6 and ib.kind~=6
          end})
        """, client)
        popup()
        assert lua("return vim.fn.complete_info().items[1].word") == "createCat"
        keys("<C-e>")
        lua("""
          vim.lsp.completion.enable(false,...,0)
          vim.lsp.completion.enable(true,...,0,{})
          vim.opt_local.completeopt:remove('nosort')
        """, client)
        popup()
        assert lua("return vim.fn.complete_info().items[1].word") == "createCat"
        stop(client)
        print("PASS live TypeScript popup: User affinity and wheat highlights")

        edit("accept.ts", "typescript", ["// module", "imp"])
        client, events = fake("accept")
        keys("A"); popup()
        item = lua("return vim.fn.complete_info().items[1]")
        assert lua("return vim.fn.strdisplaywidth(...)", item["abbr"]) <= 45
        assert lua("return vim.fn.strdisplaywidth(...)", item["menu"]) <= 24
        keys("<C-n>")
        wait(lambda: events.exists() and "resolve" in events.read_text(), "resolved docs")
        wait(lambda: lua("return (vim.fn.complete_info().preview_winid or 0)>0"), "documentation preview")
        keys("<CR>")
        wait(lambda: lua("return vim.snippet.active()"), "native snippet")
        assert lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)") == ['import { imported } from "fixture";', '// module', "imported(value)"], lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)")
        wait(lambda: "accepted" in events.read_text(), "native command")
        stop(client)
        print("PASS native resolve, documentation, full snippet insertion, auto-import, command and Enter acceptance")

        edit("duplicate.ts", "typescript", ["// module", "imp"])
        client, events = fake("duplicate")
        keys("A"); popup()
        assert len(lua("return vim.fn.complete_info().items")) == 2
        keys("<C-CR>")
        wait(lambda: lua("return vim.snippet.active()"), "Ctrl-Enter snippet")
        assert 'import { imported } from ' in lua("return vim.api.nvim_buf_get_lines(0,0,1,false)[1]")
        stop(client)
        print("PASS duplicate labels preserve distinct edits; Ctrl-Enter accepts first item")

        edit("many.ts", "typescript", ["imp"])
        client, _ = fake("many")
        keys("A"); popup()
        pos = lua("return vim.fn.pum_getpos()")
        assert pos["height"] <= 10 and pos["width"] <= 70, pos
        nvim.api.ui_try_resize(38, 18)
        keys("<C-e>"); popup()
        pos = lua("return vim.fn.pum_getpos()")
        assert pos["col"] + pos["width"] <= 38, pos
        keys("<CR>")
        wait(lambda: len(nvim.current.buffer[:]) == 2, "no-selection Enter newline")
        stop(client)
        nvim.api.ui_try_resize(90, 28)
        print("PASS bounded menu, narrow screen, Unicode labels and no-selection newline")

        # Current, window and loaded-buffer words remain available with LSP attached.
        other = lua("local b=vim.api.nvim_create_buf(true,false);vim.api.nvim_buf_set_lines(b,0,-1,false,{'createLoaded'});return b")
        edit("fallback.ts", "typescript", ["createLocal", "create"])
        window = lua("""
          local b=vim.api.nvim_create_buf(false,true)
          vim.api.nvim_buf_set_lines(b,0,-1,false,{'createWindow'})
          return vim.api.nvim_open_win(b,false,{split='right',win=0})
        """)
        client, _ = fake("ranking")
        keys("A"); popup()
        keys("<C-n><C-x><C-n>")
        wait(lambda: lua("return vim.fn.pumvisible()") == 1 and lua("return vim.fn.complete_info().mode") == "keyword", "keyword fallback")
        words = [x["word"] for x in lua("return vim.fn.complete_info().items")]
        assert "createLocal" in words and "createLoaded" in words and "createWindow" in words, words
        keys("<C-e>")
        assert nvim.current.line == "create"
        popup()
        # Russian layout Ctrl-Ч Ctrl-Т is the physical Ctrl-X Ctrl-N sequence.
        keys("<C-ч><C-т>")
        wait(lambda: lua("return vim.fn.complete_info().mode") == "keyword", "Russian keyword shortcut")
        stop(client)
        nvim.api.win_close(window,True)
        print("PASS English/Russian word fallback cancels LSP selection and preserves Ctrl-Space")
        # Unsupported filetypes keep native relevance without parser hints.
        edit("unsupported.txt", "text", ["create"])
        client, _ = fake("ranking")
        keys("A"); popup()
        assert lua("return vim.fn.complete_info().items[1].word") == "createCat"
        stop(client)
        print("PASS unsupported-language session stays neutral")

        # Existing terminal source and completion repair run unchanged.
        target = TEMP / "completion-target.txt"
        target.write_text("fixture")
        normal()
        lua("""
          local b=vim.api.nvim_create_buf(false,true)
          vim.api.nvim_set_current_buf(b)
          vim.b.terminal_command=true
          vim.api.nvim_buf_set_lines(b,0,-1,false,{...})
          vim.api.nvim_win_set_cursor(0,{1,#vim.api.nvim_get_current_line()})
        """, "cat " + str(TEMP / "completion-t"))
        keys("A"); popup()
        terminal_items = lua("return vim.fn.complete_info().items")
        index = next(i for i, x in enumerate(terminal_items) if str(target) in x["word"])
        keys("<C-n>" * (index + 1) + "<CR>")
        wait(lambda: str(target) in nvim.current.line, "terminal path acceptance")
        normal()
        print("PASS existing terminal path source and native acceptance repair")

        lua("dofile(...).setup()", str(CONFIG / "lua/configs/input.lua"))
        lua("vim.ui.input({prompt='Disabled'},function(v) _G.input_result=v or 'cancelled' end)")
        wait(lambda: lua("return vim.fn.mode()") == "i", "disabled input insert")
        assert not lua("return vim.bo.autocomplete")
        keys("feat")
        assert lua("return vim.fn.pumvisible()") == 0
        normal();keys("q")
        wait(lambda: lua("return _G.input_result") == "cancelled", "disabled input cancel")
        lua("_G.input_result=nil;vim.ui.input({prompt='Commit',filetype='gitcommit',cwd=...},function(v) _G.input_result=v or 'cancelled' end)", str(TEMP))
        wait(lambda: lua("return vim.fn.mode()") == "i", "typed input insert")
        assert lua("return vim.bo.autocomplete")
        assert "popup" not in lua("return vim.bo.completeopt")
        keys("fea")
        wait(lambda: lua("return vim.fn.pumvisible()") == 1, "typed input popup")
        keys("<C-n><CR>")
        wait(lambda: lua("return vim.snippet.active()"), "input snippet")
        assert lua("return _G.input_result") is None
        normal();keys("q")
        wait(lambda: lua("return _G.input_result") == "cancelled", "typed input cancel")
        print("PASS default-disabled input and typed floating input retain their completion behavior")

        mason = CONFIG / "data/mason/bin"
        lua_server = mason / "lua-language-server"
        if lua_server.exists():
            edit("live.lua", "lua", ["local x = math.sq"])
            client = lua("""
              local cmd,root,logs,meta=...
              return vim.lsp.start {name='live-lua',cmd={cmd,'--logpath='..logs,'--metapath='..meta},root_dir=root,
                settings={Lua={runtime={version='LuaJIT'},workspace={checkThirdParty=false},telemetry={enable=false}}}}
            """, str(lua_server), str(TEMP), str(TEMP / "lua-log"), str(TEMP / "lua-meta"))
            wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "live Lua initialize", 20)
            time.sleep(0.7)
            keys("A");popup()
            assert any("sqrt" in x["word"] for x in lua("return vim.fn.complete_info().items"))
            stop(client)
            print("PASS installed Lua language server member completion")
        else:
            print("SKIP installed Lua server (not available)")

        ts_server = mason / "typescript-language-server"
        if ts_server.exists():
            (TEMP / "tsconfig.json").write_text(json.dumps({"compilerOptions": {"target": "ES2022", "module": "ESNext", "moduleResolution": "node"}, "include": ["*.ts"]}))
            (TEMP / "user.ts").write_text("export function createUser() { return { name: 'fixture' }; }\n")
            edit("live.ts", "typescript", ["const user = createU"])
            client = lua("""
              local cmd,root=...
              return vim.lsp.start {name='live-typescript',cmd={cmd,'--stdio'},root_dir=root,
                init_options={disableAutomaticTypingAcquisition=true,preferences={includeCompletionsForModuleExports=true}}}
            """, str(ts_server), str(TEMP))
            wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "live TypeScript initialize", 20)
            time.sleep(1)
            keys("A");popup()
            items=lua("return vim.fn.complete_info().items")
            index=next(i for i,x in enumerate(items) if x["word"]=="createUser")
            keys("<C-n>"*(index+1)+"<CR>")
            wait(lambda: any("import" in x and "createUser" in x for x in nvim.current.buffer[:]), "live TypeScript auto-import", 15)
            assert any("const user = createUser" in x for x in nvim.current.buffer[:])
            stop(client)
            print("PASS installed TypeScript server auto-import acceptance")
        else:
            print("SKIP installed TypeScript server (not available)")
        go_server = mason / "gopls"
        if go_server.exists() and shutil.which("go"):
            (TEMP / "go.mod").write_text("module fixture\n\ngo 1.22\n")
            edit("live.go", "go", [
                "package main",
                "type User struct{}",
                "func createUser() User { return User{} }",
                "func createCat() int { return 0 }",
                "func main() { var user User; _ = user; _ = create }",
            ])
            # Complete inside the valid function body, before the closing brace.
            lua("vim.api.nvim_win_set_cursor(0,{5,#vim.api.nvim_get_current_line()-2})")
            client = lua("""
              local cmd,root=...
              return vim.lsp.start {name='live-go',cmd={cmd},root_dir=root,
                cmd_env={GOCACHE=root..'/go-cache',GOMODCACHE=root..'/go-mod',GOPATH=root..'/go-path',GOPROXY='off'}}
            """, str(go_server), str(TEMP))
            wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "live Go initialize", 30)
            keys("i")
            popup(seconds=40)
            items=lua("return vim.fn.complete_info().items")
            assert "createUser" in items[0]["word"], items
            assert any("createCat" in item["word"] for item in items), items
            keys("<C-n><CR>")
            wait(lambda: "createUser" in nvim.current.line, "live Go acceptance")
            stop(client)
            print("PASS installed Go server User affinity and native acceptance")
        else:
            print("SKIP installed Go server/toolchain (not available)")
        assert lua("return vim.v.errmsg") == "", lua("return vim.v.errmsg")
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
