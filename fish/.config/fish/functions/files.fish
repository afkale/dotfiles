function files --wraps=yazi --description 'alias files yazi'
  if not type -q yazi
    echo "files: yazi is not installed" >&2
    return 127
  end

  yazi $argv
end
