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
from selenium.webdriver import Firefox, FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException, ElementNotInteractableException
from selenium.webdriver.common.keys import Keys
from time import sleep
from datetime import datetime
import sys
import json
import re
import zipfile
import os
from logit import logit

VERSION='1.02.02d' # Fixed time-to-ready report estimate and reporting.
# Wait durations for page loads. 
DOWNLOAD_DELAY = 45
LONG = 15
LONGISH = 10
MEDIUM = 5
SHORT = 3
# Time OCLC warns your report may take to generate in minutes. 
# See also prod.json 'reportWaitMinutes'.
REPORT_COMPILE_MINUTES = 120

def oclcSignin(driver, url:str, userId:str, password:str, institutionCode:str):
    """ 
    Navigate to the login page and sign in. This can happen twice, once for the
    initial login and possibly again if the browser is closed during the time it 
    takes to generate the report.

    Parameters:
    - driver
    - URL to the homepage with sign in links for various services with OCLC.
    - userId of the user with authority to generate reports.
    - password of same.
    - institutionCode is the preferred default branch. Not implemented yet.

    Return:
    - True if the user was signed in to OCLC WorldShare Analyticds and false otherwise.
    """
    # I've isolated this part since it is most likely to change. 
    # By the time you are at the login page, you should have identified yourself and any hidden
    # fields that you are from a specific library. 
    if not navigateToSigninPage(driver, url=url, institutionCode=institutionCode):
        logit(f"**error can't open OCLC login homepage.", timestamp=True)
        return False

    # Now log in.
    if not login(driver, userId=userId, password=password):
        logit(f"**error, there was a problem while accessing the login page.", timestamp=True)
        return False
    return True

def login(driver, userId:str, password:str, debug:bool=False) -> bool:
    """ 
    Logs the application into the self-serve analytics portal using 
    credentials from configs.json.

    Pre-condition: 
    - The login page must be open

    Parameters:
    - driver
    - userId of the user with authority to generate reports.
    - password of same.
    - debug turns on debugging information.

    Return:
    - True if the authorized user is logged in and False otherwise.
    """
    try:
        # Wait until the page contains the expected username text box.
        element = WebDriverWait(driver, LONG).until(
            EC.presence_of_element_located((By.ID, "username"))
        )
        # User name
        user_id_textbox = driver.find_element(By.ID, 'username')
        if not user_id_textbox:
            logit(f"**error, doesn't seem to be an element called 'username' on this page.", timestamp=True)
            return False
        user_id_textbox.send_keys(userId)
        sleep(SHORT)
        # password
        user_password_textbox = driver.find_element(By.ID, 'password')
        if not user_password_textbox:
            logit(f"**error, doesn't seem to be an element called 'password' on this page.", timestamp=True)
            return False
        user_password_textbox.send_keys(password)
        sleep(SHORT)
        # Signin button click
        signin_button = driver.find_element(By.ID, 'submitSignin')
        if not signin_button:
            logit(f"**error, can't find a button called 'submitSignin' on this page.", timestamp=True)
            return False
        signin_button.click()
        return True
    except:
        logit(f"**error, timed out while waiting for page.", timestamp=True)
        return False

