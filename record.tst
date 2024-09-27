Test Record object
================


>>> from record import Record, MarcXML, TAG, IND1, IND2, SUBF, DATA


>>> flat = '.245. 10|aSilence :|bin the age of noise /|cErling Kagge ; & translated from Norwegian by Becky L. Crook.'
>>> mxml = MarcXML(flat)
>>> print(f"{mxml.getMarc(flat, TAG)}")
245
>>> print(mxml.getMarc(flat, whichPart=IND1))
1
>>> print(mxml.getMarc(flat, whichPart=IND2))
0
>>> print(mxml.getMarc(flat, whichPart=DATA))
Silence :|bin the age of noise /|cErling Kagge ; &amp; translated from Norwegian by Becky L. Crook.

>>> print(mxml.getMarc(flat, whichPart=SUBF))
a

>>> print(mxml.getMarc(flat, whichPart=DATA))
Silence :|bin the age of noise /|cErling Kagge ; &amp; translated from Norwegian by Becky L. Crook.


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
'<record><leader>00000njm a2200000   4500</leader><controlfield tag="001">ocn779882439</controlfield><controlfield tag="005">20140415031115.0</controlfield><controlfield tag="008">120307s2012    cau||n|e|i        | eng d</controlfield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">On-order.</subfield></datafield></record>'


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
'<record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield></record>'


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

Test that the 008 field is the right length (40)
------------------------------------------------

>>> r = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MARC",
... ".000. |aam i0c a",
... ".001. |a1886633",
... ".005. |a20180626122213.0",
... ".008. |a171109s2018    mnua   e      001 0 eng",
... ".010.   |a  2017051171",
... ".020.   |a0760352100 (pbk.)",
... ".020.   |a9780760352106 (pbk.)",
... ".035.   |a(Sirsi) LSC3147622",
... ".035.   |aLSC3147622",
... ".040.   |aDLC|beng|erda|cDLC|dUtOrBLW",
... ".050. 00|aTX603|b.J39 2018",
... ".082. 00|a641.42|223",
... ".092.   |a641.42 JEA",
... ".100. 1 |aJeanroy, Amelia.",
... ".245. 10|aModern pressure canning :|brecipes and techniques for today's home canner /|cAmelia Jeanroy ; photography by Kerry Michaels.",
... ".264.  1|aMinneapolis, MN :|bVoyageur Press,|c2018.",
... ".300.   |a191 pages :|bcolour illustrations",
... ".336.   |atext|2rdacontent",
... ".336.   |astill image|2rdacontent",
... ".337.   |aunmediated|2rdamedia",
... ".338.   |avolume|2rdacarrier",
... ".500.   |aIncludes Internet addresses and index.",
... ".520.   |a'Amelia Jeanroy teaches everything readers need to know about making delicious, shelf-stable foods in this all-in-one reference. Readers will learn how to properly use a pressure canner and eliminate any danger, be it from the pressure or from improperly canning foods. Also includes a wide variety of recipes, from sweet corn and apple sauce to Italian meatballs and chicken soup'--Provided by publisher.",
... ".596.   |a3 18",
... ".650.  0|aCanning and preserving.",
... ".650.  0|aPressure cooking.",
... ".949.   |a641.42 JEA|wDEWEY|i31221120104521|kON-ORDER|lNONFICTION|mEPLZORDER|p27.46|tBOOK|xNONFIC|zADULT",
... ".949.   |a641.42 JEA|wDEWEY|i31221120104547|kON-ORDER|lNONFICTION|mEPLZORDER|p27.46|tBOOK|xNONFIC|zADULT",
... ".949.   |a641.42 JEA|wDEWEY|i31221120104539|kON-ORDER|lNONFICTION|mEPLZORDER|p27.46|tBOOK|xNONFIC|zADULT"
... ]
>>> record = Record(r)
>>> record.asXml()
'<record><leader>00000nam a2200000 i 4500</leader><controlfield tag="001">1886633</controlfield><controlfield tag="005">20180626122213.0</controlfield><controlfield tag="008">171109s2018    mnua   e      001 0 eng  </controlfield><datafield tag="010" ind1=" " ind2=" "><subfield code="a">  2017051171</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">DLC</subfield><subfield code="b">eng</subfield><subfield code="e">rda</subfield><subfield code="c">DLC</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Jeanroy, Amelia.</subfield></datafield><datafield tag="245" ind1="1" ind2="0"><subfield code="a">Modern pressure canning :</subfield><subfield code="b">recipes and techniques for today\'s home canner /</subfield><subfield code="c">Amelia Jeanroy ; photography by Kerry Michaels.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Includes Internet addresses and index.</subfield></datafield></record>'