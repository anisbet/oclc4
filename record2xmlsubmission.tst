This test takes mrk data converts it to XML
===========================================

>>> from record import Record
>>> from ws2 import WebService, SetWebService, UnsetWebService, MatchWebService, AddBibWebService

This is the test mrk data which can be found in 'test/testB.mrk'
>>> r = []
>>> with open('test/testB.mrk', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         r.append(line)


=LDR 02135cjm a2200385 a 4500
=001 ocn769144454
=003 OCoLC
=005 20140415031111.0
=007 sd\fsngnnmmned
=008 111222s2012\\\\nyu||n|j|\\\\\\\\\|\eng\d
=024 1\$a886979578425
=028 00$a88697957842
=035 \\$a(Sirsi) a1001499
=035 \\$a(Sirsi) a1001499
=035 \\$a(OCoLC)769144454
=035 \\$a(CaAE) a1001499
=040 \\$aTEFMT$cTEFMT$dTEF$dBKX$dEHH$dNYP$dUtOrBLW
=050 \4$aM1997.F6384$bF47 2012
=082 04$a782.42/083$223
=099 \\$aCD J SNDTRK FRE
=245 04$aThe Fresh Beat Band$h[sound recording] :$bmusic from the hit TV show.
=264 \2$aNew York :$bDistributed by Sony Music Entertainment,$c[2012]
=264 \4$c℗2012
=300 \\$a1 sound disc :$bdigital ;$c4 3/4 in.
=336 \\$aperformed music$2rdacontent
=337 \\$aaudio$2rdamedia
=338 \\$aaudio disc$2rdacarrier
=500 \\$aAt head of title: Nickelodeon.
=500 \\$a"The Fresh Beat Band (formerly The JumpArounds) is a children's TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)
=500 \\$aContains 19 selections plus one bonus track.
=505 00$tFresh beat band theme$g(0:51) --$tHere we go$g(1:54) --$tA friend like you$g(2:19) --$tJust like a rockstar$g(2:03) --$tReach for the sky$g(1:56) --$tI can do anything$g(2:01) --$tBananas$g(1:48) --$tMusic (keeps me movin')$g(2:09) --$tGood times$g(2:00) --$tLoco legs$g(2:37) --$tGet up and go go$g(2:09) --$tAnother perfect day$g(2:12) --$tShine$g(2:20) --$tStomp the house$g(2:15) --$tSurprise yourself$g(2:10) --$tWe're unstoppable$g(2:06) --$tFriends give friends a hand$g(1:20) --$tFreeze dance$g(1:54) --$tGreat day$g(2:08) --$gbonus: Sun, beautiful sun$r(The Bubble Guppies)$g(2:10).
=511 0\$aPerformed by Frest Beat Band.
=596 \\$a3
=650 \0$aChildren's television programs$zUnited States$vSongs and music$vJuvenile sound recordings.
=710 2\$aFresh Beat Band.

Test what happens when there is no data in the record.

>>> rec = Record(r)
>>> print(rec)
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

>>> rec.asXml(useMinFields=False)
'<?xml version="1.0" encoding="UTF-8"?><record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="007">sd fsngnnmmned</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield><datafield tag="024" ind1="1" ind2=" "><subfield code="a">886979578425</subfield></datafield><datafield tag="028" ind1="0" ind2="0"><subfield code="a">88697957842</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(OCoLC)769144454</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(CaAE) a1001499</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">TEFMT</subfield><subfield code="c">TEFMT</subfield><subfield code="d">TEF</subfield><subfield code="d">BKX</subfield><subfield code="d">EHH</subfield><subfield code="d">NYP</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="050" ind1=" " ind2="4"><subfield code="a">M1997.F6384</subfield><subfield code="b">F47 2012</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">782.42/083</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">CD J SNDTRK FRE</subfield></datafield><datafield tag="245" ind1="0" ind2="4"><subfield code="a">The Fresh Beat Band</subfield><subfield code="h">[sound recording] :</subfield><subfield code="b">music from the hit TV show.</subfield></datafield><datafield tag="264" ind1=" " ind2="2"><subfield code="a">New York :</subfield><subfield code="b">Distributed by Sony Music Entertainment,</subfield><subfield code="c">[2012]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">&#x2117;2012</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">1 sound disc :</subfield><subfield code="b">digital ;</subfield><subfield code="c">4 3/4 in.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">performed music</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">audio</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">audio disc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">At head of title: Nickelodeon.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">&quot;The Fresh Beat Band (formerly The JumpArounds) is a children&#x27;s TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Contains 19 selections plus one bonus track.</subfield></datafield><datafield tag="505" ind1="0" ind2="0"><subfield code="t">Fresh beat band theme</subfield><subfield code="g">(0:51) --</subfield><subfield code="t">Here we go</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">A friend like you</subfield><subfield code="g">(2:19) --</subfield><subfield code="t">Just like a rockstar</subfield><subfield code="g">(2:03) --</subfield><subfield code="t">Reach for the sky</subfield><subfield code="g">(1:56) --</subfield><subfield code="t">I can do anything</subfield><subfield code="g">(2:01) --</subfield><subfield code="t">Bananas</subfield><subfield code="g">(1:48) --</subfield><subfield code="t">Music (keeps me movin&#x27;)</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Good times</subfield><subfield code="g">(2:00) --</subfield><subfield code="t">Loco legs</subfield><subfield code="g">(2:37) --</subfield><subfield code="t">Get up and go go</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Another perfect day</subfield><subfield code="g">(2:12) --</subfield><subfield code="t">Shine</subfield><subfield code="g">(2:20) --</subfield><subfield code="t">Stomp the house</subfield><subfield code="g">(2:15) --</subfield><subfield code="t">Surprise yourself</subfield><subfield code="g">(2:10) --</subfield><subfield code="t">We&#x27;re unstoppable</subfield><subfield code="g">(2:06) --</subfield><subfield code="t">Friends give friends a hand</subfield><subfield code="g">(1:20) --</subfield><subfield code="t">Freeze dance</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">Great day</subfield><subfield code="g">(2:08) --</subfield><subfield code="g">bonus: Sun, beautiful sun</subfield><subfield code="r">(The Bubble Guppies)</subfield><subfield code="g">(2:10).</subfield></datafield><datafield tag="511" ind1="0" ind2=" "><subfield code="a">Performed by Frest Beat Band.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">3</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Children&#x27;s television programs</subfield><subfield code="z">United States</subfield><subfield code="v">Songs and music</subfield><subfield code="v">Juvenile sound recordings.</subfield></datafield><datafield tag="710" ind1="2" ind2=" "><subfield code="a">Fresh Beat Band.</subfield></datafield></record>'

This is what MarcEdit produced from the same record.
'<record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="007">sd fsngnnmmned</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield><datafield tag="024" ind1="1" ind2=" "><subfield code="a">886979578425</subfield></datafield><datafield tag="028" ind1="0" ind2="0"><subfield code="a">88697957842</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(OCoLC)769144454</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(CaAE) a1001499</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">TEFMT</subfield><subfield code="c">TEFMT</subfield><subfield code="d">TEF</subfield><subfield code="d">BKX</subfield><subfield code="d">EHH</subfield><subfield code="d">NYP</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="050" ind1=" " ind2="4"><subfield code="a">M1997.F6384</subfield><subfield code="b">F47 2012</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">782.42/083</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">CD J SNDTRK FRE</subfield></datafield><datafield tag="245" ind1="0" ind2="4"><subfield code="a">The Fresh Beat Band</subfield><subfield code="h">[sound recording] :</subfield><subfield code="b">music from the hit TV show.</subfield></datafield><datafield tag="264" ind1=" " ind2="2"><subfield code="a">New York :</subfield><subfield code="b">Distributed by Sony Music Entertainment,</subfield><subfield code="c">[2012]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">℗2012</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">1 sound disc :</subfield><subfield code="b">digital ;</subfield><subfield code="c">4 3/4 in.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">performed music</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">audio</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">audio disc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">At head of title: Nickelodeon.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">&quot;The Fresh Beat Band (formerly The JumpArounds) is a children\'s TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Contains 19 selections plus one bonus track.</subfield></datafield><datafield tag="505" ind1="0" ind2="0"><subfield code="t">Fresh beat band theme</subfield><subfield code="g">(0:51) --</subfield><subfield code="t">Here we go</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">A friend like you</subfield><subfield code="g">(2:19) --</subfield><subfield code="t">Just like a rockstar</subfield><subfield code="g">(2:03) --</subfield><subfield code="t">Reach for the sky</subfield><subfield code="g">(1:56) --</subfield><subfield code="t">I can do anything</subfield><subfield code="g">(2:01) --</subfield><subfield code="t">Bananas</subfield><subfield code="g">(1:48) --</subfield><subfield code="t">Music (keeps me movin\')</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Good times</subfield><subfield code="g">(2:00) --</subfield><subfield code="t">Loco legs</subfield><subfield code="g">(2:37) --</subfield><subfield code="t">Get up and go go</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Another perfect day</subfield><subfield code="g">(2:12) --</subfield><subfield code="t">Shine</subfield><subfield code="g">(2:20) --</subfield><subfield code="t">Stomp the house</subfield><subfield code="g">(2:15) --</subfield><subfield code="t">Surprise yourself</subfield><subfield code="g">(2:10) --</subfield><subfield code="t">We\'re unstoppable</subfield><subfield code="g">(2:06) --</subfield><subfield code="t">Friends give friends a hand</subfield><subfield code="g">(1:20) --</subfield><subfield code="t">Freeze dance</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">Great day</subfield><subfield code="g">(2:08) --</subfield><subfield code="g">bonus: Sun, beautiful sun</subfield><subfield code="r">(The Bubble Guppies)</subfield><subfield code="g">(2:10).</subfield></datafield><datafield tag="511" ind1="0" ind2=" "><subfield code="a">Performed by Frest Beat Band.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">3</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Children\'s television programs</subfield><subfield code="z">United States</subfield><subfield code="v">Songs and music</subfield><subfield code="v">Juvenile sound recordings.</subfield></datafield><datafield tag="710" ind1="2" ind2=" "><subfield code="a">Fresh Beat Band.</subfield></datafield></record>'




Test with flat file from Capitol City Records
=============================================
>>> r = []
>>> with open('test/capcity1.flat', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         r.append(line)
>>> rec = Record(r)

# >>> print(rec)
# *** DOCUMENT BOUNDARY ***
# FORM=MARC
# .000. |aam i0c a
# .001. |apr07481759
# .003. |aCaOWLBI
# .005. |a20240603160755.0
# .008. |a240521s2024    abc    e      000 1 eng d
# .020.   |a9781773371153|q(trade paperback)
# .035.   |a(Sirsi) pr07481759
# .035.   |apr07481759
# .040.   |aCaOWLBI|beng|erda|cCaOWLBI|dCaOWLBI|dUtOrBLW
# .055. 00|aPS8603.R3832|bH43 2024
# .082. 04|a[Fic]|223
# .099.   |aBRA
# .100. 1 |aBraun, Robyn.
# .245. 14|aThe head /|cRobyn Braun.
# .264.  1|aWinnipeg, MB :|bEnfield & Wizenty,|c[2024]
# .264.  4|c©2024
# .300.   |a144 pages ;|c21 cm.
# .336.   |atext|btxt|2rdacontent
# .337.   |aunmediated|bn|2rdamedia
# .338.   |avolume|bnc|2rdacarrier
# .490. 1 |aCapital City Press Collection
# .500.   |aCanadian author.
# .520.   |a"A surreal and penetrating tale of academia, corporate work life, and surviving trauma. On the morning of her thirtieth birthday, Dr. Trish Russo, a math professor at Cascadia University, discovers a disembodied but living infant head on her dresser. Attached to nothing, somehow it still manages to wail and produce tears. Unsure what else to do, she takes it with her to work, if only to keep her neighbours from complaining about the head's terrible cries. At the university, her colleagues are mortified, not of the head itself, but that Trish has brought it into the office with her. She is soon put on leave and hopes that visiting her parents might provide some solace and advice on what she should do with the head. But no matter where she turns, Trish finds no help and is instead vilified for not knowing what to do with this impossible thing that has happened to her. The Head is a bizarre journey through trauma, bad relationships, and toxic workplace culture."--|cProvided by publisher.
# .596.   |a1
# .650.  0|aHead|vFiction.
# .650.  0|aInterpersonal relations|vFiction.
# .650.  0|aPsychic trauma|vFiction.
# .650.  0|aWomen college teachers|vFiction.
# .655.  7|aNovels.|2lcgft
# .655.  7|aEdmonton author.|2caae
# .655.  7|aAlberta author.|2caae
# .830.  0|aCapital City Press Collection.
# .949.   |aBRA|wASIS|i31221377207803|kON-ORDER|lCAPCTY|mEPLZORDER|p20.73|tCCP|xCANADFIC|zADULT
# .949.   |aBRA|wASIS|i31221377207811|kON-ORDER|lCAPCTY|mEPLZORDER|p20.73|tCCP|xCANADFIC|zADULT
# 
# 
# >>> rec.asXml(useMinFields=False)
# '<record><leader>00000nam a2200000 i 4500</leader><controlfield tag="001">pr07481759</controlfield><controlfield tag="003">CaOWLBI</controlfield><controlfield tag="005">20240603160755.0</controlfield><controlfield tag="008">240521s2024    abc    e      000 1 eng d</controlfield><datafield tag="020" ind1=" " ind2=" "><subfield code="a">9781773371153</subfield><subfield code="q">(trade paperback)</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) pr07481759</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">pr07481759</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">CaOWLBI</subfield><subfield code="b">eng</subfield><subfield code="e">rda</subfield><subfield code="c">CaOWLBI</subfield><subfield code="d">CaOWLBI</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="055" ind1="0" ind2="0"><subfield code="a">PS8603.R3832</subfield><subfield code="b">H43 2024</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">[Fic]</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">BRA</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Braun, Robyn.</subfield></datafield><datafield tag="245" ind1="1" ind2="4"><subfield code="a">The head /</subfield><subfield code="c">Robyn Braun.</subfield></datafield><datafield tag="264" ind1=" " ind2="1"><subfield code="a">Winnipeg, MB :</subfield><subfield code="b">Enfield &amp; Wizenty,</subfield><subfield code="c">[2024]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">©2024</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">144 pages ;</subfield><subfield code="c">21 cm.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">text</subfield><subfield code="b">txt</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">unmediated</subfield><subfield code="b">n</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">volume</subfield><subfield code="b">nc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="490" ind1="1" ind2=" "><subfield code="a">Capital City Press Collection</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Canadian author.</subfield></datafield><datafield tag="520" ind1=" " ind2=" "><subfield code="a">&quot;A surreal and penetrating tale of academia, corporate work life, and surviving trauma. On the morning of her thirtieth birthday, Dr. Trish Russo, a math professor at Cascadia University, discovers a disembodied but living infant head on her dresser. Attached to nothing, somehow it still manages to wail and produce tears. Unsure what else to do, she takes it with her to work, if only to keep her neighbours from complaining about the head\'s terrible cries. At the university, her colleagues are mortified, not of the head itself, but that Trish has brought it into the office with her. She is soon put on leave and hopes that visiting her parents might provide some solace and advice on what she should do with the head. But no matter where she turns, Trish finds no help and is instead vilified for not knowing what to do with this impossible thing that has happened to her. The Head is a bizarre journey through trauma, bad relationships, and toxic workplace culture.&quot;--</subfield><subfield code="c">Provided by publisher.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">1</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Head</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Interpersonal relations</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Psychic trauma</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Women college teachers</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Novels.</subfield><subfield code="2">lcgft</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Edmonton author.</subfield><subfield code="2">caae</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Alberta author.</subfield><subfield code="2">caae</subfield></datafield><datafield tag="830" ind1=" " ind2="0"><subfield code="a">Capital City Press Collection.</subfield></datafield><datafield tag="949" ind1=" " ind2=" "><subfield code="a">BRA</subfield><subfield code="w">ASIS</subfield><subfield code="i">31221377207803</subfield><subfield code="k">ON-ORDER</subfield><subfield code="l">CAPCTY</subfield><subfield code="m">EPLZORDER</subfield><subfield code="p">20.73</subfield><subfield code="t">CCP</subfield><subfield code="x">CANADFIC</subfield><subfield code="z">ADULT</subfield></datafield><datafield tag="949" ind1=" " ind2=" "><subfield code="a">BRA</subfield><subfield code="w">ASIS</subfield><subfield code="i">31221377207811</subfield><subfield code="k">ON-ORDER</subfield><subfield code="l">CAPCTY</subfield><subfield code="m">EPLZORDER</subfield><subfield code="p">20.73</subfield><subfield code="t">CCP</subfield><subfield code="x">CANADFIC</subfield><subfield code="z">ADULT</subfield></datafield></record>'

Test match web MatchWebService
------------------------------
# >>> ws = MatchWebService('prod.json')
# >>> ws.sendRequest(rec.asXml(useMinFields=True))


Create a record that looks just like the one OCLC provides that works and see if it parses. If not compare 
with the swagger version.
----------------------------------------------------------------------------------------------------------

>>> r = []
>>> with open('test/oclc.flat', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         r.append(line)
>>> rec = Record(r)
>>> rec.asXml(useMinFields=True)
'<?xml version="1.0" encoding="UTF-8"?><record><leader>00000nam a2200000 i 4500</leader><controlfield tag="001">pr07481759</controlfield><controlfield tag="005">20240603160755.0</controlfield><controlfield tag="008">240521s2024    abc    e      000 1 eng d</controlfield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">CaOWLBI</subfield><subfield code="b">eng</subfield><subfield code="e">rda</subfield><subfield code="c">CaOWLBI</subfield><subfield code="d">CaOWLBI</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Braun, Robyn.</subfield></datafield><datafield tag="245" ind1="1" ind2="4"><subfield code="a">The head /</subfield><subfield code="c">Robyn Braun.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Canadian author.</subfield></datafield></record>'

>>> rec.asXml(useMinFields=False)
'<?xml version="1.0" encoding="UTF-8"?><record><leader>00000nam a2200000 i 4500</leader><controlfield tag="001">pr07481759</controlfield><controlfield tag="003">CaOWLBI</controlfield><controlfield tag="005">20240603160755.0</controlfield><controlfield tag="008">240521s2024    abc    e      000 1 eng d</controlfield><datafield tag="020" ind1=" " ind2=" "><subfield code="a">9781773371153</subfield><subfield code="q">(trade paperback)</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) pr07481759</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">pr07481759</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">CaOWLBI</subfield><subfield code="b">eng</subfield><subfield code="e">rda</subfield><subfield code="c">CaOWLBI</subfield><subfield code="d">CaOWLBI</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="055" ind1="0" ind2="0"><subfield code="a">PS8603.R3832</subfield><subfield code="b">H43 2024</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">[Fic]</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">BRA</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Braun, Robyn.</subfield></datafield><datafield tag="245" ind1="1" ind2="4"><subfield code="a">The head /</subfield><subfield code="c">Robyn Braun.</subfield></datafield><datafield tag="264" ind1=" " ind2="1"><subfield code="a">Winnipeg, MB :</subfield><subfield code="b">Enfield &amp; Wizenty,</subfield><subfield code="c">[2024]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">&#xA9;2024</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">144 pages ;</subfield><subfield code="c">21 cm.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">text</subfield><subfield code="b">txt</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">unmediated</subfield><subfield code="b">n</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">volume</subfield><subfield code="b">nc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="490" ind1="1" ind2=" "><subfield code="a">Capital City Press Collection</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Canadian author.</subfield></datafield><datafield tag="520" ind1=" " ind2=" "><subfield code="a">&quot;A surreal and penetrating tale of academia, corporate work life, and surviving trauma. On the morning of her thirtieth birthday, Dr. Trish Russo, a math professor at Cascadia University, discovers a disembodied but living infant head on her dresser. Attached to nothing, somehow it still manages to wail and produce tears. Unsure what else to do, she takes it with her to work, if only to keep her neighbours from complaining about the head&#x27;s terrible cries. At the university, her colleagues are mortified, not of the head itself, but that Trish has brought it into the office with her. She is soon put on leave and hopes that visiting her parents might provide some solace and advice on what she should do with the head. But no matter where she turns, Trish finds no help and is instead vilified for not knowing what to do with this impossible thing that has happened to her. The Head is a bizarre journey through trauma, bad relationships, and toxic workplace culture.&quot;--</subfield><subfield code="c">Provided by publisher.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">1</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Head</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Interpersonal relations</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Psychic trauma</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Women college teachers</subfield><subfield code="v">Fiction.</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Novels.</subfield><subfield code="2">lcgft</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Edmonton author.</subfield><subfield code="2">caae</subfield></datafield><datafield tag="655" ind1=" " ind2="7"><subfield code="a">Alberta author.</subfield><subfield code="2">caae</subfield></datafield><datafield tag="830" ind1=" " ind2="0"><subfield code="a">Capital City Press Collection.</subfield></datafield><datafield tag="949" ind1=" " ind2=" "><subfield code="a">BRA</subfield><subfield code="w">ASIS</subfield><subfield code="i">31221377207803</subfield><subfield code="k">ON-ORDER</subfield><subfield code="l">CAPCTY</subfield><subfield code="m">EPLZORDER</subfield><subfield code="p">20.73</subfield><subfield code="t">CCP</subfield><subfield code="x">CANADFIC</subfield><subfield code="z">ADULT</subfield></datafield><datafield tag="949" ind1=" " ind2=" "><subfield code="a">BRA</subfield><subfield code="w">ASIS</subfield><subfield code="i">31221377207811</subfield><subfield code="k">ON-ORDER</subfield><subfield code="l">CAPCTY</subfield><subfield code="m">EPLZORDER</subfield><subfield code="p">20.73</subfield><subfield code="t">CCP</subfield><subfield code="x">CANADFIC</subfield><subfield code="z">ADULT</subfield></datafield></record>'

Test match web MatchWebService
------------------------------
>>> ws = MatchWebService('prod.json')
>>> ws.sendRequest(rec.asXml(True))
{'numberOfRecords': 1, 'briefRecords': [{'oclcNumber': '1415241025', 'title': 'The head', 'creator': 'Robyn Braun', 'date': '2024', 'machineReadableDate': '2024', 'language': 'eng', 'generalFormat': 'Book', 'specificFormat': 'PrintBook', 'edition': '', 'publisher': 'Enfield & Wizenty', 'publicationPlace': 'Winnipeg, MB', 'isbns': ['9781773371153', '1773371150'], 'issns': [], 'mergedOclcNumbers': [], 'catalogingInfo': {'catalogingAgency': 'NLC', 'catalogingLanguage': 'eng', 'levelOfCataloging': ' ', 'transcribingAgency': 'YDX'}}]}

>>> r = []
>>> with open('test/capcity2.flat', encoding='utf-8', mode='rt') as f:
...     for line in f:
...         r.append(line)
>>> rec = Record(r)
>>> ws = MatchWebService('prod.json')
>>> ws.sendRequest(rec.asXml(True))
{'numberOfRecords': 0, 'briefRecords': []}

Add the bib record.
>>> ws = AddBibWebService('prod.json')
>>> rec.asXml(useMinFields=False, ignoreControlNumber=True)
'<?xml version="1.0" encoding="UTF-8"?><record><leader>00000nam a2200000 i 4500</leader><controlfield tag="005">20240507090129.7</controlfield><controlfield tag="008">240507s2024    xx a   j      000 1 eng d</controlfield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">CaOWLBI</subfield><subfield code="b">eng</subfield><subfield code="c">CaOWLBI</subfield><subfield code="e">rda</subfield><subfield code="d">CaOWLBI</subfield></datafield><datafield tag="100" ind1="1" ind2=" "><subfield code="a">Yang, Gayoung B. B.</subfield></datafield><datafield tag="245" ind1="1" ind2="0"><subfield code="a">Convertible dream /</subfield><subfield code="c">written &amp; illustrated by Gayoung BB Yang.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">text</subfield><subfield code="b">txt</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">still image</subfield><subfield code="b">sti</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">volume</subfield><subfield code="b">nc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Canadian author.</subfield></datafield></record>'
>>> ws.sendRequest(rec.asXml(useMinFields=False, ignoreControlNumber=True))


<record>
    <leader>00000nam a2200000 i 4500</leader>
    <controlfield tag="005">20240507090129.7</controlfield>
    <controlfield tag="008">240507s2024    xx a   j      000 1 eng d</controlfield>
    <datafield tag="040" ind1=" " ind2=" ">
        <subfield code="a">CaOWLBI</subfield>
        <subfield code="b">eng</subfield>
        <subfield code="c">CaOWLBI</subfield>
        <subfield code="e">rda</subfield>
        <subfield code="d">CaOWLBI</subfield>
    </datafield>
    <datafield tag="100" ind1="1" ind2=" ">
        <subfield code="a">Yang, Gayoung B. B.</subfield>
    </datafield>
    <datafield tag="245" ind1="1" ind2="0">
        <subfield code="a">Convertible dream /</subfield>
        <subfield code="c">written &amp; illustrated by Gayoung BB Yang.</subfield>
    </datafield>
    <datafield tag="336" ind1=" " ind2=" ">
        <subfield code="a">still image</subfield>
        <subfield code="b">sti</subfield>
        <subfield code="2">rdacontent</subfield>
    </datafield>
    <datafield tag="338" ind1=" " ind2=" ">
        <subfield code="a">volume</subfield>
        <subfield code="b">nc</subfield>
        <subfield code="2">rdacarrier</subfield>
    </datafield>
    <datafield tag="500" ind1=" " ind2=" ">
        <subfield code="a">Canadian author.</subfield>
    </datafield>
</record>'

{'errorCount': 4, 'errors': [
    'Invalid character a in position 2 in 1st $c in 040.', 
    'Invalid character a in position 2 in 1st $d in 040.', 
    'Invalid symbol CaOWLBI in 1st $c in 040.', 
    'Invalid symbol CaOWLBI in 1st $d in 040.'], 
'variableFieldErrors': [
    {'tag': '040', 'errorLevel': 'CRITICAL', 'message': 'Invalid character a in position 2 in 1st $c in 040.'},
    {'tag': '040', 'errorLevel': 'CRITICAL', 'message': 'Invalid character a in position 2 in 1st $d in 040.'}, 
    {'tag': '040', 'errorLevel': 'CRITICAL', 'message': 'Invalid symbol CaOWLBI in 1st $c in 040.'}, 
    {'tag': '040', 'errorLevel': 'CRITICAL', 'message': 'Invalid symbol CaOWLBI in 1st $d in 040.'}
]}

# >>> r = []
# >>> with open('test/capcity3.flat', encoding='utf-8', mode='rt') as f:
# ...     for line in f:
# ...         r.append(line)
# >>> rec = Record(r)
# >>> ws = MatchWebService('prod.json')
# >>> ws.sendRequest(rec.asXml(True))
# 
# >>> r = []
# >>> with open('test/capcity4.flat', encoding='utf-8', mode='rt') as f:
# ...     for line in f:
# ...         r.append(line)
# >>> rec = Record(r)
# >>> ws = MatchWebService('prod.json')
# >>> ws.sendRequest(rec.asXml(True))
# 
# >>> r = []
# >>> with open('test/capcity5.flat', encoding='utf-8', mode='rt') as f:
# ...     for line in f:
# ...         r.append(line)
# >>> rec = Record(r)
# >>> ws = MatchWebService('prod.json')
# >>> ws.sendRequest(rec.asXml(True))
# {'numberOfRecords': 1, 'briefRecords': [{'oclcNumber': '1435878079', 'title': "Mission of the ro'arck", 'creator': 'Ericka Evren', 'date': '2022', 'machineReadableDate': '2022', 'language': 'eng', 'generalFormat': 'Book', 'specificFormat': 'PrintBook', 'edition': '', 'publisher': '[Twenty8 Create]', 'publicationPlace': '[Edmonton]', 'isbns': ['9781777790615', '1777790611'], 'issns': [], 'mergedOclcNumbers': [], 'catalogingInfo': {'catalogingAgency': 'NLC', 'catalogingLanguage': 'eng', 'levelOfCataloging': '3', 'transcribingAgency': 'NLC'}}]}