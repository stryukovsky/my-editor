"""Midword proof: uv run --with pynvim python tests/native_completion_midword.py.

Use --observe to record gaps before applying a correction; --json PATH saves results.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
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
        message = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
        method = message.get("method")
        if method == "exit":
            return
        if method == "initialize":
            options = message["params"]["initializationOptions"]
            result = {"capabilities": {
                "positionEncoding": options["encoding"],
                "completionProvider": {},
                "executeCommandProvider": {"commands": ["midword.accept"]},
            }}
        elif method == "textDocument/completion":
            result = options["completion"]
        elif method == "workspace/executeCommand":
            with open(options["events"], "a") as output:
                output.write("accept\n")
            result = None
        elif method == "shutdown":
            result = None
        elif "id" not in message:
            continue
        else:
            result = None
        response = json.dumps({"jsonrpc": "2.0", "id": message["id"], "result": result}).encode()
        sys.stdout.buffer.write(f"Content-Length: {len(response)}\r\n\r\n".encode() + response)
        sys.stdout.buffer.flush()


if "--server" in sys.argv:
    server()
    sys.exit(0)

import pynvim

parser = argparse.ArgumentParser()
parser.add_argument("--observe", action="store_true")
parser.add_argument("--json", type=Path)
args = parser.parse_args()
ROOT = Path(__file__).resolve().parents[1]


def case(name, before="pri|nt(value)", after="print|(value)", edit=None,
         encoding="utf-16", snippet=False, defaults=False, action="accept", key="enter"):
    lines = before.split("\n")
    row = next(i for i, line in enumerate(lines) if "|" in line)
    prefix, tail = lines[row].split("|")
    lines[row] = prefix + tail
    col = len(prefix.encode())
    word = "call" if snippet else "привет" if name == "cyrillic" else "print"
    item = {"label": word, "kind": 3, "insertText": word}
    completion = {"isIncomplete": False, "items": [item]}
    if edit:
        def units(text):
            return len(text.encode()) if encoding == "utf-8" else len(text.encode("utf-16-le")) // 2
        start = units(prefix) - units("cal" if snippet else "pri")
        end = units(prefix)
        full = end + (1 if snippet else 2)
        def span(last):
            return {"start": {"line": row, "character": start},
                    "end": {"line": row, "character": last}}
        text_edit = {"newText": "call(${1:value})$0" if snippet else word}
        if edit == "dual":
            text_edit.update(insert=span(end), replace=span(full))
        else:
            text_edit["range"] = span(end if edit == "cursor" else full)
        if defaults:
            completion["itemDefaults"] = {"editRange": text_edit["range"]}
            item["textEditText"] = text_edit["newText"]
        else:
            item["textEdit"] = text_edit
    if snippet:
        item["insertTextFormat"] = 2
    if action == "effects":
        item["additionalTextEdits"] = [{"range": {"start": {"line": 0, "character": 0},
                                                   "end": {"line": 0, "character": 0}},
                                        "newText": "-- import\n"}]
        item["command"] = {"title": "accepted", "command": "midword.accept"}
    if action == "cancel":
        item["command"] = {"title": "must not execute", "command": "midword.accept"}
    return dict(name=name, lines=lines, row=row, col=col, after=after,
                completion=completion, encoding=encoding, snippet=snippet, action=action, key=key)


cases = [
    case("suffix"),
    case("whole", before="|print(value)"),
    case("different", before="pri|Other", after="print|Other"),
    case("longer-suffix", before="pri|ntOther", after="print|ntOther"),
    dict(case("edited-query", after="print|nt(value)"), typed="n"),
    case("full-range", edit="full"),
    case("cursor-range", edit="cursor", after="print|nt(value)"),
    case("insert-replace", edit="dual", after="print|nt(value)"),
    case("defaults", edit="full", defaults=True),
    case("snippet", before="cal|l;", after="call(item)|;", edit="full", snippet=True),
    case("cyrillic", before="при|вет()", after="привет|()"),
    *[case("unicode-" + encoding, before='-- привет 😀\nlocal привет = "😀"; pri|nt(value)',
           after='-- привет 😀\nlocal привет = "😀"; print|(value)', edit="full", encoding=encoding)
      for encoding in ("utf-8", "utf-16")],
    case("cancel", action="cancel", after="pri|nt(value)"),
    case("effects", edit="full", action="effects", after="-- import\nprint|(value)"),
    case("first-item", key="first"),
    case("undo", before="pri|nt(value)", after="pri|nt(value)", action="undo"),
    case("undo-range", edit="full", after="pri|nt(value)", action="undo"),
]


def run(configured, directory):
    nvim = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"])
    def lua(code, *values):
        return nvim.exec_lua(code, *values)
    def wait(check, message):
        until = time.monotonic() + 5
        while time.monotonic() < until:
            if check():
                return
            time.sleep(0.01)
        raise AssertionError(message + repr(lua("return {vim.fn.mode(),vim.fn.complete_info(),vim.api.nvim_get_current_line(),vim.v.errmsg}")))
    def keys(value):
        nvim.input(value)
        time.sleep(0.035)
    results = []
    try:
        lua("""
          local root,configured=...
          vim.opt.rtp:prepend(root)
          vim.o.virtualedit='onemore';vim.o.timeoutlen=50;vim.o.ttimeoutlen=10
          vim.opt.completeopt={'menu','menuone','noselect'}
          if configured then
            vim.opt.rtp:append(root..'/data/lazy/langmapper.nvim')
            require('langmapper').setup{hack_keymap=false}
            require('configs.completion').setup_mappings()
          end
        """, str(ROOT), configured)
        nvim.api.ui_attach(100, 28, {"rgb": True})
        for entry in cases:
            keys("<Esc>")
            lua("if vim.snippet.active() then vim.snippet.stop() end;vim.cmd.enew{bang=true}")
            nvim.current.buffer[:] = entry["lines"]
            nvim.current.buffer.options["filetype"] = "lua"
            lua("vim.api.nvim_win_set_cursor(0,{...})", entry["row"] + 1, entry["col"])
            events = directory / (str(configured) + entry["name"] + ".events")
            client = lua("""
              local python,script,root,opts,configured=...
              local id=vim.lsp.start{name='midword',cmd={python,script,'--server'},root_dir=root,init_options=opts}
              if not configured then vim.lsp.completion.enable(true,id,0,{autotrigger=false}) end
              return id
            """, sys.executable, str(Path(__file__).resolve()), str(directory),
                         {"encoding": entry["encoding"], "completion": entry["completion"], "events": str(events)}, configured)
            wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "initialize")
            assert lua("return vim.lsp.get_client_by_id(...).offset_encoding", client) == entry["encoding"]
            keys("i")
            # Establish the pre-acceptance undo boundary without changing text.
            keys("<C-g>u")
            keys("<C-Space>" if configured else "<C-x><C-o>")
            wait(lambda: lua("return vim.fn.pumvisible()") == 1, entry["name"] + " popup")
            items = lua("return vim.fn.complete_info().items")
            assert len(items) == 1, items
            if entry.get("typed"):
                keys(entry["typed"])
                wait(lambda: lua("return vim.fn.pumvisible()") == 1, "refilter popup")
            if entry["key"] == "first" and configured:
                keys("<C-CR>")
            else:
                keys("<C-n>")
                keys("<C-e>" if entry["action"] == "cancel" else "<CR>" if configured else "<C-y>")
            wait(lambda: lua("return vim.fn.pumvisible()") == 0, "accept/cancel")
            snippet_active = lua("return vim.snippet.active{direction=1}")
            if entry["snippet"]:
                assert snippet_active, "snippet missing"
                keys("item")
                lua("vim.snippet.jump(1)")
                time.sleep(0.035)
            if entry["action"] == "effects":
                wait(lambda: events.exists(), "command")
                assert events.read_text().splitlines() == ["accept"]
            if entry["action"] == "cancel":
                assert not events.exists(), "cancelled completion executed its command"
            if entry["action"] == "undo":
                keys("<Esc>u")
            lines = list(nvim.current.buffer[:])
            row, col = nvim.current.window.cursor
            marked = lines.copy()
            raw = marked[row - 1].encode()
            marked[row - 1] = raw[:col].decode() + "|" + raw[col:].decode()
            actual = "\n".join(marked)
            # Normal-mode cursor after undo is not an acceptance cursor contract.
            passed = lines == entry["lines"] if entry["action"] == "undo" else actual == entry["after"]
            result = {"case": entry["name"], "configured": configured, "encoding": entry["encoding"],
                      "actual": actual, "expected": entry["after"], "pass": passed, "cursor": [row, col],
                      "before_lines": entry["lines"], "before_cursor": [entry["row"] + 1, entry["col"]],
                      "completion": entry["completion"], "snippet_active": snippet_active,
                      "candidate": items[0]["word"], "commands": events.read_text().splitlines() if events.exists() else []}
            results.append(result)
            print(("PASS " if passed else "GAP  ") + ("config " if configured else "native ") + entry["name"] + ": " + repr(actual), flush=True)
            keys("<Esc>")
            lua("vim.lsp.stop_client(...,true)", client)
            wait(lambda: lua("return vim.lsp.get_client_by_id(...)==nil", client), "stop")
        assert lua("return vim.v.errmsg") == "", lua("return vim.v.errmsg")
        return results
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass


with tempfile.TemporaryDirectory(prefix="midword-") as temp:
    directory = Path(temp)
    (directory / "state/nvim").mkdir(parents=True)
    os.environ["XDG_STATE_HOME"] = str(directory / "state")
    os.environ["NVIM_LOG_FILE"] = str(directory / "nvim.log")
    results = run(False, directory) + run(True, directory)
    if args.json:
        args.json.write_text(json.dumps({"version": subprocess.check_output(["nvim", "--version"], text=True).splitlines()[0],
                                        "results": results}, ensure_ascii=False, indent=2) + "\n")
    if not args.observe:
        assert all(result["pass"] for result in results if result["configured"]), "configured midword gaps"
