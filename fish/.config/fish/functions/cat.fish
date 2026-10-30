function cat --description="alias cat=bat -n" --wraps="bat -n"
  if type -q bat
    bat -n $argv
  else
    command cat $argv
  end
end
