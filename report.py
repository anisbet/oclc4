#!/usr/bin/env python3
###############################################################################
#
# Purpose: Generate OCLC holdings report and download results.
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
import argparse
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from time import sleep
from datetime import datetime
import sys
import json
import re
import zipfile

VERSION='0.00.00'
# Wait durations for page loads. 
LONG = 10
LONGISH = 5
MEDIUM = 3
SHORT = 1
# Time OCLC warns your report may take to generate in minutes. 
# See also prod.json 'reportWaitMinutes'.
REPORT_COMPILE_TIME = 120

def oclcSignin(driver, url:str, userId:str, password:str, institutionCode:str):
    # Navigate to the login page. I've isolated this part since it is most likely to change. 
    # By the time you are at the login page, you should have identified yourself and any hidden
    # fields that you are from a specific library. 
    if not navigate(driver, url=url, institutionCode=institutionCode):
        print(f"**error can't open OCLC login homepage.")
        return False

    # Now log in.
    if not login(driver, userId=userId, password=password):
        print(f"**error, there was a problem while accessing the login page.")
        return False
    return True

def login(driver, userId:str, password:str, debug:bool=False) -> bool:
    try:
        # Wait until the page contains the expected username text box.
        element = WebDriverWait(driver, LONG).until(
            EC.presence_of_element_located((By.ID, "username"))
        )
        # User name
        user_id_textbox = driver.find_element(By.ID, 'username')
        if not user_id_textbox:
            print(f"**error, doesn't seem to be an element called 'username' on this page {url}")
            return False
        user_id_textbox.send_keys(userId)
        sleep(SHORT)
        # password
        user_password_textbox = driver.find_element(By.ID, 'password')
        if not user_password_textbox:
            print(f"**error, doesn't seem to be an element called 'password' on this page {url}")
            return False
        user_password_textbox.send_keys(password)
        sleep(SHORT)
        # Signin button click
        signin_button = driver.find_element(By.ID, 'submitSignin')
        if not signin_button:
            print(f"**error, can't find a button called 'submitSignin' on this page {url}")
            return False
        signin_button.click()
        return True
    except:
        print(f"**error, timed out while waiting for {url}")
        return False

# Starts at a OCLC homepage and navigates to the login pages. 
# param: driver 
# param: url:str url of the oclc homepage. 
def navigate(driver, url:str, institutionCode:str, debug:bool=False) ->bool:
    """
    <a href="/apps/oclc/welcome?service=wms&amp;inst_type=wayf">WorldShare Metadata Services</a>
    """
    driver.get(url)  
    # Accept cookies - Jesus!
    sleep(MEDIUM)
    try:
        # <button id="onetrust-accept-btn-handler">Accept all cookies</button>
        cookie_dialog = driver.find_element(By.ID, "onetrust-accept-btn-handler")
        if cookie_dialog:
            cookie_dialog.click()
            sleep(MEDIUM)
            if debug:
                print(f"cookies: {driver.get_cookies()}")
    except NoSuchElementException as ex:
        print(f"no sign of the cookie dialog...")
    login_link = driver.find_element(By.PARTIAL_LINK_TEXT, 'WorldShare Metadata Services')
    if not login_link:
        print(f"**error, can't find a button called 'WorldShare Metadata Services' link on this page {url}")
        return False
    login_link.click()
    sleep(LONGISH)
    # That should take you to the institution page where we enter 'CNEDM' or what have you. 
    # <input autocapitalize="none" autocomplete="off" autocorrect="off" 
    # id="ac-input" spellcheck="false" tabindex="0" type="text" aria-autocomplete="list" 
    # style="box-sizing: content-box; width: 2px; background: 0px center; 
    # border: 0px; font-size: inherit; opacity: 1; outline: 0px; padding: 0px; color: inherit;" value="">
    institution_textbox = driver.find_element(By.ID, 'ac-input')
    if not institution_textbox:
        print(f"**error, can't find the institution textbox on this page {url}")
        return False
    institution_textbox.send_keys(institutionCode)
    sleep(SHORT)
    # This selects the institution from the dropdown that appears. 
    institution_textbox.send_keys(Keys.RETURN)
    sleep(SHORT)
    # The 'Continue' button should now be activated. 
    # <button class="MuiButtonBase-root MuiButton-root MuiButton-contained MuiButton-containedPrimary Mui-disabled Mui-disabled" 
    # tabindex="-1" type="submit" disabled="" name="instId" value="0"><span class="MuiButton-label">Continue</span></button>
    button = driver.find_element(By.NAME, "instId")
    sleep(MEDIUM)
    if not button:
        print(f"**error, can't find the 'Continue' button on this page {url}")
        return False
    # Submit doesn't work here, so just click the button. 
    button.click()
    return True

