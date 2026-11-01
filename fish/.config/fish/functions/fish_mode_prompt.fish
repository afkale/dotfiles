# Vi mode badge, Rosé Pine palette. One Material Design "alpha box" glyph per
# mode (I/N/R/V); each is drawn in the colour it had as a text badge before.
function fish_mode_prompt --description 'Rosé Pine vi mode indicator'
    switch $fish_bind_mode
        case insert
            set_color --bold 9ccfd8 # foam
            echo -n \U000f0c03 # md-alpha_i_box_outline
        case replace_one replace
            set_color --bold f6c177 # gold
            echo -n \U000f0c1e # md-alpha_r_box_outline
        case visual
            set_color --bold c4a7e7 # iris
            echo -n \U000f0c2a # md-alpha_v_box_outline
        case default
            set_color --bold eb6f92 # love
            echo -n \U000f0c12 # md-alpha_n_box_outline
        case '*'
            return
    end
    set_color normal
    echo -n ' '
end
