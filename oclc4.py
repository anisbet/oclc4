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
from ws2 import SetWebService, UnsetWebService, MatchWebService, DeleteWebService
from datetime import datetime
import json
from record import Record, SET, MATCH, UPDATED 
import re

VERSION='0.00.00'

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
        # adds we read from flat or mrk file...
        self.add_records    = []
        # deletes vetted for duplicates and missing from OCLC holdings list.
        self.delete_numbers = []
        # Stores the OCLC numbers from their holdings report.
        self.oclc_holdings  = []
        # Results dictionary key:TCN -> value:webService.response.
        self.results        = {}
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
                            self.add_records.append(record)
                            lines = []
                    lines.append(line.rstrip())
            flat_file.close()
            # Output the last record since there are no more doc boundaries to trigger that.
            if lines:
                record = Record(data=lines, action='set', rejectTags=self.ignore_tags, encoding=self.encoding)
                if (debug):
                    print(f"{record}")
                self.add_records.append(record)
        else:
            logit(f"**error, {fileName} is either missing or empty.")
            sys.exit(1)

    # Reads delete OCLC numbers from a JSON file. 
    def readDeleteList(self, fileName:str, debug:bool=False):
        (is_valid, path, ext) = self._test_file_(fileName)
        if not is_valid:
            logit(f"no deletes will be processed because of previous error(s) with {fileName}.")
            self.delete_numbers = []
            return
        if ext and ext.lower() == '.json':
            self.delete_numbers = self.loadJson(fileName)
        else:
            with open(fileName, 'rt') as f:
                lines = f.readlines()
            f.close()
            self.delete_numbers = list(map(str.strip, lines))
        if debug:
            logit(f"loaded {len(self.delete_numbers)} delete records: {self.delete_numbers[0:4]}...")

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
        
    # Helper method to return the count of records with a given status
    def _get_count_(self, action:str) -> int:
        count = 0
        for record in self.add_records:
            if record.getAction() == action:
                count += 1
        return count

    # Helper method to return list of OCLC numbers to be SET.
    def _get_oclc_num_list_(self) -> list:
        ret_list = []
        for record in self.add_records:
            if record.getAction() == SET:
                ret_list.append(record.getOclcNumber())
        return ret_list

    # Shows status of RecordManager.
    def showState(self, debug:bool=False):
        logit(f"{len(self.delete_numbers)} delete record(s)")
        if debug:
            print(f"{self.delete_numbers}")
        logit(f"{self._get_count_(SET)} add record(s)")
        if debug:
            print(f"{self._get_oclc_num_list_()}")
        logit(f"{self._get_count_(MATCH)} record(s) to check")
        if debug:
            for record in self.add_records:
                if record.getAction() == MATCH:
                    print(f"{record}")
        logit(f"{len(self.rejected)} rejected record(s)")
        for (oclc_num, reject_reason) in self.rejected.items():
            logit(f"{oclc_num}: {reject_reason}")

    # Review the adds, deletes, and OCLC holdings lists and compile them to 
    # the essential records to add, delete, or match. The reject list is also 
    # populated this way. Any, or all, lists may be empty. 
    # Complilation strategy:
    # * delete list - Optional list of OCLC numbers which are a string of digits. 
    #   Duplicates are removed. See below for information on how the delete list 
    #   is affected if a hold report list is available.
    # * add list - Optional list of Flat records. Duplicates are removed. If the 
    #   same number is found in both the adds and delete list, it is ignored in 
    #   the adds list and deleted from the delete list. 
    # * OCLC holding report list - Optional list of oclc numbers like the delete list.
    #   If used, the delete list is modified to remove delete requests that are not
    #   listed as library holdings with OCLC. Similarly, if a number appears in 
    #   the holding report and on the add list it is removed from the add list
    #   since OCLC already knows it is a holding. 
    def normalizeLists(self, debug:bool=False) -> list:
        my_dels = []
        while self.delete_numbers:
            oclc_num = self.delete_numbers.pop()
            if self.oclc_holdings and oclc_num not in self.oclc_holdings:
                self.rejected[oclc_num] = "OCLC has no such holding to delete"
            elif oclc_num in self.delete_numbers:
                self.rejected[oclc_num] = "duplicate delete request; ignoring"
            else:
                my_dels.append(oclc_num)
        self.delete_numbers = my_dels[:]

        # For the adds list expect records, those will have tcns and maybe oclc numbers.
        # Keep track of the numbers we've already seen.
        add_numbers = []
        for record in self.add_records:
            oclc_num = record.getOclcNumber()
            if oclc_num:
                # Order matters those already added have made it through this elif ladder.
                if oclc_num in add_numbers:
                    self.rejected[oclc_num] = "duplicate add request"
                    record.setIgnore()
                # If requested to add but previously passed the 'delete' test
                elif oclc_num in self.delete_numbers:
                    self.rejected[oclc_num] = "previously requested as a delete; ignoring"
                    record.setIgnore()
                    # and remove from the master_deletes too!
                    self.delete_numbers.remove(oclc_num)
                # Lastly if it is already a holding don't add again.
                elif oclc_num in self.oclc_holdings:
                    self.rejected[oclc_num] = "already a holding"
                    record.setIgnore()
                else:
                    add_numbers.append(oclc_num)
                    record.setAdd()
            else:
                # No OCLC number in record so we'll have to look it up.
                record.setLookupMatch()
            
        # Once done report results.
        self.showState(debug=debug)

    # Dumps simple json like delete lists.
    def dumpJson(self, fileName:str, data:list):
        with open(fileName, 'wt') as fp:
            json.dump(data, fp)
        fp.close()

    # Loads simple json like delete lists.
    def loadJson(self, fileName:str) -> list:
        fp = open(fileName, 'rt')
        ret_list = json.load(fp)
        fp.close()
        return ret_list

    # This method is for when the application is requested to close 
    # because of a software or keyboard interrupt like <ctrl-c>. 
    # It writes the existing state of update to backup files.
    # param: debug:bool outputs any additional debug information while
    #   while running. 
    def restoreState(self, debug:bool=False) -> bool:
        a_names = f"{self.backup_prefix}adds.json"
        d_names = f"{self.backup_prefix}deletes.json"
        ret = True
        if debug:
            logit(f"restoring records' state from previous process...")
        logit(f"reading {a_names}")
        if self._test_file_(d_names)[0] == True:
            with open(a_names, 'r') as jf:
                j_lines = jf.readlines() 
            jf.close()
            my_jstr = ''
            for line in j_lines:
                my_jstr += line.rstrip()
            self.add_records = self.loadRecords(my_jstr)
            logit(f"adds state restored successfully from {a_names} ")
        else:
            logit(f"{a_names} is either missing or empty")
            ret = False
        if self._test_file_(d_names)[0] == True:
            self.delete_numbers = self.loadJson(d_names)
            logit(f"deletes state restored successfully from {d_names} ")
        else:
            logit(f"{d_names} is either missing or empty")
            ret = False
        if debug:
            logit(f"done.")
        return ret

    def loadRecords(self, json_str):
        # Use a custom object hook to convert dictionaries to Customer objects
        def convert_to_object(r):
            # if "name" in r and "age" in r and "hobbies" in r:
            if "data" in r and "rejectTags" in r and "action" in r and "encoding" in r and "tcn" in r and "oclcNumber" in r and "previousNumber" in r:
                return Record.from_dict(r)
            return r

        # Use the custom object hook in json.loads
        return json.loads(json_str, object_hook=convert_to_object)

    # This method is for when the application is requested to close 
    # because of a software or keyboard interrupt like <ctrl-c>. 
    # It writes the existing state of update to backup files. 
    # param: debug:bool outputs any additional debug information while
    #   while running. 
    def saveState(self, debug:bool=False):
        if debug:
            logit(f"saving records' state to backup...")
        a_name = f"{self.backup_prefix}adds.json"
        with open(a_name, 'w') as jf:
            jf.write(self.dumpRecords(self.add_records))
        logit(f"adds state saved to {a_name}")
        d_name = f"{self.backup_prefix}deletes.json"
        self.dumpJson(d_name, self.delete_numbers)
        logit(f"deletes state saved to {d_name}")
        if debug:
            logit(f"done.")

    # Dumps a list of records to JSON ready for writing to file.
    def dumpRecords(self, record, debug:bool=False):
        # Use a custom function to convert Customer objects to dictionaries
        def convert_to_dict(r):
            if isinstance(r, Record):
                return r.to_dict()
            return r.__dict__
        # Use the custom function in json.dumps
        return json.dumps(record, default=convert_to_dict, indent=2)

    # Sets holdings based on the add list. If a record receives and updated 
    # number in the response, it updates the record, ready for output of 
    # a slim flat file.  
    # Success:
    # {
    #   "controlNumber": "70826882",
    #   "requestedControlNumber": "70826882",
    #   "institutionCode": "44376",
    #   "institutionSymbol": "CNEDM",
    #   "firstTimeUse": false,
    #   "success": true,
    #   "message": "WorldCat Holding already set.",
    #   "action": "Set Holdings"
    # }
    # Failure:
    # {
    #   "controlNumber": null,
    #   "requestedControlNumber": "12345678910",
    #   "institutionCode": "44376",
    #   "institutionSymbol": "CNEDM",
    #   "firstTimeUse": false,
    #   "success": false,
    #   "message": "Set Holding Failed.",
    #   "action": "Set Holdings"
    # } 
    # param: configs:str config json. See Readme.md for more details. 
    # param: records:list of bib records read from flat or mrk.
    # param: debug:bool turns on debugging. 
    def setHoldings(self, configs:str='prod.json', records:list=[], debug:bool=False) -> bool:
        my_results = {}
        if records:
            self.add_records = records[:]
        ws = SetWebService(configFile=configs, debug=debug)
        for record in self.add_records:
            oclc_number = record.getOclcNumber()
            if oclc_number:
                response = ws.sendRequest(oclcNumber=oclc_number)
                # OCLC couldn't find the OCLC number sent do do a lookup of the record.
                if not response.get('controlNumber'):
                    record.setLookupMatch()
                # The control number sent has been updated by OCLC.
                elif response.get('requestedControlNumber') != response.get('controlNumber'):
                    record.updateOclcNumber(response.get('controlNumber'))
                # Some other error which requires staff to take a look at.
                elif not response.get('success'):
                    my_results[record.getTitleControlNumber()] = response
                else: # Done with this record.
                    record.setCompleted()
        if debug:
            for (tcn, message) in my_results.items():
                print(f"{tcn} -> {message}")
        self.results.update(my_results)
        return len(my_results) == 0

    # Deletes holdings from OCLC's database.
    # param: configs:str path to the OCLC secret and ID. 
    # param: oclcNumbers:list Optional list of OCLC numbers to delete. Numbers as strings only. 
    #   If the list is not used, the internal delete_list is used which needs to be populated 
    #   with numbers with the readDeleteList() method. 
    # param: deleteLBD:bool Default True, if the local bib data referenced by the OCLC number
    #   is owned by your institution an attempt to remove the LBD will be triggered, and ignored
    #   if False. 
    # param: debug:bool Default False. 
    # Failure:
    # {
    #     "controlNumber": "70826882",
    #     "requestedControlNumber": "70826882",
    #     "institutionCode": "44376",
    #     "institutionSymbol": "CNEDM",
    #     "firstTimeUse": false,
    #     "success": false,
    #     "message": "Unset Holdings Failed. Local bibliographic data (LBD) is attached to this record. To unset the holding, delete attached LBD first and try again.",
    #     "action": "Unset Holdings"
    # } 
    def unsetHoldings(self, configs:str='prod.json', oclcNumbers:list=[], deleteLBD:bool=True, debug:bool=False) -> bool:
        if oclcNumbers:
            self.delete_numbers = oclcNumbers[:]
        ws = UnsetWebService(configFile=configs)
        error_count = 0
        for oclc_number in self.delete_numbers:
            if not oclc_number:
                continue
            response = ws.sendRequest(oclcNumber=oclc_number)
            # OCLC couldn't find the OCLC number sent do do a lookup of the record.
            if not response.get('controlNumber'):
                error_count += 1
                if debug:
                    logit(f"{oclc_number} not a listed holding")
            # Some other error which requires staff to take a look at.
            elif not response.get('success') and 'delete attached LBD' in response.get('message'):
                if debug:
                    logit(f"OCLC suggests {oclc_number} removing LBD (if you own it)")
                if deleteLBD:
                    error_count += self.deleteLocalBibData(configFile=configs, oclcNumber=oclc_number, debug=debug)
            else: # Done with this record.
                if debug:
                    logit(f"holding {oclc_number} removed")
        if debug:
            print(f"there were {error_count} errors")
        return error_count == 0

    # Deletes Local Bib Data. If your institution doesn't own the bib data 
    # the reported error is as follows: 
    # Failure:
    # {
    #     "type": "CONFLICT",
    #     "title": "Unable to perform the lbd delete operation.",
    #     "detail": {
    #         "summary": "NOT_OWNED",
    #         "description": "The LBD is not owned"
    #     }
    # }
    def deleteLocalBibData(self, oclcNumber:str, configFile:str='prod.json', debug:bool=False) -> int:
        del_ws = DeleteWebService(configFile=configFile)
        response = del_ws.sendRequest(oclcNumber=oclcNumber)
        description = response.get('title')
        reason = response.get('detail').get('description')
        if debug:
            logit(f"{oclcNumber} {description} {reason}")
        if 'CONFLICT' in response.get('type'):
            return 1
        return 0

    # Matches records to known bibs at OCLC, and updates the record with 
    # the new OCLC number as required.  
    def matchHoldings(self, configs:str='prod.json', records:list=[], debug:bool=False) -> bool:
        my_results = {}
        if records:
            self.add_records = records[:]
        ws = MatchWebService(configFile=configs)
        for record in self.add_records:
            if debug:
                # All the records have the match request MATCH
                record.setLookupMatch()
            if record.getAction() != MATCH:
                continue
            response = ws.sendRequest(xmlBibRecord=record.asXml(), debug=debug)
            if response.get('briefRecords'):
                new_number = response['briefRecords'][0].get('oclcNumber')
                if new_number:
                    record.updateOclcNumber(new_number)
                    continue
            my_results[record.getTitleControlNumber()] = response
        if debug:
            for (tcn, message) in my_results.items():
                print(f"{tcn} -> {message}")
        self.results.update(my_results)
        if debug:
            for record in self.add_records:
                print(f"{record.to_dict()}")
        return len(my_results) == 0
    
    # Writes a slim flat file of the records that need to be updated in the ILS.
    # By default the output is to stdout, but if a file name is provided, any
    # updated records will be appended to that file.
    def generateUpdatedSlimFlat(self, flatFile:str=None, debug:bool=False):
        for record in self.add_records:
            if record.getAction() == UPDATED:
                # Appends data to file_name or stdout if not provided. See record asSlimFlat
                record.asSlimFlat(fileName=flatFile)
                
    # This will show the result dictionary contents.
    def showResults(self, debug:bool=False):
        logit(f"Process Report: {len(self.results)} error(s) reported.")
        for tcn, result in self.results.items():
            logit(f"  {tcn} -> {result}")

    def runUpdate(self, webServiceConfig:str='prod.json', debug:bool=False):
        self.unsetHoldings(configs=webServiceConfig, debug=debug)


    
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
    parser.add_argument('--config', action='store', default='prod.json', metavar='[/foo/prod.json]', help='Configurations for OCLC web services.')
    parser.add_argument('-d', '--debug', action='store_true', default=False, help='turn on debugging.')
    parser.add_argument('--delete', action='store', metavar='[/foo/oclc_nums.lst]', help='List of OCLC numbers to delete from OCLC\'s holdings database.')
    parser.add_argument('--report', action='store', metavar='[/foo/oclcholdingsreport.csv]', help='Holdings report from OCLC\'s database in CSV format.')
    parser.add_argument('--recover', action='store_true', default=False, help='use recovery JSON files to continue a previously interrupted process.')
    parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)
    
    args = parser.parse_args()

    # Start with creating a record manager object.
    manager = RecordManager(debug=args.debug)
    # An interrupted process may need to be restarted. In this case 
    # there _should_ be two files one for deletes called 
    # '{backup_prefix}deletes.json', the second called 
    # '{backup_prefix}adds.json'. If these files don't exist the 
    # the process will stop with an error message. 
    if args.recover:
        if not manager.restoreState():
            logit(f"**error, exiting due to previous errors.")
            sys.exit(1)
    else: # Normal operation.
        manager.readDeleteList(fileName=args.delete, debug=args.debug)
        manager.readFlatOrMrkRecords(fileName=args.add, debug=args.debug)
        manager.readHoldingsReport(fileName=args.report, debug=args.debug)
        manager.normalizeLists(debug=args.debug)
    # The update process can take some time (like hours for reclamation) 
    # and if the process is interrupted by an impatient ILS admin, or the
    # server is shutdown, the recovery files are generated so the process
    # can restart with the '--recover' switch. 
    try:
        manager.runUpdate(webServiceConfig=args.config, debug=args.debug)
    except KeyboardInterrupt:
        logit(f"system interrupt received")
        manager.saveState(debug=args.debug)
        logit(f"progress saved.")

if __name__ == "__main__":
    if len(sys.argv) == 1:
        import doctest
        doctest.testmod()
        doctest.testfile("oclc4.tst")
        doctest.testfile("oclc4wscalls.tst")
    else:
        main(sys.argv[1:])
    