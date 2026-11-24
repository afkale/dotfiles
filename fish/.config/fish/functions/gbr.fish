function gbr --description 'Pick a git branch with fzf and check it out'
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "gbr: not a git repository" >&2
        return 1
    end

    set -l branches (git branch -a --format='%(refname:short)' 2>/dev/null | sort -u)
    if test (count $branches) -eq 0
        echo "gbr: no branches found" >&2
        return 1
    end

    set -l selected (printf '%s\n' $branches | fzf \
        --prompt='branch> ' \
        --preview 'git log --oneline --graph --decorate -10 {} 2>/dev/null' \
        --preview-window 'right,50%,border-left')

    if test -z "$selected"
        return 0
    end

    # Strip the "remotes/origin/" prefix if present, so we checkout a local
    # tracking branch rather than a detached HEAD.
    set -l branch (string replace -r '^remotes/[^/]+/' '' -- $selected)

    git checkout $branch
end