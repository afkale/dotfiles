function la --description="alias la=lsd -a" --wraps="lsd -a"
  if command -q lsd
    lsd -a $argv
  else
    command ls -a $argv
  end
end
