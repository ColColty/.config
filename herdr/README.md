# herdr

Copy `config.toml`, `pr-status.sh` and `open-pr.sh` into `~/.config/herdr/` (do not symlink the
whole directory: herdr keeps its socket, logs and session.json there).

- `config.toml`  tmux-style prefix keys, no name prompts, agents-first sidebar, PR tokens, terminal toasts.
- `pr-status.sh` runs every 60s from `ui.tab_bar_right`; stamps `$pr` on every agent pane and space via
  `herdr pane|workspace report-metadata`, caches `gh pr view` in `~/.cache/herdr-pr`.
- `open-pr.sh`   `prefix+shift+g` opens the focused pane's PR (or repo) in the browser.

Bell over ssh/mosh: `~/.claude/settings.json` has Notification/Stop hooks that `printf '\a' > /dev/tty`;
herdr ≥ 0.8.2 forwards BEL to the outer terminal; Ghostty `bell-features = system,attention,title`
(see `../ghostty/config`). BEL survives mosh; OSC desktop notifications only survive plain ssh.
