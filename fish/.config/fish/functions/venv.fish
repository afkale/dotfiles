function venv --description="alias venv=source .venv/bin/activate.fish" --wraps="source .venv/bin/activate.fish"
  if not test -f .venv/bin/activate.fish
    echo "venv: .venv/bin/activate.fish not found" >&2
    return 1
  end

  source .venv/bin/activate.fish
end
