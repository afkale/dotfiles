function files --wraps=yazi --description 'alias files yazi'
  if not type -q yazi
    echo "files: yazi is not installed (pacman -S yazi)" >&2
    return 127
  end

  yazi $argv
end