def selectDefaultBranch(driver, branch:str=''):
    # This dialog box _may_ appear. set it to the first selection and then click okay. 
    # <div id="aui_3_11_0_1_1210" class="yui3-branchselectdialog-content">
    # <select size="6" class="branchList">
    # <option class="branch-list-item" value="46107" data-country="CA" data-default-holding-location="MAIN">
    #   Edmonton Public Library
    # </option>
    # </select>
    # <input type="checkbox" class="branchDefault" checked=""> Make selected branch the default for this workstation</div>
    try:
        sleep(LONG)
        driver.find_element(By.CLASS_NAME, 'branch-list-item').click()
        sleep(MEDIUM)
        # If there is more than one branch to select add code here to navigate to appropriate setting.
        driver.find_element(By.CLASS_NAME, 'yui3-dialog-ok').click()
        sleep(LONGISH)
    except NoSuchElementException as ex:
        print(f"doesn't seem to be asking for default branch.")
    
# Analytics report page navigation. 
# Select branch in pop-up. For now just select the first, but it could be specified in the configs. 
# Select Analytics tab. 
# Select Collections tab -> My Library button. 
# Select Export Collection. 
# Give report a name and description. 
# Abort report generation if debug. 
# If not debug dismiss report generation duration warning to start report.  
def setupReport(driver, reportName:str='roboto_report', debug:bool=False) ->bool:
    selectDefaultBranch(driver)
    # Should be at the base page where you can select the 'Analytics' tab. 
    # <a href="/wms/cmnd/analytics/" id="uwa-component-analytics">Analytics</a>
    analytics_tab = driver.find_element(By.LINK_TEXT,'Analytics')
    if not analytics_tab:
        print(f"**error, failed to find the 'Analytics' tab.")
        return False
    analytics_tab.click()
    sleep(LONGISH)
    # Open the Reports button Jeez how tedious... 
    # <div class="yui3-accordion-panel-hd" id="aui_3_11_0_1_10484">
    #   <div class="yui3-accordion-panel-hd-liner">
    #       <div class="yui3-accordion-panel-label">Collection Evaluation</div></div></div>
    driver.find_element(By.ID, 'aui_3_11_0_1_10484').click()
    sleep(MEDIUM)
    # <a href="/analytics/myLibrary" class="open-panel-button">My Library</a>
    driver.find_element(By.LINK_TEXT, 'My Library').click()
    sleep(LONG)
    # That will open the main panel with the genre table. 
    # <button class="myLibraryExportTitleList chartButton" id="aui_3_11_0_1_13796">Export Title List</button>
    driver.find_element(By.CLASS_NAME, 'myLibraryExportTitleList').click()
    sleep(MEDIUM)
    # A popup appears to allow the entry of the report name and a description. 
    # <div id="aui_3_11_0_1_13814" class="yui3-widget yui3-dialog export-file-name-dialog modal-dialog yui3-widget-positioned yui3-widget-stacked yui3-dialog-focused" role="dialog" aria-labeledby="aui_3_11_0_1_13839" style="height: 250px; width: 400px; left: 430px; top: 307.35px; z-index: 9998;" aria-hidden="false">
    
    # Input the report name prefix. 
    #       <input type="text" class="file-name-input" maxlength="50" id="export-file-name" name="fileName"></div>
    driver.find_element(By.ID, 'export-file-name').send_keys(reportName)
    sleep(SHORT)
    #       <textarea class="export-file-desc-text" name="description" placeholder="Enter brief description for this export up to 500 characters..." maxlength="500"></textarea></div>
    driver.find_element(By.CLASS_NAME, 'export-file-desc-text').send_keys('Generated by Andrew Nisbet for EPL')
    sleep(SHORT)
    # TODO: move function to the close feature on the report duration warning diaglog. 
    # if debug:
        # <a href="#" class="yui3-dialog-close btn btn-subtle btn-xs" title="Close" id="aui_3_11_0_1_13953"><i class="uic-ico-times" id="aui_3_11_0_1_13955"><span class="sr-only">Close</span></i></a>
        # driver.find_element(By.LINK_TEXT, 'Close').click()
        # sleep(SHORT)
        # return logout(driver, debug=debug)
    # Otherwise click the Okay button.
    # <button class="btn yui3-dialog-button yui3-dialog-ok btn-primary" id="aui_3_11_0_1_13969"><span id="aui_3_11_0_1_13970">OK</span></button>
    # <button class="btn yui3-dialog-button yui3-dialog-ok btn-primary" id="aui_3_11_0_1_13944"><span id="aui_3_11_0_1_13943">OK</span></button>
    # ElementNotInteractableException: Message: Element <button class="btn yui3-dialog-button yui3-dialog-ok btn-primary"> could not be scrolled into view
    # So maybe this...? 
    webdriver.ActionChains(driver).send_keys(Keys.TAB).perform()
    sleep(SHORT)
    webdriver.ActionChains(driver).send_keys(Keys.RETURN).perform()
    sleep(LONG)
    # There should be another dialog warning about how long it takes to run the report. 
    # <div class="yui3-dialog-liner">A mylibraryFiltered Export has been requested using the filters you provided.
    # <br>
    # <br>
    # It will be available in your My Files repository in approximately 2 hours.
    # </div>
    try:
        dialog_liner = driver.find_element(By.CLASS_NAME, 'yui3-dialog-liner')
        text_content = dialog_liner.text
        # Find the time estimated
        # Define a regular expression pattern to match the number of hours
        pattern = r'in approximately (\d+) (minutes|hours)'

        # Use re.search to find the match in the text
        match = re.search(pattern, text)

        # Check if a match is found
        if match:
            # Extract the number of hours from the match
            time_count = match.group(1)
            mins_or_hours = match.group(2)
            if mins_or_hours == 'minutes':
                REPORT_COMPILE_TIME = float(time_count)
            else:
                # Convert hours to minutes.
                REPORT_COMPILE_TIME = float(time_count) * 60.0
            print("Script will wait {REPORT_COMPILE_TIME} minutes for the report.")
        else:
            print("Couldn't find time estimate, is there a report running already?")
    except:
        print("Couldn't find time estimate dialog box!")
        return False
    webdriver.ActionChains(driver).send_keys(Keys.RETURN).perform()
    return True

