This test takes mrk data converts it to XML
===========================================

>>> from record import Record
>>> from ws2 import WebService, MatchWebService

Test with flat file with parsing errors
=======================================
>>> r = []
>>> with open('test/match0.flat', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         r.append(line)
>>> rec = Record(r)
>>> print(rec.asXml(useMinFields=True))
<?xml version="1.0" encoding="UTF-8"?><record><leader>00000nam a2200000 i 4500</leader><controlfield tag="001">1853247</controlfield><controlfield tag="008">170325s2017    nyua   e b    000 0 eng  </controlfield><datafield tag="010" ind1=" " ind2=" "><subfield code="a">  2017012758</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">DLC</subfield><subfield code="b">eng</subfield><subfield code="e">rda</subfield><subfield code="c">DLC</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Kagge, Erling.</subfield></datafield><datafield tag="245" ind1="1" ind2="0"><subfield code="a">Silence :</subfield><subfield code="b">in the age of noise /</subfield><subfield code="c">Erling Kagge ; translated from the Norwegian by Becky L. Crook.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Translation of: Stillhet i st&#xF8;yens tid.</subfield></datafield></record>


Test match web MatchWebService
------------------------------
>>> ws = MatchWebService('prod.json')
>>> ws.sendRequest(rec.asXml(useMinFields=True))
{'numberOfRecords': 3, 'briefRecords': [{'oclcNumber': '985966747', 'title': 'Silence : in the age of noise', 'creator': 'Erling Kagge', 'date': '2017', 'machineReadableDate': '2017', 'language': 'eng', 'generalFormat': 'Book', 'specificFormat': 'PrintBook', 'edition': 'First American edition', 'publisher': 'Pantheon Books', 'publicationPlace': 'New York', 'isbns': ['9781524733230', '1524733237', '9780525563648', '0525563644'], 'issns': [], 'mergedOclcNumbers': ['976088885', '976295603', '1011349214', '1126073980', '1141760546', '1298702241', '1446395465'], 'catalogingInfo': {'catalogingAgency': 'DLC', 'catalogingLanguage': 'eng', 'levelOfCataloging': ' ', 'transcribingAgency': 'DLC'}}]}