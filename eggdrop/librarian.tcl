######################
#  librarian.tcl     #
#  by Wipe/Rotators  #
######################
#
#:  Inform about FOnline server status changes, basing on info from Librarian
#
###
#
#  Config:
#  - Librarian requires own user with global +L flag
#  - Channel where status should be redirected need +librarian flag
#
#  User variables:
#  - librarian(nick)      Librarian's nickname, usually "Librarian" :)
#  - librarian(reminder)  if server is offline, announce it on channel(s) every x minutes
#
#  Internal variables:
#  - librarian(status)       current server status
#                            -1  not checked since bot is running
#                            0   offline
#                            1   online
#  - librarian(lastcheck)    [unixtime] when "!status" command was sent
#  - librarian(lastchange)   [unixtime] when server status has been changed
#  - librarian(lastreminder) [unixtime] when info was passed to channel
#
###

package provide librarian 0.1;

setudef flag librarian

bind cron - "* * * * *" librarian:check;
bind msgm L * librarian:message

array set librarian {
    nick ""
    reminder -1
    status -1
    lastcheck -1
    lastchange -1
    lastreminder -1
};

proc librarian:check {minute hour day month weekday} {
    global librarian;

    # fix for timestamp-format containing "%M"
    set minute [string trimleft $minute 0];
    if { ![string length $minute] } {
	set minute 0;
    }

    # if server was online last time, check every 5 minutes
    # should be enough to not catch small hotfixes
    if { [string length $librarian(nick)] > 0 } {
	if { $librarian(status) == 1 && [expr $minute % 5] != 0 } {
	    return 1;
	}

	# TODO: check if she's online!
	set librarian(lastcheck) [unixtime];
	putmsg $librarian(nick) "!status";
    } else {
	# annoy dcc users :)
	putlog "#Librarian# librarian(nick) not set";
    }
}

proc librarian:message {nick uhost handle text {dest ""}} {
    global librarian;

    set status -1;
    set text [stripcodes * $text];

    # status
    if { [regexp "^Server status\: (Online\|Offline)" $text match tstatus] } {
	if { $tstatus == "Online" } {
	    set status 1;
	} elseif { $tstatus == "Offline" } {
	    set status 0;
	} else {
	    putlog "#Librarian# Unknown status: $text";
	    return 1;
	}

    # ignored
    } elseif {  [regexp "^Maximum players online" $text] ||
		[regexp "^The longest (up|down)time" $text] ||
		[regexp "^Switching active channel" $text] } {

    # unknown
    } else {
	putlog "#Librarian# UNKNOWN TEXT: $text";
    }

    if { $status < 0 || $status > 1 } {
	return 1;
    }

    if { $librarian(status) != $status } {
	if { $librarian(status) < 0 } {
	    # disable info on initial check
	    set text "";
	} elseif { $status > 1 } {
	    # sanity check
	    putlog "#Librarian# Unknown status number: $status";
	    return 0;
	} elseif { $status == 0 && $librarian(reminder) > 0 } {
	    putlog "#Librarian# Server offline, enabling reminder.";
	    set librarian(lastreminder) [unixtime];
	} elseif { $status == 1 && $librarian(lastreminder) > 0 } {
	    putlog "#Librarian# Server online, disabling reminder.";
	    set librarian(lastreminder) -1;
	}

	# do not save initial check time
	if { $librarian(status) >= 0 } {
	    set librarian(lastchange) [unixtime];
	}
    } else {
	if { $librarian(reminder) > 0 && $librarian(lastreminder) > 0 &&
	     [expr [unixtime] - $librarian(lastreminder)] >= [expr $librarian(reminder) * 60] } {
	    set librarian(lastreminder) [unixtime];
	} else {
	    set text "";
	}
    }

    if { [string length $text] > 0 } {
	foreach channel [channels] {
	    # TODO?: botonchan bug
	    if { [channel get $channel librarian] && [botonchan $channel] } {
		putmsg $channel "\[\002Librarian\002\] $text";
	    }
	}
    }

    set librarian(status) $status;

    return 1;
}

putlog "Loaded librarian.tcl";
