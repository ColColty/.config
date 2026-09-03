# herdr

Copy `config.toml` into `~/.config/herdr/` (do not symlink the whole directory: herdr keeps its
socket, logs, plugins and session.json there).

- tmux-style prefix keys, no name prompts, agent panel sorted by priority, prefix+1..9 = agents,
  prefix+shift+1..9 = tabs, terminal toasts + sound.
- PR status on the focused agent's sidebar row comes from the `gh-pr` plugin:
  `herdr plugin install wyattjoh/herdr-plugin-gh-pr` (needs `bun` and `gh`). prefix+u opens the PR,
  prefix+i refreshes it. `$pr` token is placed in `[ui.sidebar.agents] rows`.
- More plugins: https://herdr.dev/plugins/ (GitHub repos tagged `herdr-plugin`);
  `herdr plugin install owner/repo`.

Bell over ssh/mosh: `~/.claude/settings.json` has Notification/Stop hooks that `printf '\a' > /dev/tty`;
herdr ≥ 0.8.2 forwards BEL to the outer terminal; Ghostty `bell-features = system` (see `../ghostty/config`).
BEL survives mosh; OSC desktop notifications only survive plain ssh.
