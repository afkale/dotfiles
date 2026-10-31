function ff --wraps=fastfetch --description 'alias ff fastfetch'
  if command -q fastfetch
    fastfetch $argv
  end
end
