#!/bin/bash
###############################################################################
#
# Generates flat records of all catalog records. See LOCATIONS and ITEM_TYPES
# to restrict record selection. The script will clean up files if re-run
# today, but won't clean up submissions from previous days.
#
# The script selects all items that are not in LOCATION and not of type 
# ITEM_TYPE, outputting the item's catalog key. Once done the list is sorted
# and uniq-ed, the remaining cat keys are used to select dump catalog records
# to flat file.
# The process was originally intended for OCLC, but is not limited to it.
# 
#  Copyright (C) Andrew Nisbet 2024
#  
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#  
#       http://www.apache.org/licenses/LICENSE-2.0
#  
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#  Feb. 15, 2023
#
###############################################################################
. ~/.bashrc
# Short form: set -e
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail
TEMP_FILE="catkeys.wo_types.wo_locations.lst"
ILS='edpl.sirsidynix.net'
HOST=$(hostname)
[ "$HOST" != "$ILS" ] && { logit "*error, script must be run on a Symphony ILS."; exit 1; }
# Do clean up of flat file to save space.
VERSION="2.07.04"
TODAY=$(transdate -d-0)
APP=$(basename -s .sh "$0")
TYPES="~PAPERBACK,JPAPERBACK,BKCLUBKIT,COMIC,DAISYRD,EQUIPMENT,E-RESOURCE,FLICKSTOGO,FLICKTUNE,JFLICKTUNE,JTUNESTOGO,PAMPHLET,RFIDSCANNR,TUNESTOGO,JFLICKTOGO,PROGRAMKIT,LAPTOP,BESTSELLER,JBESTSELLR" 
LOCATIONS="~BARCGRAVE,CANC_ORDER,DISCARD,EPLACQ,EPLBINDERY,EPLCATALOG,EPLILL,INCOMPLETE,LONGOVRDUE,LOST,LOST-ASSUM,LOST-CLAIM,LOST-PAID,MISSING,NON-ORDER,BINDERY,CATALOGING,COMICBOOK,INTERNET,PAMPHLET,DAMAGE,UNKNOWN,REF-ORDER,BESTSELLER,JBESTSELLR,STOLEN"
BIN_PATH=~/Unicorn/Bin
SELITEM=$BIN_PATH/selitem
CATALOG_DUMP=$BIN_PATH/catalogdump
# Logs messages to STDOUT and $LOG_FILE file.
# param:  Message to put in the file.
# param:  (Optional) name of a operation that called this function.
LOG_FILE="${APP}.log"
logit()
{
    local message="$1"
    local time=''
    time=$(date +"%Y-%m-%d %H:%M:%S")
    if [ -t 0 ]; then
        # If run from an interactive shell message STDOUT and LOG_FILE.
        echo -e "[$time] $message" | tee -a "$LOG_FILE"
    else
        # If run from cron do write to log.
        echo -e "[$time] $message" >>"$LOG_FILE"
    fi
}

logit "=== $APP $VERSION"
[ -f "$SELITEM" ] || { logit "*error, missing $SELITEM."; exit 1; }
[ -f "$CATALOG_DUMP" ] || { logit "*error, missing $CATALOG_DUMP."; exit 1; }
# Note that this only deletes _today's_ files if they exist.
[ -f "$TEMP_FILE" ] && { logit "cleaning up temp files"; rm "$TEMP_FILE"; }
[ -f "bib_records_${TODAY}.zip" ] && { logit "cleaning up old submission"; rm "bib_records_${TODAY}.zip"; }
[ -f "bib_records_${TODAY}.flat" ] && { logit "cleaning up old flat file"; rm "bib_records_${TODAY}.flat"; }
logit "Starting item selection"
$SELITEM -t"$TYPES" -l"$LOCATIONS" -oC 2>/dev/null | sort | uniq >"$TEMP_FILE" 
logit "done"
logit "Starting to dump the records"
$CATALOG_DUMP -oF 2>/dev/null  <"$TEMP_FILE" >"bib_records_${TODAY}.flat"
logit "done"
logit "compressing flat records"
zip "bib_records_${TODAY}.zip" "bib_records_${TODAY}.flat" 2>>"$LOG_FILE"
# Test for integrity of zip archive
zip_file="bib_records_${TODAY}.zip"
[ ! -f "$zip_file" ] && { logit "Error: the zip file was not created."; exit 1; }
# Check if the file is a valid zip archive
if ! unzip -t "$zip_file" > /dev/null 2>&1; then
    logit "Error: Not a valid zip file"
    exit 1
fi
# Check if the zip file is empty
if zipinfo -t "$zip_file" | grep -q "0 files"; then
    logit "Warning: Zip file is empty"
    exit 1
else
    logit "Zip file is valid and contains data."
    logit "Contents:"
    zip_content=$(zipinfo "$zip_file")
    logit "$zip_content"
    rm "bib_records_${TODAY}.flat"
fi
logit "done"
exit 0