def navigateToSigninPage(driver, url:str, institutionCode:str, debug:bool=False) ->bool:
    """
    Starts at a OCLC homepage and navigates to the login pages. 
    Parameters:
    - driver 
    - url:str url of the oclc homepage. 
    - debug turns on debugging information.

    Return:
    - True if successfully navigated to the analytics page.

    <a href="/apps/oclc/welcome?service=wms&amp;inst_type=wayf">WorldShare Metadata Services</a>
    """
    driver.get(url)  
    # Accept cookies - Jesus!
    sleep(MEDIUM)
    try:
        # Accepts all cookies by default.
        # <button id="onetrust-accept-btn-handler">Accept all cookies</button>
        cookie_dialog = driver.find_element(By.ID, "onetrust-accept-btn-handler")
        if cookie_dialog:
            cookie_dialog.click()
            sleep(MEDIUM)
            if debug:
                logit(f"cookies: {driver.get_cookies()}", timestamp=True)
    except NoSuchElementException as ex:
        logit(f"no sign of the cookie dialog...", timestamp=True)
    login_link = driver.find_element(By.PARTIAL_LINK_TEXT, 'WorldShare Metadata Services')
    if not login_link:
        logit(f"**error, can't find a button called 'WorldShare Metadata Services' link on this page {url}", timestamp=True)
        return False
    login_link.click()
    sleep(LONGISH)
    # That should take you to the institution page where we enter 'CNEDM' or what have you. 
    # <input autocapitalize="none" autocomplete="off" autocorrect="off" 
    # id="ac-input" spellcheck="false" tabindex="0" type="text" aria-autocomplete="list" 
    # style="box-sizing: content-box; width: 2px; background: 0px center; 
    # border: 0px; font-size: inherit; opacity: 1; outline: 0px; padding: 0px; color: inherit;" value="">
    institution_textbox = driver.find_element(By.ID, 'input-institution-selection')
    if not institution_textbox:
        logit(f"**error, can't find the institution textbox on this page {url}", timestamp=True)
        return False
    institution_textbox.send_keys(institutionCode)
    sleep(SHORT)
    # This selects the institution from the dropdown that appears. 
    institution_textbox.send_keys(Keys.RETURN)
    sleep(SHORT)
    institution_textbox.send_keys(Keys.ARROW_DOWN)
    institution_textbox.send_keys(Keys.RETURN)
    sleep(SHORT)
    # The 'Continue' button should now be activated. 
    # <button class="MuiButtonBase-root MuiButton-root MuiButton-contained MuiButton-containedPrimary Mui-disabled Mui-disabled" 
    # tabindex="-1" type="submit" disabled="" name="instId" value="0"><span class="MuiButton-label">Continue</span></button>
    button = driver.find_element(By.NAME, "instId")
    sleep(MEDIUM)
    if not button:
        logit(f"**error, can't find the 'Continue' button on this page {url}", timestamp=True)
        return False
    # Submit doesn't work here, so just click the button. 
    button.click()
    return True

def selectDefaultBranch(driver, branch:str=''):
    """ 
    There are two times when you may need to select a default branch while logging 
    into the self service portal. The first when you login to start the report and 
    the next if the browser was closed, or the --request flag was the only flag used.

    Parameters:
    - driver
    - branch name to set as default. Not implemented in this version because it is
      not required at EPL.

    Return:
    - None
    """
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
        # driver.find_element(By.CLASS_NAME, 'yui3-dialog-ok').click()
        driver.find_element(By.CLASS_NAME, 'btn').click()
        sleep(LONGISH)
    except NoSuchElementException as ex:
        logit(f"doesn't seem to be asking for default branch.", timestamp=True)

def show_report_finish_time(minutes) ->str:
    """
    Calculates the time after the given number of minutes have passed.
    This is used to alert the user to when they should check for the 
    finished report if they are running report by single steps, that is,
    they are ordering the report, and later downloading the report.
    """
    mins = minutes
    if not mins:
        mins = 120
    # Convert minutes to hours and minutes
    hours = mins // 60
    remaining_minutes = mins % 60

    # Get the current time
    current_time = datetime.now().time()
    hour = current_time.hour
    minute = current_time.minute

    # Calculate the new time
    new_hour = (hour + hours) % 24
    new_minute = (minute + remaining_minutes) % 60

    # Print the result
    return f"In {mins} minutes, the time will be {int(new_hour)}:{int(new_minute)}"