def logout(driver, debug:bool=False):
    try:
        # navigate to the dropdown arrow. 
        # <a onclick="return false;" class="yui3-menu-toggle" role="presentation" id="aui_3_11_0_1_1044" tabindex="-1"><span>User Options</span></a>
        driver.find_element(By.LINK_TEXT, 'User Options').click()
        sleep(MEDIUM)
        # <a id="wms-logout" class="yui3-menuitem-content uic-icon-lockopen msi-router-exempt" href="/wms/cmnd/logout" role="menuitem" style="" tabindex="0">Log Out</a>
        driver.find_element(By.LINK_TEXT, 'Log Out').click()
        sleep(MEDIUM)
        if not debug:
            driver.quit()
        return True
    except NoSuchElementException as ex:
        print(f"doesn't seem to be a logout drop down here.")
        return False

def runReportTimer(minutes:float, debug:bool=False):
    now = datetime.now()
    current_time = now.strftime("%H:%M:%S")
    print(f"Current Time = {current_time}")
    total_minutes_to_wait = float(minutes)
    # Convert total minutes to seconds
    if debug:
        total_seconds_to_wait = total_minutes_to_wait * 1.0
        update_interval = 1.0 * 1.0
    else:
        total_seconds_to_wait = total_minutes_to_wait * 60.0
        update_interval = 10.0 * 60.0
    
    # Initialize the remaining time
    remaining_time = float(total_seconds_to_wait)
    while remaining_time > 0.0:
        # Print the remaining time
        if remaining_time / 60.0 > 1.0:
            print(f"Remaining time: {int(remaining_time / 60.0)} minutes and {remaining_time % 60.0} seconds")
        else:
            print(f"Remaining {int(remaining_time % 60.0)} seconds")
        # Pause for the update interval
        sleep(update_interval)
        # Update the remaining time
        remaining_time -= update_interval
    # Continue with the rest of your program after the specified time has passed
    print(f"Should be time to download file after a {total_minutes_to_wait} minute delay.")
   
