Tests for RecordManager Web Service Calls
=========================================
This is a separate file to speed up and simplify testing 
different parts of the oclc4 pipeline. The results of 
the tests may vary over time since Local Bib Records will get 
added and others deleted. Having a separate file isolates 
issues to either the web service or machinations of oclc4.py.


>>> from oclc4 import RecordManager

Test generating the slimflat file
---------------------------------

Based on records that were updated, write the results to a slimflat file.
>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/testC.flat')
>>> recman.setHoldings()
True
>>> recman.updateSlimFlat()
*** DOCUMENT BOUNDARY ***
FORM=VM
.001. |aocn782078599
.035.   |a(Sirsi) o782078599
.035.   |a(Sirsi) o782078599
.035.   |a(OCoLC)1259157052|z(OCoLC)782078600
.035.   |a(CaAE) o782078599


Test matchHoldings method
-------------------------




Test deleteLocalBibRecord method
--------------------------------
>>> recman = RecordManager()
>>> recman.deleteLocalBibData(oclcNumber='70826882', debug=True)
70826882 Unable to perform the lbd delete operation. The LBD is not owned
1


Test the unsetHoldings method
----------------------------- 
>>> recman = RecordManager()
>>> oclc_number_list = ['70826883', '1111111111111111', '70826883']
>>> recman.unsetHoldings(oclcNumbers=oclc_number_list, debug=True)
holding 70826883 removed
1111111111111111 not a listed holding
holding 70826883 removed
there were 1 errors
False


Test set holdings method.
-------------------------

>>> recman = RecordManager()
>>> recman.readFlatOrMrkRecords('test/add05.flat')
>>> recman.normalizeLists()
0 delete record(s)
3 add record(s)
0 record(s) to check
0 rejected record(s)
>>> recman.setHoldings(debug=True)
record -> {'data': ['*** DOCUMENT BOUNDARY ***', 'FORM=MUSIC', '.000. |ajm  0c a', '.001. |aocn779882439', '.003. |aOCoLC', '.005. |a20140415031115.0', '.007. |asd fungnnmmneu', '.008. |a120307s2012    cau||n|e|i        | eng d', '.035.   |a(Sirsi) o779882439', '.035.   |a(OCoLC)779882439', '.035.   |a(CaAE) o779882439', '.650.  0|aTelevision music|zUnited States.', '.999.   |hThis one is legit.'], 'rejectTags': {}, 'action': 'done', 'encoding': 'utf-8', 'tcn': 'ocn779882439', 'oclcNumber': '779882439', 'previousNumber': ''}
record -> {'data': ['*** DOCUMENT BOUNDARY ***', 'FORM=VM', '.000. |agm a0n a', '.001. |aocn1111111111111111', '.003. |aOCoLC', '.005. |a20170720213947.0', '.007. |avd cvaizs', '.008. |a120330p20122011mdu598 e          vleng d', '.028. 40|aAMP-8773', '.035.   |a(OCoLC)1111111111111111', '.035.   |a(CaAE) o782078599', '.040.   |aWC4|cWC4|dTEF|dIEP|dVP@|dUtOrBLW', '.999.   |hThis one should return a null control number.'], 'rejectTags': {}, 'action': 'match', 'encoding': 'utf-8', 'tcn': 'ocn1111111111111111', 'oclcNumber': '1111111111111111', 'previousNumber': ''}
record -> {'data': ['*** DOCUMENT BOUNDARY ***', 'FORM=VM', '.000. |agm a0n a', '.001. |aocn70826883', '.005. |a20170720213947.0', '.007. |avd cvaizs', '.008. |a120330p20122011mdu598 e          vleng d', '.028. 40|aAMP-8773', '.035.   |a(Sirsi) 782078599', '.035.   |a(CaAE) o782078599', '.035.   |a(OCoLC)70826883', '.040.   |aWC4|cWC4|dTEF|dIEP|dVP@|dUtOrBLW', '.999.   |hShould send a updated number.'], 'rejectTags': {}, 'action': 'updated', 'encoding': 'utf-8', 'tcn': 'ocn70826883', 'oclcNumber': '71340582', 'previousNumber': '70826883'}
True
>>> recman.showResults(debug=True)
Process Report: 0 error(s) reported.