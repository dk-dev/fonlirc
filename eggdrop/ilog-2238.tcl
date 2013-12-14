########################
#  ilog-broadcast.tcl  #
#  FOnline:2238 only   #
#  Wipe                #
########################

package require eggdrop-event;
package require eggdrop-librarian-2238;

proc ilog:broadcast:message { name args } {
    upvar $args line;

    if { $name == "ilog.pre-broadcast" } {
	if { [regexp "^Server message\:\[ \]*(.*)" $line match text] } {
	    set line $text;
	}
    } elseif { $name == "ilog.requesthelp" } {
    } else {
	putlog "#ILog:Broadcast# Unknown event \[$name\]";
    }
}

event:register "ilog.pre-broadcast" ilog:broadcast:message;
event:register "ilog.broadcast" ilog:broadcast:message;

putlog "Loaded ilog-2238.tcl";