def downloadReport(driver, reportName:str='roboto_report'):
    ### The driver must be logged in and at the Analytics page. ###
    selectDefaultBranch(driver)
    # Navigate to the side-bar nav panel; 'My Files' tab and click, as we did for 'Collection Evaluation'. 
    # <div id="aui_3_11_0_1_10562" class="yui3-widget yui3-accordion-panel yui3-accordion-panel-content yui3-accordion-panel-closed">
    # <div class="yui3-accordion-panel-label">My Files</div></div></div><div class="yui3-accordion-panel-bd-wrap">
    #   <div class="yui3-accordion-panel-bd" style="height: 0px; opacity: 0; display: none;" id="aui_3_11_0_1_14201">
    #       <div class="yui3-accordion-panel-bd-liner">
    #           <div id="aui_3_11_0_1_10620" class="yui3-widget yui3-open-uwa-panel-button">
    #               <div class="analytics-opb analytics-opb-download yui3-open-uwa-panel-button-content" id="aui_3_11_0_1_10621">
    
    # Click on the now visible download button. 
    # <a href="/analytics/files/download" class="open-panel-button">Download Files</a>
    analytics_tab = driver.find_element(By.LINK_TEXT,'Analytics')
    if not analytics_tab:
        print(f"**error, failed to find the 'Analytics' tab.")
        return False
    analytics_tab.click()
    sleep(LONGISH)
    # Open the 'My Files' button Jeez how tedious... 
    # <div id="aui_3_11_0_1_10576" class="yui3-widget yui3-accordion-panel yui3-accordion-panel-content yui3-accordion-panel-closed">
    #   ...
    #     <div class="yui3-accordion-panel-label">My Files</div>
    my_files_button = driver.find_element(By.XPATH, f"//div[text()='My Files']")
    sleep(SHORT)
    my_files_button.click()
    sleep(SHORT)
    # Open the download files link. 
    # <a href="/analytics/files/download" class="open-panel-button">Download Files</a>
    driver.find_element(By.LINK_TEXT, 'Download Files').click()
    sleep(LONG)

    # If you have already downloaded the file you may have to uncheck the 'Hide Downloaded Files' checkbox. 
    # <input type="checkbox" id="inputCheckboxHideDownloaded" class="hideDownloaded-checkbox"> 
    # Find the checkbox element by its ID
    checkbox_element = driver.find_element(By.ID, 'inputCheckboxHideDownloaded')

    # Check if the checkbox is currently checked
    if checkbox_element.is_selected():
        # If checked, uncheck it
        checkbox_element.click()

    # Find the default report name prefix, 'roboto_holdings*' report, and find and click the download button.
    # <tr id="aui_3_11_0_1_15051" data-yui3-record="model_81" class="yui3-datatable-even ">
    #   <td class="yui3-datatable-col-filename  yui3-datatable-cell ">roboto_report_inst_44376_mylibraryFiltered__2024_01_12__14_03_15.xls.zip</td>
    #   <td class="yui3-datatable-col-product  yui3-datatable-cell ">Collection Evaluation</td>
    #   <td class="yui3-datatable-col-size  yui3-datatable-cell ">22,088 KB</td>
    #   <td class="yui3-datatable-col-postDate  yui3-datatable-sorted yui3-datatable-cell ">01/12/2024</td>
    #   <td class="yui3-datatable-col-downloadDate  yui3-datatable-cell "></td>
    #   <td class="yui3-datatable-col-id  yui3-datatable-cell ">
    #       <button href="/xfer/document/id/R5574443219901933684429945847898075187123" class="download-button btn btn-default btn-sm">Download</button>
    #   </td>
    # </tr>
    # Find the table row that contains the specified text
    # TODO: Fix this because it doesn't find the record with this XPATH. 
    report_prefix = reportName
    xpath_query = f"//tr[contains(td, '{report_prefix}')]"
    row_elements = driver.find_elements(By.XPATH, xpath_query)
    # Find the 'Download' button within the found row and click it
    for row in row_elements:
        download_button = row.find_element(By.CLASS_NAME, 'download-button')
        download_button.click()
    sleep(LONG) 
    return True

