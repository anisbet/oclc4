# TODO
## Add batch processing
Typically there are thousands of records to send and the web service sometimes stops responding. 
* Detect timeout delay of more than {config} seconds.
* Save the unprocessed files.
* Log the event.
* Optionally restart after {config} delay has elapsed.

# What's New?
* The application has moved to a batch process, which means that if OCLC drops the connection, after a configurable amount of time, the remaining list of adds and deletes are written to restorable files and the application exits. The timeout setting can be set in `prod.json:"requestTimeout"` for web service request timeout: 10 seconds is done with `'requestTimeout': 10`.


# Quick Start
## The Deletes List
If you are already familiar with `oclc4.py`, but just need a refresher or order of operations for the command line, here it is.
1) Order a new report from OCLC: `python report.py --order`. This uses webscraping techniques via the customer portal, and may issue an error like 'Couldn't find time estimate dialog box!'. That doesn't matter, the report will be crunching away at the OCLC end.
2) In about 1.5 hours get the report: `python report.py --download`. The file will be found in the browsers default download directory, unzipped, and compiled into a file of delete numbers called `prod.json:oclcHoldingsListName` by default in the current working directory.

## The Adds List
Run the following on the ILS.
1) `cd sirsi@ils.com:~/Unicorn/EPLwork/anisbet/OCLC`
2) `./flatcat.sh`. This could take 8 minutes or so, and create a file called `./bib_records_[YYYYMMDD].zip`. Move this file to the server that will run `oclc4.py` and 
3) Unzip with `unzip ./bib_records_[YYYYMMDD].zip`. The unzipped version of the file is called `./bib_records_[YYYYMMDD].flat`. This is used as the `--add` input.

## Putting it Together
Now with both lists you can run the application.
1) `python3 oclc4.py --add='bib_records_[YYYYMMDD].flat' --report='oclc_report.csv'`

# Getting Started
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

### Config Flag
By default `oclc4.py` uses configurations taken from `prod.json` in the working directory. An example and explanation can found below, but if a different configuration is required for testing use this flag. 

At the time of writing any config file should contain all the following configs with the exception of the `rejectTags` dictionary, which is optional.

**Reject Tags**
Any bib record that matches a reject tag and content will be ignored. This allows for fine-grained record filtering.

```json
{
  "clientId": "generated by OCLC",
  "secret":   "generated by OCLC",
  "scope": "WorldCatMetadataAPI (literally)",
  "authUrl": "https://oauth.oclc.org/token",
  "baseUrl": "https://metadata.api.oclc.org/worldcat",
  "reportUserId": "user name",
  "reportPassword": "user password",
  "reportLoginHomePage": "https://www.oclc.org/en/services/logon.html",
  "reportWaitMinutes": "120( by default 2 hours)",
  "reportInstitution": "(Your institution code like )CNEDM",
  "reportName": "roboto_report( or whatever you like)",
  "reportDownloadDirectory": "/home/anisbet/Downloads",
  "oclcHoldingsListName": "./oclc.lst",
  "bibOverlayFileName": "./bib_overlay.flat( Only Symphony flat files are supported).",
  "rejectTags": {   
    "250": "On Order"
  },
  "requestTimeout": 10
}
```

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

cat oclc_updated.flat | catalogmerge -if -aMARC -bf -fg -d -r -t035  oclc_update_20230726.err >oclc_update_20230726.lst
```

