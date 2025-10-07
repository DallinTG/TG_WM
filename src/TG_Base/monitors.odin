package TG_Base


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

import w"core:sys/windows"


// cb_for_all_monitor :: proc "std"(
//     hMonitor: w.HMONITOR,
//     hdcMonitor: w.HDC,
//     lprcMonitor: ^w.RECT,
//     dwData: w.LPARAM
// ) -> w.BOOL {
//     context = g_context
//     info: w.MONITORINFO
//     info.cbSize = size_of(w.MONITORINFO)
//     monitor:^monitor_data
//     for i in 0..<8 {
//         if !g.monitors[i].temp_is_up_to_date{
//             g.monitors[i].temp_is_up_to_date=true
//             monitor = &g.monitors[i]
//             break
//         }
//     }

//     if w.GetMonitorInfoW(hMonitor, &info) == w.FALSE {
//         fmt.println("GetMonitorInfo failed. Error:", w.GetLastError())
//         return w.TRUE
//     }

//     monitor.data=info


//     // bounds := info.rcMonitor
//     // work   := info.rcWork

//     // fmt.println("Monitor:")
//     // fmt.println("  Bounds:   ", bounds.left, bounds.top, "-", bounds.right, bounds.bottom)
//     // fmt.println("  Work Area:", work.left, work.top, "-", work.right, work.bottom)
//     // // fmt.println("  Primary:  ", if info.dwFlags == w.MONITORINFOF_PRIMARY ,then ,"Yes" else "No")

//     return w.TRUE // Continue enumerating
// }
// update_monitor_data::proc(){

//     g.monitors = {}
//     success := w.EnumDisplayMonitors(nil, nil, cb_for_all_monitor, 0)
//     if success == w.TRUE {
//         fmt.println("EnumDisplayMonitors failed. Error:", w.GetLastError())
//     }

// }