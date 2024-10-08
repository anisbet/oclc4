#!/bin/bash
###############################################################################
#
# This script overlays bib records taken as the first and only argument.
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
#  October 2, 2024
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

ILS='edpl.sirsidynix.net'
HOST=$(hostname)
[ "$HOST" != "$ILS" ] && { logit "*error, script must be run on a Symphony ILS."; exit 1; }
# Do clean up of flat file to save space.
VERSION="0.00.01"
TODAY=$(transdate -d-0)
APP=$(basename -s .sh "$0")
CATALOG_MERGE=~/Unicorn/Bin/catalogmerge

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

[ -f "$CATALOG_MERGE" ] || { logit "*error, missing $CATALOG_MERGE."; exit 1; }
[ -f "$1" ] || { logit "*error, expected bib_overlay file as the first argument."; exit 1; }
logit "over-laying records"
# cat oclc_overlay_YYYYMMDD.flat | catalogmerge -if -aMARC -bf -fg -d -r -t035 2>oclc_update_YYYYMMDD.err >oclc_update_YYYYMMDD.lst
cat "$1" | "$CATALOG_MERGE" -if -aMARC -bf -fg -d -r -t035 2>>"oclc_update_${TODAY}.err" >>"oclc_update_${TODAY}.lst"

logit "done"
exit 0
