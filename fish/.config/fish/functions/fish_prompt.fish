# ─── Rosé Pine (main) ────────────────────────────────────────────────────────
# base #191724 · surface #1f1d2e · overlay #26233a · muted #6e6a86
# subtle #908caa · text #e0def4 · love #eb6f92 · gold #f6c177
# rose #ebbcba · pine #31748f · foam #9ccfd8 · iris #c4a7e7

# Force git prompt color/char revalidation when this file is re-sourced.
set -e ___fish_git_prompt_init

# Nerd Font Material Design icons — one family, so they share the same size,
# weight and baseline (the language/devicon glyphs differ in all three).
set -g __rp_icon_dir \U000f024b
set -g __rp_icon_git \U000f062c
set -g __rp_icon_venv \U000f0320
set -g __rp_icon_conda \U000f03d6
set -g __rp_icon_node \U000f0399
set -g __rp_icon_python \U000f0320
set -g __rp_icon_rust \U000f1617
set -g __rp_icon_go \U000f07d3
set -g __rp_icon_timer \U000f051b
set -g __rp_icon_error \U000f05d6
set -g __rp_icon_jobs \U000f08d6
set -g __rp_icon_ssh \U000f01e7
set -g __rp_icon_root \U000f0498
set -g __rp_icon_arrow \U000f0142
set -g __rp_icon_git_dirty \U000f03eb
set -g __rp_icon_git_staged \U000f0419
set -g __rp_icon_git_untracked \U000f0625
set -g __rp_icon_git_invalid \U000f05d6
set -g __rp_icon_git_clean \U000f05e1
set -g __rp_icon_git_stash \U000f0687

# Git prompt: Rosé Pine colors and informative state markers.
set -q __fish_git_prompt_showdirtystate; or set -g __fish_git_prompt_showdirtystate 1
set -q __fish_git_prompt_showuntrackedfiles; or set -g __fish_git_prompt_showuntrackedfiles 1
set -q __fish_git_prompt_showstashstate; or set -g __fish_git_prompt_showstashstate 1
set -q __fish_git_prompt_showcolorhints; or set -g __fish_git_prompt_showcolorhints 1
set -q __fish_git_prompt_showupstream; or set -g __fish_git_prompt_showupstream auto
set -q __fish_git_prompt_color_prefix; or set -g __fish_git_prompt_color_prefix 6e6a86
set -q __fish_git_prompt_color_suffix; or set -g __fish_git_prompt_color_suffix 6e6a86
set -q __fish_git_prompt_color_branch; or set -g __fish_git_prompt_color_branch 9ccfd8
set -q __fish_git_prompt_color_branch_dirty; or set -g __fish_git_prompt_color_branch_dirty eb6f92
set -q __fish_git_prompt_color_branch_staged; or set -g __fish_git_prompt_color_branch_staged f6c177
set -q __fish_git_prompt_color_branch_detached; or set -g __fish_git_prompt_color_branch_detached eb6f92
set -q __fish_git_prompt_color_dirtystate; or set -g __fish_git_prompt_color_dirtystate f6c177
set -q __fish_git_prompt_color_stagedstate; or set -g __fish_git_prompt_color_stagedstate eb6f92
set -q __fish_git_prompt_color_untrackedfiles; or set -g __fish_git_prompt_color_untrackedfiles f6c177
set -q __fish_git_prompt_color_invalidstate; or set -g __fish_git_prompt_color_invalidstate eb6f92
set -q __fish_git_prompt_color_cleanstate; or set -g __fish_git_prompt_color_cleanstate 31748f
set -q __fish_git_prompt_color_stashstate; or set -g __fish_git_prompt_color_stashstate eb6f92
set -q __fish_git_prompt_color_upstream; or set -g __fish_git_prompt_color_upstream 908caa

# State glyphs carry a leading space so multiple status icons stay apart.
set -q __fish_git_prompt_char_dirtystate; or set -g __fish_git_prompt_char_dirtystate " $__rp_icon_git_dirty"
set -q __fish_git_prompt_char_stagedstate; or set -g __fish_git_prompt_char_stagedstate " $__rp_icon_git_staged"
set -q __fish_git_prompt_char_untrackedfiles; or set -g __fish_git_prompt_char_untrackedfiles " $__rp_icon_git_untracked"
set -q __fish_git_prompt_char_invalidstate; or set -g __fish_git_prompt_char_invalidstate " $__rp_icon_git_invalid"
set -q __fish_git_prompt_char_cleanstate; or set -g __fish_git_prompt_char_cleanstate " $__rp_icon_git_clean"
set -q __fish_git_prompt_char_stashstate; or set -g __fish_git_prompt_char_stashstate " $__rp_icon_git_stash"
set -q __fish_git_prompt_char_upstream_prefix; or set -g __fish_git_prompt_char_upstream_prefix ' '
set -q __fish_git_prompt_char_stateseparator; or set -g __fish_git_prompt_char_stateseparator ''

