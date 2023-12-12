#!/usr/bin/env python3
###############################################################################
#
# Purpose: Update OCLC local holdings for a given library.
# Date:    Mon 04 Dec 2023 07:46:56 PM EST
# Copyright (c) 2023 Andrew Nisbet
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

from os.path import exists
from os import linesep
import argparse
import sys
from ws2 import WebService
from datetime import datetime
import json
from record import Record

VERSION='0.00.00'
APP = 'hist2json'

# Wrapper for the logger. Added after the class was written
# and to avoid changing tests. 
# param: message:str message to either log or print. 
# param: to_stderr:bool if True and logger
def logit(messages, level:str='info', timestamp:bool=False):
    time_str = ''
    if timestamp:
        time_str = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] "
    if isinstance(messages, list):
        if level == 'error':
            for message in messages:
                print(f"{time_str}*error, {message}")
        else:
            for message in messages:
                print(f"{time_str}{message}")
    else:
        if level == 'error':
            msg = f"{time_str}*error, {messages}"
        else:
            msg = f"{time_str}{messages}"
        print(f"{msg}")

class RecordManager:
    # TODO: add encoding flag?
    def __init__(self, ignoreTags:dict={}, encoding:str='utf-8'):
        self.adds = []
        self.deletes = []
        self.matchs = []
        self.ignore_tags = ignoreTags
        # OCLC numbers that were rejected. These could be because there was an add 
        # request, when OCLC already has the number listed as a holding, a delete
        # that OCLC doesn't show as a holding, and records rejected because they
        # match an of the ignoreTags. 
        self.rejected = []
        self.encoding = encoding
        self.backup_prefix = 'oclc_update_'

    # Reads flat records into a list from file. Add lists are always flat format records. 
    def readFlatOrMrkRecords(self, fileName:str, debug:bool=False) ->list:
        if not fileName:
            logit(f"no flat or mrk records to read.")
        if exists(fileName):
            with open(fileName, encoding='utf-8', mode='rt') as flat_file:
                lines = []
                my_type = ''
                for line in flat_file:
                    if '*** DOCUMENT BOUNDARY ***' in line or '=LDR ' in line:
                        # A new boundary means a new record so output any existing.
                        if lines:
                            # Remember all mrk or flat files are add or set holding records when reading from file.
                            record = Record(data=lines, action='set', rejectTags=self.ignore_tags, encoding=self.encoding)
                            if (debug):
                                print(f"{record}")
                            self.adds.append(record)
                            lines = []
                    lines.append(line.rstrip())
            flat_file.close()
            # Output the last record since there are no more doc boundaries to trigger that.
            if lines:
                record = Record(data=lines, action='set', rejectTags=self.ignore_tags, encoding=self.encoding)
                if (debug):
                    print(f"{record}")
                self.adds.append(record)
        else:
            logit(f"**error, {fileName} is either missing or empty.")
            sys.exit(1)

    # Reads delete OCLC numbers into a JSON list in a file. 
    def readDeleteList(self, fileName:str, debug:bool=False) ->list:
        self.deletes = self.loadJson(fileName)
        if debug:
            logit(f"loaded {len(self.deletes)} delete records.")

    # Reads the holding report from OCLC which includes all of the library's holdings. 
    # This is used as a yardstick to compare adds and deletes, that is, the adds list
    # is compared and only the records not on this list will be added. Similarly, if
    # this list doesn't include a number that appears on the delete list, it is not 
    # sent as a delete request.
    def readHoldingsReport(self, csvfileName:str) ->list:
        pass
        
    # Given an arbitrary but specific list of records remove those that 
    # are part of a second list, and return the first list. 
    def dedupLists(self, *lists:list, debug:bool=False) -> list:
        # Compares two lists with '+', ' ', or '-' instructions and returns
        # a merged list. If duplicate numbers have the different instructions
        # the instruction character is replaced with a space ' ' character. 
        # If there are duplicate numbers and they are both '+' or '-', the 
        # duplicate is removed, and actions are reconciled by the following
        # algorithm: 
        # 1) '!' trumps all other rules. 
        # 2) '?' trumps any lower rule.
        # 3) Conflicting add ('+') and delete ('-') actions equates to an inaction ' ', do nothing.
        # 4) Any action ('+','-','!', or '?') over rules inaction ' '. 
        #  
        # param: list1:list of any set of oclc numbers with arbitrary instructions.
        # param: list2:list of any set of oclc numbers with arbitrary instructions.
        # return: list of instructions deduped with conflicting recociled as specified above.
        # def merge(self, *lists:list) ->list:
        # merged_dict = {}
        # merged_list = []
        # for l in lists:
        #     for num in l:
        #         key = num[1:]
        #         sign= num[0]
        #         if sign == '!':
        #             merged_dict[key] = sign
        #             continue
        #         stored_sign = merged_dict.get(key)
        #         if stored_sign:
        #             if stored_sign == '!':
        #                 continue
        #             if stored_sign == '?' or sign == '?':
        #                 merged_dict[key] = '?'
        #             elif (stored_sign == '+' and sign == '-') or (stored_sign == '-' and sign == '+'):
        #                 merged_dict[key] = ' '
        #             else:
        #                 merged_dict[key] = sign
        #         else:
        #             merged_dict[key] = sign
        # for number in sorted(merged_dict.keys()):
        #     sign = merged_dict[number]
        #     merged_list.append(f"{sign}{number}")
        # return merged_list
        pass

    def setHoldings(self, debug:bool=False):
        pass
    def unsetHoldings(self, debug:bool=False):
        pass
    def matchFailedHoldings(self, debug:bool=False):
        pass
    def updateSlimFlat(self, flatFile:str=None, debug:bool=False):
        pass

    def dumpJson(self, fileName:str, data:dict):
        with open(fileName, 'wt') as fp:
            json.dump(data, fp)
        fp.close()

    def loadJson(self, fileName:str) -> dict:
        fp = open(fileName, 'rt')
        ret_dict = json.load(fp)
        fp.close()
        return ret_dict

    # This method is for when the application is requested to close 
    # because of a software or keyboard interrupt like <ctrl-c>. 
    # It writes the existing state of update to backup files.
    # param: debug:bool outputs any additional debug information while
    #   while running. 
    def _restore_(self, debug:bool=False):
        if debug:
            logit(f"restoring records from backup...")
        self.adds = self.loadJson(f"{self.backup_prefix}adds.json", self.adds)
        self.deletes = self.loadJson(f"{self.backup_prefix}deletes.json", self.deletes)
        self.matches = self.loadJson(f"{self.backup_prefix}matches.json", self.matches)
        if debug:
            logit(f"done.")

    # This method is for when the application is requested to close 
    # because of a software or keyboard interrupt like <ctrl-c>. 
    # It writes the existing state of update to backup files. 
    # param: debug:bool outputs any additional debug information while
    #   while running. 
    def cleanUp(self, debug:bool=False):
        if debug:
            logit(f"saving records' state to backup...")
        self.dumpJson(f"{self.backup_prefix}adds.json", self.adds)
        self.dumpJson(f"{self.backup_prefix}deletes.json", self.deletes)
        self.dumpJson(f"{self.backup_prefix}matches.json", self.matches)
        if debug:
            logit(f"done.")

