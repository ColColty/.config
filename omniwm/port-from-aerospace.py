#!/usr/bin/env python3
"""Patch OmniWM's generated settings.toml with the AeroSpace setup.

Run AFTER OmniWM's first launch has written ~/.config/omniwm/settings.toml
(switch.sh does this). Idempotent: re-running only fixes what differs.
Text-level patching on purpose: the system Python has no TOML writer, and the
generated file is flat "key = value" TOML, so regexes are safe here.
"""
import os, re, shutil, subprocess, sys, time, uuid, json

P = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/omniwm/settings.toml")
if not os.path.exists(P):
    sys.exit(f"{P} does not exist yet: launch OmniWM once so it writes its defaults")
BACKUP = P + ".bak-pre-port"
if not os.path.exists(BACKUP):
    shutil.copy(P, BACKUP)
    print(f"backup: {BACKUP}")
notes = []
ONLY = set(os.environ.get("PORT_ONLY", "general,gaps,workspaces,rules,hotkeys").split(","))

# ---------------------------------------------------------------- TOML text
def blocks(text):
    """Split into [(header_or_None, [lines])], header lines start with '['."""
    out, cur = [], (None, [])
    for line in text.splitlines():
        if re.match(r"^\s*\[", line):
            out.append(cur); cur = (line.strip(), [])
        else:
            cur[1].append(line)
    out.append(cur)
    return out

def join(bs):
    lines = []
    for h, ls in bs:
        if h is not None: lines.append(h)
        lines.extend(ls)
    return "\n".join(lines) + "\n"

def set_key(bs, header, key, value):
    """Set `key = value` inside the block with this header (created if missing)."""
    for i, (h, ls) in enumerate(bs):
        if h == header:
            for j, l in enumerate(ls):
                if re.match(rf"^\s*{re.escape(key)}\s*=", l):
                    if l.strip() != f"{key} = {value}":
                        ls[j] = f"{key} = {value}"; print(f"  {header} {key} = {value}")
                    return
            # insert before trailing blank lines
            k = len(ls)
            while k > 0 and ls[k-1].strip() == "": k -= 1
            ls.insert(k, f"{key} = {value}"); print(f"  {header} {key} = {value} (added)")
            return
    bs.append((header, [f"{key} = {value}", ""])); print(f"  {header} created, {key} = {value}")

def has_header(bs, header): return any(h == header for h, _ in bs)

def kv(ls, key):
    for l in ls:
        m = re.match(rf'^\s*{re.escape(key)}\s*=\s*"(.*)"\s*$', l)
        if m: return m.group(1)
    return None

src = open(P).read()
bs = blocks(src)

# ---------------------------------------------------------------- general
if "general" in ONLY:
    print("general/focus/bar:")
    set_key(bs, "[general]", "defaultLayoutType", '"niri"')     # the whole point: scrolling layout
    set_key(bs, "[general]", "ipcEnabled", "true")               # sketchybar + karabiner talk to omniwmctl
    set_key(bs, "[focus]", "followsMouse", "false")
    set_key(bs, "[workspaceBar]", "enabled", "false")            # sketchybar draws the workspaces

# ---------------------------------------------------------------- gaps (AeroSpace: inner 5, outer 5, top 38 for the bar)
if "gaps" in ONLY:
    print("gaps:")
    set_key(bs, "[gaps]", "size", "5.0")
    set_key(bs, "[gaps]", "fullscreenUsesOuterGaps", "true")   # fullscreen still leaves room for the bar
    if has_header(bs, "[gaps.outer]"):
        for k, v in (("left", "5.0"), ("right", "5.0"), ("bottom", "5.0"), ("top", "38.0")):
            set_key(bs, "[gaps.outer]", k, v)
    else:
        for k, v in (("outer.left", "5.0"), ("outer.right", "5.0"), ("outer.bottom", "5.0"), ("outer.top", "38.0")):
            set_key(bs, "[gaps]", k, v)

# ---------------------------------------------------------------- workspace 10 (AeroSpace had 1..10)
if "workspaces" in ONLY:
    ws_idx = [i for i, (h, _) in enumerate(bs) if h == "[[workspaces]]"]
    names = [kv(bs[i][1], "name") for i in ws_idx]
    if "10" not in names and ws_idx:
        last = ws_idx[-1]
        # copy the last workspace block plus its [workspaces.*] sub-blocks
        end = last + 1
        while end < len(bs) and bs[end][0] and bs[end][0].startswith("[workspaces."): end += 1
        copy = []
        for h, ls in bs[last:end]:
            nl = []
            for l in ls:
                l = re.sub(r'^(\s*id\s*=\s*)".*"', rf'\g<1>"{str(uuid.uuid4()).upper()}"', l)
                l = re.sub(r'^(\s*name\s*=\s*)".*"', r'\g<1>"10"', l)
                l = re.sub(r'^(\s*displayName\s*=\s*)".*"', r'\g<1>"10"', l)
                nl.append(l)
            copy.append((h, nl))
        bs[end:end] = copy
        print("workspaces: added workspace 10 (same monitor assignment as the last one)")
    else:
        print(f"workspaces: {len(ws_idx)} present, names {names}")

