Test Record object
================
>>> from record import Record



Test Constructor
----------------
>>> r = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm  0c a",
... ".001. |aocn779882439",
... ".003. |aOCoLC",
... ".005. |a20140415031115.0",
... ".007. |asd fungnnmmneu",
... ".008. |a120307s2012    cau||n|e|i        | eng d",
... ".024. 1 |a011661913028",
... ".028. 00|a11661-9130-2",
... ".035.   |a(Sirsi) o779881111",
... ".035.   |a(Sirsi) o779882222",
... ".035.   |a(OCoLC)779882439",
... ".035.   |a(CaAE) o779883333",
... ]
>>> record = Record(r)

Test __json__ method
--------------------
>>> record.__json__()
{'record': ['*** DOCUMENT BOUNDARY ***', 'FORM=MUSIC', '.000. |ajm  0c a', '.001. |aocn779882439', '.003. |aOCoLC', '.005. |a20140415031115.0', '.007. |asd fungnnmmneu', '.008. |a120307s2012    cau||n|e|i        | eng d', '.024. 1 |a011661913028', '.028. 00|a11661-9130-2', '.035.   |a(Sirsi) o779881111', '.035.   |a(Sirsi) o779882222', '.035.   |a(OCoLC)779882439', '.035.   |a(CaAE) o779883333'], 'encoding': 'ISO-8859-1', 'action': 'set', 'reject_tags': {}, 'title_control_number': 'ocn779882439', 'oclc_number': '779882439', 'prev_oclc_number': ''}


Test __str__() method
---------------------

>>> print(record)
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.000. |ajm  0c a
.001. |aocn779882439
.003. |aOCoLC
.005. |a20140415031115.0
.007. |asd fungnnmmneu
.008. |a120307s2012    cau||n|e|i        | eng d
.024. 1 |a011661913028
.028. 00|a11661-9130-2
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779883333


Test representation method
--------------------------

>>> record.__repr__()
TCN        : ocn779882439
OCLC number:    779882439
Action     :          set


Test Reject tags
----------------
>>> r.append('.500.   |aOn-order.')
>>> record = Record(r, rejectTags={'500':'On-order', '900': 'Non circ item'})
>>> record.__repr__()
TCN        : ocn779882439
OCLC number:    779882439
Action     :       ignore
>>> print(record)
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.000. |ajm  0c a
.001. |aocn779882439
.003. |aOCoLC
.005. |a20140415031115.0
.007. |asd fungnnmmneu
.008. |a120307s2012    cau||n|e|i        | eng d
.024. 1 |a011661913028
.028. 00|a11661-9130-2
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779883333
.500.   |aOn-order.


Test output slim flat file
--------------------------
>>> record.asSlimFlat()
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.001. |aocn779882439
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779883333


Test update OCLC number and output slim flat file
--------------------------

>>> record.updateOclcNumber('12345678')
>>> record.asSlimFlat()
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.001. |aocn779882439
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)12345678|z(OCoLC)779882439
.035.   |a(CaAE) o779883333


Test output slim flat file to file
----------------------------------

>>> test_slim_file = 'test/test.slim.flat'
>>> record.asSlimFlat(test_slim_file)
>>> from os.path import exists
>>> import os
>>> if exists(test_slim_file):
...     print(os.stat(test_slim_file).st_size != 0)
True
>>> lines = []
>>> with open(test_slim_file, 'rt') as f:
...     lines = f.readlines()
...     f.close()
>>> print(lines)
['*** DOCUMENT BOUNDARY ***\n', 'FORM=MUSIC\n', '.001. |aocn779882439\n', '.035.   |a(Sirsi) o779881111\n', '.035.   |a(Sirsi) o779882222\n', '.035.   |a(OCoLC)12345678|z(OCoLC)779882439\n', '.035.   |a(CaAE) o779883333\n']


Test that writing is an append operation.
-----------------------------------------

>>> record.asSlimFlat(test_slim_file)
>>> with open(test_slim_file, 'rt') as f:
...     lines = f.readlines()
...     f.close()
>>> print(lines)
['*** DOCUMENT BOUNDARY ***\n', 'FORM=MUSIC\n', '.001. |aocn779882439\n', '.035.   |a(Sirsi) o779881111\n', '.035.   |a(Sirsi) o779882222\n', '.035.   |a(OCoLC)12345678|z(OCoLC)779882439\n', '.035.   |a(CaAE) o779883333\n', '*** DOCUMENT BOUNDARY ***\n', 'FORM=MUSIC\n', '.001. |aocn779882439\n', '.035.   |a(Sirsi) o779881111\n', '.035.   |a(Sirsi) o779882222\n', '.035.   |a(OCoLC)12345678|z(OCoLC)779882439\n', '.035.   |a(CaAE) o779883333\n']
>>> os.unlink(test_slim_file)


