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

# Name of the file to check
FILE_ADDS="oclc_update_adds.json"
FILE_DELS="oclc_update_deletes.json"
# Name of the Python script to run
PYTHON_SCRIPT="oclc4.py"

# Start the loop
while true; do
    if [ -f "$FILE_ADDS" ] || [ -f "$FILE_DELS" ]; then
        echo "File $FILE_ADDS (or $FILE_DELS) found. Running $PYTHON_SCRIPT...(BG)"
        python3 "$PYTHON_SCRIPT" --recover&
        echo "Sleeping for 3 hours..."
        sleep 3h
    else
        echo "File $FILE_ADDS not found, updates finished"
        break
    fi
done

echo "Script completed."
