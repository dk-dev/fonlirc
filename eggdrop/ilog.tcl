####################
# ilog.tcl         #
# by Wipe/Rotators #
####################
#
#: Pass messages from FOnlineServer to IRC, using regular files
#
###

package provide ilog 0.2;

package require db;
package require event;

bind cron - "* * * * *" ilog:check;
array set ilog {
    dir ""
    db  ""
};

array set ilog-types {}

proc ilog:init {} {
    global ilog;
    global ilog-types;

    if { ![ilog:ok] } {
	return;
    }

    array unset ilog-types;
    array set ilog-types {};
    array set types [db:getarray $ilog(db)];
    set added [list];
    foreach type [array names types] {
	if { [regexp "^\(\[a-z\]+)$" $type match flag] } {
	    setudef flag "ilog-$flag";
	    set ilog-types($flag) $types($flag);
	    lappend added $flag;
	} else {
	    putlog "#ILog# Skipped: $type";
	}
    }

    if { [llength added] > 0 } {
	putlog "#ILog# Added flags : $added";
	after idle ilog:check 0 0 0 0 0;
    }
}

proc ilog:ok {} {
    global ilog;

    if { ![string length $ilog(dir)] } {
	return 0;
    } elseif { ![string length $ilog(db)] } {
	return 0;
    } elseif { ![file exists $ilog(db)] } {
	return 0;
    }

    return 1;
}

proc ilog:check { minute hour day month weekday } {
    global ilog;
    global ilog-types;

    if { ![ilog:ok] } {
	return;
    }

    set files [lsort -unique [glob -nocomplain -directory $ilog(dir) "*"]];
    foreach fname $files {
	if { [file type $fname] != "file" } {
	    continue;
	}

	if { [regexp "\/(\[a-z\]+)\.(\[0-9]+)$" $fname match fflag elapsedtime] &&
	     [info exists ilog-types($fflag)] } {
	    set text [lindex [array get ilog-types $fflag] 1];

	    set fd [open $fname "r"];
	    set content [read $fd];
	    close $fd;
	    file delete -force $fname;

	    foreach line [split $content "\n"] {
		set line [stripcodes * [string trim $line]];
		if { ![string length $line] } {
		    continue;
		}

		event:trigger "ilog.pre-$fflag" line;

		# re-check
		if { ![string length $line] } {
		    continue;
		}

		putlog "#ILog# \[$text\] $line";
		foreach channel [channels] {
		    if { ![channel get $channel inactive] && [channel get $channel "ilog-$fflag"] && [botonchan $channel] } {
			putmsg $channel "\[\002$text\002\] $line";
		    }
		}

		event:trigger "ilog.$fflag" line;
	    }
	}
    }
}

after idle ilog:init;

putlog "Loaded ilog.tcl";