Test asXml()
------------

When output it should look like this:

<?xml version="1.0" encoding="UTF-8"?>
<record>
	<leader>00000njm a2200000   4500</leader>
	<controlfield tag="001">ocn779882439</controlfield>
	<controlfield tag="003">OCoLC</controlfield>
	<controlfield tag="005">20140415031115.0</controlfield>
	<controlfield tag="007">sd fungnnmmneu</controlfield>
	<controlfield tag="008">120307s2012    cau||n|e|i        | eng d</controlfield>
	<datafield tag="024" ind1="1" ind2=" ">
		<subfield code="a">011661913028</subfield>
	</datafield>
	<datafield tag="028" ind1="0" ind2="0">
		<subfield code="a">11661-9130-2</subfield>
	</datafield>
	<datafield tag="035" ind1=" " ind2=" ">
		<subfield code="a">(Sirsi) o779881111</subfield>
	</datafield>
	<datafield tag="035" ind1=" " ind2=" ">
		<subfield code="a">(Sirsi) o779882222</subfield>
	</datafield>
	<datafield tag="035" ind1=" " ind2=" ">
		<subfield code="a">(OCoLC)779882439</subfield>
	</datafield>
	<datafield tag="035" ind1=" " ind2=" ">
		<subfield code="a">(CaAE) o779883333</subfield>
	</datafield>
	<datafield tag="500" ind1=" " ind2=" ">
		<subfield code="a">On-order.</subfield>
	</datafield>
</record>
>>> record.asXml()
'<?xml version="1.0" encoding="UTF-8"?><record><leader>00000njm a2200000   4500</leader><controlfield tag="001">ocn779882439</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031115.0</controlfield><controlfield tag="007">sd fungnnmmneu</controlfield><controlfield tag="008">120307s2012    cau||n|e|i        | eng d</controlfield><datafield tag="024" ind1="1" ind2=" ">  <subfield code="a">011661913028</subfield></datafield><datafield tag="028" ind1="0" ind2="0">  <subfield code="a">11661-9130-2</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(Sirsi) o779881111</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(Sirsi) o779882222</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(OCoLC)779882439</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(CaAE) o779883333</subfield></datafield><datafield tag="500" ind1=" " ind2=" ">  <subfield code="a">On-order.</subfield></datafield></record>'


Test multiline entries get put all on one line.
----------------------------------------------

>>> r = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm  0c a",
... ".001. |aocn779882439",
... ".003. |aOCoLC",
... ".005. |a20140415031115.0",
... ".007. |asd fungnnmmneu",
... ".008. |a120307s2012    cau||n|e|i        | eng d",
... ".024. 1 |a011661913028",
... ".028. 00|a11661-9130-2",
... ".035.   |a(Sirsi) o779881111",
... ".035.   |a(Sirsi) o779882222",
... ".035.   |a(OCoLC)779882439",
... ".035.   |a(CaAE) o779883333",
... ".505. 00|tNew Orleans after the city|r(Hot 8 Brass Band) --|tFrom the corner",
... "--|tHu ta nay|r(Donald Harrison & friends) --|tYou might be surprised|r(Dr.",
... "John).",
... ".511. 0 |aVarious performers.",
... ]
>>> record = Record(r)
>>> print(record)
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.000. |ajm  0c a
.001. |aocn779882439
.003. |aOCoLC
.005. |a20140415031115.0
.007. |asd fungnnmmneu
.008. |a120307s2012    cau||n|e|i        | eng d
.024. 1 |a011661913028
.028. 00|a11661-9130-2
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779883333
.505. 00|tNew Orleans after the city|r(Hot 8 Brass Band) --|tFrom the corner--|tHu ta nay|r(Donald Harrison & friends) --|tYou might be surprised|r(Dr.John).
.511. 0 |aVarious performers.


Test reading and parsing MRK format marc data
---------------------------------------------
Note that all the strings in the test have 2x'\' over the regular mrk file format because 
in python tests the escape character '\' needs to be double escaped, or '\\'.

