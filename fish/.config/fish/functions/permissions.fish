function permissions --wraps='printf "r:4\\nw:2\\nx:1\\n"' --description 'alias permissions=printf "r:4\\nw:2\\nx:1\\n"'
    printf "r:4\nw:2\nx:1\n" $argv
end