def setupReport(driver, reportName:str, debug:bool=False) ->bool:
    """ 
    Analytics report page navigation. 

    Steps:
    1) Select branch in pop-up. For now just select the first, but it could be specified in the configs. 
    2) Select Analytics tab. 
    3) Select Collections tab -> My Library button. 
    4) Select Export Collection. 
    5) Give report a name and description. 
    6) Abort report generation if debug. 
    7) If not debug dismiss report generation duration warning to start report.

    Parameters:
    - driver 
    - reportName prefix of the report name from configs.json file.
    - debug, turns on debugging information.

    Return:
    - True if the request for OCLC holdings report was successful and 
      False otherwise.
    """
    selectDefaultBranch(driver)
    # Should be at the base page where you can select the 'Analytics' tab. 
    # <a href="/wms/cmnd/analytics/" id="uwa-component-analytics">Analytics</a>
    analytics_tab = driver.find_element(By.LINK_TEXT,'Analytics')
    if not analytics_tab:
        logit(f"**error, failed to find the 'Analytics' tab.", timestamp=True)
        return False
    analytics_tab.click()
    sleep(LONGISH)
    # Open the Reports button Jeez how tedious... 
    # <div class="yui3-accordion-panel-hd" id="aui_3_11_0_1_10484">
    #   <div class="yui3-accordion-panel-hd-liner">
    #       <div class="yui3-accordion-panel-label">Collection Evaluation</div></div></div>
    driver.find_element(By.CLASS_NAME, 'yui3-accordion-panel-label').click()
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
    # Convert hours to minutes.
    time_count = 2
    REPORT_COMPILE_MINUTES = float(time_count) * 60.0
    try:
        dialog_liner = driver.find_element(By.CLASS_NAME, 'yui3-dialog-liner')
        text_content = dialog_liner.text
        # Find the time estimated
        # Define a regular expression pattern to match the number of hours
        pattern = r'(\d+) (minutes|hours)'

        # Use re.search to find the match in the text
        match = re.search(pattern, text_content)

        # Check if a match is found
        if match:
            # Extract the number of hours from the match
            time_count = match.group(1)
            mins_or_hours = match.group(2)
            if mins_or_hours == 'minutes':
                REPORT_COMPILE_MINUTES = float(time_count)
            logit(f"Script will wait {REPORT_COMPILE_MINUTES} minutes for the report, which should be at {show_report_finish_time(REPORT_COMPILE_MINUTES)}", timestamp=True)
        else:
            logit(f"Couldn't find time estimate, there could be a report running\nbut check back at {show_report_finish_time(REPORT_COMPILE_MINUTES)}", timestamp=True)
    except:
        logit(f"Couldn't find time estimate dialog box, but check back at {show_report_finish_time(REPORT_COMPILE_MINUTES)}", timestamp=True)
        return False
    sleep(SHORT)
    # Close the Export Requested dialog box
    # <a href="#" class="yui3-dialog-close btn btn-subtle btn-xs" title="Close">
    # <i class="uic-ico-times">
    # <span class="sr-only">Close</span>
    # </i></a>
    try:
        close_button = driver.find_element(By.CSS_SELECTOR, "a.yui3-dialog-close")
        driver.execute_script("arguments[0].click();", close_button)
    except ElementNotInteractableException:
        # Alternatively:
        logit(f"couldn't find the close button on the dialog box.")
        # okay_button = driver.find_element(By.CSS_SELECTOR, "button.yui3-dialog-okay")
        # # Scroll element into view
        # driver.execute_script("arguments[0].scrollIntoView(true);", okay_button)
        # # Add a small wait to let the scroll complete
        # WebDriverWait(driver, SHORT).until(EC.element_to_be_clickable(okay_button))
        # okay_button.click()
    sleep(SHORT)
    return True

def logout(driver, debug:bool=False):
    """ 
    Logs the user out of the portal.

    Parameters:
    - driver
    - debug to turn on and off diagnostic messaging.

    Return: 
    - True if the user is logged out successfully and False otherwise.
    """
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
        logit(f"doesn't seem to be a logout drop down here.", timestamp=True)
        return False