# ---------------------------------------------------------------- app rules (from aerospace.toml on-window-detected)
# Added through `omniwmctl rule add`, NOT by appending TOML: raw appended
# [[appRules]] blocks made OmniWM reject the whole file (2026-09-05). The CLI
# validates each rule and OmniWM writes the file itself. Needs IPC (see below).
RULES = [  # (bundleId, titleRegex, layout, workspace)
    ("company.thebrowser.Browser", "Little Arc", "float", None),
    (None, "Picture-in-Picture", "float", None),
    ("com.apple.MobileSMS", None, "float", None),
    ("com.t3tools.t3code", None, None, "1"),
    ("com.mitchellh.ghostty", None, None, "1"),
    ("com.anthropic.claudefordesktop", None, None, "1"),
    ("company.thebrowser.Browser", None, None, "2"),
    ("com.linear", None, None, "3"),
    ("com.automattic.beeper.desktop", None, None, "5"),   # Beeper Desktop (was im.beeper under AeroSpace)
    ("com.apple.Music", None, None, "9"),
    ("com.todesktop.210203cqcj00tw1", None, None, "4"),   # Morgen
    ("notion.id", None, None, "4"),
]
def add_rules():
    existing = [(kv(ls, "bundleId") or None, kv(ls, "titleRegex") or None, kv(ls, "assignToWorkspace") or None, kv(ls, "layout") or None)
                for h, ls in blocks(open(P).read()) if h == "[[appRules]]"]
    n = 0
    for bid, rx, layout, ws in RULES:
        if any(e[0] == bid and e[1] == rx and (e[2] == ws if ws else e[3] == layout) for e in existing): continue
        cmd = ["/opt/homebrew/bin/omniwmctl", "rule", "add"]
        if bid: cmd += ["--bundle-id", bid]
        if rx: cmd += ["--title-regex", rx]
        if layout: cmd += ["--layout", layout]
        if ws: cmd += ["--assign-to-workspace", ws]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0: n += 1
        else: notes.append(f"rule add failed for {bid or rx}: {r.stderr.strip()[:120]}")
    print(f"appRules: {n} added via omniwmctl ({len(existing)} were present)")

