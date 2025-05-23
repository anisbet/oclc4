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
VERSION="1.01.00"
SLEEP_TIME="2"
DEBUG=false
ADD_FILE=
DEL_FILE=
LOG="${APP}.log"
SHARED_DIR="/home/anisbet/Shared"
AUTHOR_ID=anisbet
MAX_RUNS=4

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

 The script expects the --add list to be found in $SHARED_DIR 
 so you can just specify the name, for example --add=bib_records_xyz.zip
 and the script will look in $SHARED_DIR for bib_records_xyz.zip and
 unpack and process the file.

 -a, --add: Sets the add file, which are the zipped bib records from 
   the ILS. This script will look for the argument file name in the 
   $SHARED_DIR and if found, copy it to the current directory, and
   change its ownership to $AUTHOR_ID.
 -d, --delete: Set the delete file. These are numbers extracted from
   an xls (csv) report generated by OCLC. The conversion to this list
   is automatically done by report.py.
 -h, --xhelp: See -x.
 -m, --maxruns: integer max number of processing sessions. Default $MAX_RUNS.
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
    echo -e "[$time] $message" | tee -a "$LOG"
}
# Logs messages as an error and exits with status code '1'.
logerr()
{
    local message="${1} exiting!"
    local time=''
    time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$time] **error: $message" | tee -a "$LOG"
    exit 1
}
# Reports the number of records left to process.
report_progress()
{
    logit "File $ADD_FILE_BACKUP (or $DEL_FILE_BACKUP) found. Running $PYTHON_SCRIPT...(BG) on "
    pipe.pl -W'", "' -K <"$DEL_FILE_BACKUP" | pipe.pl -cc0 >/dev/null
    logit "delete records and "
    grep -c '\"action\": \"set\"' "$ADD_FILE_BACKUP"
    logit "add records."
}

### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "add:,delete:,help,maxruns:,version,xhelp" -o "a:d:hm:vx" -a -- "$@") || logerr "Failed to parse options...exiting."
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
        if ! sudo test -f "$SHARED_DIR/$1"; then
            logerr "no such file $1, check $SHARED_DIR and try again."
        fi
        sudo cp "$SHARED_DIR/$1" "./$1"
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
    -m|--maxruns)
        shift
        [ "$DEBUG" == true ] || logit "Maximum number of recoveries set to: $1"
		MAX_RUNS="$1"
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
logit "== starting $0 version: $VERSION"
if [[ -f "$ADD_FILE" && -f "$DEL_FILE" ]]; then
    logit "File $ADD_FILE and $DEL_FILE found. Running $PYTHON_SCRIPT"
    python3 "$PYTHON_SCRIPT" --add="$ADD_FILE" --delete="$DEL_FILE"
    if [ -f "$ADD_FILE_BACKUP" ] || [ -f "$DEL_FILE_BACKUP" ]; then
        report_progress
    fi
fi
# The previous run counts as the first process.
count=1
# Start the loop through any backup files.
while true; do
    if [ -f "$ADD_FILE_BACKUP" ] || [ -f "$DEL_FILE_BACKUP" ]; then
        report_progress
        if [[ "$count" -ge "$MAX_RUNS" ]]; then
            logit "Finished $MAX_RUNS processing attempts."
            break
        fi
        python3 "$PYTHON_SCRIPT" --recover &
        count=$((count + 1))
        sleep "$SLEEP_TIME"h
    else
        logit "File $ADD_FILE_BACKUP not found, updates finished"
        break
    fi
done

logit "$APP completed."
