###############################################################################
#
# Purpose: API for Symphony flat file.
# Date:    Tue Jan 31 15:48:12 EST 2023
# Copyright (c) 2024 Andrew Nisbet
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
import re
import sys
from os import linesep

SET = 'set'
UNSET = 'unset'
MATCH = 'match'
IGNORE = 'ignore'
UPDATED = 'updated'
COMPLETED = 'done'
FAILED = 'failed'

FLAT_DOCUMENT_REGEX     = re.compile(r'^\*\*\* DOCUMENT BOUNDARY \*\*\*[\s+]?$')
FLAT_FORM_REGEX         = re.compile(r'^FORM=')
FLAT_TCN_REGEX          = re.compile(r'^\.001\.\s+')
FLAT_O_THREE_FIVE_REGEX = re.compile(r'^\.035\.\s+')
OCLC_PREFIX_REGEX       = re.compile(r'\(OCoLC\)')
MRK_DOCUMENT_REGEX      = re.compile(r'^=LDR\s')
MRK_TCN_REGEX           = re.compile(r'^=001\s')
MRK_O_THREE_FIVE_REGEX  = re.compile(r'^=035\s')

# Different parts of a MARC entry. 
TAG = 1
IND1= 2
IND2= 3
SUBF= 4
DATA= 5
# Define a regular expression pattern for extracting the tag and data
MARC_PATTERN = re.compile(r'\.(\d+)\.\s(\d|\s)?(\d|\s)?\|([a-z])(.+)$')

