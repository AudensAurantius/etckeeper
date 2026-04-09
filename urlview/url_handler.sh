#! /bin/sh

#   Copyright (c) 1998  Martin Schulze <joey@debian.org>
#   Slightly modified by:
#   Luis Francisco Gonzalez <luisgh@debian.org>
#   Emanuele Rocca <ema@debian.org>

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

###########################################################################
# Configurable section
###########################################################################
#
# Any entry in the lists of programs that urlview handler will try out will
# be made of /path/to/program + ':' + TAG where TAG is one of
# PW: X11 program intended to live on after urlview's caller exits.
# XW: X11 program
# XT: Launch with an xterm if possible or as VT if not
# VT: Launch in the same terminal

# The lists of programs to be executed are
http_prgs="/usr/bin/sensible-browser:PW /usr/bin/sensible-browser:XT /usr/bin/galeon:PW /usr/bin/konqueror:PW /usr/bin/mozilla:PW /usr/bin/lynx:XT /usr/bin/w3m:XT /usr/bin/links:XT"
mailto_prgs="/usr/bin/mutt:VT /usr/bin/elm:VT /usr/bin/alpine:VT /usr/bin/pine:VT /usr/bin/mail:VT"
gopher_prgs="/usr/bin/gopher:XT /usr/bin/lynx:XT"
ftp_prgs="/usr/bin/ncftp:XT /usr/bin/lftp:XT $http_prgs"
file_prgs="/usr/bin/wget:XT /usr/bin/snarf:XT"

XTERM=/usr/bin/x-terminal-emulator


###########################################################################
# Change below this at your own risk
###########################################################################
getprg()
{
    for ele; do
	tag=${ele##*:}
	prog=${ele%%:*}
	if [ -x "$prog" ]; then
	    case "$tag" in
	    PW) [ -n "$DISPLAY" ] && echo "PW:$prog" && return 0
	    	;;
	    XW)
		[ -n "$DISPLAY" ] && echo "XW:$prog" && return 0
		;;
	    XT)
		[ -n "$DISPLAY" ] && [ -x "$XTERM" ] && \
		    echo "XT:$XTERM -e $prog" && return 0
		echo "$prog" && return 0
		;;
	    VT)
		echo "$prog" && return 0
		;;
	    esac
	fi
    done
}

url=$1; shift

type=${url%%:*}

if [ "$url" = "$type" ]; then
    type=${url%%.*}
    case "$type" in
    www|web|www[1-9])
	type=http
	;;
    esac
    url=$type://$url
fi

if [ "$type" = "ftp" ]; then
    filename=${url##*/}
    if [ -n "$filename" ]; then
    	echo "Is \"$filename\" a file? (y/N)";
	read -r x
	[ "${x#[yY1]}" != "$x" ] && type="file"
    fi
fi

case "$type" in
http|https)
    prg=$(getprg $http_prgs)
    ;;
ftp)
    prg=$(getprg $ftp_prgs)
    ;;
mailto)
    prg=$(getprg $mailto_prgs)
    ;;
gopher)
    prg=$(getprg $gopher_prgs)
    ;;
file)
    prg=$(getprg $file_prgs)
    ;;
*)
    echo "Unknown URL protocol $type."
    echo "Please report URL and viewer to:"
    echo "  urlview@packages.debian.org"
    printf "Press enter to continue... "
    read -r _
    exit
    ;;
esac

if [ -n "$prg" ]; then
    case "${prg%:*}" in
	PW)
	    nohup ${prg#*:} "$url" 2>/dev/null 1>&2 &
	    ;;
	XT)
	    ${prg#*:} "$url" 2>/dev/null &
	    ;;
	*)
	    exec $prg "$url"
	    ;;
    esac
fi
