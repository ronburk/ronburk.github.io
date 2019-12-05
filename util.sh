#!/bin/bash

# util.sh - utility code for scripts

function DebugTrapError(){
    echo "Error in ${1}, Line ${2}"
    DebugTraceBack "$1" "$2"
    exit 1
}
function DebugTotesAmazeballs(){
    # exit on any error
    # OK, you really have to understand the obscure rules for errexit and
    # look at every command to see if returning !0 is OK, and therefore must
    # be treated specially (if you see an inexplicable use of a subshell,
    # it's probably to avoid an error exit). Still, it can be a net win for robustness
    set -o errexit
    # catch uninitialized variables
    set -o nounset
    # catch failed pipes
    set -o pipefail
    # emit line number and nesting debug info
    PS4=':${LINENO}+'
#    set -o xtrace
    trap 'DebugTraceBack "${BASH_SOURCE}" "${LINENO}"' ERR
}

DebugTotesAmazeballs

# tricky part of TraceOff() and TraceOn() is that we want both functions
# to do nothing if trace was not on when we started.

function TraceCheck() {
    # if first time anybody called us
    if [ -z ${TraceOff+x} ]; then
        if [ -o xtrace ]; then TraceOff="0"; else TraceOff="1"; fi
    fi    
    }
function TraceOff() {
    TraceCheck
    # if we think tracing was on at startup
    if [ "$TraceOff" == "0" ]; then
        set +o xtrace
    fi
    }

function TraceOn()  {
    TraceCheck
    # if we think tracing was on at startup
    if [ "$TraceOff" == "0" ]; then
        set -o xtrace
    fi
    }

function DieMarker() {
    echo "****************************************************************"
    }
