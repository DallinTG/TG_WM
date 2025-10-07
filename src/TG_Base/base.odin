package TG_Base

import "core:time"
import "core:fmt"
import "core:math/linalg"
import "core:math"
import "core:math/rand"
import "base:runtime"
import rl "vendor:raylib"
import noise"core:math/noise"
import clay "/clay-odin"
import "core:log"
import "core:thread"
import te "core:terminal"
import str "core:strings"
import scon"core:strconv"
import utf16"core:unicode/utf16"
import os2 "core:os/os2"
import "core:mem"
import hm"../handle_map_static"
import cm"../Commands"

import w"core:sys/windows"

g:^state

win_handle::distinct hm.Handle
state::struct{
    stop:bool,
    // monitors:[8]monitor_data,
    window_keys:map[w.HWND]win_handle,
    windows :hm.Handle_Map(window,win_handle,500),
    // curent_win_node:^windows_nodes,
    // root_node:^windows_nodes,
    // windows:map[w.HWND]windows_nodes,
    // branches:[dynamic]windows_nodes,
    ui_mem:[^]u8,
    temp_d:temp_data,
    ui_render_command:clay.ClayArray(clay.RenderCommand),
    event:event_data,
    time:time_stuff,
    style:style,

    cursor_pos:[2]i32,

    shared_comands_handle:w.HANDLE,
    shared_comands_ptr:^cm.command_buff,

    focused_window:w.HWND,
    
}
l_r::enum{
    left,
    right,
    up,
    down,
}
time_data::struct{

}

monitor_data::struct{
    is_main:bool,
    temp_is_up_to_date:bool,//! this is only used to help me loop the monitors 
    data : w.MONITORINFO,
}

window::struct{
    handle:win_handle,
    hwnd:w.HWND,
    pos_size:[4]i32,
    min_size:[2]i32,
    offset:[4]i32,
}

temp_data::struct{
    w_count:int,
}
    

init::proc(){
    init_styles()
    create_shared_comands()

    hide_show_task_bar(true)
    maintane_settings()

    for !g.stop{
        g.focused_window = w.GetForegroundWindow()
        maintain_cursor()
        maintain_windo_pos_size()
        maintain_shared_comands()
        w.EnumWindows(cb_for_all_windows_get,0)
        maintain_timers()
        // g.ui_render_command=create_ui_layout()
        // clay_raylib_render(&g.ui_render_command)
        time.sleep(time.Millisecond * 16)
        if g.time.frame_count >1500{g.stop = true}
    }
    shutdoun()
}





create_shared_comands::proc(){
    g.shared_comands_handle=w.CreateFileMappingW(
        w.INVALID_HANDLE_VALUE,       // Use the system paging file
        nil,                          // Default security
        w.PAGE_READWRITE,             // Read/write access
        0, size_of(cm.command_buff),                       // Size of the memory block (256 bytes)
        "TG_comands"          // The name for the shared memory
    )

    g.shared_comands_ptr = cast(^cm.command_buff)w.MapViewOfFile(
        g.shared_comands_handle,
        w.FILE_MAP_ALL_ACCESS,
        0,
        0,
        0,
    )
}

move_focus::proc(move:l_r){
    pad::40
    ofset::pad/4
    f_pos:=rec_to_xywh(get_window_pos_size(g.focused_window))
    f_center:[2]i32={f_pos.x+f_pos.z/2,f_pos.y+f_pos.w/2}
    clos_win:[2]i32
    clos_win_ptr:w.HWND
    curent_dist:i32=100000
    for key,handl in g.window_keys{
        if key == nil{continue}
        win:=hm.get(&g.windows,handl)
        if win ==nil{continue}
        fmt.print("waffles\n")
        if move==.left  {if !rects_overlap({f_pos.x-pad+ofset,f_pos.y+ofset,f_pos.z-pad/2,f_pos.w-pad/2},win.pos_size){continue}}
        if move==.right {if !rects_overlap({f_pos.x+pad+ofset,f_pos.y+ofset,f_pos.z-pad/2,f_pos.w-pad/2},win.pos_size){continue}}
        if move==.up    {if !rects_overlap({f_pos.x+ofset,f_pos.y-pad+ofset,f_pos.z-pad/2,f_pos.w-pad/2},win.pos_size){continue}}
        if move==.down  {if !rects_overlap({f_pos.x+ofset,f_pos.y+pad+ofset,f_pos.z-pad/2,f_pos.w-pad/2},win.pos_size){continue}}

        win_center:[2]i32={win.pos_size.x+win.pos_size.z/2,win.pos_size.y+win.pos_size.w/2}
        if key!=g.focused_window{
            clos_win_ptr = key
            clos_win=win_center
            break
        }

    }
    if clos_win_ptr!=nil{
        w.SetCursorPos(clos_win.x,clos_win.y)
        set_focus(clos_win_ptr)
        g.focused_window=clos_win_ptr
    }
}

rects_overlap :: proc(a:[4]i32, b:[4]i32) -> bool {
    return a.x < b.x + b.z && a.x + a.z > b.x && a.y < b.y + b.w && a.y + a.w > b.y,
}

process_commands::proc(commands:^cm.command_buff){
    for &com in commands{
        switch com{
            case .non:

//---------------------------------------------------------
            case .move_focus_left:
                move_focus(move=.left)

            case .move_focus_right:
                move_focus(move=.right)

            case .move_focus_up:
                move_focus(move=.up)

            case .move_focus_down:
                move_focus(move=.down)
//---------------------------------------------------------
            case .move_window_left:
                
            case .move_window_right:

            case .move_window_up:

            case .move_window_down:

        }
        com=.non
    }
}
