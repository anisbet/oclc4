# Known Issues

* Bib records need to be uploaded and then set. This will include any record that was `set` or `match`ed but no results were returned.
* Need to click Okay on the `Export Requested:` dialog box. **Done** not working.
* Restart the deletes process after an exception is thrown.
* Should be able to `--recover` `add` records (marked `"action": "set"`), or use `--add` with json file. You can add a single dummy record to the deletes json file and it will run, but this could be cleaner. **Fixed**
* Report script can't find report generation estimate in modal dialog box. **Fixed**
* The script dumps records before the match stage. This shouldn't happen unless an exception is thrown. **Fixed**
* OCLC match responses are showing errors when matching records. **Fixed**
* OCLC response to matching files is that the 008 field must be 40 characters long but isn't. Example 1805004. Add test to confirm correct XML output. **Fixed**
* Use database instead of reading entire flat file.
* Firefox Missing Profile error. The script `report.py` uses Firefox via Selenium to run the OCLC web portal. On Ubuntu 22.04 Firefox will fail to run with a 'Profile Missing' error dialog complaining that the profile is missing or empty. **Fixed** ([See replacing `snap` Firefox with `apt-get` version](#firefox-installation)).
* unzip the adds file if needed, when using the `--add` flag. **Done**
Typically there are thousands of records to send and the web service sometimes stops responding. **Done**
* Detect timeout delay of more than {config} seconds. **Done** [configurable](#sample-configuration-file).
* Save the unprocessed files. **Done** 
* Log the event. **Done**
* Optionally restart after {config} delay has elapsed.
* The application has moved to a batch process, which means that if OCLC drops the connection, after a configurable amount of time, the remaining list of adds and deletes are written to restorable files and the application exits. The timeout setting can be set in `prod.json:"requestTimeout"` for web service request timeout: 10 seconds is done with `'requestTimeout': 10`. **Done**

# Quick Start

The entire process can start with `runreport.sh` which automates the process of ordering the current list of holdings for EPL. Once that is completed use `runoclc.sh` to run a reclamation or continue a cancelled or failed reclamation process. 

To run a reclamation you will need a [deletes list](#the-deletes-list) and a [adds list](#the-adds-list) of OCLC numbers.

## The Adds List
The adds file is a flat, or marcedit mrk file of all the MARC records that have been added or modified. The adds list is compared to the delete list to figure out which records to actually add **or** delete. Run the following on the ILS.
1) `cd sirsi@ils.com:~/Unicorn/EPLwork/anisbet/OCLC`
2) `./flatcat.sh`. This could take 8 minutes or so, and create a file called `./bib_records_[YYYYMMDD].zip`. 
3) Move the file `./bib_records_[YYYYMMDD].zip` to the server where `oclc4.py` will run.
4) Use `--add=./bib_records_(YYYYMMDD).(zip|flat)` to automatically unzip and or run the flat file (of the same name If the file is a zip file). For example `bib_records_20140911.zip` would contain a flat file called `bib_records_20140911.flat`.

## The Deletes List
The deletes list is just a list of OCLC numbers without any prefixes, one-per-line in a flat text file. It can be created as follows.

1) Order a new report from OCLC: 
```bash
oclc4$ python3 report.py --order`. 
# This uses webscraping techniques via the customer portal, 
# and may issue an error like 'Couldn't find time estimate dialog box!'.
# That doesn't matter, the report will be crunching away at the OCLC end.
```
2) In about 1.5 hours get the report: 
```bash
oclc4$ python3 report.py --download`
# The file will be found in the browsers default download directory,
# unzipped, and compiled into a file of delete numbers called 
# `prod.json:oclcHoldingsListName` by default in the current 
# working directory.
```

## Running a Reclamation
Now with both lists you can run the application.
```bash
oclc4$ python3 oclc4.py --add='bib_records_(YYYYMMDD).flat' --delete='deletes_(YYYYMMDD).lst'
```

