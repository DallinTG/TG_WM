package TG_Base

import "base:sanitizer"
import clay "/clay-odin"
import "core:math"
import "core:strings"
import rl"vendor:raylib"
import "base:runtime"
import "core:fmt"
import "core:c"
import w"core:sys/windows"
// import edit"text_edit"
import hm"../handle_map_static"

RaylibFont :: struct {
    fontId: u16,
    font:   rl.Font,
}
custom_element::union{
    text_box_element,
}
text_box_element::struct{
    // s:^edit.State,
    line_width:int,
    carit_pos:int,
}

clayColorToRaylibColor :: proc(color: clay.Color) -> rl.Color {
    return rl.Color{cast(u8)color.r, cast(u8)color.g, cast(u8)color.b, cast(u8)color.a}
}


raylibFonts := [10]RaylibFont{}

measure_text :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: rawptr) -> clay.Dimensions {
    // Measure string size for Font
    context = runtime.default_context()
    textSize: clay.Dimensions = {0, 0}

    maxTextWidth: f32 = 0
    lineTextWidth: f32 = 0

    textHeight := cast(f32)config.fontSize


    fontToUse := raylibFonts[config.fontId].font
    // fontToUse := raylibFonts[0].font

    for i in 0 ..< int(text.length) {
        if (text.chars[i] == '\n') {
            maxTextWidth = max(maxTextWidth, lineTextWidth)
            lineTextWidth = 0
            continue
        }
        index := cast(i32)text.chars[i] - 32
        if (fontToUse.glyphs[index].advanceX != 0) {
            lineTextWidth += cast(f32)fontToUse.glyphs[index].advanceX
        } else {
            lineTextWidth += (fontToUse.recs[index].width + cast(f32)fontToUse.glyphs[index].offsetX)
        }
    }
    text_ := string(text.baseChars[:text.length])
    cloned := strings.clone_to_cstring(text_, context.temp_allocator)
    lineTextWidth = rl.MeasureTextEx(fontToUse,cloned,auto_cast config.fontSize,auto_cast config.letterSpacing).x +rl.MeasureTextEx(fontToUse,".",auto_cast config.fontSize,auto_cast config.letterSpacing).x
    // lineTextWidth+= cast(f32)(config.letterSpacing*cast(u16)text.length)
    maxTextWidth = max(maxTextWidth, lineTextWidth)
    textSize.width = maxTextWidth
    textSize.height = textHeight

    return textSize
}
clay_color_to_rl_color :: proc(color: clay.Color) -> rl.Color {
    return {u8(color.r), u8(color.g), u8(color.b), u8(color.a)}
}
color_to_clay_color :: proc(color: [4]u8) -> clay.Color {
    return {f32(color.r), f32(color.g), f32(color.b), f32(color.a)}
}


clay_raylib_render :: proc(render_commands: ^clay.ClayArray(clay.RenderCommand), allocator := context.temp_allocator) {

    for i in 0 ..< render_commands.length {
        render_command := clay.RenderCommandArray_Get(render_commands, i)
        bounds := render_command.boundingBox

        switch render_command.commandType {
        case .None: // None
 
        case .Text:
            
        case .Image:

        case .ScissorStart:
            
        case .ScissorEnd:
          
        case .Rectangle:
           
        case .Border:
            
        case clay.RenderCommandType.Custom:
            
            hwnd :=cast(w.HWND)render_command.renderData.custom.customData
            if hwnd != nil{

                ok:w.BOOL
                // ok=w.SetForegroundWindow(hwnd)
                ok=w.ShowWindow(hwnd, w.SW_RESTORE)
                // fmt.print(bounds,"\n")
                handl:=g.window_keys[hwnd]
                win_data:=hm.get(&g.windows,handl)
                off:=&win_data.offset
                rec:=rec_to_xywh(get_window_pos_size(hwnd))
                if rec !={cast(i32)bounds.x+off.x,cast(i32)bounds.y+off.y,cast(i32)bounds.width+off.z,cast(i32)bounds.height+off.w}{
                    w.SetWindowPos(hwnd,nil,cast(i32)bounds.x+off.x,cast(i32)bounds.y+off.y,cast(i32)bounds.width+off.z,cast(i32)bounds.height+off.w,(w.SWP_NOACTIVATE|w.SWP_NOZORDER))
                }
                // w.SetWindowPos(hwnd,nil,0,0,10,10,w.SWP_SHOWWINDOW)
            }
        }
    }
}

// Helper procs, mainly for repeated conversions

@(private = "file")
draw_arc :: proc(x, y: f32, inner_rad, outer_rad: f32,start_angle, end_angle: f32, color: clay.Color){
    rl.DrawRing(
        {math.round(x),math.round(y)},
        math.round(inner_rad),
        outer_rad,
        start_angle,
        end_angle,
        10,
        clay_color_to_rl_color(color),
    )
}

@(private = "file")
draw_rect :: proc(x, y, w, h: f32, color: clay.Color) {
    rl.DrawRectangle(
        i32(math.round(x)), 
        i32(math.round(y)), 
        i32(math.round(w)), 
        i32(math.round(h)), 
        clay_color_to_rl_color(color)
    )
}

@(private = "file")
draw_rect_rounded :: proc(x,y,w,h: f32, radius: f32, color: clay.Color){
    rl.DrawRectangleRounded({x,y,w,h},radius,8,clay_color_to_rl_color(color))
}