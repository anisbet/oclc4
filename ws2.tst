Test specialized functions in the oclcws module

>>> from ws2 import WebService, SetWebService, UnsetWebService, MatchWebService
>>> from os.path import exists
>>> from os import unlink
>>> from record import Record

Test match web MatchWebService
------------------------------
>>> ws = MatchWebService('prod.json')
>>> r = [
... "=LDR 02135cjm a2200385 a 4500",
... "=001 LSC769144454",
... "=003 OCoLC",
... "=005 20140415031111.0",
... "=007 sd\\fsngnnmmned",
... "=008 111222s2012\\\\\\\\nyu||n|j|\\\\\\\\\\\\\\\\\\|\eng\\d",
... "=024 1\\$a886979578425",
... "=028 00$a88697957842",
... "=035 \\\\$a(Sirsi) a1001499",
... "=035 \\\\$a(CaAE) a1001499",
... "=040 \\\\$aTEFMT$cTEFMT$dTEF$dBKX$dEHH$dNYP$dUtOrBLW",
... "=050 \\4$aM1997.F6384$bF47 2012",
... "=082 04$a782.42/083$223",
... "=099 \\\\$aCD J SNDTRK FRE",
... "=245 04$aThe Fresh Beat Band$h[sound recording] :$bmusic from the hit TV show.",
... "=264 \\2$aNew York :$bDistributed by Sony Music Entertainment,$c[2012]",
... "=300 \\\\$a1 sound disc :$bdigital ;$c4 3/4 in.",
... "=336 \\\\$aperformed music$2rdacontent",
... "=337 \\\\$aaudio$2rdamedia",
... "=338 \\\\$aaudio disc$2rdacarrier",
... "=500 \\\\$aAt head of title: Nickelodeon.",
... "=500 \\\\$a\"The Fresh Beat Band (formerly The JumpArounds) is a children's TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)",
... "=500 \\\\$aContains 19 selections plus one bonus track.",
... "=511 0\\$aPerformed by Frest Beat Band.",
... "=596 \\\\$a3",
... "=650 \\0$aChildren's television programs$zUnited States$vSongs and music$vJuvenile sound recordings.",
... "=710 2\\$aFresh Beat Band.",
... ]
>>> record = Record(r)
>>> ws.sendRequest(record.asXml())
{'numberOfRecords': 2, 'briefRecords': [{'oclcNumber': '769144454', 'title': 'The Fresh Beat Band : music from the hit TV show', 'creator': 'Fresh Beat Band', 'date': '2012', 'machineReadableDate': '2012', 'language': 'eng', 'generalFormat': 'Music', 'specificFormat': 'CD', 'edition': '', 'publisher': 'Sony Music Entertainment', 'publicationPlace': 'New York', 'isbns': [], 'issns': [], 'mergedOclcNumbers': ['1014292698'], 'catalogingInfo': {'catalogingAgency': 'TEFMT', 'catalogingLanguage': 'eng', 'levelOfCataloging': ' ', 'transcribingAgency': 'DLC'}}]}

NOTE: for dev of the return match the entry of interest is 'mergedOclcNumbers': ['1014292698'],

Test SetWebService
------------------
>>> ws = SetWebService('prod.json')
>>> ws.sendRequest('70826882')
{'controlNumber': '70826882', 'requestedControlNumber': '70826882', 'institutionCode': '44376', 'institutionSymbol': 'CNEDM', 'firstTimeUse': False, 'success': True, 'message': 'WorldCat Holding already set.', 'action': 'Set Holdings'}


Test UnsetWebService
--------------------
>>> ws = UnsetWebService('prod.json')
>>> ws.sendRequest('70826882')
{'controlNumber': '70826882', 'requestedControlNumber': '70826882', 'institutionCode': '44376', 'institutionSymbol': 'CNEDM', 'firstTimeUse': False, 'success': False, 'message': 'Unset Holdings Failed. Local bibliographic data (LBD) is attached to this record. To unset the holding, delete attached LBD first and try again.', 'action': 'Unset Holdings'}


Test constructor method
--------------------------

>>> ws = WebService('prod.json')

Test __authenticate_worldcat_metadata__ method
--------------------------

>>> auth_response = ws.__authenticate_worldcat_metadata__(debug=True)
OAuth responded 200


Test getAccessToken
-------------------
>>> auth_token = ws.getAccessToken(debug=True)

>>> if exists('_auth_.json'):
...     unlink('_auth_.json')
>>> auth_token = ws.getAccessToken(debug=True)
requesting new auth token.
OAuth responded 200

Test _is_expired_()
-------------------

>>> ws._is_expired_("2023-01-31 20:59:39Z", debug=True)
True
>>> ws._is_expired_("2050-01-31 00:59:39Z", debug=True)
False