>>> r = [
... "=LDR 02135cjm a2200385 a 4500",
... "=001 ocn769144454",
... "=003 OCoLC",
... "=005 20140415031111.0",
... "=007 sd\\fsngnnmmned",
... "=008 111222s2012\\\\\\\\nyu||n|j|\\\\\\\\\\\\\\\\\\|\eng\\d",
... "=024 1\\$a886979578425",
... "=028 00$a88697957842",
... "=035 \\\\$a(Sirsi) a1001499",
... "=035 \\\\$a(Sirsi) a1001499",
... "=035 \\\\$a(OCoLC)769144454",
... "=035 \\\\$a(CaAE) a1001499",
... "=040 \\\\$aTEFMT$cTEFMT$dTEF$dBKX$dEHH$dNYP$dUtOrBLW",
... "=050 \\4$aM1997.F6384$bF47 2012",
... "=082 04$a782.42/083$223",
... "=099 \\\\$aCD J SNDTRK FRE",
... "=245 04$aThe Fresh Beat Band$h[sound recording] :$bmusic from the hit TV show.",
... "=264 \\2$aNew York :$bDistributed by Sony Music Entertainment,$c[2012]",
... "=264 \\4$c℗2012",
... "=300 \\\\$a1 sound disc :$bdigital ;$c4 3/4 in.",
... "=336 \\\\$aperformed music$2rdacontent",
... "=337 \\\\$aaudio$2rdamedia",
... "=338 \\\\$aaudio disc$2rdacarrier",
... "=500 \\\\$aAt head of title: Nickelodeon.",
... "=500 \\\\$a\"The Fresh Beat Band (formerly The JumpArounds) is a children's TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)",
... "=500 \\\\$aContains 19 selections plus one bonus track.",
... "=505 00$tFresh beat band theme$g(0:51) --$tHere we go$g(1:54) --$tA friend like you$g(2:19) --$tJust like a rockstar$g(2:03) --$tReach for the sky$g(1:56) --$tI can do anything$g(2:01) --$tBananas$g(1:48) --$tMusic (keeps me movin')$g(2:09) --$tGood times$g(2:00) --$tLoco legs$g(2:37) --$tGet up and go go$g(2:09) --$tAnother perfect day$g(2:12) --$tShine$g(2:20) --$tStomp the house$g(2:15) --$tSurprise yourself$g(2:10) --$tWe're unstoppable$g(2:06) --$tFriends give friends a hand$g(1:20) --$tFreeze dance$g(1:54) --$tGreat day$g(2:08) --$gbonus: Sun, beautiful sun$r(The Bubble Guppies)$g(2:10).",
... "=511 0\\$aPerformed by Frest Beat Band.",
... "=596 \\\\$a3",
... "=650 \\0$aChildren's television programs$zUnited States$vSongs and music$vJuvenile sound recordings.",
... "=710 2\\$aFresh Beat Band.",
... ]
>>> record = Record(r)
>>> print(record)
*** DOCUMENT BOUNDARY ***
.000. |a02135cjm a2200385 a 4500
.001. |aocn769144454
.003. |aOCoLC
.005. |a20140415031111.0
.007. |asd fsngnnmmned
.008. |a111222s2012    nyu||n|j|         | eng d
.024. 1 |a886979578425
.028. 00|a88697957842
.035.   |a(Sirsi) a1001499
.035.   |a(Sirsi) a1001499
.035.   |a(OCoLC)769144454
.035.   |a(CaAE) a1001499
.040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW
.050.  4|aM1997.F6384|bF47 2012
.082. 04|a782.42/083|223
.099.   |aCD J SNDTRK FRE
.245. 04|aThe Fresh Beat Band|h[sound recording] :|bmusic from the hit TV show.
.264.  2|aNew York :|bDistributed by Sony Music Entertainment,|c[2012]
.264.  4|c℗2012
.300.   |a1 sound disc :|bdigital ;|c4 3/4 in.
.336.   |aperformed music|2rdacontent
.337.   |aaudio|2rdamedia
.338.   |aaudio disc|2rdacarrier
.500.   |aAt head of title: Nickelodeon.
.500.   |a"The Fresh Beat Band (formerly The JumpArounds) is a children's TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)
.500.   |aContains 19 selections plus one bonus track.
.505. 00|tFresh beat band theme|g(0:51) --|tHere we go|g(1:54) --|tA friend like you|g(2:19) --|tJust like a rockstar|g(2:03) --|tReach for the sky|g(1:56) --|tI can do anything|g(2:01) --|tBananas|g(1:48) --|tMusic (keeps me movin')|g(2:09) --|tGood times|g(2:00) --|tLoco legs|g(2:37) --|tGet up and go go|g(2:09) --|tAnother perfect day|g(2:12) --|tShine|g(2:20) --|tStomp the house|g(2:15) --|tSurprise yourself|g(2:10) --|tWe're unstoppable|g(2:06) --|tFriends give friends a hand|g(1:20) --|tFreeze dance|g(1:54) --|tGreat day|g(2:08) --|gbonus: Sun, beautiful sun|r(The Bubble Guppies)|g(2:10).
.511. 0 |aPerformed by Frest Beat Band.
.596.   |a3
.650.  0|aChildren's television programs|zUnited States|vSongs and music|vJuvenile sound recordings.
.710. 2 |aFresh Beat Band.


>>> r = [
... "=LDR 02135cjm a2200385 a 4500",
... "=001 ocn769144454",
... "=003 OCoLC",
... "=005 20140415031111.0",
... "=007 sd\\fsngnnmmned",
... "=008 111222s2012\\\\\\\\nyu||n|j|\\\\\\\\\\\\\\\\\\|\eng\\d",
... "=024 1\\$a886979578425",
... "=028 00$a88697957842",
... "=035 \\\\$a(Sirsi) a1001499",
... "=035 \\\\$a(Sirsi) a1001499",
... "=035 \\\\$a(OCoLC)769144454",
... "=035 \\\\$a(CaAE) a1001499",
... ]
>>> record = Record(r)
>>> record.asXml()
'<?xml version="1.0" encoding="UTF-8"?><record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="007">sd fsngnnmmned</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield><datafield tag="024" ind1="1" ind2=" ">  <subfield code="a">886979578425</subfield></datafield><datafield tag="028" ind1="0" ind2="0">  <subfield code="a">88697957842</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(OCoLC)769144454</subfield></datafield><datafield tag="035" ind1=" " ind2=" ">  <subfield code="a">(CaAE) a1001499</subfield></datafield></record>'


Test that the makeFlatLineFromMrk method works
------------------------------------------
For this test there is no DOCUMENT_BOUNDERY, just testing the makeFlatLineFromMrk method. 

>>> with open('test/testA.mrk', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         print(f"{record.makeFlatLineFromMrk(line)}")
.000. |a02135cjm a2200385 a 4500
.001. |aocn769144454
.003. |aOCoLC
.005. |a20140415031111.0
.007. |asd fsngnnmmned
.008. |a111222s2012    nyu||n|j|         | eng d
.024. 1 |a886979578425
.028. 00|a88697957842
.035.   |a(Sirsi) a1001499
.035.   |a(Sirsi) a1001499
.035.   |a(OCoLC)769144454
.035.   |a(CaAE) a1001499
.040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW
.050.  4|aM1997.F6384|bF47 2012
.082. 04|a782.42/083|223
.099.   |aCD J SNDTRK FRE
.245. 04|aThe Fresh Beat Band|h[sound recording] :|bmusic from the hit TV show.
.264.  2|aNew York :|bDistributed by Sony Music Entertainment,|c[2012]
.264.  4|c℗2012
.300.   |a1 sound disc :|bdigital ;|c4 3/4 in.
.336.   |aperformed music|2rdacontent
.337.   |aaudio|2rdamedia
.338.   |aaudio disc|2rdacarrier
.500.   |aAt head of title: Nickelodeon.
.500.   |a"The Fresh Beat Band (formerly The JumpArounds) is a children's TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)
.500.   |aContains 19 selections plus one bonus track.
.505. 00|tFresh beat band theme|g(0:51) --|tHere we go|g(1:54) --|tA friend like you|g(2:19) --|tJust like a rockstar|g(2:03) --|tReach for the sky|g(1:56) --|tI can do anything|g(2:01) --|tBananas|g(1:48) --|tMusic (keeps me movin')|g(2:09) --|tGood times|g(2:00) --|tLoco legs|g(2:37) --|tGet up and go go|g(2:09) --|tAnother perfect day|g(2:12) --|tShine|g(2:20) --|tStomp the house|g(2:15) --|tSurprise yourself|g(2:10) --|tWe're unstoppable|g(2:06) --|tFriends give friends a hand|g(1:20) --|tFreeze dance|g(1:54) --|tGreat day|g(2:08) --|gbonus: Sun, beautiful sun|r(The Bubble Guppies)|g(2:10).
.511. 0 |aPerformed by Frest Beat Band.
.596.   |a3
.650.  0|aChildren's television programs|zUnited States|vSongs and music|vJuvenile sound recordings.
.710. 2 |aFresh Beat Band.

Test what happens when there is no data in the record.

>>> rec = Record([])
>>> print(rec)
<BLANKLINE>
>>> rec.asXml()
''
>>> rec.__repr__()
TCN        :             
OCLC number:             
Action     :          set