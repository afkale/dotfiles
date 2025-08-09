function venv --description="alias venv=source .venv/bin/activate.fish" --wraps="source .venv/bin/activate.fish"
    source .venv/bin/activate.fish $argv
end
