Tests for RecordManager Web Service Calls
=========================================
This is a separate file to speed up and simplify testing 
different parts of the oclc4 pipeline. The results of 
the tests may vary over time since Local Bib Records will get 
added and others deleted. Having a separate file isolates 
issues to either the web service or machinations of oclc4.py.


>>> from oclc4 import RecordManager

Test match holdings method
--------------------------
TODO: fix record so it can read delimiters other than '|a', then retest.
It looks like this
*warning invalid syntax on '.264.  4|c℗2012'
*warning invalid syntax on '.505. 00|tNew Orleans after the city|r(Hot 8 Brass Band) --|tFrom the cornerto the block|r(Galactic, Juvenile, Dirty Dozen Brass Band) --|tCarved in stone|r(the Subdudes) --|tSisters|r(John Boutté, Michiel Huisman, Lucia Micarelli,Paul Sanchez) --|tSpring can really hang you up the most|r(David Torkanowsky &Lucia Micarelli) --|tHeavy Henry|r(Tom McDermott, Evan Christopher, LuciaMicarelli) --|tMama Roux|r(Henry Butler) --|tWhat is New Orleans?|r(KermitRuffins & the Barbeque Swingers) --|tTake it to the street|r(Rebirth BrassBand) --|tRoad home|r(DJ Davis & the Brassy Knoll) --|tOye, Isabel|r(theIguanas) --|tLong hard journey home|r(the Radiators) --|tCarnival time|r(Al"Carnival Time" Johnson & the Soul Apostles) --|tLa danse de Mardi Gras|r(SteveRiley, Steve Earle, & the Faquetaique Mardi Gras) --|tFerry man|r(AuroraNealand & the Red [i.e. Royal] Roses) --|tFrenchmen street blues|r(Jon Cleary)--|tHu ta nay|r(Donald Harrison & friends) --|tYou might be surprised|r(Dr.John).'
DEBUG: url=https://metadata.api.oclc.org/worldcat/manage/bibs/match
DEBUG: response code 200 headers: '{'Date': 'Thu, 21 Dec 2023 00:13:02 GMT', 'Content-Type': 'application/json;charset=UTF-8', 'Content-Length': '546', 'Connection': 'keep-alive', 'x-amzn-RequestId': '28d14bb7-7127-414e-8156-3e0b2cd388c4', 'X-XSS-Protection': '1; mode=block', 'X-Frame-Options': 'DENY', 'x-amzn-Remapped-Connection': 'keep-alive', 'x-amz-apigw-id': 'QRFqMEW8iYcEq6A=', 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate', 'Expires': '0', 'X-Content-Type-Options': 'nosniff', 'Pragma': 'no-cache', 'x-amzn-Remapped-Date': 'Thu, 21 Dec 2023 00:13:02 GMT'}'
    content: 'b'{"numberOfRecords":1,"briefRecords":[{"oclcNumber":"779882439","title":"Treme. Season 2 : music from the HBO original series","creator":"Juvenile","date":"\xe2\x84\x972012","machineReadableDate":"\xe2\x84\x972012","language":"eng","generalFormat":"Music","specificFormat":"CD","edition":"","publisher":"Rounder","publicationPlace":"Beverly Hills, CA","isbns":["9786314663087","6314663083"],"issns":[],"mergedOclcNumbers":["1014287877"],"catalogingInfo":{"catalogingAgency":"BTCTA","catalogingLanguage":"eng","levelOfCataloging":"I","transcribingAgency":"BTCTA"}}]}''

# >>> recman = RecordManager()
# >>> recman.readFlatOrMrkRecords('test/testD.flat')
# >>> recman.matchHoldings(debug=True)
# True




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
unsetHoldings found 1 errors
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
setHoldings found 0 errors
True
>>> recman.showResults()
Process Report: 0 error(s) reported.