function Die(){
    if [ $# ] ; then
        DieMarker
        echo "$@"
    fi
    exit 1
    }

function DebugTraceBack(){
    local -i end=${#BASH_SOURCE[@]}
    local -i i
    for ((i=1; i < end; ++i));
    do
        local -i linenum=${BASH_LINENO[(($i-1))]}
        echo "${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:$linenum"
        local Src="${BASH_SOURCE[$i]}"
        if test -r "$Src" -a -f "$Src" ; then
            # read line number of file
            mapfile -t -s $(($linenum - 1)) -n 1 LineArray < ${Src}
            echo "    ${LineArray[*]}"
        else
            echo "That's friggin weird. Source file [${Src}] not readable!"
        fi
    done
}

# assert "assertion" - simple assert function
function assert(){
    # time to be quiet
    TraceOff
    # no args means assert statement should not have been reached
    if [ $# -le 0 ]; then die "Assertion failed." ; fi
    # otherwise, die if assertion not true
    if $@ ; then
        TraceOn
    else
        DieMarker
        echo "Assertion failed: " "$@"
        local -i end=${#BASH_SOURCE[@]}
        local -i i
        for ((i=1; i < end; ++i));
            do
            local -i linenum=${BASH_LINENO[(($i-1))]}
            echo "${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:$linenum"
            local Src="${BASH_SOURCE[$i]}"
            if test -r "$Src" -a -f "$Src" ; then
                # read line number of file
                mapfile -t -s $(($linenum - 1)) -n 1 LineArray < ${Src}
                echo "    ${LineArray[*]}"
            else
                echo "That's friggin weird. Source file [${Src}] not readable!"
            fi
            done
        Die
    fi
    }

function assertname(){
    # you gotta give us the name, and nothing but the name
    assert "[ $# -eq 1 ]"
    # and it looks like this...
    local pattern='^[_[:alpha:]][_[:alnum:]]*$'
    # assert it is a legal name
    assert "[[ $1 =~ ${pattern} ]]"
    }

# IsDirEmpty - return 1/0 to indicate given directory contains no files
function IsDirEmpty(){
    assert "[ $# -eq 1 ]"

    # be a little fancy to avoid invoking external command
    # dotglob = don't hide files that start with '.'
    # nullglob = pattern that doesn't match any expands to null string
    files=$(shopt -s nullglob;shopt -s dotglob;echo $1/*)
    if [ ${#files} -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# RequireUserExists - die if a given user does not exist
function RequireUserExists() {
    assert "[ $# -eq 1 ]"
    if ! id -u "$1" >/dev/null 2>&1; then
        Die "User \"${iUser}\" does not exist."
    fi
}

# PkgInstall - ensure one or more packages is installed
function PkgInstall()    {
    # no args? no operation.
    if [ $# -le 0 ]; then return; fi

    # grep -q can cause a pipefail
    set +o pipefail
    # iterate over package names
    for pkg in "$@"; do
        if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$"; then
            echo -e "$pkg is already installed"
        else
            echo "Let's install $pkg!"
            # catch install error and give explicit error message
            echo "========================="
            if ! apt-get -qq install $pkg ; then
                Die  "[exit code:$?] Failed to install package " $pkg
            fi
            if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
                echo "Successfully installed $pkg"
            else
                Die "Install of $pkg seems to have been unsuccessful!"
            fi
        fi
    done
    # re-enable pipefail
    set -o pipefail
    }

# safe - execute command that may fail (but don't cause script termination)
function safe() {
#    $@ && rc=$? || rc=$?

    local ReturnCode="0"
    if ! "$@" ; then
        ReturnCode="$?"
    fi
    return ReturnCode
}

# ronburk - execute command as user "ronburk"
function ronburk()  {
    sudo -u ronburk $@
    }

# RequireReadableFile - die if file not readable
# Syntax:
#     RequireReadableFile filename error_prefix?
function RequireReadableFile() {
    local ErrorPrefix=""
    if [ $# -gt 1 ]; then
        ErrorPrefix="$2 "
    fi
        
    if ! [ -e "$1" ]; then
        Die "${ErrorPrefix}\"$1\" does not exist."
    elif ! [ -f "$1" ]; then
        Die "${ErrorPrefix}\"$1\" is not a file."
    elif ! [ -r "$1" ]; then
        Die "${ErrorPrefix}\"${CFGNAME}.cfg\" is not a readable file."
    fi
    return 0
}


# Warn - echo warning message
#
# This exists just to have a consistent syntax for marking warnings
# in the output. Also, to be able to grep for warnings in script.
function Warn(){
    echo "!!! " "$@"
}

# ShoptExec - set shell options for just this command.
#
# Usage:
#     ShoptExec <shopt options> -- <command to execute>
#
function ShoptExec(){
    # this function is way too noisy
    TraceOff
    # save executable description of current shopt state
    local OldOptions=$(shopt -p)

    # must locate the '--' argument
    local Arg
    local ArgCount=1
    for Arg in "${@:2}"; do
        if [ "${!ArgCount}" == "--" ]; then
            break
        else
            ((++ArgCount))
        fi
    done

    assert "[ ${ArgCount} -lt $# ]"
    TraceOn

    # set shell options as caller desired
    if [ $ArgCount -gt 1 ]; then
        echo "calling shopt as: " shopt "${@:1:$((ArgCount-1))}"
        shopt ${@:1:$((ArgCount-1))}
    fi
    # now execute caller's command (everything past '--')
    "${@:$((ArgCount+1))}"

    # replay original description of shopt state
    TraceOff
    eval "$OldOptions" 2> /dev/null
    TraceOn
    }

# YesNo(): ask user yes/no question, return true if yes
function YesNo() {
    declare -l Answer    # make a lower-casing variable
    while true; do
        read -p "$1 [Y/n]: " Answer
        Answer=${Answer:-y}
        case "$Answer" in
            "y"|"yes"|"")
                Answer="y"
                break
                ;;
            "n"|"no")
                Answer="n"
                break
                ;;
        esac
    done
    if [ "$Answer" == "y" ]; then
        return 0
    else
        return 1
    fi
}

function ReadNoEcho() {
    assert "[ $# -eq 1 ]"
    local Prompt="$1"
    echo -n "$Prompt"
    read -r -s ReadNoEcho
    echo ""
}
