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
SET = 'set'
UNSET = 'unset'
MATCH = 'match'
IGNORE = 'ignore'

# A single flat record object.
class Flat:

    # Take either a file or a list of flat data.
    def __init__(self, flat:list, action:str='set', rejectTags:dict={}):
        self.record = []
        self.action = action
        self.reject_tags = rejectTags
        self.tcn =''
        self.oclc_number = ''
        self._read_bib_record_(flat)

    # Reads a single bib record
    def _read_bib_record_(self, flat, debug:bool=False):
        document_sentinal = re.compile(r'^\*\*\* DOCUMENT BOUNDARY \*\*\*[\s+]?$')
        form_sentinal     = re.compile(r'^FORM=')
        tcn               = re.compile(r'^\.001\.\s+')
        zero_three_five   = re.compile(r'^\.035\.\s+')
        oclc_num_matcher  = re.compile(r'\(OCoLC\)')
        line_num = 0
        for l in flat: 
            oclc_number = ''
            line_num += 1
            line = l.rstrip()
            # Configurable tag and value rejection functionality. Like '250': 'On Order' = 'reject': True.
            for (tag, value) in self.reject_tags.items():
                if tag in line and value in line:
                    self.action = IGNORE
                    break
            # *** DOCUMENT BOUNDARY ***
            if re.search(document_sentinal, line):
                if debug:
                    self.print_or_log(f"DEBUG: found document boundary on line {line_num}")
                self.record.append(line)
                continue
            # FORM=MUSIC 
            if re.search(form_sentinal, line):
                if debug:
                    self.print_or_log(f"DEBUG: found form description on line {line_num}")
                self.record.append(line)
                continue
            # .001. |aon1347755731  
            if re.search(tcn, line):
                zero_01 = line.split("|a")
                self.tcn = zero_01[1].strip()
            # .035.   |a(OCoLC)987654321
            # .035.   |a(Sirsi) 111111111
            if re.search(zero_three_five, line):
                # If this has an OCoLC then save as a 'set' number otherwise just record it as a regular 035.
                if re.search(oclc_num_matcher, line):
                    tag_oclc = line.split("|a(OCoLC)")
                    self.oclc_number = self.get_first_subfield(tag_oclc)
                    if not self.oclc_number:
                        self.print_or_log(f"rejecting {self.tcn}, malformed OCLC number {line} on {line_num}.")
                        continue
            # All other tags are stored as is.
            if not line.startswith('.'):
                # It's the next line of a previous record entry.
                line += line.rstrip()
                continue
            self.record.append(line)

    # Wrapper for the logger. Added after the class was written
    # and to avoid changing tests. 
    # param: message:str message to either log or print. 
    # param: to_stderr:bool if True and logger  
    def print_or_log(self, message:str, to_stderr:bool=False):
        if to_stderr:
            sys.stderr.write(f"{message}" + linesep)
        else:
            print(f"{message}")

    # Strips out and returns the first subfield of a tag field possibly full of sub fields. 
    def get_first_subfield(self, tag_values:list):
        if len(tag_values) > 1:
            values = tag_values[1].split("|")
            if values:
                return values[0]

    # Convert to XML data.
    def asXml(self) -> str:
        pass
    
    # Output as slim flat file.
    # param: fileName:str if provided the data is appended to the file
    #   otherwise the data is output to stdout.
    def asSlimFlat(self, fileName:str=None) -> str:
        pass

    def __repr__(self):
        self.print_or_log(f"{'TCN':<11}: {self.tcn:>12}")
        self.print_or_log(f"OCLC number: {self.oclc_number:>12}")
        self.print_or_log(f"{'Action':<11}: {self.action:>12}")

    def __str__(self):
        return '\n'.join(self.record)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("flat.tst")