# Given an OCLC report file will convert to a list of OCLC holdings numbers. 
# param: downloadReport:str Path and name of the report file downloaded from
#   OCLC customer self-serve portal. 
# param: listName:str Path and name of the output file of OCLC holding numbers. 
#   Default: './oclc.lst'. 
def reportToList(downloadedReport:str, listName:str='./oclc.lst', debug:bool=False):
    fout = open(listName, 'w')
    max_count = 10
    line_count = 0
    pattern = re.compile(r'=HYPERLINK\("http://www.worldcat.org/oclc/(\d+)"')
    if not downloadedReport.lower().endswith('.zip'):
        with open(downloadedReport, 'r') as csv:
            for line in csv:
                line = line.strip()
                match = re.search(pattern, line)
                if match:
                    fout.write(f"{match[1]}\n")
                    if debug and line_count <= 10:
                        print(f"DEBUG=>{match[1]}")
                    line_count += 1
        csv.close()
    else:
        with zipfile.ZipFile(downloadedReport, 'r') as zip_file:
            # List all files in the zip archive
            file_list = zip_file.namelist()
            for file_name in file_list:
                with zip_file.open(file_name) as csv:
                    for line in csv:
                        line = line.decode('utf-8').strip()
                        match = re.search(pattern, line)
                        if match:
                            fout.write(f"{match[1]}\n")
                            if debug and line_count <= 10:
                                print(f"DEBUG=>{match[1]}")
                            line_count += 1
        csv.close()
    fout.close()
    if debug:
        print(f"Total records: {line_count}")

def main(argv):
    parser = argparse.ArgumentParser(
        prog = 'oclcreport',
        usage='%(prog)s [options]' ,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='''\
            Generates a report of a library's OCLC holdings.
            Works on OCLC's analytics portal 
                https://www.oclc.org/en/services/logon.html
            as of January 16, 2024.
            ''',
        epilog='''\
    TODO: add documentation here.
        '''
    )
    parser.add_argument('--all', action='store_true', default=False, help='Request report, wait for report, download report.')
    parser.add_argument('--config', action='store', default='prod.json', metavar='[/foo/prod.json]', help='Configurations for OCLC web services.')
    parser.add_argument('-d', '--debug', action='store_true', default=False, help='turn on debugging.')
    parser.add_argument('--download', action='store_true', default=False, help='Assumes the report has been requested, and it is time to download it.')
    parser.add_argument('--order', action='store_true', default=False, help='Requests a holdings report from OCLC\'s analytics self-serve portal and exit.')
    parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)
    
    args = parser.parse_args()
    # Read in configurations.
    configs_file = args.config
    print(f"config file: {configs_file}")
    with open(configs_file) as f:
        configs = json.load(f)
    user_name = configs.get('reportUserId')
    assert user_name
    user_password = configs.get('reportPassword')
    assert user_password
    homepage = configs.get('reportLoginHomePage')
    assert homepage
    institution_code = configs.get('reportInstitution')
    assert institution_code
    # Function has default name 'roboto_report'
    report_name = configs.get('reportName')
    assert report_name
    report_download_directory = configs.get('reportDownloadDirectory')
    assert report_download_directory
    holdings_list_name = configs.get('oclcHoldingsListName')  # Optional, default is './oclc.lst'.

    # Open the page
    driver = webdriver.Firefox()
    sleep(SHORT)

    if args.order or args.all:
        # Sign in to OCLC WorldShare services.  
        if not oclcSignin(driver, url=homepage, userId=user_name, password=user_password, institutionCode=institution_code):
            print(f"**error, while signing in? Is the system down or did they change the page?")
            sys.exit(1)

        if not setupReport(driver, reportName=report_name, debug=args.debug):
            print(f"**error while accessing the analytics report setup page")
            if not args.debug:
                driver.quit()
            sys.exit(1)

    # Now wait for the report to compile.
    if args.all:
        assert runReportTimer(REPORT_COMPILE_TIME, debug=args.debug)
    
    # Time to check in on the report. 
    # Test that the analytics page is still open. It does stay logged in for a long time but the
    # user may have closed the browser. 
    if args.download or args.all:
        if not driver.title == 'OCLC WorldShare':
            if not oclcSignin(driver, url=homepage, userId=user_name, password=user_password, institutionCode=institution_code):
                print(f"**error, while signing in? Is the system down or did they change the page?")
                sys.exit(1)

        # The page does stay active for some time so the 1.5 hours-ish wait _should_ keep you logged in. 
        if not downloadReport(driver, reportName=report_name):
            print(f"**error, while downloading file starting with {report_name}")
            sys.exit(1)
        reportToList(downloadedReport=report_download_directory, listName=holdings_list_name, debug=args.debug)
        # logout(driver)
    if not args.debug:
        pass
        # driver.quit()


if __name__ == "__main__":
    if len(sys.argv) == 1:
        # import doctest
        # doctest.testmod()
        # doctest.testfile("sometest.tst")
        # runReportTimer(REPORT_COMPILE_TIME, debug=True)
        reportToList('/home/anisbet/Downloads/roboto.xls.zip', debug=True)
    else:
        main(sys.argv[1:])