def runReportTimer(minutes:float, debug:bool=False):
    """ 
    Runs a timer for the duration of the time it takes to generate the report.
    For our library that is 2 hours, but the function tries to read the 
    estimated time reported by the portal. If that fails the default of 2 hours
    is used. During this time a message is issued every 10 minutes about how
    much time is left. If debug is selected the timer runs in test mode and 
    the message is issued every second for a minute.

    All time is specified in minutes.

    Parameters:
    - minutes duration for the report to be compiled.
    - debug to turn on and off diagnostic messaging.

    Return: 
    - None, the function blocks until the time has elapsed.
    """
    now = datetime.now()
    current_time = now.strftime("%H:%M:%S")
    logit(f"Current Time = {current_time}", timestamp=True)
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
            logit(f"Remaining time: {int(remaining_time / 60.0)} minutes.", timestamp=True)
        else:
            logit(f"Remaining {int(remaining_time % 60.0)} seconds", timestamp=True)
        # Pause for the update interval
        sleep(update_interval)
        # Update the remaining time
        remaining_time -= update_interval
    # Continue with the rest of your program after the specified time has passed
    logit(f"Should be time to download file after a {total_minutes_to_wait} minute delay.", timestamp=True)
   
def downloadReport(driver, reportName:str):
    """ 
    Downloads the latest report from the self-service portal.

    Requirements:
    - The application must be logged in and at the Analytics page.

    Parameters:
    - driver
    - reportName, or report file name prefix specified in the configs.json.
    
    Return:
    - full name of the report file if successful and an empty string otherwise.
    """
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
        logit(f"**error, failed to find the 'Analytics' tab.", timestamp=True)
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

    # Find the default report name prefix, 'roboto_report*' report, and find and click the download button.
    report_prefix = reportName
    # <tbody class="yui3-datatable-data">
    #   <tr id="aui_3_11_0_1_11593" data-yui3-record="model_9" class="yui3-datatable-even ">
    #       <td class="yui3-datatable-col-filename  yui3-datatable-cell ">roboto_report_inst_44376_mylibraryFiltered__2024_01_12__14_03_15.xls.zip</td>
    #       <td class="yui3-datatable-col-product  yui3-datatable-cell ">Collection Evaluation</td>
    #       <td class="yui3-datatable-col-size  yui3-datatable-cell ">22,088 KB</td>
    #       <td class="yui3-datatable-col-postDate  yui3-datatable-sorted yui3-datatable-cell ">01/12/2024</td>
    #       <td class="yui3-datatable-col-downloadDate  yui3-datatable-cell ">01/12/2024</td>
    #       <td class="yui3-datatable-col-id  yui3-datatable-cell ">
    #           <button href="/xfer/document/id/R5574443219901933684429945847898075187123" class="download-button btn btn-default btn-sm">Download</button>
    #       </td>
    #   </tr>
    # </tbody>
    sleep(SHORT)
    my_table = driver.find_element(By.CLASS_NAME, 'yui3-datatable-data')
    table_recs = my_table.find_elements(By.TAG_NAME, 'tr')
    sleep(SHORT)
    report_full_name = ''
    flag = False
    for t_recs in table_recs:
        tds = t_recs.find_elements(By.TAG_NAME, 'td')
        sleep(SHORT)
        for td in tds:
            logit(f"* {td.text}", timestamp=True)
            if td.text.endswith('.zip'):
                report_full_name = td.text
            if td.text == 'Download':
                button = td.find_element(By.TAG_NAME, 'button')
                button.click()
                sleep(DOWNLOAD_DELAY) 
                flag = True
                break
        # break out of outer loop.
        if flag:
            break
    return report_full_name

