function fish_right_prompt --description 'Rosé Pine clock'
    set_color 6e6a86
    echo -n \U000f0150' '
    set_color 908caa
    echo -n (date '+%H:%M')
    set_color normal
end
