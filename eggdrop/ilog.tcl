####################
# ilog.tcl         #
# by Wipe/Rotators #
####################
#
#: Pass messages from FOnlineServer to IRC, using regular files.
#
###
#
#  Config:
#  - Channel(s) where ilog entries should be redirected need +ilog-[type] flag
#  - To create ilog message type, use: "db:set info Information"
#    All 'info' entries will be seen as "[Information] text"
#
#  User variables:
#  - ilog(dir)  directory which should be checked for new messages
#  - ilog(db)   name of file which will hold available ilog types (usually "ilog.db")
#
###

package provide eggdrop-ilog 0.2;

package require eggdrop-db;
package require eggdrop-event;

bind cron - "* * * * *" ilog:check;

array set ilog {
    dir   ""
    db    ""
    debug 0
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
	} elseif { $ilog(debug) } {
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
		# check
		set line [stripcodes * [string trim $line]];
		if { ![string length $line] } {
		    continue;
		}

		event:trigger "ilog.pre-$fflag" line;

		# re-check
		set line [stripcodes * [string trim $line]];
		if { ![string length $line] } {
		    continue;
		}

		if { $ilog(debug) } {
		    putlog "#ILog# \[$text\] $line";
		}

		foreach channel [channels] {
		    if { ![channel get $channel inactive] && [channel get $channel "ilog-$fflag"] && [botonchan $channel] } {
			if { $ilog(debug) } {
			    putlog "#ILog# Sending to $channel";
			}
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
