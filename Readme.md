# Getting Started
OCLC needs to know what records your library has to make WorldCat searches and other services work effectively. Libraries are constantly adding and removing titles, so it is important to update OCLC about these changes. Up-to-date records help customers find materials in your collection. Stale records make customers grumpy.

Updating OCLC is a matter of sending records that are new, called **set**ting holdings, removing records you no longer have, called **unset**ting holdings.

During this process OCLC will provide feedback in the form of updated numbers if they have changed or merged numbers. These changes need to be reflected in your bibs.

## Adding Records to OCLC Holdings
A library will select records it considers of interest to OCLC and then compiles a Symphony `flat` file of these records for submission. This file is also used as the basis for a slim-flat file of records to overlay in the ILS.

## Deleting Records from OCLC Holdings
`oclc4` does away with searching logs for deleted titles. Instead it requests a holdings report and compares it to your collection. Then it compiles a list of records to set and unset, performs those operations, and outputs a slim-flat file of records that need updating. 

## Steps
1) Compile a list of bibs to add as a `flat` file. [An example of how EPL does this can be found here](#flat-files).
2) Compile a list of holdings to remove from a holdings report from the OCLC customer support portal.
   1) [Creating one by hand](#oclc-holdings-report).
   2) [Creating one with `report.py`](#report-driver-reportpy).
3) Compare and compile an `add`, or `delete` list with `oclc4.py`.
4) Run the update with `oclc4.py`

## Features
* `--add` [List of bib records to add as holdings. This flag can read both `flat` and `mrk` format](#add-flag).
* `--config` Configurations for running including OCLC web services and `report.py`.
* `-d` or `--debug` Turns on debugging.
* `--delete` List of OCLC numbers to delete as holdings.
* `--report` [(Optional) OCLC's holdings report in CSV format which will used to normalize the add and delete lists](#report-flag).
* `--recover` [Used to recover a previously interrupted process](#recover-flag).
* `--version` Prints the application's version.

### Add Flag
Used to specify the records to 'set' as holdings. The records are `flat` or `mrk` records. The records will be used later to update the bibs in the ILS.

### Config Flag
Specifys the JSON file that contains all the configuration settings needed to run `oclc4.py` and `report.py`. At the time of writing include the following.
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
  "reportWaitMinutes": "120 by default 2 hours",
  "reportInstitution": "Your institution code like CNEDM",
  "reportName": "roboto_report or whatever you like",
  "reportDownloadDirectory": "/home/anisbet/Downloads",
  "oclcHoldingsListName": "./oclc.lst",
  "bibOverlayFileName": "./bib_overlay.flat Only Symphony flat files are supported."
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

### Flat Files
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

```bash
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