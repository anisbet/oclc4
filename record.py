###############################################################################
#
# Purpose: API for Symphony flat file.
# Date:    Tue Jan 31 15:48:12 EST 2023
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
import re
import sys
from os import linesep
SET = 'set'
UNSET = 'unset'
MATCH = 'match'
IGNORE = 'ignore'
UPDATED = 'updated'
COMPLETED = 'done'

FLAT_DOCUMENT_REGEX     = re.compile(r'^\*\*\* DOCUMENT BOUNDARY \*\*\*[\s+]?$')
FLAT_FORM_REGEX         = re.compile(r'^FORM=')
FLAT_TCN_REGEX          = re.compile(r'^\.001\.\s+')
FLAT_O_THREE_FIVE_REGEX = re.compile(r'^\.035\.\s+')
OCLC_PREFIX_REGEX       = re.compile(r'\(OCoLC\)')
MRK_DOCUMENT_REGEX      = re.compile(r'^=LDR\s')
MRK_TCN_REGEX           = re.compile(r'^=001\s')
MRK_O_THREE_FIVE_REGEX  = re.compile(r'^=035\s')

###
# This class formats flat data into MARC XML either as described by the Library
# of Congress with specific considerations for the expectation of OCLC.
# Ref: 
#   https://www.loc.gov/standards/marcxml/
#   https://www.loc.gov/standards/marcxml/xml/spy/spy.html 
#   https://www.loc.gov/standards/marcxml/xml/collection.xml
# Schema:
#   https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd

