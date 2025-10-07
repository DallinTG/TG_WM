package TG_TWM

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
    monitors:[8]monitor_data,
    window_keys:map[w.HWND]win_handle,
    windows :hm.Handle_Map(window,win_handle,500),
    curent_win_node:^windows_nodes,
    root_node:^windows_nodes,
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
win_nodes::enum{
    leafe,
    branch,
}
windows_nodes::struct{
    handle:win_handle,
    type:win_nodes,
    layout_dir:clay.LayoutDirection,
    parent:^windows_nodes,
    children:[2]^windows_nodes,
}
window::struct{
    handle:win_handle,
    node:^windows_nodes,
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

    // run_program_w({command={"Restart_Explorer.exe"}},"restart_explorer")
    update_monitor_data()
    init_clay()
    g.curent_win_node = new(windows_nodes)
    g.root_node = g.curent_win_node

    // w.EnumWindows(cb_for_all_windows_get,0)

    g.ui_render_command=create_ui_layout()
    clay_raylib_render(&g.ui_render_command)

    for !g.stop{
        g.focused_window = w.GetForegroundWindow()
        maintain_cursor()
        maintain_windo_pos_size()
        maintain_shared_comands()
        w.EnumWindows(cb_for_all_windows_get,0)
        maintain_timers()
        g.ui_render_command=create_ui_layout()
        clay_raylib_render(&g.ui_render_command)
        time.sleep(time.Millisecond * 16)
        if g.time.frame_count >1500{g.stop = true}
    }
    shutdoun()
}


add_win::proc(new_win:^windows_nodes,old_node:^windows_nodes,left_or_right:l_r=.right)->(suc:bool){

    switch old_node.type {
        case .branch:
            if left_or_right == .left{
                if add_win(new_win,old_node.children.x,.right) {return true}
            }else{
                add_win(new_win,old_node.children.y,.left)
                return true
            }
            if left_or_right == .right{
                if add_win(new_win,old_node.children.y,.left) {return true}
            }else{
                add_win(new_win,old_node.children.x,.right)
                return true
            }
        case .leafe:
        temp_node_data:=old_node^
        if hm.valid(g.windows, old_node.handle) {
            old_node^=new_win^
            old_node.parent = temp_node_data.parent
            return true
        }
        old_node.type = .branch
        old_node.handle={0,0}


        if left_or_right == .left{
            old_node.children.x = new(windows_nodes)
            old_node.children.x^ = temp_node_data
            old_node.children.x.type=.leafe
            old_node.children.x.parent = old_node
            
            // old_node.children.y = new(windows_nodes)
            old_node.children.y = new_win
            old_node.children.y.parent = old_node
        }
        if left_or_right == .right{
            old_node.children.y = new(windows_nodes)
            old_node.children.y^ = temp_node_data
            old_node.children.y.type=.leafe
            old_node.children.y.parent = old_node
            
            // old_node.children.y = new(windows_nodes)
            old_node.children.x = new_win
            old_node.children.x.parent = old_node
        }
        win:=hm.get(&g.windows,new_win.handle)
        if win !=nil{
            if win.hwnd !=nil{
                set_focus(win.hwnd)
            }
        }
        return true
    }
    return false
}

cb_for_all_windows_get::proc "std" (hwnd:w.HWND,p1:int)->(out:w.BOOL){
    context = g_context
    if hwnd == nil{return w.TRUE}
    if (!w.IsWindowVisible(hwnd)) {return w.TRUE}
    if w.IsIconic(hwnd){return w.TRUE}
    if w.GetParent(hwnd) != nil  {return w.TRUE}

    ex_style := cast(u32)w.GetWindowLongPtrW(hwnd, w.GWL_EXSTYLE);
    if (ex_style & w.WS_EX_TOOLWINDOW) != 0 {
        return w.TRUE;
    }

    cloaked: u32 = 0
    DWM_CLOAKED :u32= 14 // DWMWA_CLOAKED
    result := w.DwmGetWindowAttribute(hwnd, cast(u32)w.DWMWINDOWATTRIBUTE.DWMWA_CLOAKED, &cloaked, size_of(u32))
    if result == 0 && cloaked != 0 {
        return w.TRUE
    }
    

    length:i32 = w.GetWindowTextLengthW(hwnd)
    rec:w.RECT
    w.GetWindowRect(hwnd, &rec)
    buffer: [256]u16
    title_len := w.GetWindowTextW(hwnd, &buffer[0], 256)
    
    if title_len > 0 {
        if !(hwnd in g.window_keys) {
            // remove_win_decorations(hwnd)
            win_node:=new(windows_nodes)
            win:window
            win.node = win_node
            win.hwnd = hwnd
            win.offset = get_window_ofset(hwnd)
            win.min_size = get_window_min_size(hwnd)
            handle:=hm.add(&g.windows,win)
            g.window_keys[hwnd] = handle

            win_node.type = .leafe
            win_node.handle = handle

            focused_win:=g.focused_window
            
            // if (focused_win in g.window_keys){
            //     curent_win_handle:=g.window_keys[focused_win]
            //     curent_win:=hm.get(&g.windows,curent_win_handle)
            //     curent_node:=curent_win.node
                // if curent_node!=nil{
                    // add_win(win_node,curent_node)
                // }else{add_win(win_node,g.curent_win_node)}
            // }else{add_win(win_node,g.curent_win_node)}
            add_win(win_node,g.curent_win_node)
        }
        do_window_transparency(hwnd)

    }
    return w.TRUE
}
do_window_transparency::proc(hwnd:w.HWND){
    if g.focused_window == hwnd{// is focused so not transparent
        set_widow_transparency(hwnd,255)

    }else{
        set_widow_transparency(hwnd,230)

    }
}
// alpha is 0 to 255
set_widow_transparency::proc(hwnd:w.HWND,alpha:u8){
    w.SetWindowLongPtrW(hwnd, w.GWL_EXSTYLE,w.GetWindowLongPtrW(hwnd, w.GWL_EXSTYLE) | cast(int)w.WS_EX_LAYERED)
    w.SetLayeredWindowAttributes(hwnd, 0, cast(w.BYTE)alpha, 2)//2 is spcifiying alpha
}

