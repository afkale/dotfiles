function tree --description="alias tree=lsd --tree" --wraps="lsd --tree"
  if command -q lsd
    lsd --tree $argv
  else
    command tree $argv
  end
end
