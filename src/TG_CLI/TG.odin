package TG

import "base:sanitizer"
// import clay "/clay-odin"
import "core:math"
import "core:os"
import "core:strings"
import rl"vendor:raylib"
import "base:runtime"
import "core:fmt"
import "core:c"
import w"core:sys/windows"
// import edit"text_edit"
import hm"../handle_map_static"
import cm"../Commands"
import sy"core:sync"

main::proc(){
    if len(os.args) < 2 {
        fmt.println("Usage: TG <command> [args...]")
        return
    }
    comand:=string_to_enum(os.args[1],cm.commands)
    if comand == nil{
        fmt.println("invalid command")
        return
    }

    mapping_handle := w.OpenFileMappingW(
        w.FILE_MAP_ALL_ACCESS,
        false,
        "TG_comands" 
    )
    shared_data_ptr :=cast(^cm.command_buff) w.MapViewOfFile(
        mapping_handle,
        w.FILE_MAP_ALL_ACCESS,
        0, 0, 0
    )
    if shared_data_ptr == nil {
        return
    }
    
    for &com ,i in shared_data_ptr{
        _,ok :=sy.atomic_compare_exchange_strong(&com,nil,comand)
        if ok{
            break
        }
    }

    fmt.print(os.args,"\n")
    fmt.println("Connecting to pipe...")
    w.CloseHandle(mapping_handle)

}

string_to_enum::proc(str:string,$T:typeid)->(enum_name:T){
    for enum_, i in  T {
        if fmt.tprint(enum_) == str{
            return enum_
        }
    }
    return nil
}