def findReport(directoryPath:str, filePrefix:str) ->str:
    """
    Find a latest file that starts with the 'reportName' prefix 
    described in the JSON configuration file given a arbitrary 
    but specific directory. In the case of this application 
    it is the browser's download directory. 

    Parameters:
    - directoryPath:str Directory to start the search in. 
    - filePrefix:str Name of report given the 'reportName' 
      parameter in the configuration JSON file.

    return: 
    - None if not found, and the newest version if found.
    """
    newest_file = None
    newest_time = 0
    for root, dirs, files in os.walk(directoryPath):
        for file in files:
            if file.startswith(filePrefix):
                file_path = os.path.join(root, file)
                modification_time = os.path.getmtime(file_path)
                if modification_time > newest_time:
                    logit(f"... found newer @time {modification_time}", timestamp=True)
                    newest_file = file_path
                    newest_time = modification_time
    logit(f"newest file found that starts with {filePrefix} is {newest_file}", timestamp=True)
    return newest_file

def reportToList(inputFile:str, outputFile:str, debug:bool=False):
    """ 
    Given an OCLC report file will convert to a list of OCLC holdings numbers.
    The report can be be zipped or unzipped.

    Note: OCLC labels thier reports with the 'xls' extension but don't be fooled
    the report is plain tab-delimited CSV (TSV) and not an Excel file per se.

    Parameters: 
    - downloadReport:str Path and name of the report file downloaded from
      OCLC customer self-serve portal. 
    - outputFile:str Path and name of the output file of OCLC holding numbers. 
      Default: './oclc.lst'.
    - debug turns on debugging information.

    Return:
    - None, but does write the list of OCLC numbers to a file, one per line.
    """
    if debug:
        logit(f"input file: {inputFile}", timestamp=True)
    fout = open(outputFile, 'w')
    max_count = 10
    line_count = 0
    pattern = re.compile(r'=HYPERLINK\("http://www.worldcat.org/oclc/(\d+)"')
    if not inputFile.lower().endswith('.zip'):
        with open(inputFile, 'r') as csv:
            for line in csv:
                line = line.strip()
                match = re.search(pattern, line)
                if match:
                    fout.write(f"{match[1]}\n")
                    if debug and line_count <= 10:
                        logit(f"DEBUG=>{match[1]}", timestamp=True)
                    line_count += 1
        csv.close()
    else:
        with zipfile.ZipFile(inputFile, 'r') as zip_file:
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
                                logit(f"DEBUG=>{match[1]}", timestamp=True)
                            line_count += 1
        csv.close()
    fout.close()
    logit(f"Total records: {line_count}", timestamp=True)

