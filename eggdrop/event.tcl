######################
#  event.tcl         #
#  by Wipe/Rotators  #
######################
#
#: Primitive event system (blocking), allowing to edit passed variable
#
###
#
#  Internal variables:
#  - event  list of registered events
#
#  Usage example:
#  (send)
#      set var "Example";
#      event:trigger "identifier" var;
#  (receive)
#      proc get_func { type args } {
#          upvar $args var
#          putlog "Got: $type -> $var";
#      }
#      event:register "identifier" get_func;
#
###

package provide eggdrop-event 0.1;

array set event {};

proc event:register { name func } {
    global event;

    if { [info exists event($name)] } {
	if { [lsearch -exact $event($name) $func] < 0 } {
	    lappend event($name) $func;
	    putlog "#Event# Registered $name +> $func";
	}
    } else {
	set event($name) [list $func];
	putlog "#Event Registered $name -> $func";
    }
}

# TODO
#proc event:unregister { name func } {
#    global event;
#}

proc event:trigger { name var } {
    global event;
    upvar $var args;
    set counter 0;

    if { [info exists event($name)] } {
	foreach func [list $event($name)] {
	    eval $func $name args;
	    incr counter;
	}
    }
    return $counter;
}

putlog "Loaded event.tcl";