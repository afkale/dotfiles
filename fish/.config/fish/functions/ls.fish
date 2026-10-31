function ls --description="alias ls=lsd" --wraps="lsd"
  if command -q lsd
    lsd $argv
  else
    command ls $argv
  end
end