# ---------------------------------------------------------------- hotkeys (AeroSpace bindings)
if "hotkeys" in ONLY:
    # (regex on the action id, binding). Exactly one id must match each regex.
    WANT = [
        (r"^focus\.left$", "Option+H"), (r"^focus\.down$", "Option+J"),
        (r"^focus\.up$", "Option+K"), (r"^focus\.right$", "Option+L"),
        (r"^move\.left$", "Option+Shift+H"), (r"^move\.down$", "Option+Shift+J"),
        (r"^move\.up$", "Option+Shift+K"), (r"^move\.right$", "Option+Shift+L"),
        (r"^toggleFullscreen$", "Option+F"),
        (r"^toggleFocusedWindowFloating$", "Unassigned"),        # Karabiner: Option+Shift+F runs toggle-float.sh (sizes to 60%)
        (r"^closeFocusedWindow$", "Option+Q"),
        (r"^balanceSizes$", "Option+B"),
        (r"^toggleColumnTabbed$", "Option+W"),                    # accordion equivalent
        (r"^toggleWorkspaceLayout$", "Option+E"),
        (r"^switchWorkspace\.previous$", "Option+LeftBracket"),
        (r"^switchWorkspace\.next$", "Option+RightBracket"),
        (r"^workspaceBackAndForth$", "Option+Tab"),
        (r"^moveWorkspaceToMonitor\.right$", "Option+Shift+Tab"),
        (r"^toggleScratchpad\.1$", "Option+Minus"),
        (r"^assignFocusedWindowToScratchpad\.1$", "Option+Shift+Minus"),
    ]
    # switchWorkspace.N / moveToWorkspace.N are ZERO-based (switchWorkspace.0 = Option+1) and
    # already default to Option+1..9 / Option+Shift+1..9: leave them alone. Workspace 10 goes
    # through Karabiner -> omniwmctl.
    # Karabiner owns these chords; make sure OmniWM does not also act on them.
    KARABINER_OWNED = ["Option+Return", "Option+0", "Option+Shift+0", "Option+M", "Option+Shift+F"]

    hk = [(i, kv(ls, "id"), kv(ls, "binding")) for i, (h, ls) in enumerate(bs) if h == "[[hotkeys]]"]
    def norm(b): return re.sub(r"\s+", "", b or "").lower()
    def set_binding(i, b):
        ls = bs[i][1]
        for j, l in enumerate(ls):
            if re.match(r"^\s*binding\s*=", l): ls[j] = f'binding = "{b}"'; return
        ls.insert(0, f'binding = "{b}"')

    print("hotkeys:")
    if not hk:
        notes.append("no [[hotkeys]] blocks found: bindings NOT changed (schema differs from the docs?)")
    else:
        taken = set()
        for rx, b in WANT:
            m = [x for x in hk if x[1] and re.search(rx, x[1])]
            if len(m) != 1:
                notes.append(f"hotkey {rx}: {len(m)} ids matched ({[x[1] for x in m]}); left as is"); continue
            i, hid, cur = m[0]
            if b != "Unassigned": taken.add(norm(b))
            if norm(cur) != norm(b):
                # free the chord from whatever OmniWM had on it
                for k, oid, ob in hk:
                    if k != i and norm(ob) == norm(b) and b != "Unassigned":
                        set_binding(k, "Unassigned"); print(f"  {oid}: {ob} -> Unassigned (chord taken by {hid})")
                set_binding(i, b); print(f"  {hid}: {cur} -> {b}")
        # re-read: bindings changed above
        hk = [(i, kv(ls, "id"), kv(ls, "binding")) for i, (h, ls) in enumerate(bs) if h == "[[hotkeys]]"]
        for k, oid, ob in hk:
            if norm(ob) in {norm(x) for x in KARABINER_OWNED} and norm(ob) not in taken:
                set_binding(k, "Unassigned"); print(f"  {oid}: {ob} -> Unassigned (Karabiner owns this chord)")

# ---------------------------------------------------------------- write
new = join(bs)
if new != src:
    open(P, "w").write(new); print(f"wrote {P}")
else:
    print("settings.toml already up to date")

# ---------------------------------------------------------------- validate (best effort)
try:
    try: import tomllib as t
    except ImportError: import tomli as t
    t.loads(open(P).read()); print("TOML parses OK")
except ImportError:
    notes.append("no TOML parser available (pip3 install --user tomli) - not validated; OmniWM shows parse errors in Diagnostics")
except Exception as e:
    print(f"TOML PARSE ERROR: {e}\nrestoring {BACKUP}"); shutil.copy(BACKUP, P); sys.exit(1)

# ---------------------------------------------------------------- notch display override (needs IPC up)
def ipc_ok():
    return subprocess.run(["/opt/homebrew/bin/omniwmctl", "ping"], capture_output=True).returncode == 0
for _ in range(30):
    if ipc_ok(): break
    time.sleep(1)
if ipc_ok() and "rules" in ONLY:
    time.sleep(1); add_rules(); time.sleep(1)
if ipc_ok():
    out = subprocess.run(["/opt/homebrew/bin/omniwmctl", "query", "displays", "--format", "json"], capture_output=True, text=True).stdout
    def walk(o):
        if isinstance(o, dict):
            if "name" in o and "has-notch" in o: yield o
            for v in o.values(): yield from walk(v)
        elif isinstance(o, list):
            for v in o: yield from walk(v)
    try: displays = list(walk(json.loads(out)))
    except Exception: displays = []
    notch = [d for d in displays if d.get("has-notch")]
    src = open(P).read()
    for d in notch:
        if f'monitorName = "{d["name"]}"' in src: continue
        src += f'\n[[monitorGapOverrides]]\nid = "{str(uuid.uuid4()).upper()}"\nmonitorName = "{d["name"]}"\nouterGapTop = 0.0\n'
        print(f'monitorGapOverrides: outerGapTop = 0 for notch display "{d["name"]}" (bar lives in the notch band there)')
    open(P, "w").write(src)
    if not notch: notes.append("no notch display connected now: re-run this script with the MacBook display active to add its outerGapTop = 0 override")
else:
    notes.append("IPC not reachable (omniwmctl ping failed): app rules and notch-display gap override skipped; re-run once OmniWM is running")

print("\nNOTES:" if notes else "\nno notes")
for n in notes: print(" -", n)
