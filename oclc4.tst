Tests for RecordManager
=======================

>>> from oclc4 import RecordManager
>>> from os.path import exists
>>> import os


Test cleanup and restoreState
-----------------------------

>>> recman = RecordManager()
>>> recman.readDeleteList('test/del00.lst')
>>> recman.readHoldingsReport('test/report.csv')
>>> recman.readFlatOrMrkRecords('test/add03.flat')
>>> recman.showState(debug=True)
2 delete record(s)
['177677', '1234567']
2 add record(s)
['12345678', '99999999']
0 record(s) to check
0 rejected record(s)


Save the lists 
--------------
>>> recman.saveState()
adds state saved to oclc_update_adds.json
deletes state saved to oclc_update_deletes.json
>>> recman = RecordManager()


Restore the lists 
-----------------
>>> recman.restoreState()
reading oclc_update_adds.json
adds state restored successfully from oclc_update_adds.json 
deletes state restored successfully from oclc_update_deletes.json 
True
>>> recman.showState(debug=True)
2 delete record(s)
['177677', '1234567']
2 add record(s)
['12345678', '99999999']
0 record(s) to check
0 rejected record(s)


Test _test_file_ and clean up after save and restore state tests 
----------------------------------------------------------------

>>> tested = recman._test_file_('oclc_update_adds.json')
>>> if tested[0] == True:
...     os.unlink('oclc_update_adds.json')
>>> tested = recman._test_file_('oclc_update_deletes.json')
>>> if tested[0] == True:
...     os.unlink('oclc_update_deletes.json')

Test normalizeLists method
--------------------------

Test that just adding a holdings report has no effect.
>>> recman = RecordManager()
>>> recman.readHoldingsReport('test/report.csv')
>>> recman.normalizeLists()
0 delete record(s)
0 add record(s)
0 record(s) to check
0 rejected record(s)

Test deletes
------------
Test that we can delete an OCLC number listed as a holding but not one that isn't
>>> recman.readDeleteList('test/del00.lst')
>>> recman.normalizeLists()
1 delete record(s)
0 add record(s)
0 record(s) to check
1 rejected record(s)
1234567: OCLC has no such holding to delete

Test that we add a record that OCLC doesn't have a holding.
>>> recman = RecordManager()
>>> recman.readHoldingsReport('test/report.csv')
>>> recman.readFlatOrMrkRecords('test/add02.flat')
>>> recman.normalizeLists()
0 delete record(s)
1 add record(s)
0 record(s) to check
0 rejected record(s)

>>> recman = RecordManager()
>>> recman.readDeleteList('test/del02.lst')
>>> recman.normalizeLists()
1 delete record(s)
0 add record(s)
0 record(s) to check
1 rejected record(s)
12345678: duplicate delete request; ignoring


Test adds
---------
Test that duplicate add request ignores the second add request.
>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/add04.flat')
>>> recman.normalizeLists()
0 delete record(s)
1 add record(s)
0 record(s) to check
1 rejected record(s)
12345678: duplicate add request

This test makes sure records with no OCLC number end up on the matches list
>>> recman = RecordManager()
>>> recman.readHoldingsReport('test/report.csv')
>>> recman.readFlatOrMrkRecords('test/add01.flat')
>>> recman.normalizeLists(debug=True)
0 delete record(s)
[]
0 add record(s)
[]
1 record(s) to check
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
0 rejected record(s)

Test that a add request when OCLC already has a holding is rejected.
>>> recman = RecordManager()
>>> recman.readHoldingsReport('test/report.csv')
>>> recman.readFlatOrMrkRecords('test/add00.flat')
>>> recman.normalizeLists()
0 delete record(s)
0 add record(s)
0 record(s) to check
1 rejected record(s)
1381679000: already a holding

Test that a add request that contradicts a delete request is rejected and the record is removed from the delete list.
>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/add03.flat')
>>> recman.readDeleteList('test/del01.lst')
>>> recman.normalizeLists()
1 delete record(s)
1 add record(s)
0 record(s) to check
1 rejected record(s)
12345678: previously requested as a delete; ignoring

Test repeated calls to add longer deletes, adds, and holdings report work.
>>> recman.readFlatOrMrkRecords('test/addlong.flat')
>>> recman.readDeleteList('test/deletelong.lst')
>>> recman.normalizeLists()
4 delete record(s)
4 add record(s)
1 record(s) to check
3 rejected record(s)
12345678: previously requested as a delete; ignoring
3333: previously requested as a delete; ignoring
1111: duplicate add request

