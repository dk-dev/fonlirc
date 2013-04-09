######################
#  forestnet.tcl     #
#  by Wipe/Rotators  #
######################
#
#: irc.forestnet.org services
#
###
#
#  Config:
#  - Each service require own user with global +Sf flags
#  - Due to weird behaviour of eggdrop (v1.8), NickServ's AUTOOP option should be disabled
#    It's possible that bot won't detect it's opped/voiced/etc. when it's set in the moment of joining channel
#
#  User variablies:
#  - forestnet(password)  password for NickServ
#
#  Internal variables:
#  - forestnet-channels  channels access levels (minimal ALIST; supports XOP channels only)
#
###
#
#  TODO:
#  - pass 432 numeric when connecting to server
#  - check if valid nick is used before IDENTIFY
#  - use GHOST command
#  - faster OP/HALFOP/VOICE/GETKEY/INVITE/UNBAN
#
###

package provide forestnet 0.4;

bind notc S * forestnet:message
bind need - * forestnet:need
bind raw - 432 forestnet:432

array set forestnet {
    password ""
};

array set forestnet-channels {};

# don't use PRIVMSG to communicate with services; 

proc forestnet:message {nick uhost handle text dest} {
    global forestnet;
    global forestnet-channels;

    set text [stripcodes * $text];

    if { $nick == "NickServ" } {
	if { [regexp "^This nickname is registered and protected\." $text] } {
	    if { [string length forestnet(password)] == 0 } {
		putlog "#ForestNet# Can't IDENTIFY : password not set";
		return 1;
	    }
	    putlog "#ForestNet# IDENTIFY...";

	    # send it really fast, so we won't get into trouble on +R channels
	    putquick "NICKSERV :IDENTIFY $forestnet(password)" -next;

	    array unset forestnet-channels;
	    array set forestnet-channels {};
	    return 1;
	} elseif { $text == "Channels that you have access on:" } {
	    putlog "#ForestNet# Received ALIST";
	    array unset forestnet-channels;
	    array set forestnet-channels { * 1 };
	    return 1;
	} elseif { [regexp "\[0-9\]+\[ \]+(\#.+)\[ \]+(\[SAHV\]OP)" $text match channel xop] } {
	    set channel [string trim $channel];
	    set lchannel [string tolower $channel];
	    set xop [string trim $xop];
	    set access 0;

	    switch $xop {
		"SOP"	{ set access 4; }
		"AOP"	{ set access 3; }
		"HOP"	{ set access 2; }
		"VOP"	{ set access 1; }
	    }

	    if { $access > 0 } {
		putlog "#ForestNet#   $channel -> $xop ($access)";
		set forestnet-channels($lchannel) $access;
	    } else {
		putlog "#ForestNet# Unknown ALIST entry : $text";
	    }

	    return 1;
	} elseif { $text == "Services' hold on your nick has been released." } {
	    putlog "#ForestNet# Received RELEASE";
	}
	
	# ignored
	if { $text == "Password accepted - you are now recognized." ||
	     [regexp "^\[ \]*Num\[ \]+Channel\[ \]+Level\[ \]+Description" $text] ||
	     [regexp "^End of list - \[0-9\]+/\[0-9\]+ channels shown\." $text] } {
	     return 1;
	}
	
    } elseif { $nick == "ChanServ" || $nick == "Mystery" } {
	if { $text == "Permission denied." } {
	    # someone changed our ALIST after we cached it?
	    putlog "#ForestNet# Requesting ALIST refresh";
	    putserv "NICKSERV :ALIST";
	    array unset forestnet-channels;
	    array set forestnet-channels {};
	    return 1;
	} elseif { [regexp "^KEY (\#.+) (.+)$" $text match channel pass] } {
	    putlog "#ForestNet# Received KEY: $channel";
	    forestnet:tryjoin $channel $pass;
	    return 1;
	} elseif { [regexp "^You have been unbanned from (#.+)\.$" $text match channel] } {
	    putlog "#ForestNet# Received UNBAN: $channel";
	    forestnet:tryjoin $channel;
	    return 1;
	}
    }
};

proc forestnet:tryjoin { channel {key ""} } {
    if { ![validchan $channel] } {
	putlog "#ForestNet# Invalid channel: $channel";
	return;
    } elseif { [channel get $channel inactive] } {
	putlog "#ForestNet# Inactive channel: $channel";
	return;
    } else {
	if { $key == "" } {
	    putlog "#ForestNet# Joining: $channel";
	    putserv "JOIN $channel";
	} else {
	    putlog "#ForestNet# Joining: $channel (with key)";
	    putserv "JOIN $channel :$key";
	}
    }
};

proc forestnet:need { channel type } {
    global forestnet-channels;

    if { ![info exists forestnet-channels(*)] } {
	putlog "#ForestNet# Requesting ALIST";
	putserv "NICKSERV :ALIST";
	set forestnet-channels(*) 1;
	return 0;
    }

    set lchannel [string tolower $channel];

    if { [info exists forestnet-channels($lchannel)] } {
	set access [lindex [array get forestnet-channels $lchannel] 1];

	if { $type == "op" && [botonchan $channel] } {
	    if { $access >= 3 && ![botisop $channel] } {
		putlog "#ForestNet# Requesting OP: $channel";
		putserv "CHANSERV :OP $channel";
		if { $access >= 4 } {
		    putlog "#ForestNet# Requesting PROTECT: $channel";
		    putserv "CHANSERV :PROTECT $channel";
		}
		return 1;
	    } elseif { $access >= 2 && ![botisop $channel] && ![botishalfop $channel] } {
		putlog "#ForestNet# Requesting HALFOP: $channel";
		putserv "CHANSERV :HALFOP $channel";
		return 1;
	    } elseif { $access >= 1 && ![botisop $channel] && ![botishalfop $channel] && ![botisvoice $channel] } {
		putlog "#ForestNet# Requesting VOICE: $channel";
		putserv "CHANSERV :VOICE $channel";
		return 1;
	    }
	} elseif { $access >= 3 && $type == "key" } {
	    putlog "#ForestNet# Requesting KEY: $channel";
	    putserv "CHANSERV :GETKEY $channel";
	    return 1;
	} elseif { $access >= 3 && $type == "invite" } {
	    putlog "#ForestNet# Requesting INVITE: $channel";
	    putserv "CHANSERV :INVITE $channel";
	    return 1;
	} elseif { $access >= 3 && $type == "unban" } {
	    putlog "#ForestNet# Requesting UNBAN: $channel";
	    putserv "CHANSERV :UNBAN $channel";
	    return 1;
	}
    }
}

proc forestnet:432 { from keyword text } {
    global forestnet;

    if { [string length forestnet(password)] > 0 &&
	 [regexp "(.+) (.+) :Being held for registered user$" $text match target nick] } {
	if { $target == "*" } {
	    # connecting to server
	} else {
	    # already connected
	    putlog "#ForestNet# Requesting RELEASE: $nick";
	    putserv "NICKSERV :RELEASE $nick $forestnet(password)";
	}
    }
}

putlog "Loaded forestnet.tcl";