get_window_min_size::proc(hwnd:w.HWND)->([2]i32){
    rec:w.RECT
    w.GetWindowRect(hwnd, &rec)
    rec_2:w.RECT
    ok := w.SetWindowPos(hwnd,nil,0,0,10,10,w.SWP_SHOWWINDOW)
    w.GetWindowRect(hwnd, &rec_2)
    // fmt.print(ok,rec_2,"\n")
    w.SetWindowPos(hwnd,nil,rec.bottom,rec.right,rec.left,rec.top,w.SWP_SHOWWINDOW)
    // fmt.print(rec,"  ", rec_2.left,rec_2.top,"\n")
    return {rec_2.right,rec_2.bottom}
}
get_window_ofset::proc(hwnd:w.HWND)->(out:[4]i32){
    winRect:w.RECT  
    frameRect:w.RECT 

    
    // GetWindowRect includes the extended frame (with shadows)
    if !w.GetWindowRect(hwnd, &winRect){return{0,0,0,0}}
    
    // DWMWA_EXTENDED_FRAME_BOUNDS gives the client area excluding shadows
    hr: = w.DwmGetWindowAttribute(
        hwnd,
        9,
        &frameRect,
        size_of(w.RECT)
    )
    if !w.SUCCEEDED(hr){return{0,0,0,0}}
    out={
        winRect.left-frameRect.left,
        winRect.top-frameRect.top,
        winRect.right-frameRect.right+math.abs(winRect.left-frameRect.left),
        winRect.bottom-frameRect.bottom,
    }

    return out
}
get_window_pos_size::proc(hwnd:w.HWND)->(out:[4]i32){
    winRect:w.RECT  
    // frameRect:w.RECT 

    
    // // GetWindowRect includes the extended frame (with shadows)
    if !w.GetWindowRect(hwnd, &winRect){return{0,0,0,0}}
    
    // DWMWA_EXTENDED_FRAME_BOUNDS gives the client area excluding shadows
    // hr: = w.DwmGetWindowAttribute(
    //     hwnd,
    //     9,
    //     &winRect,
    //     size_of(w.RECT)
    // )
    // if !w.SUCCEEDED(hr){return{0,0,0,0}}

    out={
        winRect.left,
        winRect.top,
        winRect.right,
        winRect.bottom,
    }

    return out
}
rec_to_xywh::proc(rec:[4]i32)->(out:[4]i32){
    out={
        rec.x,
        rec.y,
        rec.z-rec.x,
        rec.w-rec.y,
    }
    return out
}
xywh_to_rec::proc(rec:[4]i32)->(out:[4]i32){
    out={
        rec.x,
        rec.y,
        rec.z+rec.x,
        rec.w+rec.y,
    }
    return out
}

// remove_win_decorations::proc(hwnd:w.HWND){
//     style := cast(u32)w.GetWindowLongW(hwnd, w.GWL_STYLE)
//     style &~= (w.WS_CAPTION | w.WS_THICKFRAME | w.WS_MINIMIZEBOX | w.WS_MAXIMIZEBOX | w.WS_SYSMENU)
//     w.SetWindowLongW(hwnd, w.GWL_STYLE, cast(i32)style)
// }
remove_win_decorations::proc(hwnd:w.HWND){
    style := cast(u32)w.GetWindowLongW(hwnd, w.GWL_STYLE)
    style &~= (w.WS_CAPTION | w.WS_THICKFRAME | w.WS_MINIMIZEBOX | w.WS_MAXIMIZEBOX | w.WS_SYSMENU)
    w.SetWindowLongW(hwnd, w.GWL_STYLE, cast(i32)style)
}

