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

# Name of the Python script
PYTHON_SCRIPT="report.py"

# Wait time in seconds
WAIT_TIME=$((2 * 60 * 60))  # 2 hours converted to seconds
UPDATE_INTERVAL=$((5 * 60))  # 5 minutes converted to seconds

echo "Running $PYTHON_SCRIPT with --order..."
python3 "$PYTHON_SCRIPT" --order

echo "Waiting for 2 hours..."
time_remaining=$WAIT_TIME

# Countdown loop
while [ $time_remaining -gt 0 ]; do
    minutes_left=$((time_remaining / 60))
    echo "Time remaining: $minutes_left minutes"
    sleep $UPDATE_INTERVAL
    time_remaining=$((time_remaining - UPDATE_INTERVAL))
    if [ $time_remaining -lt 0 ]; then
        time_remaining=0
    fi
done

echo "Running $PYTHON_SCRIPT with --download..."
python3 "$PYTHON_SCRIPT" --download