# Main entry to the application if not testing.
def main(argv):
    debug = False
    parser = argparse.ArgumentParser(
        prog = 'oclc',
        usage='%(prog)s [options]' ,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='''\
            Maintains holdings in OCLC WorldCat database.
            ''',
        epilog='''\
    TODO: add documentation here.
        '''
    )
    parser.add_argument('--add', action='store', metavar='[/foo/my_nums.flat|.mrk]', help='List of bib records to add in flat or mrk format.')
    parser.add_argument('-d', '--debug', action='store_true', default=False, help='turn on debugging.')
    parser.add_argument('--delete', action='store', metavar='[/foo/oclc_nums.lst]', help='List of OCLC numbers to delete from OCLC\'s holdings database.')
    parser.add_argument('--report', action='store', metavar='[/foo/oclcholdingsreport.csv]', help='Holdings report from OCLC\'s database in CSV format.')
    parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)
    
    args = parser.parse_args()
    if args.version:
        print(f"{APP} version: {VERSION}")
        sys.exit(0)
    manager = RecordManager(debug=args.debug)
    try:
        manager.readFlatOrMrkRecords(add=args.add, debug=args.debug)
        manager.readHoldingsReport(reportCsv=args.report)
        manager.runUpdate(debug=args.debug)
        
    except KeyboardInterrupt:
        print(f"Keyboard interrupt.")
        manager.cleanUp(debug=args.debug)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("oclc4.tst")