Test all together with new object.
>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/addlong.flat')
>>> recman.readDeleteList('test/deletelong.lst')
>>> recman.readHoldingsReport('test/holdingssmall.csv')
>>> recman.normalizeLists(debug=True)
3 delete record(s)
['5555', '4444', '0000']
2 add record(s)
['1111', '2222']
1 record(s) to check
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
3 rejected record(s)
6666: OCLC has no such holding to delete
3333: previously requested as a delete; ignoring
1111: duplicate add request

Test readHoldingsReport method
------------------------------
>>> recman = RecordManager()
>>> recman.readHoldingsReport('test/report_broken.txt', debug=True)
The holding report is missing, empty or not the correct format. Expected a .csv (or .tsv) file.

>>> recman.readHoldingsReport('test/report.csv', debug=True)
loaded 19 delete records: ['267', '1210', '1834', '171857']...


Test _test_file_
----------------
>>> recman = RecordManager()
>>> recman._test_file_('test/delete.json')
[True, 'test/delete', '.json']

>>> recman._test_file_('test/delete')
The test/delete file is empty (or missing).
[False, 'test/delete', '']

>>> recman._test_file_('.flag')
The .flag file is empty (or missing).
[False, '.flag', '']


Test readDeleteList
-------------------
>>> recman = RecordManager()
>>> recman.readDeleteList('test/delete.lst', debug=True)
loaded 100 delete records: ['1381363338', '1381363342', '1381363412', '1381364833']...

>>> recman = RecordManager()
>>> recman.readDeleteList('test/delete.json', debug=True)
loaded 100 delete records: ['1381363338', '1381363342', '1381363412', '1381364833']...

Test readFlatOrMrkRecords
-------------------------
 
>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/testB.flat', debug=True)
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.000. |ajm  0c a
.001. |aocn779882439
.003. |aOCoLC
.005. |a20140415031115.0
.007. |asd fungnnmmneu
.008. |a120307s2012    cau||n|e|i        | eng d
.035.   |a(Sirsi) o779882439
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779882439
.650.  0|aTelevision music|zUnited States.
*** DOCUMENT BOUNDARY ***
FORM=VM
.000. |agm a0n a
.001. |aocn782078599
.003. |aOCoLC
.005. |a20170720213947.0
.007. |avd cvaizs
.008. |a120330p20122011mdu598 e          vleng d
.028. 40|aAMP-8773
.035.   |a(OCoLC)782078599
.035.   |a(CaAE) o782078599
.040.   |aWC4|cWC4|dTEF|dIEP|dVP@|dUtOrBLW
.999.   |hEPLZDVD


Test logit
----------
>>> from oclc4 import logit
>>> logit("Something happened")
Something happened
>>> bad_mojo = ['this happened', 'then this', 'and finally this of all things.']
>>> logit(bad_mojo, level='error')
*error, this happened
*error, then this
*error, and finally this of all things.


The following tests will fail because they include timestamps which changes. 
Recomment them out after testing.
# >>> logit("Something happened", timestamp=True)
# Something happened
# >>> logit(bad_mojo, level='error', timestamp=True)
# [2023-12-12 16:32:18] *error, this happened
# [2023-12-12 16:32:18] *error, then this
# [2023-12-12 16:32:18] *error, and finally this of all things.

Test dumping json
-----------------

>>> d = [
...     {
...     "numberOfRecords": 1,
...     "briefRecords": [
...         {
...             "oclcNumber": "1236899214",
...             "title": "Cats!",
...             "creator": "Erica S. Perl",
...             "date": "2021",
...             "machineReadableDate": "2021",
...             "language": "eng",
...             "generalFormat": "Book",
...             "specificFormat": "PrintBook",
...             "edition": "",
...             "publisher": "Random House",
...             "publicationPlace": "New York",
...             "isbns": [
...                 "9780593380321",
...                 "0593380320",
...                 "9780593380338",
...                 "0593380339",
...                 "9781544460291",
...                 "1544460295"
...             ],
...             "issns": [],
...             "mergedOclcNumbers": [
...                 "1237101016",
...                 "1237102366",
...                 "1276783496",
...                 "1276798734",
...                 "1281721227",
...                 "1285930950",
...                 "1288704071",
...                 "1289594397",
...                 "1289941124",
...                 "1305859745"
...             ],
...             "catalogingInfo": {
...                 "catalogingAgency": "DLC",
...                 "catalogingLanguage": "eng",
...                 "levelOfCataloging": " ",
...                 "transcribingAgency": "DLC"
...             }
...         }
...     ]
... }]
>>> rm = RecordManager()
>>> test_json_file = 'test.json'
>>> rm.dumpJson(fileName=test_json_file, data=d)
>>> exists(test_json_file)
True
>>> e = rm.loadJson(test_json_file)
>>> d == e
True
>>> if d == e:
...     os.unlink(test_json_file)
