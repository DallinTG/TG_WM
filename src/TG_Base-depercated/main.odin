package TG_TWM

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
import "core:mem"

import w"core:sys/windows"

use_tracking_allocator :: #config(use_tracking_allocator, true)
g_context:runtime.Context

main :: proc() {
	when use_tracking_allocator {
		default_allocator := context.allocator
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
	}
    
    g=new(state)
    g_context = context
    init()

    when use_tracking_allocator {
		leake_count:=0
		t_b_leaked:=0
		for _, value in tracking_allocator.allocation_map {
			// log.errorf("%v: Leaked %v bytes\n", value.location, value.size)

			fmt.print("-----------------------------------\n Leaked:",value.size,"Bytes At:\n",value.location,"\n-----------------------------------")
			if value.size<256 {
				str_b:=cast([^]u8)value.memory
				str_d:=str_b[:value.size]
				str:=cast(string)str_d
				fmt.print(str)
			}
			t_b_leaked+=value.size
			leake_count+=1
		}
		fmt.print("\n",leake_count,":Leaks Detected\n")
		fmt.print("",t_b_leaked,":Bytes Leaked Total")
		mem.tracking_allocator_destroy(&tracking_allocator)
	}
    
}


