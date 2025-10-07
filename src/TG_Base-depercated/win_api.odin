package TG_TWM

import w"core:sys/windows"

GA_PARENT :: 1  // Gets the parent (might not be top-level)
GA_ROOT   :: 2  // Gets the top-level ancestor
GA_ROOTOWNER :: 3 // Gets the top-level owner (can differ in tool windows)

LWA_COLORKEY:: 1

foreign import user32 "system:User32.lib"
@(default_calling_convention="system")
foreign user32 {
    

    WindowFromPoint :: proc (pt:w.POINT) -> w.HWND ---
    AttachThreadInput :: proc (myThread:w.DWORD, fgThread:w.DWORD, t_f:w.BOOL) ->w.BOOL ---
    GetAncestor :: proc (child:w.HWND, gaFlags:i32) -> w.HWND ---
 
}