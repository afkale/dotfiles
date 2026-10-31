function lla --description="alias lla=lsd -la" --wraps="lsd -la"
  if command -q lsd
    lsd -la $argv
  else
    command ls -la $argv
  end
end
