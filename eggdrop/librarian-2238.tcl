########################
#  librarian-2238.tcl  #
#  FOnline:2238 only   #
#  Wipe                #
########################

package provide eggdrop-librarian-2238 0.1;
package require eggdrop-librarian;

proc librarian:say {message} {
    global librarian;

    putlog "#Librarian# Saying to #2238: $message";
    # not needed, according to Cpt.Rookie
    #putmsg $librarian(nick) "!channel #2238"; 
    putmsg $librarian(nick) "!say $message";
}

putlog "Loaded librarian-2238.tcl";