# Searches the Download directory for the latest [reportName]*.xls.zip and converts it to 
# a delete list. 
# param: downloadDir:str browser's download directory. 
# param: reportName:str name prefix of the report. Something from prod.json 'reportName' config. 
# param: outputFile:str name and path of the compiled list of deletes. Also defined in prod.json 
#   in the oclcHoldingsListName setting. 
# param: debug:bool turns on debugging.  
def compile_report(downloadDirectory:str, reportName:str, outputFile:str, debug:bool=False):
    latest_report_full_path = findReport(directoryPath=downloadDirectory, filePrefix=reportName)
    if not latest_report_full_path:
        logit(f"**error, there doesn't seem to be a report downloaded to {downloadDirectory} that starts with '{reportName}'", timestamp=True)
        sys.exit(1)
    logit(f"converting CSV to list.", timestamp=True)
    reportToList(inputFile=latest_report_full_path, outputFile=outputFile, debug=debug)
    logit(f"done outputting {outputFile}", timestamp=True)

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
    parser.add_argument('--all', action='store_true', default=False, help='request report, wait for report, download report.')
    parser.add_argument('--config', action='store', default='prod.json', metavar='[/foo/prod.json]', help='configurations for OCLC web services.')
    parser.add_argument('--compile', action='store_true', default=False, help='compile OCLC report into a list OCLC numbers. Assumes report has been downloaded before".')
    parser.add_argument('-d', '--debug', action='store_true', default=False, help='turn on debugging.')
    parser.add_argument('--download', action='store_true', default=False, help='assumes the report has been requested, and it is time to download it.')
    parser.add_argument('--order', action='store_true', default=False, help='requests a holdings report from OCLC\'s analytics self-serve portal and exit.')
    parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)
    
    args = parser.parse_args()
    # Read in configurations.
    configs_file = args.config
    logit(f"config file: {configs_file}", timestamp=True)
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
    report_name = configs.get('reportName')
    assert report_name
    report_download_directory = configs.get('reportDownloadDirectory')
    assert report_download_directory
    holdings_list_prefix = configs.get('oclcHoldingsListName')
    assert holdings_list_prefix
    # Give the deletes list a dated name.
    current_date = datetime.now()
    date_string  = current_date.strftime("%Y%m%d")
    holdings_list_name = f"./{holdings_list_prefix}_{date_string}.lst"
    assert holdings_list_name

    if args.compile:
        logit(f"Compiling OCLC report", timestamp=True)
        compile_report(report_download_directory, report_name, holdings_list_name, args.debug)
        sys.exit(0)

    options = FirefoxOptions()
    
    driver = Firefox(options=options)
    sleep(SHORT)

    logit(f"Started browser", timestamp=True)
    if args.order or args.all:
        # Sign in to OCLC WorldShare services. 
        logit(f"signing in to {homepage}", timestamp=True)
        if not oclcSignin(driver, url=homepage, userId=user_name, password=user_password, institutionCode=institution_code):
            logit(f"**error, while signing in? Is the system down or did they change the page?", timestamp=True)
            sys.exit(1)

        logit(f"setting up {report_name}", timestamp=True)
        if setupReport(driver, reportName=report_name, debug=args.debug):
            driver.quit()
        else:
            logit(f"*warning, there was an issue but check for the report in a couple of hours.", timestamp=True)
            if not args.debug:
                driver.quit()
            sys.exit(1)

    # Now wait for the report to compile.
    if args.all:
        driver.quit()
        logit(f"starting delay timer {REPORT_COMPILE_MINUTES}", timestamp=True)
        runReportTimer(REPORT_COMPILE_MINUTES, debug=args.debug)
        logit(f"timer finished", timestamp=True)
    
    # Time to check in on the report. 
    # Test that the analytics page is still open. It does stay logged in for a long time but the
    # user may have closed the browser. 
    if args.download or args.all:
        logit(f"checking for correct page.", timestamp=True)
        if not driver.title == 'OCLC WorldShare':
            if not oclcSignin(driver, url=homepage, userId=user_name, password=user_password, institutionCode=institution_code):
                logit(f"**error, while signing in? Is the system down or did they change the page?", timestamp=True)
                sys.exit(1)
        logit(f"found correct page.", timestamp=True)
        # The page does stay active for some time so the 1.5 hours-ish wait _should_ keep you logged in. 
        full_report_name = downloadReport(driver, reportName=report_name)
        logit(f"attempt to download report {full_report_name}.", timestamp=True)
        if not full_report_name:
            logit(f"**error, while downloading file starting with {full_report_name}", timestamp=True)
            sys.exit(1)
        # Find the latest report starting with 'reportName' from configs.json.
        compile_report(downloadDirectory=report_download_directory, reportName=report_name, outputFile=holdings_list_name, debug=args.debug)
        logout(driver)
        logit(f"done.", timestamp=True)
    if not args.debug:
        driver.quit()

if __name__ == "__main__":
    if len(sys.argv) == 1:
        # import doctest
        # doctest.testmod()
        # doctest.testfile("sometest.tst")
        # runReportTimer(REPORT_COMPILE_MINUTES, debug=True)
        reportToList('/home/anisbet/Downloads/roboto_report_inst_44376_mylibraryFiltered__2024_01_12__14_03_15.xls.zip', outputFile='./oclc_test.lst', debug=True)
    else:
        main(sys.argv[1:])