## Updating the ILS
If a `bib_overlay_(yyyymmdd).flat` file is created, transfer it to the ILS and overlay the bib records through [this process](#catalogmerge).

# In More Detail
OCLC needs to know what records your library has to make WorldCat searches and other services work effectively. Libraries are constantly adding and removing titles, so it is important to update OCLC about these changes. Up-to-date records help customers find materials in your collection. Stale records make customers grumpy.

Updating OCLC is a matter of sending records that are new, called **set**ting holdings, removing records you no longer have, called **unset**ting holdings.

During this process OCLC will provide feedback in the form of updated numbers if they have changed or merged numbers. These changes need to be reflected in your bibs.

## Adding Records to OCLC Holdings
A library will select records it considers of interest to OCLC and then compiles a Symphony `flat` file of these records for submission. This file is also used as the basis for a slim-flat file of records to overlay in the ILS. The flat records can be easily generated with [`flatcat.sh`]

## Deleting Records from OCLC Holdings
`oclc4` does away with searching logs for deleted titles. Instead it requests a holdings report and compares it to your collection. Then it compiles a list of records to set and unset, performs those operations, and outputs a slim-flat file of records that need updating. 

## Steps
1) Compile a list of bibs to add as a `flat` file. [An example of how EPL does this can be found here](#flat-files), but it is easier to use the script [`flatcat.sh`](#flatcatsh). 
2) Compile a list of holdings to remove from a holdings report from the OCLC customer support portal.
   2) [Creating a holdings report by hand](#oclc-holdings-report).
   3) [Creating a holdings report with `report.py`](#report-driver-reportpy). report.py.
3) Run `oclc4.py` with [appropriate flags](#features). For example:

```bash
python3 oclc4.py --add='cat_recs.flat' --report='oclc_report.csv'
```
See [how it works](#how-it-works)
4) TODO: Update ILS with flat file updates.

## Features
Here are the flags of features that `oclc4.py` uses.
* `--add` [List of bib records to add as holdings. This flag can read both `flat` and `mrk` format](#add-flag).
* `--config` Optional alternate configurations for running `oclc.py` and `report.py`. The default behaviour looks for a file called `prod.json` in the working directory.
* `-d` or `--debug` Turns on debugging.
* `--delete` List of OCLC numbers to delete as holdings.
* `--report` [(Optional) OCLC's holdings report in CSV format which will used to normalize the add and delete lists](#report-flag).
* `--recover` [Used to recover a previously interrupted process](#recover-flag).
* `--version` Prints the application's version.

# How It Works
1) An input file of MARC records in either Symphony [**flat**](#flat-files) or MarcEdig [**mrk**](#mrk-files) format is used to set holdings with OCLC. Either file format is parsed for OCLC numbers in the `035` field.
1) Holdings can be deleted from OCLC via a list in the form of a **CSV** [`--report`](#report-flag) from OCLC. Alternatively unset holding numbers can be read from a text file with the `--delete` flag.
1) In either case the [`delete`](#delete-flag) list is compared to the `add` list. OCLC numbers that appear in both lists are ignored.
1) The uniq adds and delete requests are made to OCLC through their [WorldCat Metadata API](#web-service-api-keys). Any reported changes are recorded for the next step. 
1) The original flat file (if provided) is referenced to create a [**slim**](#example-of-a-slim-flat-file) flat file for updating library's MARC records using [`catalogmerge`](#catalogmerge). This process is not automated.

The process can take quite a long time for a big catalog and if interrupted, the application will make checkpoint files so the process can be restarted with the `--recover` flag.

### Add Flag
Used to specify the records to 'set' as holdings. The records are [`flat`](#flat-files) or [`mrk`](#mrk-files) records. The records will be used later to update the bibs in the ILS.

### Configuration File
By default `oclc4.py` uses configurations taken from `prod.json` in the working directory, but an alternate can be specified with the `--config` flag. A use case is if you have access to a sandbox for testing, then an alternate config.json can be specified with this flag ([see below](#sample-configuration-file)) 

At the time of writing any config file should contain all the following configs with the exception of the `rejectTags` dictionary, which is optional.

**Reject Tags**
Any bib record that matches a reject tag and content will be ignored. This allows for fine-grained record filtering.

#### Sample Configuration File
```json
{
  "clientId": "generated by OCLC",
  "secret":   "generated by OCLC",
  "scope": "WorldCatMetadataAPI",
  "authUrl": "https://oauth.oclc.org/token",
  "baseUrl": "https://metadata.api.oclc.org/worldcat",
  "reportUserId": "user name",
  "reportPassword": "user password",
  "reportLoginHomePage": "https://www.oclc.org/en/services/logon.html",
  "reportWaitMinutes": "120",
  "reportInstitution": "CNEDM",
  "reportName": "roboto_report",
  "reportDownloadDirectory": "/home/anisbet/Downloads",
  "oclcHoldingsListName": "./deletes",
  "bibOverlayFileName": "./bib_overlay",
  "rejectTags": {   
    "250": "On Order"
  },
  "requestTimeout": 10
}
```
* `clientId` is the web service client ID that identifies your institution and is assigned by OCLC.
* `secret` is your web services password in effect, though it is assigned by OCLC when you successfully [apply for web services keys](https://platform.worldcat.org/wskey/). [See here for more information about how to apply](https://www.oclc.org/developer/develop/authentication/how-to-request-a-wskey.en.html).
* `scope` refers to the scope of services accessible once the application authenticates.
* `reportUserId` and `reportPassword` are the user name and password you would use to log into the OCLC portal to order a report.
* `reportWaitMinutes` refers to the time between ording the report and it being ready to download.
* `reportInstitution` institutional ID of your library.
* `reportName` is the prefix of the name of the report. OCLC uses this along with a timestamp to name the holdings report to download.
* `oclcHoldingsListName` is the prefix for the deletes list. The actual list will include a date in ANSI format, for example `deletes_20240926.lst`.
* `bibOverlayFileName` is the prefix of the bib overlay file. The actual file will include a date in ANSI format, for example `bib_overlay_20240926.flat`.
* Multiple `rejectTags` can be specified along with additional filtering information.
* `requestTimeout` refers to the time a web service call can hang before the application considers the connection dropped. If that occurs, the remaining adds and deletes are output to JSON, to be used as input with the `--recover` flag.

### Delete Flag
Specifies the file name that contains a list of OCLC numbers, one-per-line that are to be 'unset'. `oclc4.py` makes the best effort to delete holdings, and will try 2 different techniques to remove a local holding.
1) Unset holding.
2) If 'unset' fails, use alternate web service call to delete their record remotely.

### Recover Flag
This version saves the records and their state during processing. If the process receives `<ctrl-C>` the current state of delete and add lists are saved to JSON files. When the process restarts it uses these files to continue. See `--recover`

### Report Flag
This optional flag specifies the OCLC CSV report which is used to remove add records that are already holdings, and report delete numbers that OCLC doesn't have as holdings for your library.

## Web Service API Keys
[Renew or request keys here](https://platform.worldcat.org/wskey/).

# Flat Files
Flat files are a specific type of MARC21 catalog record format used by Sirsi Dynix's Symphony ILS, and are human-readable.

## Example
```console
*** DOCUMENT BOUNDARY ***
FORM=VM
.000. |agm a0n a
.001. |aocn782078599
.005. |a20170720213947.0
.007. |avd cvaizs
.008. |a120330p20122011mdu598 e          vleng d
.028. 40|aAMP-8773
.035.   |a(Sirsi) 782078599
.035.   |a(CaAE) o782078599
.040.   |aWC4|cWC4|dTEF|dIEP|dVP@|dUtOrBLW
.999.   |hShould end up for testing with match API.
```

## Example of a Slim Flat File
```console
*** DOCUMENT BOUNDARY ***
FORM=MUSIC                      
.001. |a7755731     
.035.   |a(OCoLC)1000001234|z(OCoLC)987654321
.035.   |a(Sirsi) on1347755731
.035.   |a(EPL) on1347755731
```

## Example `oclc_update_adds.json`
This is a backup file created if the process was interrupted. The `adds` are saved as JSON because they are later used to generate slim FLAT files for merging modified records back into the catalog.

The `action` tells the processor what has to happen to the record. There are 'n' different actions. 
* updated - the record has a new OCLC number and needs to be included in the slim-FLAT overlay file.
* done - the record was processed successfully.
* ignore - nothing needs to be done to this record.
* set - set the record as a holding.
* unset - unset the record as a holding.

```json
[
  {
    "data": [
      "*** DOCUMENT BOUNDARY ***",
      "FORM=MARC",
      ".000. |aam i0n a",
      ".001. |a2104230",
      ".008. |a210815s2022    nyua   e b    000 0aeng  ",
      ".010.   |a  2021033001",
      ".020.   |a1538734168",
      ".020.   |a9781538734162",
      ".035.   |aLSC4227812",
      ".040.   |aLBSOR/DLC|beng|erda|cDLC",
      ".043.   |an-us---",
      ".050. 00|aR154.S55|bA3 2022",
      ".082. 00|a617.092|aB|223",
      ".092.   |a617.092 SHR",
      ".100. 1 |aShrime, Mark.",
      ".245. 10|aSolving for why :|ba surgeon's journey to discover the transformative power of purpose /|cMark Shrime.",
      ".250.   |aFirst edition.",
      ".264.  1|aNew York :|bTwelve,|c2022.",
      ".300.   |axii, 253 pages :|billustrations",
      ".336.   |atext|btxt|2rdacontent",
      ".336.   |astill image|bsti|2rdacontent",
      ".337.   |aunmediated|bn|2rdamedia",
      ".338.   |avolume|bnc|2rdacarrier",
      ".504.   |aIncludes bibliographical references and Internet addresses.",
      ".520.   |a\"SOLVING FOR WHY chronicles one man's journey to find the answer to the biggest of all life's questions: \"Why?\".",
      ".600. 10|aShrime, Mark.",
      ".650.  0|aSurgeons|zUnited States|vBiography.",
      ".650.  0|aTraffic accident victims|zUnited States|vBiography.",
      ".650.  0|aSocial medicine.",
      ".650.  0|aSelf-realization.",
      ".949.   |a617.092 SHR|wDEWEY|i31221122366748|kON-ORDER|lNONFICTION|mEPLZORDER|p29.83|tBOOK|xNONFIC|zADULT",
      ".949.   |a617.092 SHR|wDEWEY|i31221122366730|kON-ORDER|lNONFICTION|mEPLZORDER|p29.83|tBOOK|xNONFIC|zADULT",
      ".596.   |a12 16"
    ],
    "rejectTags": {
      "250": "On Order"
    },
    "action": "updated",
    "encoding": "utf-8",
    "tcn": "2104230",
    "oclcNumber": "1266203700",
    "previousNumber": ""
  },
  {
    "data": [
      "*** DOCUMENT BOUNDARY ***",
      "FORM=MARC",
      ".000. |aam i0c a",
      ".001. |a2104186",
      ".008. |a210706s2022    nyu    e b    000 0 eng d",
      ".010.   |a   2021033002",
      ".020.   |a1546016120",
      ".020.   |a9781546016120",
      ".035.   |aLSC4227826",
      ".040.   |aDLC|beng|erda|cDLC|dGCmBT|dNjBwBT",
      ".082. 04|a241/.4|223",
      ".092.   |a241.4 MEY",
      ".100. 1 |aMeyer, Joyce,|d1943-",
      ".245. 14|aThe power of thank you :|bdiscover the joy of gratitude /|cJoyce Meyer.",
      ".250.   |aFirst edition.",
      ".264.  1|aNew York :|bFaithWords,|c2022.",
      ".300.   |aix, 190 pages ;|c22 cm",
      ".336.   |atext|btxt|2rdacontent",
      ".337.   |aunmediated|bn|2rdamedia",
      ".338.   |avolume|bnc|2rdacarrier",
      ".504.   |aIncludes bibliographical references.",
      ".520.   |a\"Adopt a lifestyle of thanksgiving and discover that no matter how messy life gets, God will make it good. Each moment that you're given is a precious gift from God. You can choose to have a thankful attitude and live each moment full of joy.",
      ".650.  0|aGratitude|xReligious aspects|xChristianity.",
      ".650.  0|aJoy|xReligious aspects|xChristianity.",
      ".949.   |a241.4 MEY|wDEWEY|i31221122366672|kON-ORDER|lNONFICTION|mEPLZORDER|p25.70|tBOOK|xNONFIC|zADULT",
      ".949.   |a241.4 MEY|wDEWEY|i31221122366680|kON-ORDER|lNONFICTION|mEPLZORDER|p25.70|tBOOK|xNONFIC|zADULT",
      ".949.   |a241.4 MEY|wDEWEY|i31221122366698|kON-ORDER|lNONFICTION|mEPLZORDER|p25.70|tBOOK|xNONFIC|zADULT",
      ".596.   |a11 18"
    ],
    "rejectTags": {
      "250": "On Order"
    },
    "action": "done",
    "encoding": "utf-8",
    "tcn": "2104186",
    "oclcNumber": "1250204558",
    "previousNumber": ""
  }, ...
]
```

## Flatcat.sh
`flatcat.sh` searches for all catalog records filtering out records if they only contains OCLC-restricted materials, which are records you don't want to show up in [WorldCat searches](https://search.worldcat.org/).

The records within the flat file can be filtered further with the use of [rejectTags](#config-flag) in the configuration JSON.

## Flat Files Manually
The Sympony API to collect *all* records for **adding** as follows.
```bash
selitem -t"~PAPERBACK,JPAPERBACK,BKCLUBKIT,COMIC,DAISYRD,EQUIPMENT,E-RESOURCE,FLICKSTOGO,FLICKTUNE,JFLICKTUNE,JTUNESTOGO,PAMPHLET,RFIDSCANNR,TUNESTOGO,JFLICKTOGO,PROGRAMKIT,LAPTOP,BESTSELLER,JBESTSELLR" -l"~BARCGRAVE,CANC_ORDER,DISCARD,EPLACQ,EPLBINDERY,EPLCATALOG,EPLILL,INCOMPLETE,LONGOVRDUE,LOST,LOST-ASSUM,LOST-CLAIM,LOST-PAID,MISSING,NON-ORDER,BINDERY,CATALOGING,COMICBOOK,INTERNET,PAMPHLET,DAMAGE,UNKNOWN,REF-ORDER,BESTSELLER,JBESTSELLR,STOLEN" -oC 2>/dev/null | sort | uniq >oclc_catkeys.lst 
cat oclc_catkeys.lst | catalogdump -oF -kf >all_records.flat
# The oclc.py can read flat files.
```

To collect records from more recently requires a small alteration. In this case collect records added or updated in the last **90** days. You may choose <ins>not</ins> to use `-r` (updated records) because presumably those records were added prior to the last 90 days. This code was `batchload` which required the submission of new *and* updated records.
```bash
selitem -t"~PAPERBACK,JPAPERBACK,BKCLUBKIT,COMIC,DAISYRD,EQUIPMENT,E-RESOURCE,FLICKSTOGO,FLICKTUNE,JFLICKTUNE,JTUNESTOGO,PAMPHLET,RFIDSCANNR,TUNESTOGO,JFLICKTOGO,PROGRAMKIT,LAPTOP,BESTSELLER,JBESTSELLR" -l"~BARCGRAVE,CANC_ORDER,DISCARD,EPLACQ,EPLBINDERY,EPLCATALOG,EPLILL,INCOMPLETE,LONGOVRDUE,LOST,LOST-ASSUM,LOST-CLAIM,LOST-PAID,MISSING,NON-ORDER,BINDERY,CATALOGING,COMICBOOK,INTERNET,PAMPHLET,DAMAGE,UNKNOWN,REF-ORDER,BESTSELLER,JBESTSELLR,STOLEN" -oC 2>/dev/null | sort | uniq >oclc_ckeys.lst 
cat oclc_ckeys.lst | selcatalog -iC -p">`transdate -d-90`" -oC  >oclc_catalog_selection.lst
cat oclc_ckeys.lst | selcatalog -iC -r">`transdate -d-90`" -oC  >>oclc_catalog_selection.lst 
cat oclc_catalog_selection.lst | sort | uniq >oclc_catalog_selection.uniq.lst
# Output the flat records as a flat file.
# If the records don't wrap, pipe it to flatskip -if -aMARC -om >mixed.flat
# -oF outputs the flat record without linewrapping. 
# -kf outputs the flexkey TCN in the 001 field for matching. 
cat oclc_catalog_selection.uniq.lst | catalogdump -oF -kf >oclc_submission.flat
```

# MRK Files
The *mrk* file format is similar to a flat file in that it is human-readable, but is created by MarcEdit.

## Example
```console
=LDR 02135cjm a2200385 a 4500
=001 ocn769144454
=003 OCoLC
=005 20140415031111.0
=007 sd\fsngnnmmned
=008 111222s2012\\\\nyu||n|j|\\\\\\\\\|\eng\d
=024 1\$a886979578425
=028 00$a88697957842
=035 \\$a(Sirsi) a1001499
=035 \\$a(Sirsi) a1001499
=035 \\$a(OCoLC)769144454
=035 \\$a(CaAE) a1001499
=040 \\$aTEFMT$cTEFMT$dTEF$dBKX$dEHH$dNYP$dUtOrBLW
=050 \4$aM1997.F6384$bF47 2012
=082 04$a782.42/083$223
=099 \\$aCD J SNDTRK FRE
```

## OCLC Holdings Report
A great way to avoid a reclamation project is to use an OCLC holdings report as a `--delete` list.

1) Create a report of all the titles from the library by logging into OCLC's [WorldShare Administration Portal](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary). For EPL the URL is [https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary) but your library will have it's own portal.
2) Once logged in select the `Analytics` navigate to `Collection Evaluation` and then click the `My Library` button.
3) Below the summary table, select `Export Title List` button, give the report a name and description (optional), and dismiss the dialog box telling you how long it will take. Expect at least **1.5+ hours**.
4) After the appropriate time has elapsed, re-login to the [portal](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary) and navigate to the `Analytics` tab. Select the `My Files` menu on the left margin of the page, click the `Download Files` button. Download, and unzip the compressed '.xls.zip' report which is just a CSV and can be read as a text file.

### Report Driver (report.py)
This application uses web scraping techniques to login, generate, download, and parse a report from the OCLC customer portal. The app uses the `prod.json` file for user credentials and other settings. The app can login, navigate the portal to set up a report, will wait for the report to finish based on a pre-set delay or a delay specified by the portal if possible.

Once the delay has expired, it will navigate to the download page (logging back in if necessary) and download all the reports it finds there. It will even download hidden reports, however it will only process the *latest* file that starts with the `reportName` specified in the `prod.json` file.

#### Setup for Report Driver (report.py)
1) `pip install selenium`
2) Download the Geckodriver from [here](https://github.com/mozilla/geckodriver/releases)
   1) `mkdir $HOME/bin` if you don't already have one.
3) Untar the tarball into `$HOME/bin`.
4) `chmod +x $HOME/bin/geckodriver`
5) The current version (`0.34.0`) on `Ubuntu 22.04` requires a `tmp` directory.
   1) `mkdir $HOME/tmp`
   2) Edit `~/.bashrc` to `export TMPDIR="$HOME/tmp"`.
   3) `. ~/.bashrc` 