class MarcXML:
    def __init__(self, flat:list):
        self.xml = []
        self.xml.append(f"<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        self.xml.extend(self._convert_(flat))

    # Gets a string version of the entry's tag, like '000' or '035'.
    # param: str of the flat entry from the flat marc data.
    # return: str of the tag or empty string if no tag was found.
    def _getTag_(self, entry:str) -> str:
        t = re.match(r'\.\d{3}\.', entry)
        if t:
            # print(f"==>{t.group()}")
            t = t.group()[1:-1]
            return f"{t}"
        else:
            return ''

    def _getControlFieldData_(self, entry:str, raw:bool=True) -> str:
        fields = entry.split('|a')
        if len(fields) > 1:
            if raw:
                return f"|a{fields[1]}"
            return f"{fields[1]}"
        else:
            # Breaks on errors like '.264.  4|c©2021'. Broken entries don't get output.
            print(f"*warning invalid syntax on '{entry}'")
        return ''
    
    def _getIndicators_(self, entry:str) -> list:
        # .245. 04|aThe Fresh Beat Band|h[sound recording] :|bmusic from the hit TV show.
        inds = entry.split('|a')
        ind1 = ' '
        ind2 = ' '
        # There are no indicators for fields < '008'.
        tag = self._getTag_(entry)
        if inds and int(tag) >= 8:
            ind1 = inds[0][-2:][0]
            ind2 = inds[0][-2:][1]
        return (ind1,ind2)

    # Private method that, given a MARC field returns 
    # a list of any subfields.
    def _getSubfields_(self, entry:str) -> list:
        # Given: '.040.  1 |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW'
        tag           = self._getTag_(entry)        # '040'
        (ind1, ind2)  = self._getIndicators_(entry) # ('1',' ')
        tag_entries   = [f"<datafield tag=\"{tag}\" ind1=\"{ind1}\" ind2=\"{ind2}\">"]
        data_fields   = self._getControlFieldData_(entry)     # '|aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW'
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

    # Converts MARC tag entries into XML. 
    # param: entries list of FLAT data strings.
    # return: list of XML strings.
    def _convert_(self, entries:list) ->list:
        record = []
        record_dict = {}
        for entry in entries:
            # Sirsi Dynix flat files contain a 'FORM=blah-blah' which is not valid MARC.
            if re.match(r'^FORM*', entry):
                continue
            tag = self._getTag_(entry)
            try:
                if tag == '000':
                    leader = self._getControlFieldData_(entry, False)
                    if len(leader) <= 10:
                        # Flush out the Symphony flat leader to full size or the record fails recognition as valid MARC.
                        full_leader = '00000n'+leader[0:2]+' a2200000 '+leader[3]+' 4500'
                    else:
                        full_leader = leader
                    tag_value = f"<leader>{full_leader}</leader>"
                # Any tag below '008' is a control field and doesn't have indicators or subfields.
                elif int(tag) <= 8:
                    tag_value = f"<controlfield tag=\"{tag}\">{self._getControlFieldData_(entry, False)}</controlfield>"
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
        for item in lst:
            if isinstance(item, list):
                self._flatten_(final_list, item)
            else:
                final_list.append(item)

    def __str__(self, pretty:bool=False) -> str:
        a = []
        self._flatten_(a, self.xml)
        if pretty:
            return f"{linesep}".join(a)
        return ''.join(a)

    # Converts the XML content into byte a byte-string.
    def asBytes(self):
        a = []
        self._flatten_(a, self.xml)
        xml_content_str = f"{linesep}".join(a)
        return bytes(xml_content_str, 'utf-8')

# A single flat record object.
class Record:

    # Take either a file or a list of flat data.
    def __init__(self, data:list, action:str='set', rejectTags:dict={}, encoding:str='ISO-8859-1', tcn:str='', oclcNumber:str='', previousNumber:str=''):
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

    # Converts a Record to a dictionary suitable for serialization into JSON.
    def to_dict(self):
        return {"data": self.record, "rejectTags": self.reject_tags, 
        "action": self.action, "encoding": self.encoding, 
        "tcn": self.title_control_number, "oclcNumber": self.oclc_number, 
        "previousNumber": self.prev_oclc_number}

    # The from_dict method is a class method because it doesn't operate 
    # on an instance of the class but rather on the class itself. 
    # It is used to create an instance of the Customer class based 
    # on a dictionary (Record).
    @classmethod
    def from_dict(cls, jdata):
        return cls(data=jdata["data"], rejectTags=jdata["rejectTags"],
        action=jdata["action"], encoding=jdata["encoding"], 
        tcn=jdata["tcn"], oclcNumber=jdata["oclcNumber"], 
        previousNumber=jdata["previousNumber"])

    # Turns a line of mrk output into flat format, as per these examples.
    # =LDR 02135cjm a2200385 a 4500 --> .000. |a02135cjm a2200385 a 4500
    # =007 sd\fsngnnmmned --> .007. |asd fsngnnmmned
    # =008 111222s2012    nyu||n|j|\\\\\\\\\|\eng\d --> .008. |a111222s2012    nyu||n|j|         | eng d
    # =024 1\$a886979578425 --> .024. 1 |a886979578425
    # =028 00$a88697957842  --> .028. 00|a88697957842
    def makeFlatLineFromMrk(self, data:str) -> str:
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

    # Reads a single mrk bib record.
    def _readMrkBibRecord_(self, mrk:list, debug:bool=False):
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
                    tag_oclc = line.split("a(OCoLC)")
                    self.oclc_number = self.__getFirstMrkSubfield__(tag_oclc)
                    if not self.oclc_number:
                        self.printLog(f"rejecting {self.title_control_number}, malformed OCLC number {line} on {line_num}.")
                        continue
            # All other tags are stored as is.
            self.record.append(self.makeFlatLineFromMrk(line))
    
    # Strips out and returns the first subfield of a tag field possibly 
    # full of sub fields. 
    # param: tag_values:list list of values from the tag entry.
    #   For example: '=035   \\$a(OCoLC12345678$z(OCoLC)9101112                    
    def __getFirstMrkSubfield__(self, tag_values:list) -> str:
        if len(tag_values) > 1:
            values = tag_values[1].split("$")
            if values and len(values[0]) > 0:
                return values[0][1:]

    # Reads a single flat bib record
    def _readFlatBibRecord_(self, flat:list, debug:bool=False):
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
                    tag_oclc = line.split("|a(OCoLC)")
                    self.oclc_number = self.__getFirstFlatSubfield__(tag_oclc)
                    if not self.oclc_number:
                        self.printLog(f"rejecting {self.title_control_number}, malformed OCLC number {line} on {line_num}.")
                        continue
            # It's the next line of a multiline entry.
            if not line.startswith('.'):
                multiline += line
                continue
            # All other tags are stored as is.
            self.record.append(line)

    def getAction(self) -> str:
        return self.action

    def setUpdated(self, newNumber:str):
        self.action = UPDATED
        self.prev_oclc_number = self.oclc_number
        self.oclc_number = newNumber

    def setIgnore(self):
        self.action = IGNORE

    def setAdd(self):
        self.action = SET
        
    def setDelete(self):
        self.action = UNSET
    
    def setCompleted(self):
        self.action = COMPLETED

    def setLookupMatch(self):
        self.action = MATCH

    def getOclcNumber(self) -> str:
        return self.oclc_number

    def getTitleControlNumber(self) -> str:
        return self.title_control_number
        
    # Convert to XML data.
    def asXml(self, asBytes:bool=False) -> str:
        if not self.record:
            return ''
        xml = MarcXML(self.record)
        if asBytes:
            return xml.asBytes()
        return xml.__str__()
    
    # Output as slim flat file with minimal fields to update.
    # param: fileName:str if provided the data is appended to the file
    #   otherwise the data is output to stdout.
    def asSlimFlat(self, fileName:str=None) -> str:
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
        self.printLog(f"{'TCN':<11}: {self.title_control_number:>12}")
        self.printLog(f"OCLC number: {self.oclc_number:>12}")
        self.printLog(f"{'Action':<11}: {self.action:>12}")

    def __str__(self):
        if not self.record:
            return ''
        return f"{linesep}".join(self.record)

    # Wrapper for the logger. Added after the class was written
    # and to avoid changing tests. 
    # param: message:str message to either log or print. 
    # param: to_stderr:bool if True and logger  
    def printLog(self, message:str, to_stderr:bool=False):
        if to_stderr:
            sys.stderr.write(f"{message}{linesep}")
        else:
            print(f"{message}")

    # Strips out and returns the first subfield of a tag field possibly 
    # full of sub fields. 
    # param: tag_values:list list of values from the tag entry.
    #   For example: '.035.   |a(OCoLC)12345678|z(OCoLC)9101112
    def __getFirstFlatSubfield__(self, tag_values:list):
        if len(tag_values) > 1:
            values = tag_values[1].split("|")
            if values:
                return values[0]

    # Update the existing OCLC number with the new one provided by
    # OCLC through the match ws call.
    def updateOclcNumber(self, oclcNumber:str):
        self.prev_oclc_number = self.oclc_number
        self.oclc_number = oclcNumber

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("record.tst")
    doctest.testfile("xml.tst")