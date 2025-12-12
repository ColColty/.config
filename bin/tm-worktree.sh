#!/usr/bin/env bash

COMMAND=$1
shift

notify() {
    tmux display-message "$1"
}

create_worktree() {
    local BRANCH_NAME=$1
    local CURRENT_PATH=$2

    cd "$CURRENT_PATH" || return

    # 1. Resolve Git Data
    local GIT_COMMON_DIR
    GIT_COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

    if [ -z "$GIT_COMMON_DIR" ]; then
        notify "Error: Not inside a git repository."
        exit 1
    fi

    local REPO_ROOT
    REPO_ROOT=$(dirname "$GIT_COMMON_DIR")
    local REPO_NAME
    REPO_NAME=$(basename "$REPO_ROOT")

    # 2. Define Paths & Names
    local WORKTREE_BASE="$HOME/.worktrees/$REPO_NAME"
    local WORKTREE_PATH="$WORKTREE_BASE/$BRANCH_NAME"
    
    # Sanitize Session Name (replace . with _)
    local SAFE_REPO_NAME="${REPO_NAME//./_}"
    local SESSION_NAME="${SAFE_REPO_NAME}/${BRANCH_NAME}"

    mkdir -p "$WORKTREE_BASE"

    # 3. Check / Create Worktree
    if [ -d "$WORKTREE_PATH" ]; then
        # Case A: Folder exists. Assume it's valid and just switch.
        notify "Worktree found. Switching to session..."
    else
        # Case B: Folder missing. Create it.
        
        # Check if branch exists in git (but not in this worktree folder)
        if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
            notify "Branch exists. Checking out into new worktree..."
            if ! git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>&1; then
                 notify "Error: Failed to checkout existing branch."
                 exit 1
            fi
        else
            notify "Creating new branch and worktree..."
            if ! git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" 2>&1; then
                 notify "Error creating worktree."
                 exit 1
            fi
        fi
    fi

    # 4. Create Session (if needed)
    # If the worktree existed but the session didn't (e.g. after a reboot), this creates it.
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_PATH" || true
    fi

    # 5. Switch
    tmux switch-client -t "$SESSION_NAME"
}

remove_worktree() {
    local CURRENT_SESSION=$1
    local CURRENT_PATH=$2

    cd "$CURRENT_PATH" || return

    local IS_WORKTREE
    IS_WORKTREE=$(git rev-parse --is-inside-work-tree 2>/dev/null)
    local IS_BARE_GIT
    IS_BARE_GIT=$(test -f .git && echo "yes" || echo "no")

    if [ "$IS_WORKTREE" != "true" ] || [ "$IS_BARE_GIT" != "yes" ]; then
        notify "Error: This is not a worktree."
        exit 1
    fi

    if [[ -n $(git status --porcelain) ]]; then
        notify "Error: Worktree is dirty. Commit first."
        exit 1
    fi

    if ! tmux switch-client -l 2>/dev/null; then
        tmux switch-client -n
    fi

    tmux kill-session -t "$CURRENT_SESSION"
    sleep 0.2
    git worktree remove . --force
    notify "Worktree removed."
}

case "$COMMAND" in
    create) create_worktree "$@" ;;
    remove) remove_worktree "$@" ;;
esac
