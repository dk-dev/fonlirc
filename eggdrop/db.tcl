######################
#  db.tcl            #
#  by Wipe/Rotators  #
######################
#
#: Minimalistic flat database
#
###

package provide db 0.1;

proc db:get { fname var } {
    set var [string tolower $var];

    if { [file exists $fname] } {
	set db [open $fname r];
	fconfigure $db -encoding binary;
	while { ![eof $db] } {
	    set line [gets $db];
	    if { ![string length $line] } {
		continue;
	    }

	    set fvar [string tolower [lindex $line 0]];
	    if { $fvar == [string tolower $var] } {
		return [lreplace $line 0 0];
	    }
	}
    }

    return 0;
}

proc db:getarray { fname } {
    if { [file exists $fname] } {
	set db [open $fname r];
	fconfigure $db -encoding binary;
	set bullshit 1;
	while { ![eof $db] } {
	    set line [gets $db];
	    if { ![string length $line] } {
		continue;
	    }

	    set fvar [string tolower [lindex $line 0]];
	    set fval [lreplace $line 0 0];
	    if { $bullshit == 1 } {
		array set result { * 1 };
		set result($fvar) $fval;
		unset result(*);
		set bullshit 0;
	    } else {
		set result($fvar) $fval;
	    }
	}
    }

    return [array get result];
}

proc db:set { fname var val } {
    set var [string tolower $var];

    if { ![file exists $fname] } {
	set db [open $fname w];
	puts $db "$var $val";
	close $db;
    } elseif { ![db:exists $fname $var] } {
	set db [open $fname a];
	puts $db "$var $val";
	close $db;
    } else {
	set content [list];
	set db [open $fname r];
	fconfigure $db -encoding binary;
	while { ![eof $db] } {
	    set line [gets $db];
	    if { ![string length $line] } {
		continue;
	    }

	    set fvar [string tolower [lindex $line 0]];
	    if { $fvar == [string tolower $var] } {
		lappend content "$var $val";
	    } else {
		lappend content $line;
	    }
	}
	close $db;
	set db [open $fname w];
	foreach line $content {
	    puts $db $line;
	}
	close $db;
    }
    
    return 1;
}

proc db:setarray { fname arr } {
    array set tarr $arr;

    set db [open $fname w];
    foreach key [array names tarr] {
	puts $db "$key $tarr($key)";
    }
    close $db;

    return 1;
}

proc db:del { fname var } {
    set var [string tolower $var];

    if { ![db:exists $fname $var] } {
	return;
    }

    set content [list];
    set db [open $fname r];
    fconfigure $db -encoding binary;
    while { ![eof $db] } {
	set line [gets $db];
	if { ![string length $line] } {
	    continue;
	}

	set fvar [string tolower [lindex $line 0]];
	if { $fvar == [string tolower $var] } {
	    # skip
	} else {
	    lappend content $line;
	}
    }
    close $db;
    set db [open $fname w];
    foreach line $content {
        puts $db $line;
    }
    close $db;
}

proc db:remove { fname } {
    if { [file exists $fname] } {
	file delete -force $fname;
    }
}

proc db:exists { fname var } {
    set var [string tolower $var];

    if { [file exists $fname] } {
	set db [open $fname r];
	fconfigure $db -encoding binary;
	while { ![eof $db] } {
	    set line [gets $db];
	    if { ![string length $line] } {
		continue;
	    }

	    set fvar [string tolower [lindex $line 0]];
	    if { $fvar == [string tolower $var] } {
		return 1;
	    }
	}
    }

    return 0;
}

proc db:count { fname } {
    if { [file exists $fname] } {
	set count 0;
	set db [open $fname r];
	fconfigure $db -encoding binary;
	while { ![eof $db] } {
	    set line [gets $db];
	    if { ![string length $line] } {
		continue;
	    }
	    incr count;
	}
	return $count;
    }
    return 0;
}

putlog "Loaded db.tcl";
