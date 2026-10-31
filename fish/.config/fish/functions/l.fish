function l --description="alias l=lsd" --wraps="lsd"
  if command -q lsd
    lsd $argv
  else
    command ls $argv
  end
end
