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



get_window_pos_size::proc(hwnd:w.HWND)->(out:[4]i32){
    winRect:w.RECT  

    if !w.GetWindowRect(hwnd, &winRect){return{0,0,0,0}}
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
    // set_reg_drop_shadow()
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
// set_reg_drop_shadow :: proc() -> bool {
// // Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DropShadow
//     key_path :: "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects\\DropShadow"
//     value_name :: "DefaultApplied"
//     value :u64= 0 // Disable taskbar on all displays (show only on main)
//     hKey: w.HKEY
//     res := cast(u32)w.RegOpenKeyExW(w.HKEY_CURRENT_USER, key_path, 0, w.KEY_SET_VALUE, &hKey)
//     if res != w.ERROR_SUCCESS {
//         fmt.println("Failed to open registry key: ", key_path)
//         return false
//     }

//     res = cast(u32)w.RegSetValueExW(hKey, value_name, 0, w.REG_DWORD, cast(^w.BYTE)&value, 4)
//     if res != w.ERROR_SUCCESS {
//         fmt.println("Failed to set registry value: ", value_name)
//         w.RegCloseKey(hKey)
//         return false
//     }

//     w.RegCloseKey(hKey)
//     return true
// }






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
        // set_focus(huv_win)
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
do_window_transparency::proc(hwnd:w.HWND){
    if g.focused_window == hwnd{// is focused so not transparent
        set_widow_transparency(hwnd,255)
    }else{
        set_widow_transparency(hwnd,230)
    }
}
set_widow_transparency::proc(hwnd:w.HWND,alpha:u8){
    w.SetWindowLongPtrW(hwnd, w.GWL_EXSTYLE,w.GetWindowLongPtrW(hwnd, w.GWL_EXSTYLE) | cast(int)w.WS_EX_LAYERED)
    w.SetLayeredWindowAttributes(hwnd, 0, cast(w.BYTE)alpha, 2)//2 is spcifiying alpha
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
            win:window
            win.hwnd = hwnd
            handle:=hm.add(&g.windows,win)
            g.window_keys[hwnd] = handle
            focused_win:=g.focused_window
        }
        do_window_transparency(hwnd)

    }
    return w.TRUE
}





