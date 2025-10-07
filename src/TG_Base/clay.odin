package TG_Base

import "core:fmt"
import "core:math/linalg"
import "core:math"
import rl "vendor:raylib"
import noise"core:math/noise"
import clay "/clay-odin"
import "base:runtime"
import "core:c"
import "core:strconv"
import "core:hash"
import "core:os"
import "core:time"
import "core:path/filepath"
import "core:strings"
// import edit"text_edit"
import w"core:sys/windows"
import hm"../handle_map_static"

// ui_render_command:clay.ClayArray(clay.RenderCommand)

style::struct{
    gap:u16,
    pading:u16,
}
init_styles::proc(){
    g.style.pading = 4
    g.style.gap = 4
}

// init_clay::proc(){
//     min_memory_size: u32 = clay.MinMemorySize()
//     g.ui_mem = make([^]u8, min_memory_size)
//     arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(auto_cast min_memory_size, g.ui_mem)
//     clay.Initialize(arena, { width = cast(f32)g.monitors[0].data.rcWork.right, height = cast(f32)g.monitors[0].data.rcWork.bottom }, { handler = nil })
//     // clay.SetMeasureTextFunction(measureText,nil)
//     // clay.SetMeasureTextFunction(measure_text,nil)
//     // loadFont(FONT_ID_TITLE_56, 56, "resources/Calistoga-Regular.ttf")
//     // raylibFonts[1].font = rl.GetFontDefault()
//     // raylibFonts[1].fontId = 1
//     // raylibFonts[0].font = rl.GetFontDefault()
//     // raylibFonts[0].fontId = 1


// }

// create_ui_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {

//     // g.st.overide_left_click=false

//     clay.BeginLayout()

//     if clay.UI()({
//         id = clay.ID("Container"),
//         layout = {
//             sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
//             padding = { },
//             childGap = 0,
//             layoutDirection=.LeftToRight,
//             childAlignment = {x=.Right,y=.Bottom,},
//         },
//         backgroundColor = { 0, 0, 0, 255 },
    
//     }) 
//     {    
//         if clay.UI()({
//             id = clay.ID("windo_Container"),
//             layout = {
//                 sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
//                 padding = { g.style.pading, g.style.pading, g.style.pading, g.style.pading },
//                 // padding = { },
//                 childGap = g.style.gap,
//                 layoutDirection=.LeftToRight,
//                 childAlignment = {x=.Right,y=.Bottom,},
//             },
//             backgroundColor = { 0, 0, 0, 255 },
        
//         }) 
//         {
//             count:u32=0
//             if g.root_node != nil{draw_win_and_children(g.root_node, .TopToBottom, &count)}
            
//         }
        
//     }
//     // Returns a list of render commands
//     render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()

//     return render_commands
// }

// draw_win_and_children::proc(node:^windows_nodes=g.root_node,tb_lr:clay.LayoutDirection ,win_count:^u32){
//     next_layout_direction:=tb_lr
//     if next_layout_direction == .TopToBottom{
//         next_layout_direction = .LeftToRight
//     }else{
//         next_layout_direction = .TopToBottom
//     }

//     if node.type == .branch{
//         if clay.UI()({
//             id = clay.ID_LOCAL("spaser",win_count^),
//             layout = {
//                 sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
//                 padding = { 0, 0, 0, 0 },
//                 childGap = g.style.gap,
//                 layoutDirection=next_layout_direction,
//                 childAlignment = {x=.Right,y=.Bottom,},
//             },
            
//             // custom = {customData =data.hwnd},
//             backgroundColor = { 0, 0, 0, 0 },
            
//         }) 
//         {
//             if node.children.x != nil{draw_win_and_children(node.children.x, next_layout_direction, win_count)}
//             if node.children.y != nil{draw_win_and_children(node.children.y, next_layout_direction, win_count)}
//         }
//     }
//     if node.type == .leafe{
//         win_count^ +=1
//         if hm.valid(g.windows,node.handle){
//             data:=hm.get(&g.windows,node.handle)
//             if clay.UI()({
//                 id = clay.ID_LOCAL("window",win_count^),
//                 layout = {
//                     sizing = { width = clay.SizingGrow({min=cast(f32)data.min_size.x}), height = clay.SizingGrow({min=cast(f32)data.min_size.y}) },
//                     padding = { 0, 0, 0, 0 },
//                     childGap = g.style.gap,
//                     layoutDirection=next_layout_direction,
//                     childAlignment = {x=.Right,y=.Bottom,},
//                 },
                
//                 custom = {customData =data.hwnd},
//                 backgroundColor = { 0, 0, 0, 0 },
                
//             }) 
//             {
                
//             }
//         }
//     }
// }
