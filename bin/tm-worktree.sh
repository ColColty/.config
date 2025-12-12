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

    # 2. Check if branch is ALREADY checked out anywhere
    # We use git worktree list --porcelain to reliably find the path
    local EXISTING_WT_PATH
    EXISTING_WT_PATH=$(git worktree list --porcelain | grep -B 2 "^branch refs/heads/$BRANCH_NAME$" | grep "^worktree " | cut -d ' ' -f 2-)

    local WORKTREE_PATH
    
    if [ -n "$EXISTING_WT_PATH" ]; then
        # CASE A: Branch is already active in another folder
        WORKTREE_PATH="$EXISTING_WT_PATH"
        notify "Branch active at $(basename "$WORKTREE_PATH"). Switching..."
    else
        # CASE B: Branch is not checked out. Create new standard path.
        local WORKTREE_BASE="$HOME/.worktrees/$REPO_NAME"
        WORKTREE_PATH="$WORKTREE_BASE/$BRANCH_NAME"
        mkdir -p "$WORKTREE_BASE"

        # Check if folder exists (but git doesn't think the branch is there)
        if [ -d "$WORKTREE_PATH" ]; then
             notify "Resuming existing worktree folder..."
        else
            # Actually create the worktree
            notify "Creating worktree for $BRANCH_NAME..."
            
            # Check if branch exists in git history (but not checked out)
            if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
                # Branch exists: Checkout
                if ! git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>&1; then
                    notify "Error checking out existing branch."
                    exit 1
                fi
            else
                # Branch new: Create (-b)
                if ! git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" 2>&1; then
                    notify "Error creating new branch/worktree."
                    exit 1
                fi
            fi
        fi
    fi

    # 3. Create Session
    # Sanitize Session Name
    local SAFE_REPO_NAME="${REPO_NAME//./_}"
    local SESSION_NAME="${SAFE_REPO_NAME}/${BRANCH_NAME}"

    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_PATH" || true
    fi

    # 4. Switch
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