class MarcXML:
    """ 
    This class formats flat data into MARC XML either as described by the Library
    of Congress with specific considerations for the expectation of OCLC.
    
    Ref: 
        https://www.loc.gov/standards/marcxml/
        https://www.loc.gov/standards/marcxml/xml/spy/spy.html 
        https://www.loc.gov/standards/marcxml/xml/collection.xml
    Schema:
        https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd
    """
    def __init__(self, flat:list):
        self.xml = []
        self.xml.append(f"<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        self.xml.extend(self._convert_(flat))

    def getMarc(self, marcEntry:str, whichPart:int=1) ->str:
        """ 
        Gets different parts of a MARC entry such as TAG, IND1, IND2, SUBF, and DATA
        as denoted by the 'whichPart' parameter.
        
        Parameters:
        - Single line of MARC from a flat file. 
        - The desired part of the entry as follows.
            * TAG the MARC tag, like '008'. 
            * IND1 first indicator. Returns the indicator if there is one and a space character if not. 
            * IND2 second indicator. Same behaviour as IND1. 
            * SUBF returns the first sub field.
            * DATA returns the value of the MARC entry.

        Returns:
        - The requested value, or an empty string if not found.
        """
        # Match the pattern in the given MARC entry
        match = re.match(MARC_PATTERN, marcEntry)
        # Check if there is a match
        if not match:
            return ''
        try:
            part = match.group(whichPart)
            if not part:
                return ''
            return part
        except IndexError:
            return ''

    def _getMarcTag_(self, entry:str) -> str:
        """ 
        Gets a MARC tag, like '000' or '035' from a line of flat marc data.
        
        Parameters:
        - MARC data entry in flat format.

        Returns:
        - MARC tag and an empty string if none found.
        """
        return self.getMarc(entry, TAG)

    def _getMarcField_(self, entry:str, raw:bool=True) -> str:
        """ 
        Returns the data from the given line of flat MARC data.

        Parameters:
        - MARC entry.
        - True to return the entire MARC field as-is, and False to return just the data.

        Returns:
        - MARC entry data if any and an empty string otherwise.
        """
        if raw:
            return f"|{self.getMarc(entry, SUBF)}{self.getMarc(entry, DATA)}"
        return self.getMarc(entry, DATA)
    
    def _getIndicators_(self, entry:str) -> list:
        """ 
        Returns both indicators from tags greater than 008.

        Parameters:
        - The MARC entry line from a flat file.

        Returns:
        - tuple of (indicator 1, indicator 2).
        """
        return (self.getMarc(entry, IND1), self.getMarc(entry, IND2))

    def _getSubfields_(self, entry:str) -> list:
        """ 
        Returns any subfields that appear in the MARC data. 
        For example, '.040.  1 |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW'
        returns a list of tuples arranged by (subfield, content) for example,
         [('a', 'TEFMT'), ('c', 'TEFMT'), ('d', 'TEF'), ('d', 'BKX'), ('d', 'EHH'), ('d', 'NYP'), ('d', 'UtOrBLW')]

        Parameters:
        - The MARC entry line from a flat file.

        Returns:
        - A list of tuples arranged by (subfield, content).
        """
        # Given: '.040.  1 |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW'
        tag           = self._getMarcTag_(entry)        # '040'
        (ind1, ind2)  = self._getIndicators_(entry) # ('1',' ')
        tag_entries   = [f"<datafield tag=\"{tag}\" ind1=\"{ind1}\" ind2=\"{ind2}\">"]
        data_fields   = self._getMarcField_(entry)     # '|aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW'
        subfields     = data_fields.split('|')
        subfield_list = []
        for subfield in subfields:
            # The sub field name is the first character
            field_name = subfield[:1]
            field_value= subfield[1:]
            if field_name != '':
                subfield_list.append((field_name, field_value))
        for subfield in subfield_list:
            # [('a', 'TEFMT'), ('c', 'TEFMT'), ('d', 'TEF'), ('d', 'BKX'), ('d', 'EHH'), ('d', 'NYP'), ('d', 'UtOrBLW')]
            tag_entries.append(f"  <subfield code=\"{subfield[0]}\">{subfield[1]}</subfield>")
        tag_entries.append(f"</datafield>")
        return tag_entries
 
    def _convert_(self, entries:list) ->list:
        """ 
        Converts a list of flat-MARC strings into a list of XML strings.

        Parameters:
        - entry list of strings of FLAT data.

        Returns:
        - Flat file converted into a list of XML strings.
        """
        record = []
        record_dict = {}
        for entry in entries:
            # Sirsi Dynix flat files contain a 'FORM=blah-blah' which is not valid MARC.
            if re.match(r'^FORM*', entry):
                continue
            tag = self._getMarcTag_(entry)
            try:
                if tag == '000':
                    leader = self._getMarcField_(entry, False)
                    if len(leader) <= 10:
                        # Flush out the Symphony flat leader to full size or the record fails recognition as valid MARC.
                        full_leader = '00000n'+leader[0:2]+' a2200000 '+leader[3]+' 4500'
                    else:
                        full_leader = leader
                    tag_value = f"<leader>{full_leader}</leader>"
                # Any tag below '008' is a control field and doesn't have indicators or subfields.
                elif int(tag) <= 8:
                    tag_value = f"<controlfield tag=\"{tag}\">{self._getMarcField_(entry, False)}</controlfield>"
                else:
                    tag_value = self._getSubfields_(entry)
                if f"{tag}" in record_dict:
                    record_dict[f"{tag}"] += tag_value
                else:
                    record_dict[f"{tag}"] = tag_value
            except ValueError as ex:
                pass

        if entries:
            record.append(f"<record>")
            for i in sorted(record_dict.keys()):
                record.append(record_dict[i])
            record.append(f"</record>")
        return record

    # Used to collapse lists within lists, for example when printing the xml as a string.
    def _flatten_(self, final_list:list, lst):
        """ 
        Flattens lists of lists into a single list structure. 

        Parameters:
        - list of lists.

        Returns:
        - a single list.
        """
        for item in lst:
            if isinstance(item, list):
                self._flatten_(final_list, item)
            else:
                final_list.append(item)

    def __str__(self, pretty:bool=False) -> str:
        """ 
        Output the MarcXML object as a meaningful string.

        Parameters:
        - Outputs leading indentation if 'pretty' equals True, 
          and no new lines or indentation if False. 

        Returns:
        - XML string.
        """
        a = []
        self._flatten_(a, self.xml)
        if pretty:
            return f"{linesep}".join(a)
        return ''.join(a)

    def asBytes(self) ->bytes:
        """ 
        Converts the XML content into byte a byte-string. 

        Parameters:
        - None

        Returns:
        - XML file as an array of bytes.
        """
        a = []
        self._flatten_(a, self.xml)
        xml_content_str = f"{linesep}".join(a)
        return bytes(xml_content_str, 'utf-8')

class Record:
    """ 
    A single flat record object.
    """
    
    def __init__(self, data:list, action:str='set', rejectTags:dict={}, encoding:str='ISO-8859-1', tcn:str='', oclcNumber:str='', previousNumber:str=''):
        """ 
        Contructor

        Parameters:
        - List of MARC strings in flat OR mrk format. 
        - action for the record, like 'set', 'unset', or 'match'.
        - Dictionary of tags that will cause the record to be rejected or 'ignore'd. 
          The dictionary is organized with {'tag': 'ignore-able content'}. The tag and content
          must both match for the record to be rejected.
        - encoding for reading and writing flat, mrk, or XML.
        - TCN, if known. Record will try to use the value in the '001' field. 
          This is mostly used when serializing and deserializing a Record object.
        - The OCLC number, if known. Record will try to find the value in the '035' fields. 
          This is mostly used when serializing and deserializing a Record object.
        - The previous OCLC number, if known or required. 
          This is mostly used when serializing and deserializing a Record object.

        Returns:
        - Record object.
        """
        self.record = []
        self.encoding = encoding
        self.action = action
        self.reject_tags = rejectTags
        self.title_control_number = ''
        self.oclc_number = ''
        # To put the old OCLC number in a subfield - z.
        self.prev_oclc_number = ''
        if not data:
            return
        elif data and re.search(FLAT_DOCUMENT_REGEX, data[0]):
            self._readFlatBibRecord_(data)
        elif data and re.search(MRK_DOCUMENT_REGEX, data[0]):
            self._readMrkBibRecord_(data)
        else:
            raise NotImplementedError("**error, unknown marc data type.")

    def to_dict(self):
        """ 
        Converts a Record to a dictionary suitable for serialization into JSON.

        Parameters:
        - None

        Returns:
        - Dictionary of a Record object.
        """
        return {"data": self.record, "rejectTags": self.reject_tags, 
        "action": self.action, "encoding": self.encoding, 
        "tcn": self.title_control_number, "oclcNumber": self.oclc_number, 
        "previousNumber": self.prev_oclc_number}

    # The from_dict method is a class method because it doesn't operate 
    # on an instance of the class but rather on the class itself.  
    @classmethod
    def from_dict(cls, jdata):
        """ 
        Used to create an instance of a Record class based on a dictionary of Record data.

        Parameters:
        - Dictionary of Record data.

        Returns:
        - New Record object.
        """
        return cls(data=jdata["data"], rejectTags=jdata["rejectTags"],
        action=jdata["action"], encoding=jdata["encoding"], 
        tcn=jdata["tcn"], oclcNumber=jdata["oclcNumber"], 
        previousNumber=jdata["previousNumber"])

    def makeFlatLineFromMrk(self, data:str) -> str:
        """ 
        Turns a line of mrk output into flat format, as per these examples.
        =LDR 02135cjm a2200385 a 4500 --> .000. |a02135cjm a2200385 a 4500
        =007 sd\fsngnnmmned --> .007. |asd fsngnnmmned
        =008 111222s2012    nyu||n|j|\\\\\\\\\|\eng\d --> .008. |a111222s2012    nyu||n|j|         | eng d
        =024 1\$a886979578425 --> .024. 1 |a886979578425
        =028 00$a88697957842  --> .028. 00|a88697957842

        Parameters:
        - String of mrk data.

        Returns:
        - String of flat-format data.
        """
        data = data.rstrip()
        if '=LDR ' in data:
            data = data.replace("=LDR ", "=000 ")
        data = data.replace('\\', ' ')
        f =''
        for i in range(len(data)):
            if data[i] == '=':
                f += '.'
                continue
            if i == 4:
                f += '.'
            if i == 5 and int(data[1:4]) <= 8:
                f += '|a'
            if data[i] == '$':
                f += '|'
                continue
            f += data[i]
        return f

    def _readMrkBibRecord_(self, mrk:list, debug:bool=False):
        """ 
        Reads a single mrk bib record from a list of lines read from a mrk file.

        Parameters:
        - List of strings mrk strings.

        Returns:
        - None
        """
        line_num = 0
        # To save re-writing a bunch of code just turn the mrk format
        # into flat format.
        self.record.append('*** DOCUMENT BOUNDARY ***')
        # TODO: Do we need a FORM too?
        for l in mrk:
            line_num += 1
            line = l.rstrip()
            # Test for record rejecting tags
            for (tag, value) in self.reject_tags.items():
                if tag in line and value in line:
                    self.action = IGNORE
                    break
            # =001 ocn769144454
            if re.search(MRK_TCN_REGEX, line):
                zero_01 = line.split(" ")
                self.title_control_number = zero_01[1].strip()
            # =035 \\$a(Sirsi) a1001499
            # =035 \\$a(OCoLC)769144454
            if re.search(FLAT_O_THREE_FIVE_REGEX, line):
                # If this has an OCoLC then save as a 'set' number otherwise just record it as a regular 035.
                if re.search(OCLC_PREFIX_REGEX, line):
                    try:
                        my_oclc_num = re.search(r'\(OCoLC\)(\d+)', line)
                        self.oclc_number = my_oclc_num.group(1)
                    except:
                        self.printLog(f"rejecting {self.title_control_number}, malformed OCLC number {line} on {line_num}.")
                        continue
            # All other tags are stored as is.
            self.record.append(self.makeFlatLineFromMrk(line))

    def _readFlatBibRecord_(self, flat:list, debug:bool=False):
        """ 
        Reads a single flat bib record.

        Parameters:
        - list of bib data in flat format.
        - Debug turns on diagnostic messages.

        Returns:
        - None
        """
        line_num = 0
        multiline = ''
        for l in flat:
            line_num += 1
            line = l.rstrip()
            if line.startswith('.') and multiline:
                first_of_long_line = self.record.pop()
                self.record.append(first_of_long_line + multiline)
                multiline = ''
                # And carry on with the new entry
            # Configurable tag and value rejection functionality. Like '250': 'On Order' = 'reject': True.
            for (tag, value) in self.reject_tags.items():
                if tag in line and value in line:
                    self.action = IGNORE
                    break
            # *** DOCUMENT BOUNDARY ***
            if re.search(FLAT_DOCUMENT_REGEX, line):
                if debug:
                    self.printLog(f"DEBUG: found document boundary on line {line_num}")
                self.record.append(line)
                continue
            # FORM=MUSIC 
            if re.search(FLAT_FORM_REGEX, line):
                if debug:
                    self.printLog(f"DEBUG: found form description on line {line_num}")
                self.record.append(line)
                continue
            # .001. |aon1347755731  
            if re.search(FLAT_TCN_REGEX, line):
                zero_01 = line.split("|a")
                self.title_control_number = zero_01[1].strip()
            # .035.   |a(OCoLC)987654321
            # .035.   |a(Sirsi) 111111111
            if re.search(FLAT_O_THREE_FIVE_REGEX, line):
                # If this has an OCoLC then save as a 'set' number otherwise just record it as a regular 035.
                if re.search(OCLC_PREFIX_REGEX, line):
                    try:
                        my_oclc_num = re.search(r'\(OCoLC\)(\d+)', line)
                        self.oclc_number = my_oclc_num.group(1)
                    except:
                        self.printLog(f"rejecting {self.title_control_number}, malformed OCLC number {line} on {line_num}.")
                        continue
            # It's the next line of a multiline entry.
            if not line.startswith('.'):
                multiline += line
                continue
            # All other tags are stored as is.
            self.record.append(line)

    def getAction(self) -> str:
        """ 
        Returns the action command from a Record. 

        Parameters:
        - None

        Returns:
        - String of the action like 'set' or 'unset', 'ignore' etc.
        """
        return self.action

    def setIgnore(self):
        """ 
        Sets the action status of a record to ignore.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = IGNORE

    def setUpdated(self):
        """ 
        Sets the action status of a record to updated.

        Parameters:
        - None

        Returns:
        - None 
        """
        self.action = UPDATED

    def setAdd(self):
        """ 
        Sets the action status of a record to set.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = SET
        
    def setDelete(self):
        """ 
        Sets the action status of a record to unset.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = UNSET

    def setFailed(self):
        """ 
        Sets the action status of a record to failed.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = FAILED
    
    def setCompleted(self):
        """ 
        Sets the action status of a record to completed.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = COMPLETED

    def setLookupMatch(self):
        """ 
        Sets the action status of a record to match.

        Parameters:
        - None

        Returns:
        - None
        """
        self.action = MATCH

    def getOclcNumber(self) -> str:
        """ 
        Gets the OCLC number of the Record.

        Parameters:
        - None

        Returns:
        - OCLC of the record and an empty string if there isn't one.
        """
        return self.oclc_number

    def getTitleControlNumber(self) -> str:
        """ 
        Gets the Record's TCN or title control number. 

        Parameters:
        - None

        Returns:
        - TCN as a string or an empty string if there is none.
        """
        return self.title_control_number
        
    def asXml(self, asBytes:bool=False) -> str:
        """ 
        Converts the Record object in to MARCXML21.

        Parameters:
        - asBytes tells the object to return XML as bytes instead of a string.

        Returns:
        - Bytes of MARC21 XML.
        """
        if not self.record:
            return ''
        xml = MarcXML(self.record)
        if asBytes:
            return xml.asBytes()
        return xml.__str__()
    
    def asSlimFlat(self, fileName:str=None) -> str:
        """ 
        Converts a record into an overlay-able slim flat file.
        This file contains the minimum data required to update the ILS's bib record
        with a new or updated OCLC number.

        Parameters:
        - File name of the slim flat output file. If None, the data is output
          to STDOUT.

        Returns:
        - None. Writes to a file.
        """
        if not self.record:
            return ''
        s = open(fileName, mode='at', encoding=self.encoding) if fileName else sys.stdout
        for entry in self.record:
            if re.search(FLAT_DOCUMENT_REGEX, entry):
                s.write(f"{entry}{linesep}")
            elif re.search(FLAT_FORM_REGEX, entry):
                s.write(f"{entry}{linesep}")
            elif re.search(FLAT_TCN_REGEX, entry):
                s.write(f"{entry}{linesep}")
            elif re.search(FLAT_O_THREE_FIVE_REGEX, entry):
                # If this has an OCoLC then save as a 'set' number otherwise just record it as a regular 035.
                if re.search(OCLC_PREFIX_REGEX, entry):
                    if self.prev_oclc_number:
                        s.write(f".035.   |a(OCoLC){self.oclc_number}|z(OCoLC){self.prev_oclc_number}{linesep}")
                    else:
                        s.write(f".035.   |a(OCoLC){self.oclc_number}{linesep}")
                else:
                    # Write all 035s since catalogmerge will drop all 035s
                    # when replacing any one of them.
                    s.write(f"{entry}{linesep}")
            else:
                continue
        if s is not sys.stdout:
            s.close()

    def __repr__(self):
        """ 
        Prints the internal representation of this record object.

        Parameters:
        - None

        Returns:
        - Prints the TCN, OCLC number and current action to STDOUT.
        """
        self.printLog(f"{'TCN':<11}: {self.title_control_number:>12}")
        self.printLog(f"OCLC number: {self.oclc_number:>12}")
        self.printLog(f"{'Action':<11}: {self.action:>12}")

    def __str__(self):
        """ 
        The string version of the record object.

        Parameters:
        - None

        Returns:
        - String of all the record data on separate lines.
        """
        if not self.record:
            return ''
        return f"{linesep}".join(self.record)
 
    def printLog(self, message:str, to_stderr:bool=False):
        """ 
        Convienence method to print process related messages.

        Parameters:
        - The message string itself.
        - to_stderr prints the message to STDERR if True and STDOUT otherwise by default.

        Returns:
        - None
        """
        if to_stderr:
            sys.stderr.write(f"{message}{linesep}")
        else:
            print(f"{message}")

    def updateOclcNumber(self, oclcNumber:str):
        """ 
        Updates the record's OCLC number, preserving any previous number in 
        a z-subfield.

        Parameters:
        - New OCLC number in string format.

        Returns:
        - None.
        """
        self.prev_oclc_number = self.oclc_number
        self.oclc_number = oclcNumber

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("record.tst")
    doctest.testfile("xml.tst")