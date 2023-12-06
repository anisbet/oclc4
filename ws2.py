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
import datetime
import base64
import requests
import json
from os import linesep
import sys
from os.path import exists

TOKEN_CACHE = '_auth_.json'
# In case OCLC changes these names.
CLIENT_KEY   = 'clientId'
SECRET_KEY   = 'secret'
SCOPE_KEY    = 'scope'
AUTH_URL_KEY = 'authUrl'
BASE_URL     = 'baseUrl'

# Wrapper for the logger. Added after the class was written
# and to avoid changing tests. 
# param: message:str message to either log or print. 
# param: toStderr:bool if True and logger  
def print_or_log(message:str, toStderr:bool=False):
    if toStderr:
        sys.stderr.write(f"{message}{linesep}")
    else:
        print(f"{message}")

class WebService:
    
    def __init__(self, configFile:str, debug:bool=False):
        self.status_code = 0
        if not exists(configFile):
            sys.stderr.write(f"*error, config file not found! Expected '{configFile}'")
            sys.exit()
        with open(configFile) as f:
            self.configs = json.load(f)
        # Stack for records that don't have OCLC numbers or numbers aren't recognized.
        self.match_records = []

    # Manage authorization to the OCLC web service.
    def __authenticate_worldcat_metadata__(self, debug:bool=False):
        client_id = self.configs.get(CLIENT_KEY)
        secret    = self.configs.get(SECRET_KEY)
        encoded_auth = base64.b64encode(f"{client_id}:{secret}".encode()).decode()
        headers = {
            "Authorization": f"Basic {encoded_auth}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        body = {
            "grant_type": "client_credentials",
            "scope": self.configs.get(SCOPE_KEY)
        }
        token_url = self.configs.get(AUTH_URL_KEY)
        response = requests.post(token_url, headers=headers, data=body)
        self.status_code = response.status_code
        if debug == True:
            print_or_log(f"OAuth responded {response.status_code}")
        return response.json()

    # Determines if an expiry time has passed.
    # Param: Token expiry time in "%Y-%m-%d %H:%M:%SZ" format as it is stored in the authorization JSON
    #   returned from the OCLC web service authorize request.
    # Return: True if the token expires_at time has passed and False otherwise.
    def _is_expired_(self, expiresAt:str, debug:bool=False) -> bool:
        if expiresAt:
            expiry_time = expiresAt
        else:
            # No expiresAt time then by default it has expired.
            return True
        # parse the expiry time string into a datetime object
        expiry_datetime = datetime.datetime.strptime(expiry_time, "%Y-%m-%d %H:%M:%SZ")
        # get the current time as utc
        current_time = datetime.datetime.utcnow()
        # compare the current time to the expiry time
        if current_time > expiry_datetime:
            return True
        else:
            return False

    # Tests and refreshes authentication token.
    def getAccessToken(self, debug:bool=False) -> str:
        expiry_deadline = '1900-01-01 00:00:00Z'
        if exists(TOKEN_CACHE):
            with open(TOKEN_CACHE, 'r') as f:
                self.auth_json = json.load(f)
            f.close()
        else:
            if debug == True:
                print_or_log(f"requesting new auth token.")
            self.auth_json = self.__authenticate_worldcat_metadata__(debug=debug)
        expiry_deadline = self.auth_json.get('expires_at')
        if self._is_expired_(expiry_deadline):
            # Refresh the token
            if debug == True:
                print_or_log(f"requesting refreshed auth token.")
            self.auth_json = self.__authenticate_worldcat_metadata__(debug=debug)
        # Cache the results for repeated requests.
        with open(TOKEN_CACHE, 'w') as f:
            # Note to self: Use json.dump for streams files, or sockets and dumps for formatted strings.
            json.dump(self.auth_json, f, ensure_ascii=False, indent=2)
        access_token = self.auth_json.get('access_token')
        if not access_token:
            print_or_log(f"**error, request for access token was denied!", toStderr=True)
            self.status_code = 500
        else:
            self.status_code = 200
        return self.auth_json.get('access_token')

    def success(self, debug:bool=False) -> bool:
        if debug:
            print_or_log(str(self.status_code))
        return self.status_code == 200

# Set the holding on a Bibliographic record for an institution by OCLC Number.
# Success:
# {
# "controlNumber": "70826882",
# "requestedControlNumber": "70826882",
# "institutionCode": "44376",
# "institutionSymbol": "CNEDM",
# "firstTimeUse": false,
# "success": true,
# "message": "WorldCat Holding already set.",
# "action": "Set Holdings"
# }
# Failure:
# {
# "controlNumber": null,
# "requestedControlNumber": "12345678910",
# "institutionCode": "44376",
# "institutionSymbol": "CNEDM",
# "firstTimeUse": false,
# "success": false,
# "message": "Set Holding Failed.",
# "action": "Set Holdings"
# }
# param: configFile:str name of the configuration JSON file.
# param: records:dict dictionary of TCN: OCLC Number | Record.
class SetWebService(WebService):

    def __init__(self, configFile:str, records:dict, debug:bool=False):
        super().__init__(configFile=configFile, debug=debug)
        # /manage/institution/holdings/:oclcNumber/set
        self.url = f"{self.configs.get(BASE_URL)}/manage/institution/holdings"

# Unset the holding on a Bibliographic record for an institution by OCLC Number.

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
# param: configFile:str name of the configuration JSON file.
# param: records:dict dictionary of TCN: OCLC Number.
class UnsetWebService(SetWebService):

    def __init__(self, configFile:str, records:dict, debug:bool=False):
        super().__init__(configFile=configFile)
        # /manage/institution/holdings/:oclcNumber/unset
        self.url = f"{self.configs.get(BASE_URL)}/manage/institution/holdings"

# Match a Bibliographic Record.
# param: configFile:str name of the configuration JSON file.
# param: records:dict dictionary of TCN: Record.
class MatchWebService(WebService):

    def __init__(self, configFile:str, records:dict, debug:bool=False):
        super().__init__(configFile=configFile)
        # /manage/bibs/match
        self.url = f"{self.configs.get(BASE_URL)}/manage/bibs/match"

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("ws2.tst")
    doctest.testfile('oclc.tst')