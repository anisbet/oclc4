#!/bin/bash

###############################################################################
#
# Purpose: Run oclc4.py until there are no more adds or deletes JSON files.
# Date:    Tue 14 Jan 2025 07:46:56 PM EST
# Copyright (c) 2025 Andrew Nisbet
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
APP=$(basename -s .sh "$0")
# Name of the file to check
ADD_FILE_BACKUP="oclc_update_adds.json"
DEL_FILE_BACKUP="oclc_update_deletes.json"
# Name of the Python script to run
PYTHON_SCRIPT="oclc4.py"
VERSION="1.00.02"
SLEEP_TIME="2"
DEBUG=false
ADD_FILE=
DEL_FILE=
LOG="${APP}.log"
SHARED_DIR="/home/anisbet/Shared"
AUTHOR_ID=anisbet

###############################################################################
# Display usage message.
# param:  none
# return: none
usage()
{
    cat << EOFU!
Usage: $APP [-options]
 Runs the OCLC update process. It will run $PYTHON_SCRIPT and if 
 the process finishes leaving the $ADD_FILE_BACKUP and/or $DEL_FILE_BACKUP 
 the script will wait $SLEEP_TIME hours and then restart work on 
 the leftovers.

 -a, --add: Sets the add file.
 -d, --delete: Set the delete file.
 -h, --xhelp: See -x.
 -v, --version: Display version and exits.
 -x, --xhelp: display usage message and exit.

EOFU!
	exit 1
}

# Logs messages to STDOUT and $LOG file.
# param:  Message to put in the file.
# param:  (Optional) name of a operation that called this function.
logit()
{
    local message="$1"
    local time=''
    time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$time] $message" | tee -a $LOG
}
# Logs messages as an error and exits with status code '1'.
logerr()
{
    local message="${1} exiting!"
    local time=''
    time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$time] **error: $message" | tee -a $LOG
    exit 1
}

### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "add:,delete:,help,version,xhelp" -o "a:d:hvx" -a -- "$@")
if [ $? != 0 ] ; then logit "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"
while true
do
    case $1 in
    -a|--add)
        shift
        [ "$DEBUG" == true ] || logit "set records from the ILS in the following file: $1"
        if ! sudo ls -l "$SHARED_DIR/$1"; then
            logerr "no such file $1, check $SHARED_DIR and try again."
        fi
        sudo cp "$SHARED_DIR/$1" .
        sudo chown "$AUTHOR_ID":"$AUTHOR_ID" "$1"
		ADD_FILE="$1"
		;;
    -d|--delete)
        shift
        [ "$DEBUG" == true ] || logit "unset records from OCLC in the following file: $1"
		DEL_FILE="$1"
		;;
    -h|--help)
        usage
        ;;
    -v|--version)
        logit "$0 version: $VERSION"
        exit 0
        ;;
    -x|--xhelp)
        usage
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done
if [[ -z "$ADD_FILE" && -z "$DEL_FILE" ]]; then
    logit "the add file or delete file are not set."
    exit 2
fi
logit "== starting $0 version: $VERSION"
logit "File $ADD_FILE (and $DEL_FILE) found. Running $PYTHON_SCRIPT"
python3 "$PYTHON_SCRIPT" --add="$ADD_FILE" --delete="$DEL_FILE"



# Start the loop
while true; do
    if [ -f "$ADD_FILE_BACKUP" ] || [ -f "$DEL_FILE_BACKUP" ]; then
        logit "File $ADD_FILE_BACKUP (or $DEL_FILE_BACKUP) found. Running $PYTHON_SCRIPT...(BG)"
        python3 "$PYTHON_SCRIPT" --recover&
        logit "Sleeping for $SLEEP_TIME hours..."
        sleep "$SLEEP_TIME"h
    else
        logit "File $ADD_FILE_BACKUP not found, updates finished"
        break
    fi
done

logit "$APP completed."