hide_show_task_bar::proc(show:bool=false){
    hwnd:w.HWND = w.FindWindowW("Shell_TrayWnd", nil)
    if hwnd!=nil {
        if show{
            fmt.print("show first taskbar\n")
            w.ShowWindow(hwnd, w.SW_SHOW)
        }else{
            fmt.print("hid first taskbar\n")
            w.ShowWindow(hwnd, w.SW_HIDE)
        } 
        rect: w.RECT
        rect.left   = 0
        rect.top    = 0
        rect.right  = w.GetSystemMetrics(w.SM_CXSCREEN)
        rect.bottom = w.GetSystemMetrics(w.SM_CYSCREEN)
        
        
        success := w.SystemParametersInfoW(
            w.SPI_SETWORKAREA,
            0,
            &rect,
            w.SPIF_SENDCHANGE | w.SPIF_UPDATEINIFILE,
        )
        
        fmt.print("did task bar get removed",success,"\n")
        fmt.print("work space size",success,"\n")
    }

}
maintane_settings::proc(){
    set_reg_multy_taskbars()
    set_reg_drop_shadow()
    w.SystemParametersInfoW(w.SPI_SETCLIENTAREAANIMATION, 0, nil, w.SPIF_UPDATEINIFILE | w.SPIF_SENDCHANGE)

    minimizeAnimation:w.BOOL = w.FALSE
    w.SystemParametersInfoW(w.SPI_SETANIMATION, 0, &minimizeAnimation, w.SPIF_UPDATEINIFILE)
}

set_reg_multy_taskbars :: proc() -> bool {
// Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    key_path :: "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced"
    value_name :: "MMTaskbarEnabled"
    value :u64= 0 // Disable taskbar on all displays (show only on main)
    hKey: w.HKEY
    res := cast(u32)w.RegOpenKeyExW(w.HKEY_CURRENT_USER, key_path, 0, w.KEY_SET_VALUE, &hKey)
    if res != w.ERROR_SUCCESS {
        fmt.println("Failed to open registry key: ", key_path)
        return false
    }

    res = cast(u32)w.RegSetValueExW(hKey, value_name, 0, w.REG_DWORD, cast(^w.BYTE)&value, 4)
    if res != w.ERROR_SUCCESS {
        fmt.println("Failed to set registry value: ", value_name)
        w.RegCloseKey(hKey)
        return false
    }

    w.RegCloseKey(hKey)
    return true
}
set_reg_drop_shadow :: proc() -> bool {
// Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DropShadow
    key_path :: "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects\\DropShadow"
    value_name :: "DefaultApplied"
    value :u64= 0 // Disable taskbar on all displays (show only on main)
    hKey: w.HKEY
    res := cast(u32)w.RegOpenKeyExW(w.HKEY_CURRENT_USER, key_path, 0, w.KEY_SET_VALUE, &hKey)
    if res != w.ERROR_SUCCESS {
        fmt.println("Failed to open registry key: ", key_path)
        return false
    }

    res = cast(u32)w.RegSetValueExW(hKey, value_name, 0, w.REG_DWORD, cast(^w.BYTE)&value, 4)
    if res != w.ERROR_SUCCESS {
        fmt.println("Failed to set registry value: ", value_name)
        w.RegCloseKey(hKey)
        return false
    }

    w.RegCloseKey(hKey)
    return true
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


maintain_shared_comands::proc(){
    process_commands(g.shared_comands_ptr)
}
shutdoun::proc(){
    w.CloseHandle(g.shared_comands_handle)
}
maintain_cursor::proc(){
    pt:w.POINT
    w.GetCursorPos(&pt)
    g.cursor_pos.x=pt.x
    g.cursor_pos.y=pt.y
    huv_win_child:=WindowFromPoint(pt)
    huv_win:=GetAncestor(huv_win_child, GA_ROOT)
    if huv_win in g.window_keys{
        set_focus(huv_win)
    }
}

set_focus::proc(hwnd:w.HWND){
    if g.focused_window!=hwnd{

        current_thread := w.GetCurrentThreadId()
        fgThread := w.GetWindowThreadProcessId(g.focused_window, nil)
        myThread := w.GetWindowThreadProcessId(hwnd, nil)

        AttachThreadInput(current_thread, myThread, true)
        AttachThreadInput(current_thread, fgThread, true)
        // AttachThreadInput(myThread, fgThread, true)
        w.ShowWindow(hwnd, w.SW_RESTORE)
        w.SetForegroundWindow(hwnd)
        w.SetFocus(hwnd)
        w.SetActiveWindow(hwnd)
        // AttachThreadInput(myThread, fgThread, false)
        AttachThreadInput(current_thread, myThread, false)
        AttachThreadInput(current_thread, fgThread, false)
        
        g.focused_window=hwnd
    }
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
maintain_windo_pos_size::proc(){
    for key,handl in g.window_keys{
        if key != nil{
            win:=hm.get(&g.windows,handl)
            if win !=nil{
                win.pos_size=rec_to_xywh(get_window_pos_size(key))
            }
        }
    }
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



