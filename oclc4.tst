Tests for RecordManager
=======================

>>> from oclc4 import RecordManager
>>> from os.path import exists
>>> import os

Test readDeleteList
-------------------
>>> recman = RecordManager()
>>> recman.readDeleteList('test/delete.lst', debug=True)
loaded 100 delete records.

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
