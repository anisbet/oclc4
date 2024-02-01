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

def logit(messages, level:str='info', timestamp:bool=False):
    """ 
    Wrapper for the logger. Added after the class was written
    and to avoid changing tests. 
    
    Parameters:
    - message:str message to either log or print. 
    - level of messaging. If 'error' is used the message is prefixed with '*error'.
    - timestamp:bool if True add a timestamp to the output.

    Return:
    - None
    """
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
        """ 
        Constructor for RecordManagers using ingoreTags and encoding options.

        Parameters:
        - ignore tags dictionary that will invalidate a bib record for selection
          based on whether the tag and tag content match.
        - encoding of any files read or written to.

        Return:
        - None
        """
        # adds we read from flat or mrk file...
        self.add_records    = []
        # deletes vetted for duplicates and missing from OCLC holdings list.
        self.delete_numbers = []
        # Stores the OCLC numbers from their holdings report.
        self.oclc_holdings  = []
        # Results dictionary key:TCN -> value:webService.response.
        self.errors        = {}
        self.ignore_tags = ignoreTags
        # OCLC numbers that were rejected and the reason for rejection.
        # These could be because there was an add 
        # request, when OCLC already has the number listed as a holding, a delete
        # that OCLC doesn't show as a holding, and records rejected because they
        # match an of the ignoreTags. T
        self.rejected = {}
        self.encoding = encoding
        self.backup_prefix = 'oclc_update_'

    def _test_file_(self, fileName:str) -> list:
        """ 
        Helper function that tests if the file has content and returns True if it does and False 
        otherwise, along with the path and extension of the file.

        Parameters:
        - fileName to test

        Return:
        - list for example: [True, '/home/foo.bar', '.bar']
        """
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

    def readFlatOrMrkRecords(self, fileName:str, debug:bool=False) ->list:
        """ 
        Reads flat or mrk records from file into a list. If the format is mrk
        it is converted to flat format for potential loading into the ILS.

        Parameters:
        - fileName of the flat or mrk file.
        - debug turns on debugging information. 

        Return:
        - List of bib Records. See Record.py for more information.
        """
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
 
    def readDeleteList(self, fileName:str, debug:bool=False):
        """ 
        Reads delete OCLC numbers from a JSON file.

        Parameters:
        - fileName of the JSON data.
        - debug turns on debugging information.

        Return:
        -
        """
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

    def readHoldingsReport(self, fileName:str, debug:bool=False):
        """ 
        Reads the holding report from OCLC which includes all of the library's holdings. 
        This is used as a yardstick to compare adds and deletes, that is, the adds list
        is compared and only the records not on this list will be added. Similarly, if
        this list doesn't include a number that appears on the delete list, it is not 
        sent as a delete request.

        Parameters:
        - fileName of the OCLC holdings report list which should contain OCLC numbers
          one-per-line. See report.py's reportToList() for how it compiles this list.
        - debug turns on debugging information.

        Return:
        - None but sets the internal oclc holdings list.
        """
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
    
    def getRecordCount(self, action:str) -> int:
        """ 
        Helper method to return the count of records with a given status. 
        For example it can be used to find the number of records that will
        be 'SET'.

        Parameters:
        - action key word of either 'SET', 'UNSET', 'MATCH', 'IGNORE', 
          'UPDATED', or 'COMPLETED'.

        Return:
        - integer count of records matching the action parameter.
        """
        count = 0
        for record in self.add_records:
            if record.getAction() == action:
                count += 1
        return count

    def _get_oclc_num_list_(self) -> list:
        """ 
        Helper method to return list of OCLC numbers to be SET.

        Parameters:
        - None

        Return:
        - list of OCLC (integer) numbers to be set as holdings.
        """
        ret_list = []
        for record in self.add_records:
            if record.getAction() == SET:
                ret_list.append(record.getOclcNumber())
        return ret_list

    # Shows status of RecordManager.
    def showState(self, debug:bool=False):
        """ 
        Displays information about how many records were set, unset, rejected, 
        or looked up (matched).

        Parameters:
        - debug turns on debugging information.

        Return:
        - None
        """
        logit(f"{len(self.delete_numbers)} delete record(s)")
        if debug:
            print(f"{self.delete_numbers}")
        logit(f"{self.getRecordCount(SET)} add record(s)")
        if debug:
            print(f"{self._get_oclc_num_list_()}")
        logit(f"{self.getRecordCount(MATCH)} record(s) to check")
        if debug:
            for record in self.add_records:
                if record.getAction() == MATCH:
                    print(f"{record}")
        logit(f"{len(self.rejected)} rejected record(s)")
        for (oclc_num, reject_reason) in self.rejected.items():
            logit(f"{oclc_num}: {reject_reason}")
 
    def normalizeLists(self, debug:bool=False):
        """ 
        Review the adds, deletes, and OCLC holdings lists and compile them to 
        the essential records to add, delete, or match. The reject list is also 
        populated this way. Any, or all, lists may be empty.

        Complilation strategy:
        * delete list - Optional list of OCLC numbers which are a string of digits. 
        Duplicates are removed. See below for information on how the delete list 
        is affected if a hold report list is available.

        * add list - Optional list of Flat records. Duplicates are removed. If the 
        same number is found in both the adds and delete list, it is ignored in 
        the adds list and deleted from the delete list. 

        * OCLC holding report list - Optional list of oclc numbers like the delete list.
        If used, the delete list is modified to remove delete requests that are not
        listed as library holdings with OCLC. Similarly, if a number appears in 
        the holding report and on the add list it is removed from the add list
        since OCLC already knows it is a holding.

        Parameters:
        - debug turns on debugging information.

        Return:
        - None
        """
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

    def dumpJson(self, fileName:str, data:list):
        """ 
        Dumps simple lists to JSON. Used for delete lists.

        Parameters:
        - fileName of the final JSON file.
        - data list to write to file.

        Return:
        - None
        """
        with open(fileName, 'wt') as fp:
            json.dump(data, fp)
        fp.close()

    def loadJson(self, fileName:str) -> list:
        """ 
        Loads a list from a JSON file. Used for reading delete lists of 
        OCLC numbers.

        Parameters:
        - fileName of the JSON file.

        Return:
        - list read from JSON file. Usually a list of integer OCLC
          numbers.
        """
        fp = open(fileName, 'rt')
        ret_list = json.load(fp)
        fp.close()
        return ret_list
 
    def restoreState(self, debug:bool=False) -> bool:
        """ 
        Used to restore interrupted operations due to close 
        signal from software or keyboard interrupt like <ctrl-c>. 
        It writes the existing state of update to backup files.
        
        Parameters:
        - debug outputs any additional debug information while
          while running.

        Return:
        - True if state was restored successfully and False otherwise.
        """
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
        """ 
        Converts JSON data read from file in to Record objects.

        Parameters:
        - json_str read of record data.

        Return:
        - the custom object, in our case a Record.
        """
        def convert_to_object(r):
            """ 
            Used as a custom object hook to convert dictionaries to Customer objects.

            Parameters:
            - r 

            Return:
            - r
            """
            # if "name" in r and "age" in r and "hobbies" in r:
            if "data" in r and "rejectTags" in r and "action" in r and "encoding" in r and "tcn" in r and "oclcNumber" in r and "previousNumber" in r:
                return Record.from_dict(r)
            return r

        # Use the custom object hook in json.loads
        return json.loads(json_str, object_hook=convert_to_object)
 
    def saveState(self, debug:bool=False):
        """ 
        Saves the state of the application in the case of a software
        or keyboard interrupt <ctrl-c>. 
        It writes the existing state of update to backup files. 
        
        Parameters:
        - debug outputs any additional debug information while
          while running.

        Return:
        - None
        """
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

    def dumpRecords(self, record, debug:bool=False):
        """ 
        Dumps a list of records to JSON ready for writing to file.

        Parameters:
        - custom object in this case a bib record.
        - debug outputs any additional debug information while
          while running.

        Return:
        - String version of JSON-fied custom object.
        """
        # Use a custom function to convert Customer objects to dictionaries
        def convert_to_dict(r):
            """ 
            Converts custom object to JSON.

            Parameters:
            - r custom object.

            Return:
            - r as JSON object.
            """
            if isinstance(r, Record):
                return r.to_dict()
            return r.__dict__
        # Use the custom function in json.dumps
        return json.dumps(record, default=convert_to_dict, indent=2)
 
    def setHoldings(self, configs:str='prod.json', records:list=[], debug:bool=False) -> bool:
        """ 
        Sets holdings based on the add list. If a record receives and updated 
        number in the response, it updates the record, ready for output of 
        a slim flat file.  
        Success:
        {
        "controlNumber": "70826882",
        "requestedControlNumber": "70826882",
        "institutionCode": "44376",
        "institutionSymbol": "CNEDM",
        "firstTimeUse": false,
        "success": true,
        "message": "WorldCat Holding already set.",
        "action": "Set Holdings"
        }
        Failure:
        {
        "controlNumber": null,
        "requestedControlNumber": "12345678910",
        "institutionCode": "44376",
        "institutionSymbol": "CNEDM",
        "firstTimeUse": false,
        "success": false,
        "message": "Set Holding Failed.",
        "action": "Set Holdings"
        }

        Parameters:
        - configs config json. See Readme.md for more details. 
        - Optional list of bib records of bib records that will over-write 
          any pre-existing bib records the class may have. Used for testing.
        - debug turns on debugging.

        Return:
        - True if there were no issues, and False otherwise.
        """
        error_count = 0
        if records:
            self.add_records = records[:]
        ws = SetWebService(configFile=configs, debug=debug)
        for record in self.add_records:
            # Records can be SET or UPDATED
            if not (record.getAction() == SET or record.getAction() == UPDATED):
                continue
            oclc_number = record.getOclcNumber()
            if oclc_number:
                response = ws.sendRequest(oclcNumber=oclc_number)
                if ws.status_code != 200:
                    logit(f"Server error status: {ws.status_code} on TCN {record.getTitleControlNumber()}")
                    error_count += 1
                    # Don't set the record to any status, this failure is a web-services problem.
                    return error_count == 0
                # OCLC couldn't find the OCLC number sent do do a lookup of the record.
                if not response.get('controlNumber'):
                    if record.getAction() == SET:
                        record.setLookupMatch()
                    elif record.getAction() == UPDATED:
                        record.setFailed()
                # The control number sent has been updated by OCLC.
                elif response.get('requestedControlNumber') != response.get('controlNumber'):
                    record.updateOclcNumber(response.get('controlNumber'))
                    # These records will be output to slim flat file for bib overlay.
                    record.setUpdated()
                # Some other error which requires staff to take a look at.
                elif not response.get('success'):
                    tcn = record.getTitleControlNumber()
                    self.errors[tcn] = response
                    error_count += 1
                    if debug:
                        print(f"{tcn} -> {response}")
                    record.setFailed()
                else: # Done with this record.
                    record.setCompleted()
        if debug:
            print(f"setHoldings found {error_count} errors")
        return error_count == 0

    def unsetHoldings(self, configs:str='prod.json', oclcNumbers:list=[], deleteLBD:bool=True, debug:bool=False) -> bool:
        """ 
        Deletes holdings from OCLC's database.
         
        Failure:
        {
            "controlNumber": "70826882",
            "requestedControlNumber": "70826882",
            "institutionCode": "44376",
            "institutionSymbol": "CNEDM",
            "firstTimeUse": false,
            "success": false,
            "message": "Unset Holdings Failed. Local bibliographic data (LBD) is attached to this record. To unset the holding, delete attached LBD first and try again.",
            "action": "Unset Holdings"
        } 

        Parameters:
        - configs path to the OCLC secret and ID. 
        - oclcNumbers Optional list of OCLC numbers to delete. Numbers as strings only. 
          If the list is not used, the internal delete_list is used which needs to be populated 
          with numbers with the readDeleteList() method. 
        - deleteLBD Default True, if the local bib data referenced by the OCLC number
          is owned by your institution an attempt to remove the LBD will be triggered, and ignored
          if False.
        - debug outputs any additional debug information while
          while running.

        Return:
        - True if there were no errors, and False otherwise
        """
        if oclcNumbers:
            self.delete_numbers = oclcNumbers[:]
        ws = UnsetWebService(configFile=configs)
        error_count = 0
        for oclc_number in self.delete_numbers:
            if not oclc_number:
                continue
            response = ws.sendRequest(oclcNumber=oclc_number)
            if ws.status_code != 200:
                logit(f"Server error status: {ws.status_code} on OCLC number {oclc_number}")
                error_count += 1
                return error_count == 0
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
            print(f"unsetHoldings found {error_count} errors")
        return error_count == 0

    def deleteLocalBibData(self, oclcNumber:str, configFile:str='prod.json', debug:bool=False) -> int:
        """ 
        Deletes Local Bib Data. If your institution doesn't own the bib data 
        the reported error is as follows: 
        Failure:
        {
            "type": "CONFLICT",
            "title": "Unable to perform the lbd delete operation.",
            "detail": {
                "summary": "NOT_OWNED",
                "description": "The LBD is not owned"
            }
        }

        Parameters:
        - oclcNumber as a string.
        - configFile as json configurations.
        - debug outputs any additional debug information while
          while running.

        Return:
        - 0 if there was no conflict during lookup and 1 if there was.
        """
        ws = DeleteWebService(configFile=configFile)
        response = ws.sendRequest(oclcNumber=oclcNumber)
        if ws.status_code != 200:
            logit(f"Server error status: {ws.status_code} on OCLC number {oclcNumber}")
            return 1
        try:
            description = response.get('title')
            reason = response.get('detail').get('description')
            if debug:
                logit(f"{oclcNumber} {description} {reason}")
            if 'CONFLICT' in response.get('type'):
                return 1
            return 0
        except AttributeError:
            logit(f"{oclcNumber} failed with response:\n{response}")
  
    def matchHoldings(self, configs:str='prod.json', records:list=[], debug:bool=False) -> bool:
        """ 
        Matches local records that are missing OCLC numbers to known bibs at OCLC, and updates the record with 
        the new OCLC number as required. It sends only records where action is MATCH in the list add records.

        Parameters:
        - configs path to the OCLC secret and ID.
        - Optional list of records in flat format. Over-writes any pre-existing records during testing.
        - debug outputs any additional debug information while running, 
          but also sets all the bib records to MATCH for testing.

        Return:
        - Integer count of the number of records responses were received  
        """
        error_count = 0
        if records:
            self.add_records = records[:]
        ws = MatchWebService(configFile=configs)
        for record in self.add_records:
            if debug:
                # All the records have the match request MATCH during testing.
                record.setLookupMatch()
            if record.getAction() != MATCH:
                continue
            response = ws.sendRequest(xmlBibRecord=record.asXml(), debug=debug)
            if ws.status_code != 200:
                logit(f"Server error status: {ws.status_code} on record {record.getTitleControlNumber()}")
                error_count += 1
                return error_count == 0
            brief_records = response.get('briefRecords')
            if brief_records:
                try:
                    new_number = brief_records[0].get('oclcNumber')
                    if new_number:
                        record.updateOclcNumber(new_number)
                        record.setUpdated()
                        continue
                except IndexError:
                    pass
            # Save the response for diagnostics
            tcn = record.getTitleControlNumber()
            error_count += 1
            if debug:
                print(f"{tcn} -> {response}")
            self.errors[tcn] = response
            record.setFailed()

        if debug:
            print(f"matchHoldings found {error_count} errors")
        return error_count == 0
    
    def generateUpdatedSlimFlat(self, flatFile:str=None):
        """ 
        Writes a slim flat file of the records that need to be updated in the ILS.
        By default the output is to stdout, but if a file name is provided, any
        updated records will be appended to that file.

        Parameters:
        - flatFile name of the flat file to append the slim-flat record.

        Return:
        - The number of records that were output to the slim flat file.
        """
        records_as_slim = 0
        for record in self.add_records:
            if record.getAction() == UPDATED:
                # Appends data to file_name or stdout if not provided. See record asSlimFlat
                record.asSlimFlat(fileName=flatFile)
                records_as_slim += 1
        return records_as_slim

    def showResults(self):
        """ 
        Writes a summary of results to stdout.

        Parameters:
        - None

        Return:
        - None
        """
        logit(f"Process Report: {len(self.errors)} error(s) reported.")
        for tcn, result in self.errors.items():
            logit(f"  {tcn} -> {result}")

    def runUpdate(self, webServiceConfig:str='prod.json', debug:bool=False):
        """ 
        Convience method that runs all updates (adds, deletes, and matching).

        Parameters:
        - Configuration JSON file.

        Return:
        - None
        """
        self.unsetHoldings(configs=webServiceConfig, debug=debug)
        self.setHoldings(configs=webServiceConfig, debug=debug)
        self.matchHoldings(configs=webServiceConfig, debug=debug)
        # Second round for records with updates.
        self.setHoldings(configs=webServiceConfig, debug=debug)
        bib_overlay_file_name = webServiceConfig.get('bibOverlayFileName')
        self.generateUpdatedSlimFlat(bib_overlay_file_name)

    
# Main entry to the application if not testing.
def main(argv):
    """ 
    Main function, entry point for the application.

    Parameters:
    - List of valid arguments.

    Return:
    - None
    """
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
    parser.add_argument('--add', action='store', metavar='[/foo/my_nums.flat|.mrk]', help='List of bib records to add as holdings. This flag can read both flat and mrk format.')
    parser.add_argument('--config', action='store', default='prod.json', metavar='[/foo/prod.json]', help='Configurations for running including OCLC web services and report.py.')
    parser.add_argument('-d', '--debug', action='store_true', default=False, help='Turns on debugging.')
    parser.add_argument('--delete', action='store', metavar='[/foo/oclc_nums.lst]', help='List of OCLC numbers to delete as holdings.')
    parser.add_argument('--report', action='store', metavar='[/foo/oclcholdingsreport.csv]', help='(Optional) OCLC\'s holdings report in CSV format which will used to normalize the add and delete lists')
    parser.add_argument('--recover', action='store_true', default=False, help='Used to recover a previously interrupted process.')
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
    