# Extract the first dotted version number from a command's output.
function __rp_version
    set -l out ($argv 2>/dev/null | head -1)
    string match -r '\d+\.\d+(\.\d+)?' -- $out | head -1
end

# Human-readable command duration from $CMD_DURATION (milliseconds).
function __rp_duration --argument-names ms
    if test $ms -ge 60000
        printf '%dm%02ds' (math "floor($ms / 60000)") (math "floor($ms % 60000 / 1000)")
    else if test $ms -ge 1000
        printf '%.1fs' (math "$ms / 1000")
    else
        printf '%dms' $ms
    end
end

function fish_prompt --description 'Rosé Pine prompt'
    set -l last_status $status
    set -l muted 6e6a86
    set -l subtle 908caa
    set -l love eb6f92
    set -l gold f6c177
    set -l rose ebbcba
    set -l foam 9ccfd8
    set -l iris c4a7e7

    # ── line 1: context ──────────────────────────────────────────────────────
    if set -q SSH_CONNECTION
        set_color --bold $love
        echo -n $__rp_icon_ssh' '
        echo -n $USER'@'(prompt_hostname)'  '
    else if test "$USER" = root
        set_color --bold $love
        echo -n $__rp_icon_root' '$USER'  '
    end

    # Working directory
    set_color $subtle
    echo -n $__rp_icon_dir' '
    set_color $iris
    echo -n (prompt_pwd)

    # Git branch + state
    fish_vcs_prompt "  $__rp_icon_git %s"

    # Python virtualenv
    if set -q VIRTUAL_ENV
        set_color $gold
        echo -n '  '$__rp_icon_venv
        set_color $muted
        echo -n ' venv:'
        set_color $gold
        echo -n (path basename $VIRTUAL_ENV)
    end

    # Conda environment
    if set -q CONDA_DEFAULT_ENV; and test "$CONDA_DEFAULT_ENV" != base
        set_color $rose
        echo -n '  '$__rp_icon_conda
        set_color $muted
        echo -n ' conda:'
        set_color $rose
        echo -n $CONDA_DEFAULT_ENV
    end

    # Node / JavaScript project
    if test -f package.json -o -f package-lock.json -o -f pnpm-lock.yaml -o -f yarn.lock -o -f bun.lockb -o -f deno.json -o -f deno.jsonc -o -f .nvmrc -o -d node_modules
        if type -q node
            set -l v (__rp_version node --version)
            if test -n "$v"
                set_color $foam
                echo -n '  '$__rp_icon_node
                set_color $muted
                echo -n ' node:'
                set_color $foam
                echo -n $v
            end
        end
    end

    # Python project (skip when a virtualenv already describes the interpreter)
    if not set -q VIRTUAL_ENV; and test -f pyproject.toml -o -f requirements.txt -o -f .python-version -o -f Pipfile -o -f setup.py -o -f manage.py
        set -l py python
        type -q $py; or set py python3
        if type -q $py
            set -l v (__rp_version $py --version)
            if test -n "$v"
                set_color $gold
                echo -n '  '$__rp_icon_python
                set_color $muted
                echo -n ' py:'
                set_color $foam
                echo -n $v
            end
        end
    end

    # Rust project
    if test -f Cargo.toml; and type -q rustc
        set -l v (__rp_version rustc --version)
        if test -n "$v"
            set_color $gold
            echo -n '  '$__rp_icon_rust
            set_color $muted
            echo -n ' rust:'
            set_color $foam
            echo -n $v
        end
    end

    # Go project
    if test -f go.mod; and type -q go
        set -l v (__rp_version go version)
        if test -n "$v"
            set_color $foam
            echo -n '  '$__rp_icon_go
            set_color $muted
            echo -n ' go:'
            set_color $foam
            echo -n $v
        end
    end

    # Background jobs
    set -l job_count (count (jobs -p))
    if test $job_count -gt 0
        set_color $rose
        echo -n '  '$__rp_icon_jobs' '$job_count
    end

    # Last command duration (only if it was slow)
    if set -q CMD_DURATION; and test "$CMD_DURATION" -ge 2000
        set_color $muted
        echo -n '  '$__rp_icon_timer' '(__rp_duration $CMD_DURATION)
    end

    # Last command exit status
    if test $last_status -ne 0
        set_color $love
        echo -n '  '$__rp_icon_error' '$last_status
    end

    # ── line 2: prompt character ─────────────────────────────────────────────
    echo
    if test $last_status -ne 0
        set_color --bold $love
    else if test "$USER" = root
        set_color --bold $gold
    else if not test -w .
        set_color --bold $gold
    else
        set_color --bold $foam
    end
    echo -n $__rp_icon_arrow' '
    set_color normal
end
