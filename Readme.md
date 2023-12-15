## Features
This version saves the records and their state during processing. If the process receives `<ctrl-C>` the current state of delete and add lists are saved to JSON files. When the process restarts it uses these files to continue. See `--recover`

### Flat Files
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

The Sympony API to collect data for submission to OCLC is listed below.
```bash
selitem \ 
-t"~PAPERBACK,JPAPERBACK,BKCLUBKIT,COMIC,DAISYRD,EQUIPMENT,E-RESOURCE,FLICKSTOGO,FLICKTUNE,JFLICKTUNE,JTUNESTOGO,PAMPHLET,RFIDSCANNR,TUNESTOGO,JFLICKTOGO,PROGRAMKIT,LAPTOP,BESTSELLER,JBESTSELLR" \ 
-l"~BARCGRAVE,CANC_ORDER,DISCARD,EPLACQ,EPLBINDERY,EPLCATALOG,EPLILL,INCOMPLETE,LONGOVRDUE,LOST,LOST-ASSUM,LOST-CLAIM,LOST-PAID,MISSING,NON-ORDER,BINDERY,CATALOGING,COMICBOOK,INTERNET,PAMPHLET,DAMAGE,UNKNOWN,REF-ORDER,BESTSELLER,JBESTSELLR,STOLEN" \ 
-oC 2>/dev/null | sort | uniq >oclc_catkeys.lst 
cat oclc_catkeys.lst | catalogdump -oF -kf >all_records.flat
# The oclc.py can read flat files.
```

# Data Collection
The application supports reading lists in the following formats.
* [text files](#text-files) - lists of mrk or flat marc file that may have been grep-ed from a bib extract.
* [CSV](#csv-files) - specifically CSVs in the form of OCLC holdings reports.
* [Symphony FLAT files](#flat-files) - raw bib exports in flat format. This differes from text versions because the flat file can be updated with change suggestions from OCLC as an [additional process](#merging-lists-of-oclc-numbers).


## OCLC Holdings Report
A great way to avoid a reclamation project is to use an OCLC holdings report as a `--delete` list.

1) Create a report of all the titles from the library by logging into OCLC's [WorldShare Administration Portal](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary). For EPL the URL is [https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary) but your library will have it's own portal.
2) Once logged in select the `Analytics` tab and make sure you are on the page with the `My Library` heading. If not select `Collection Evaluation` and then the `My Library` button.
3) Below the summary table select `Export Title List` button, give the report a name and description if desired, and dismiss the dialog box telling you how long it will take. Expect at least **1.5+ hours**.
4) After the appropriate time has elapsed, re-login to the [portal](https://edmontonpl.share.worldcat.org/wms/cmnd/analytics/myLibrary) and navigate to the `Analytics` tab. Select the `My Files` menu on the left margin of the page, click the `Download Files` button. Download, and unzip the compressed XSL report.
5) You can use `excel` or `OpenOffice` to open and save as CSV.

### CSV Files
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
Once done we can use `catalogmerge` to update the bib record with the data from the slim file with the following.

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