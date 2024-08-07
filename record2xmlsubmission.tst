This test takes mrk data converts it to XML
===========================================

>>> from record import Record

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

>>> rec.asXml()
'<record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="007">sd fsngnnmmned</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield><datafield tag="024" ind1="1" ind2=" "><subfield code="a">886979578425</subfield></datafield><datafield tag="028" ind1="0" ind2="0"><subfield code="a">88697957842</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(OCoLC)769144454</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(CaAE) a1001499</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">TEFMT</subfield><subfield code="c">TEFMT</subfield><subfield code="d">TEF</subfield><subfield code="d">BKX</subfield><subfield code="d">EHH</subfield><subfield code="d">NYP</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="050" ind1=" " ind2="4"><subfield code="a">M1997.F6384</subfield><subfield code="b">F47 2012</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">782.42/083</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">CD J SNDTRK FRE</subfield></datafield><datafield tag="245" ind1="0" ind2="4"><subfield code="a">The Fresh Beat Band</subfield><subfield code="h">[sound recording] :</subfield><subfield code="b">music from the hit TV show.</subfield></datafield><datafield tag="264" ind1=" " ind2="2"><subfield code="a">New York :</subfield><subfield code="b">Distributed by Sony Music Entertainment,</subfield><subfield code="c">[2012]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">℗2012</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">1 sound disc :</subfield><subfield code="b">digital ;</subfield><subfield code="c">4 3/4 in.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">performed music</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">audio</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">audio disc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">At head of title: Nickelodeon.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">&quot;The Fresh Beat Band (formerly The JumpArounds) is a children\'s TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Contains 19 selections plus one bonus track.</subfield></datafield><datafield tag="505" ind1="0" ind2="0"><subfield code="t">Fresh beat band theme</subfield><subfield code="g">(0:51) --</subfield><subfield code="t">Here we go</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">A friend like you</subfield><subfield code="g">(2:19) --</subfield><subfield code="t">Just like a rockstar</subfield><subfield code="g">(2:03) --</subfield><subfield code="t">Reach for the sky</subfield><subfield code="g">(1:56) --</subfield><subfield code="t">I can do anything</subfield><subfield code="g">(2:01) --</subfield><subfield code="t">Bananas</subfield><subfield code="g">(1:48) --</subfield><subfield code="t">Music (keeps me movin\')</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Good times</subfield><subfield code="g">(2:00) --</subfield><subfield code="t">Loco legs</subfield><subfield code="g">(2:37) --</subfield><subfield code="t">Get up and go go</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Another perfect day</subfield><subfield code="g">(2:12) --</subfield><subfield code="t">Shine</subfield><subfield code="g">(2:20) --</subfield><subfield code="t">Stomp the house</subfield><subfield code="g">(2:15) --</subfield><subfield code="t">Surprise yourself</subfield><subfield code="g">(2:10) --</subfield><subfield code="t">We\'re unstoppable</subfield><subfield code="g">(2:06) --</subfield><subfield code="t">Friends give friends a hand</subfield><subfield code="g">(1:20) --</subfield><subfield code="t">Freeze dance</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">Great day</subfield><subfield code="g">(2:08) --</subfield><subfield code="g">bonus: Sun, beautiful sun</subfield><subfield code="r">(The Bubble Guppies)</subfield><subfield code="g">(2:10).</subfield></datafield><datafield tag="511" ind1="0" ind2=" "><subfield code="a">Performed by Frest Beat Band.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">3</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Children\'s television programs</subfield><subfield code="z">United States</subfield><subfield code="v">Songs and music</subfield><subfield code="v">Juvenile sound recordings.</subfield></datafield><datafield tag="710" ind1="2" ind2=" "><subfield code="a">Fresh Beat Band.</subfield></datafield></record>'

