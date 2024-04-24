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
        # Default server error if the response can't be retreived, otherwise get response status.
        if not exists(configFile):
            print_or_log(f"*error, config file not found! Expected '{configFile}'")
            sys.exit()
        with open(configFile) as f:
            self.configs = json.load(f)
        self.status_code = 200
        

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
        if debug:
            print_or_log(f"OAuth responded {self.getStatus()}")
        return response.json()

    # Updated after authentication and all web services calls. 
    def getStatus(self):
        return self.status_code

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
            print_or_log(f"**error: {self.auth_json.get('message')}")
            self.status_code = self.auth_json.get('code')
        return access_token

    # Manages sending request by either HTTPMethod POST, GET, or DELETE (case insensitive).
    def sendRequest(self, requestUrl:str, headers:dict, body:str='', httpMethod:str='POST', debug:bool=False) -> dict:
        access_token = self.getAccessToken()
        if not access_token:
            return {}
        headers["Authorization"] = f"Bearer {access_token}"
        if debug:
            print(f"DEBUG: url={requestUrl}")
        if httpMethod.lower() == 'get':
            response = requests.get(url=requestUrl, headers=headers)
        elif httpMethod.lower() == 'delete':
            response = requests.delete(url=requestUrl, headers=headers)
        elif httpMethod.lower() == 'post':
            response = requests.post(url=requestUrl, headers=headers, data=body)
        else:
            print_or_log(f"**error, unknown HTTP method '{httpMethod}'")
        if debug:
            print(f"DEBUG: response code {response.status_code} headers: '{response.headers}'\n content: '{response.content}'")
        return response.json()

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
    def __init__(self, configFile:str, debug:bool=False):
        super().__init__(configFile=configFile, debug=debug)

    def sendRequest(self, oclcNumber:str, debug:bool=False) -> dict:
        # /manage/institution/holdings/:oclcNumber/set
        url = f"{self.configs.get(BASE_URL)}/manage/institution/holdings/{oclcNumber}/set"
        header = {"Application": "application/json"}
        return super().sendRequest(requestUrl=url, headers=header, httpMethod='POST', debug=debug)


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
class UnsetWebService(WebService):
    def __init__(self, configFile:str, debug:bool=False):
        super().__init__(configFile=configFile)

    def sendRequest(self, oclcNumber:str, debug:bool=False) -> dict:
        # /manage/institution/holdings/:oclcNumber/unset
        url = f"{self.configs.get(BASE_URL)}/manage/institution/holdings/{oclcNumber}/unset"
        header = {"Application": "application/json"}
        return super().sendRequest(requestUrl=url, headers=header, httpMethod='POST', debug=debug)

# Match a Bibliographic Record.
# param: configFile:str name of the configuration JSON file.
# param: records:dict dictionary of TCN: Record.
# Success:
# {
#     "numberOfRecords": 1,
#     "briefRecords": [
#         {
#             "oclcNumber": "1236899214",
#             "title": "Cats!",
#             "creator": "Erica S. Perl",
#             "date": "2021",
#             "machineReadableDate": "2021",
#             "language": "eng",
#             "generalFormat": "Book",
#             "specificFormat": "PrintBook",
#             "edition": "",
#             "publisher": "Random House",
#             "publicationPlace": "New York",
#             "isbns": [
#                 "9780593380321",
#                 "0593380320",
#                 "9780593380338",
#                 "0593380339",
#                 "9781544460291",
#                 "1544460295"
#             ],
#             "issns": [],
#             "mergedOclcNumbers": [
#                 "1237101016",
#                 "1237102366",
#                 "1276783496",
#                 "1276798734",
#                 "1281721227",
#                 "1285930950",
#                 "1288704071",
#                 "1289594397",
#                 "1289941124",
#                 "1305859745"
#             ],
#             "catalogingInfo": {
#                 "catalogingAgency": "DLC",
#                 "catalogingLanguage": "eng",
#                 "levelOfCataloging": " ",
#                 "transcribingAgency": "DLC"
#             }
#         }
#     ]
# }
class MatchWebService(WebService):
    def __init__(self, configFile:str, debug:bool=False):
        super().__init__(configFile=configFile)

    def sendRequest(self, xmlBibRecord:str, debug:bool=False) -> dict:
        # /manage/bibs/match
        url = f"{self.configs.get(BASE_URL)}/manage/bibs/match"
        header = {
            "Content-Type": "application/marcxml+xml",
            "Accept": "application/json"
        }
        return super().sendRequest(requestUrl=url, headers=header, body=xmlBibRecord, httpMethod='POST', debug=debug)

# Delete: {{baseUrl}}/manage/lbds/:controlNumber DELETE
# Delete a Local Bibliographic Data record.
# param: configFile:str name of the configuration JSON file.
# param: oclcNumber:str OCLC number that matches Local Bib Data.
# Failure:
# {
#     "type": "CONFLICT",
#     "title": "Unable to perform the lbd delete operation.",
#     "detail": {
#         "summary": "NOT_OWNED",
#         "description": "The LBD is not owned"
#     }
# }
class DeleteWebService(WebService):
    def __init__(self, configFile:str, debug:bool=False):
        super().__init__(configFile=configFile)

    def sendRequest(self, oclcNumber:str, debug:bool=False) -> dict:
        # /manage/lbds/
        url = f"{self.configs.get(BASE_URL)}/manage/lbds/{oclcNumber}"
        header = {
            # The 'documentation' says this, but the method sends back json so, there's that.
            "Accept": "application/marcxml+xml"
        }
        return super().sendRequest(requestUrl=url, headers=header, httpMethod='DELETE', debug=debug)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("ws2.tst")
    doctest.testfile('oclc4.tst')