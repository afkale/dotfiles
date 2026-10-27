# Vi mode badge, Rosé Pine palette.
function fish_mode_prompt --description 'Rosé Pine vi mode indicator'
    switch $fish_bind_mode
        case default
            set_color --bold 191724 --background eb6f92
            echo -n ' NORMAL '
        case replace_one replace
            set_color --bold 191724 --background f6c177
            echo -n ' REPLACE '
        case visual
            set_color --bold 191724 --background c4a7e7
            echo -n ' VISUAL '
        case '*'
            return
    end
    set_color normal
    echo -n ' '
end