'<record><leader>02135cjm a2200385 a 4500</leader><controlfield tag="001">ocn769144454</controlfield><controlfield tag="003">OCoLC</controlfield><controlfield tag="005">20140415031111.0</controlfield><controlfield tag="007">sd fsngnnmmned</controlfield><controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield><datafield tag="024" ind1="1" ind2=" "><subfield code="a">886979578425</subfield></datafield><datafield tag="028" ind1="0" ind2="0"><subfield code="a">88697957842</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(Sirsi) a1001499</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(OCoLC)769144454</subfield></datafield><datafield tag="035" ind1=" " ind2=" "><subfield code="a">(CaAE) a1001499</subfield></datafield><datafield tag="040" ind1=" " ind2=" "><subfield code="a">TEFMT</subfield><subfield code="c">TEFMT</subfield><subfield code="d">TEF</subfield><subfield code="d">BKX</subfield><subfield code="d">EHH</subfield><subfield code="d">NYP</subfield><subfield code="d">UtOrBLW</subfield></datafield><datafield tag="050" ind1=" " ind2="4"><subfield code="a">M1997.F6384</subfield><subfield code="b">F47 2012</subfield></datafield><datafield tag="082" ind1="0" ind2="4"><subfield code="a">782.42/083</subfield><subfield code="2">23</subfield></datafield><datafield tag="099" ind1=" " ind2=" "><subfield code="a">CD J SNDTRK FRE</subfield></datafield><datafield tag="245" ind1="0" ind2="4"><subfield code="a">The Fresh Beat Band</subfield><subfield code="h">[sound recording] :</subfield><subfield code="b">music from the hit TV show.</subfield></datafield><datafield tag="264" ind1=" " ind2="2"><subfield code="a">New York :</subfield><subfield code="b">Distributed by Sony Music Entertainment,</subfield><subfield code="c">[2012]</subfield></datafield><datafield tag="264" ind1=" " ind2="4"><subfield code="c">℗2012</subfield></datafield><datafield tag="300" ind1=" " ind2=" "><subfield code="a">1 sound disc :</subfield><subfield code="b">digital ;</subfield><subfield code="c">4 3/4 in.</subfield></datafield><datafield tag="336" ind1=" " ind2=" "><subfield code="a">performed music</subfield><subfield code="2">rdacontent</subfield></datafield><datafield tag="337" ind1=" " ind2=" "><subfield code="a">audio</subfield><subfield code="2">rdamedia</subfield></datafield><datafield tag="338" ind1=" " ind2=" "><subfield code="a">audio disc</subfield><subfield code="2">rdacarrier</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">At head of title: Nickelodeon.</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">&quot;The Fresh Beat Band (formerly The JumpArounds) is a children\'s TV show with original pop songs ; the Fresh Beats are Shout, Twist, Marina, and Kiki, described as four best friends in a band who go to music school together and love to sing and dance. The show is filmed at Paramount Studios in Los Angeles, California)</subfield></datafield><datafield tag="500" ind1=" " ind2=" "><subfield code="a">Contains 19 selections plus one bonus track.</subfield></datafield><datafield tag="505" ind1="0" ind2="0"><subfield code="t">Fresh beat band theme</subfield><subfield code="g">(0:51) --</subfield><subfield code="t">Here we go</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">A friend like you</subfield><subfield code="g">(2:19) --</subfield><subfield code="t">Just like a rockstar</subfield><subfield code="g">(2:03) --</subfield><subfield code="t">Reach for the sky</subfield><subfield code="g">(1:56) --</subfield><subfield code="t">I can do anything</subfield><subfield code="g">(2:01) --</subfield><subfield code="t">Bananas</subfield><subfield code="g">(1:48) --</subfield><subfield code="t">Music (keeps me movin\')</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Good times</subfield><subfield code="g">(2:00) --</subfield><subfield code="t">Loco legs</subfield><subfield code="g">(2:37) --</subfield><subfield code="t">Get up and go go</subfield><subfield code="g">(2:09) --</subfield><subfield code="t">Another perfect day</subfield><subfield code="g">(2:12) --</subfield><subfield code="t">Shine</subfield><subfield code="g">(2:20) --</subfield><subfield code="t">Stomp the house</subfield><subfield code="g">(2:15) --</subfield><subfield code="t">Surprise yourself</subfield><subfield code="g">(2:10) --</subfield><subfield code="t">We\'re unstoppable</subfield><subfield code="g">(2:06) --</subfield><subfield code="t">Friends give friends a hand</subfield><subfield code="g">(1:20) --</subfield><subfield code="t">Freeze dance</subfield><subfield code="g">(1:54) --</subfield><subfield code="t">Great day</subfield><subfield code="g">(2:08) --</subfield><subfield code="g">bonus: Sun, beautiful sun</subfield><subfield code="r">(The Bubble Guppies)</subfield><subfield code="g">(2:10).</subfield></datafield><datafield tag="511" ind1="0" ind2=" "><subfield code="a">Performed by Frest Beat Band.</subfield></datafield><datafield tag="596" ind1=" " ind2=" "><subfield code="a">3</subfield></datafield><datafield tag="650" ind1=" " ind2="0"><subfield code="a">Children\'s television programs</subfield><subfield code="z">United States</subfield><subfield code="v">Songs and music</subfield><subfield code="v">Juvenile sound recordings.</subfield></datafield><datafield tag="710" ind1="2" ind2=" "><subfield code="a">Fresh Beat Band.</subfield></datafield></record>'