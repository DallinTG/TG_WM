package Comands

// import sy"core:sync"

commands::enum{
    non,

    move_focus_left,
    move_focus_right,
    move_focus_up,
    move_focus_down,

    move_window_left,
    move_window_right,
    move_window_up,
    move_window_down,
}
command_buff_size::10

command_buff::[command_buff_size]commands

process_commands::proc(commands:^command_buff){
    for &com in commands{
        switch com{
            case .non:

            case .move_focus_left:
            case .move_focus_right:
            case .move_focus_up:
            case .move_focus_down:

            case .move_window_left:
            case .move_window_right:
            case .move_window_up:
            case .move_window_down:
        }
    }
}