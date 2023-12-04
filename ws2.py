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

TOKEN_CACHE = '_auth_.json'

class WebService:
    
    def __init__(self, configs:dict, debug:bool=False):
        self.configs   = configs
        self.client_id = configs['clientId']
        self.secret    = configs['secret']
        self.auth_json = self._authenticate_worldcat_metadata_()

    # Manage authorization to the OCLC web service.
    def _authenticate_worldcat_metadata_(self, debug:bool=False):
        encoded_auth = base64.b64encode(f"{self.client_id}:{self.secret}".encode()).decode()
        headers = {
            "Authorization": f"Basic {encoded_auth}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        body = {
            "grant_type": "client_credentials",
            "scope": "WorldCatMetadataAPI"
        }
        token_url = f"https://oauth.oclc.org/token"
        response = requests.post(token_url, headers=headers, data=body)
        if debug == True:
            self.print_or_log(f"{response.json()}")
        return response.json()

    # Determines if an expiry time has passed.
    # Param: Token expiry time in "%Y-%m-%d %H:%M:%SZ" format as it is stored in the authorization JSON
    #   returned from the OCLC web service authorize request.
    # Return: True if the token expires_at time has passed and False otherwise.
    def _is_expired_(self, expires_at:str, debug:bool=False) -> bool:
        if expires_at:
            expiry_time = expires_at
        else:
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
    def _get_access_token_(self) -> str:
        expiry_deadline = '1900-01-01 00:00:00Z'
        if exists(TOKEN_CACHE):
            with open(TOKEN_CACHE, 'r') as f:
                self.auth_json = json.load(f)
            f.close()
        try:
            expiry_deadline = self.auth_json['expires_at']
            if self._is_expired_(expiry_deadline) == True:
                self._authenticate_worldcat_metadata_()
                if self.debug == True:
                    self.print_or_log(f"refreshed auth token, expiry: {expiry_deadline}")
            else:
                if self.debug == True:
                    self.print_or_log(f"auth token is valid until {expiry_deadline}") 
        except KeyError:
            self._authenticate_worldcat_metadata_()
            if self.debug == True:
                self.print_or_log(f"getting new auth token, expiry: {expiry_deadline}")
        except TypeError:
            self._authenticate_worldcat_metadata_()
            if self.debug == True:
                self.print_or_log(f"getting new auth token, expiry: {expiry_deadline}")
        # Cache the results for repeated testing.
        with open(TOKEN_CACHE, 'w', encoding='ISO-8859-1') as f:
            # Use json.dump for streams files, or sockets and dumps for formatted strings.
            json.dump(self.auth_json, f, ensure_ascii=False, indent=2)
        return self.auth_json['access_token']
    
    # Wrapper for the logger. Added after the class was written
    # and to avoid changing tests. 
    # param: message:str message to either log or print. 
    # param: to_stderr:bool if True and logger  
    def print_or_log(self, message:str, to_stderr:bool=False):
        if to_stderr:
            sys.stderr.write(f"{message}{linesep}")
        else:
            print(f"{message}")


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    doctest.testfile("ws2.tst")