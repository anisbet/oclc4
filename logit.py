
###############################################################################
#
# Simple log function.
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
#  May 3, 2024
#
###############################################################################

import sys
from datetime import datetime

def logit(message, level:str='info', timestamp:bool=False, logFilePrefix:str='./oclc4_'):
    """ 
    Wrapper for the logger. Added after the class was written
    and to avoid changing tests. 
    
    Parameters:
    - message:list message(s) to either log or print. 
    - level of messaging. If 'error' is used the message is prefixed with '*error'.
    - timestamp:bool if True add a timestamp to the output.

    Return:
    - None
    """
    time_str = ''
    if timestamp:
        time_str = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] "
    log_file = f"{logFilePrefix}{datetime.now().strftime('%Y-%m-%d')}.log"

    if isinstance(message, str):
        message = [message]
    for msg in message:
        if level == 'error':
            print(f"{time_str}*error, {msg}")
        else:
            print(f"{time_str}{msg}")
    with open(f"{log_file}", 'a') as log:
        for msg in message:
            if level == 'error':
                print(f"{time_str}*error, {msg}", file=log)
            else:
                print(f"{time_str}{msg}", file=log)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("logit.tst")