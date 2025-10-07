package build

import os2 "core:os/os2"
import "core:c/libc"
import "core:fmt"
import "base:runtime"



is_debug_mode:: #config(is_debug_mode,true)
do_TG_Base :: #config(do_TG_Base,true)
do_TG_CLI :: #config(do_TG_CLI,true)
run_or_build::#config(run_or_build, "run")
// comp_flag:comp_flags
starting_dir:string
cer_dir:string
out_dir:string
commands:[dynamic]string

main :: proc() {
    // comp_flag=string_to_enum(comp_flag_str,comp_flags)

    {
        dir,err:=os2.get_working_directory(context.allocator)
        starting_dir=dir
    }
   if do_TG_CLI{
        commands:=commands
        append(&commands,"odin","build",".","-subsystem:windows")
        append(&commands,fmt.tprintf("-out:%s/TG/TG.exe",starting_dir))
        // run_program_w(desc={working_dir=fmt.tprintf("%s/src/TG_Base ",starting_dir),command=commands[:]},name="TG_Base")
        run_program_w(desc={working_dir=fmt.tprintf("%s/src/TG_CLI ",starting_dir),command=commands[:]},name="TG_CLI")
    }
    append(&commands,"odin",run_or_build,".")
    if do_TG_Base{
        commands:=commands
        append(&commands,fmt.tprintf("-out:%s/TG/TG_Base.exe",starting_dir))
        run_program_w(desc={working_dir=fmt.tprintf("%s/src/TG_Base ",starting_dir),command=commands[:]},name="TG_Base")
        // run_program(desc={working_dir=fmt.tprintf("%s/src/TG_Base ",starting_dir),command=commands[:]},name="TG_Base")
    }

    fmt.print("build progrm finished\n")
}


run_program_w::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
){
    fmt.printf("starting (%s) \n",name)
    state, stdout, stderr, err:=os2.process_exec(desc,context.allocator)
    if err != nil {
        fmt.eprintln("Unable to launch process (",name,") because of:", err)
        fmt.eprintln("desc(",desc,") ")
        fmt.eprintln("comand(",desc.command[:],") ")
        return
    }
    fmt.println(string(stdout), string(stderr))
    fmt.printf("finished (%s) \n",name)
    return
}

run_program::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
){
    fmt.printf("starting (%s) \n",name)
    p, err :=os2.process_start(desc)
    if err != nil {
        fmt.eprintln("Unable to launch process(",name,") because of:", err)
    }
            fmt.eprintln("desc(",desc,") ")
        fmt.eprintln("comand(",desc.command[:],") ")
    return
}
run_program_get_p_err::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
) -> (p:os2.Process, err:os2.Error){
    fmt.printf("starting (%s) \n",name)
    p, err =os2.process_start(desc)
    if err != nil {
        fmt.eprintln("Unable to launch process(",name,") because of:", err)
    }
    return
}


string_to_enum::proc(str:string,$T:typeid)->(enum_name:T){
    for enum_, i in  T {
        if fmt.tprint(enum_) == str{
            return enum_
        }
    }
    return nil
}