### Using OCLC's Report as XLS and CSV Files
Although OCLC produces reports in compressed XLS files, they are, in fact, just CSV files with an '.xls' extension.

All CSV files are assumed to be created from the OCLC holdings report, here is an example.
```bash
=HYPERLINK("http://www.worldcat.org/oclc/1834", "1834")	Book, Print	Juvenile ...
```

## Updating the Library's Catalog Records
The `oclc.py` will use information in oclc's responses to create a slim-flat file for overlaying updated OCoLC numbers in the `035` tag. The slim-flat file can then be used with Symphony's [`catalogmerge`](#catalogmerge) API command to update the ILS.

**Note:** [`catalogmerge`](#catalogmerge) can either delete all the `035` tags or add the new one(s) to the record. I have opted to use the delete option to avoid duplicates. This requires preserving all non-OCLC `035` tags and replacing the OCLC tags with updated values. See below.

```console
*** DOCUMENT BOUNDARY ***
FORM=MUSIC                      
.001. |a7755731     
.035.   |a(OCoLC)1000001234|z(OCoLC)987654321
.035.   |a(Sirsi) on1347755731
.035.   |a(EPL) on1347755731
  ...
```

### Catalogmerge
Once done, Symphony's `catalogmerge` is used to update the bib record with the slim file.

```bash
# -if flat ascii records will be read from standard input.
# -aMARC (required) specifies the format of the record.
# -b is followed by one option to indicate how bib records will be matched
#       for update.
#     c matches on the internal catalog key.
#     f(default) matches on the flexible key.
#     n matches on the call number key.
# -d delete all existing occurrences of entries being merged.
# -f is followed by a list of options specifying how to use the flexible key.
#    g use the local number as is (001). *TCN*
# -r reorder record according to format.
# -l Use the format to determine the tags to be merged. If the tag is
#      marked as non-repeatable, do not merge if the Symphony record contains
#      the tag. If the tag is non-repeatable, and the Symphony record does not
#      contain the tag, merge the tag into Symphony. If the tag is marked as
#      repeatable, the tag will be merged. This option is not valid if
#      the '-t' is used. If this '-t' is not used, this option is required.
#  == or ==
# -t list of entry id's to merge. This option is not valid if the '-l' is
#      used. If the '-l' is not specified, the '-t' is required.

cat oclc_overlay_YYYYMMDD.flat | catalogmerge -if -aMARC -bf -fg -d -r -t035 2>oclc_update_YYYYMMDD.err >oclc_update_YYYYMMDD.lst
```

## Firefox Installation
To delete the `snap` version and install Firefox by `apt-get` from now on, [do the following](https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04#:%7E:text=Installing%20Firefox%20via%20Apt%20(Not%20Snap)&text=You%20add%20the%20Mozilla%20Team,%2C%20bookmarks%2C%20and%20other%20data.).

```bash
oclc4$ sudo snap remove firefox
[sudo] password for xxxxxxx: 
firefox removed
oclc4$ sudo install -d -m 0755 /etc/apt/keyrings
oclc4$ wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
oclc4$ echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
oclc4$ echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1' | sudo tee /etc/apt/preferences.d/mozilla
oclc4$ sudo apt update
oclc4$ sudo apt install firefox
```
