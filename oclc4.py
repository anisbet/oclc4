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

from os.path import exists, getsize, splitext
from os import linesep
import argparse
import sys
from ws2 import WebService
from datetime import datetime
import json
from record import Record
import re

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
        self.adds_read    = []
        self.master_adds  = []
        self.deletes_read = []
        self.master_delete= []
        # An internal list for records that don't have OCLC numbers and need matching.
        self.matches = []
        # Stores the OCLC numbers from their holdings report.
        self.oclc_holdings = []
        self.ignore_tags = ignoreTags
        # OCLC numbers that were rejected and the reason for rejection.
        # These could be because there was an add 
        # request, when OCLC already has the number listed as a holding, a delete
        # that OCLC doesn't show as a holding, and records rejected because they
        # match an of the ignoreTags. T
        self.rejected = {}
        self.encoding = encoding
        self.backup_prefix = 'oclc_update_'

    # Helper tests if the file has content and returns True if it does and False 
    # otherwise, and returns the path and extension of the file as well. 
    def _test_file_(self, fileName:str) -> list:
        ret_list = []
        if not exists(fileName) or getsize(fileName) == 0:
            logit(f"The {fileName} file is empty (or missing).")
            ret_list.append(False)
        else:
            ret_list.append(True)
        (path, ext) = splitext(fileName)
        ret_list.append(path)
        ret_list.append(ext)
        return ret_list

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
                            self.adds_read.append(record)
                            lines = []
                    lines.append(line.rstrip())
            flat_file.close()
            # Output the last record since there are no more doc boundaries to trigger that.
            if lines:
                record = Record(data=lines, action='set', rejectTags=self.ignore_tags, encoding=self.encoding)
                if (debug):
                    print(f"{record}")
                self.adds_read.append(record)
        else:
            logit(f"**error, {fileName} is either missing or empty.")
            sys.exit(1)

    # Reads delete OCLC numbers from a JSON file. 
    def readDeleteList(self, fileName:str, debug:bool=False):
        (is_valid, path, ext) = self._test_file_(fileName)
        if not is_valid:
            logit(f"no deletes will be processed because of previous error(s) with {fileName}.")
            self.deletes_read = []
            return
        if ext and ext.lower() == '.json':
            self.deletes_read = self.loadJson(fileName)
        else:
            with open(fileName, 'rt') as f:
                lines = f.readlines()
            f.close()
            self.deletes_read = list(map(str.strip, lines))
        if debug:
            logit(f"loaded {len(self.deletes_read)} delete records: {self.deletes_read[0:4]}...")

    # Reads the holding report from OCLC which includes all of the library's holdings. 
    # This is used as a yardstick to compare adds and deletes, that is, the adds list
    # is compared and only the records not on this list will be added. Similarly, if
    # this list doesn't include a number that appears on the delete list, it is not 
    # sent as a delete request.
    def readHoldingsReport(self, fileName:str, debug:bool=False):
        (is_valid, path, ext) = self._test_file_(fileName)
        if not is_valid:
            logit(f"The holding report {fileName} is broken.")
            self.oclc_holdings = []
            return
        if ext and (ext.lower() == '.csv' or ext.lower() == '.tsv'):
            numbers = []
            num_matcher  = re.compile(r'"\d+"')
            with open(fileName, encoding=self.encoding, mode='r') as report_file:
                for line in report_file:
                    num_match = re.search(num_matcher, line)
                    if num_match:
                        # Trim off the double-quotes
                        number = num_match[0][1:-1]
                        self.oclc_holdings.append(f"{number}")
            report_file.close()
            if debug:
                logit(f"loaded {len(self.oclc_holdings)} delete records: {self.oclc_holdings[0:4]}...")
        else:
            logit(f"The holding report is missing, empty or not the correct format. Expected a .csv (or .tsv) file.")
            self.oclc_holdings = []
        
    # Review the adds, deletes, and OCLC holdings list and distill them to 
    # the essential records to add delete. This will also sort records onto
    # the match list. The reject list is also populated in this method. 
    def normalizeLists(self, debug:bool=False) -> list:
        while self.deletes_read:
            oclc_num = self.deletes_read.pop()
            if self.oclc_holdings and oclc_num not in self.oclc_holdings:
                self.rejected[oclc_num] = "OCLC has no such holding to delete"
            elif oclc_num in self.master_delete:
                self.rejected[oclc_num] = "duplicate delete request; ignoring"
            else:
                self.master_delete.append(oclc_num)

        # For the adds list expect records, those will have tcns and maybe oclc numbers.
        while self.adds_read:
            record = self.adds_read.pop()
            oclc_num = record.getOclcNumber()
            if oclc_num:
                # Order matters those already added have made it through this elif ladder.
                if oclc_num in self.master_adds:
                    self.rejected[oclc_num] = "duplicate add request"
                # If requested to add but previously passed the 'delete' test
                elif oclc_num in self.master_delete:
                    self.rejected[oclc_num] = "previously requested as a delete; ignoring"
                    # and remove from the master_deletes too!
                    self.master_delete.remove(oclc_num)
                # Lastly if it is already a holding don't add again.
                elif oclc_num in self.oclc_holdings:
                    self.rejected[oclc_num] = "already a holding"
                else:
                    self.master_adds.append(oclc_num)
            else:
                self.matches.append(record)
            
        # Once done report results.
        logit(f"{len(self.master_delete)} delete record(s)")
        if debug:
            print(f"{self.master_delete}")
        logit(f"{len(self.master_adds)} add record(s)")
        if debug:
            print(f"{self.master_adds}")
        logit(f"{len(self.matches)} record(s) to check")
        if debug:
            for record in self.matches:
                print(f"{record}")   
        logit(f"{len(self.rejected)} rejected record(s)")
        for (oclc_num, reject_reason) in self.rejected.items():
            logit(f"{oclc_num}: {reject_reason}")

    def setHoldings(self, debug:bool=False):
        pass
    def unsetHoldings(self, debug:bool=False):
        pass
    def matchHoldings(self, debug:bool=False):
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
        self.adds_read = self.loadJson(f"{self.backup_prefix}adds.json", self.adds_read)
        self.deletes_read = self.loadJson(f"{self.backup_prefix}deletes.json", self.deletes_read)
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
        self.dumpJson(f"{self.backup_prefix}adds.json", self.adds_read)
        self.dumpJson(f"{self.backup_prefix}deletes.json", self.deletes_read)
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