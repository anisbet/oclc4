
Test flat to marc 21 xml conversions.
-------------------------------------

Basic imports

>>> from record import MarcXML



Test the tag getting function
-----------------------------


>>> marc_slim = MarcXML([])
>>> marc_slim._getMarcTag_(".000. |ajm a0c a")
'000'

>>> marc_slim = MarcXML([])
>>> marc_slim._getMarcField_(".000. |ajm a0c a")
'|ajm a0c a'


Test get indicators
-------------------

>>> marc_slim = MarcXML([])
>>> print(f"{marc_slim._getIndicators_('.082. 04|a782.42/083|223')}")
('0', '4')
>>> print(f"{marc_slim._getIndicators_('.082.   |a782.42/083|223')}")
(' ', ' ')
>>> print(f"{marc_slim._getIndicators_('.082. 1 |a782.42/083|223')}")
('1', ' ')
>>> print(f"{marc_slim._getIndicators_('.082.  5|a782.42/083|223')}")
(' ', '5')
>>> print(f"{marc_slim._getIndicators_('.050.  4|aM1997.F6384|bF47 2012')}")
(' ', '4')


Test get subfields
------------------


>>> marc_slim = MarcXML([])
>>> print(f"{marc_slim._getSubfields_('.040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW')}")
['<datafield tag="040" ind1=" " ind2=" ">', '  <subfield code="a">TEFMT</subfield>', '  <subfield code="c">TEFMT</subfield>', '  <subfield code="d">TEF</subfield>', '  <subfield code="d">BKX</subfield>', '  <subfield code="d">EHH</subfield>', '  <subfield code="d">NYP</subfield>', '  <subfield code="d">UtOrBLW</subfield>', '</datafield>']
>>> print(f"{marc_slim._getSubfields_('.050.  4|aM1997.F6384|bF47 2012')}")
['<datafield tag="050" ind1=" " ind2="4">', '  <subfield code="a">M1997.F6384</subfield>', '  <subfield code="b">F47 2012</subfield>', '</datafield>']
>>> print(f"{marc_slim._getSubfields_('.245.  4|aTreasure Island, 2004')}")
['<datafield tag="245" ind1=" " ind2="4">', '  <subfield code="a">Treasure Island, 2004</subfield>', '</datafield>']


Test XML production from slim FLAT data.
---------------------------------------


>>> marc_slim = MarcXML(["*** DOCUMENT BOUNDARY ***", ".000. |ajm a0c a", ".008. |a111222s2012    nyu||n|j|         | eng d", ".035.   |a(OCoLC)769144454", "*** DOCUMENT BOUNDARY ***"])
>>> print(marc_slim.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
</record>





Test convert method
-------------------


>>> marc_slim = MarcXML([
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm a0c a",
... ".001. |aocn769144454",
... ".003. |aOCoLC",
... ".005. |a20140415031111.0",
... ".007. |asd fsngnnmmned",
... ".008. |a111222s2012    nyu||n|j|         | eng d",
... ".024. 1 |a886979578425",
... ".028. 00|a88697957842",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(OCoLC)769144454",
... ".035.   |a(CaAE) a1001499",
... ".040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW"])
>>> print(marc_slim.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="001">ocn769144454</controlfield>
<controlfield tag="003">OCoLC</controlfield>
<controlfield tag="005">20140415031111.0</controlfield>
<controlfield tag="007">sd fsngnnmmned</controlfield>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="024" ind1="1" ind2=" ">
  <subfield code="a">886979578425</subfield>
</datafield>
<datafield tag="028" ind1="0" ind2="0">
  <subfield code="a">88697957842</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(CaAE) a1001499</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">TEFMT</subfield>
  <subfield code="c">TEFMT</subfield>
  <subfield code="d">TEF</subfield>
  <subfield code="d">BKX</subfield>
  <subfield code="d">EHH</subfield>
  <subfield code="d">NYP</subfield>
  <subfield code="d">UtOrBLW</subfield>
</datafield>
</record>



Test collection flag.
---------------------



>>> flat_marc = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm a0c a",
... ".001. |aocn769144454",
... ".003. |aOCoLC",
... ".005. |a20140415031111.0",
... ".007. |asd fsngnnmmned",
... ".008. |a111222s2012    nyu||n|j|         | eng d",
... ".024. 1 |a886979578425",
... ".028. 00|a88697957842",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(OCoLC)769144454",
... ".035.   |a(CaAE) a1001499",
... ".040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW"]
>>> xml = MarcXML(flat_marc)
>>> print(xml.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="001">ocn769144454</controlfield>
<controlfield tag="003">OCoLC</controlfield>
<controlfield tag="005">20140415031111.0</controlfield>
<controlfield tag="007">sd fsngnnmmned</controlfield>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="024" ind1="1" ind2=" ">
  <subfield code="a">886979578425</subfield>
</datafield>
<datafield tag="028" ind1="0" ind2="0">
  <subfield code="a">88697957842</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(CaAE) a1001499</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">TEFMT</subfield>
  <subfield code="c">TEFMT</subfield>
  <subfield code="d">TEF</subfield>
  <subfield code="d">BKX</subfield>
  <subfield code="d">EHH</subfield>
  <subfield code="d">NYP</subfield>
  <subfield code="d">UtOrBLW</subfield>
</datafield>
</record>



Test output of 'standard' namespace elements
--------------------------------------------

>>> flat_marc = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm a0c a",
... ".001. |aocn769144454",
... ".003. |aOCoLC",
... ".005. |a20140415031111.0",
... ".007. |asd fsngnnmmned",
... ".008. |a111222s2012    nyu||n|j|         | eng d",
... ".024. 1 |a886979578425",
... ".028. 00|a88697957842",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(OCoLC)769144454",
... ".035.   |a(CaAE) a1001499",
... ".040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW"]
>>> xml = MarcXML(flat_marc)
>>> print(xml.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="001">ocn769144454</controlfield>
<controlfield tag="003">OCoLC</controlfield>
<controlfield tag="005">20140415031111.0</controlfield>
<controlfield tag="007">sd fsngnnmmned</controlfield>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="024" ind1="1" ind2=" ">
  <subfield code="a">886979578425</subfield>
</datafield>
<datafield tag="028" ind1="0" ind2="0">
  <subfield code="a">88697957842</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(CaAE) a1001499</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">TEFMT</subfield>
  <subfield code="c">TEFMT</subfield>
  <subfield code="d">TEF</subfield>
  <subfield code="d">BKX</subfield>
  <subfield code="d">EHH</subfield>
  <subfield code="d">NYP</subfield>
  <subfield code="d">UtOrBLW</subfield>
</datafield>
</record>



Test output of branch if requested
----------------------------------


>>> flat_marc = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm a0c a",
... ".001. |aocn769144454",
... ".003. |aOCoLC",
... ".005. |a20140415031111.0",
... ".007. |asd fsngnnmmned",
... ".008. |a111222s2012    nyu||n|j|         | eng d",
... ".024. 1 |a886979578425",
... ".028. 00|a88697957842",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(OCoLC)769144454",
... ".035.   |a(CaAE) a1001499",
... ".040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW"]
>>> xml = MarcXML(flat_marc)
>>> print(xml.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="001">ocn769144454</controlfield>
<controlfield tag="003">OCoLC</controlfield>
<controlfield tag="005">20140415031111.0</controlfield>
<controlfield tag="007">sd fsngnnmmned</controlfield>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="024" ind1="1" ind2=" ">
  <subfield code="a">886979578425</subfield>
</datafield>
<datafield tag="028" ind1="0" ind2="0">
  <subfield code="a">88697957842</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(CaAE) a1001499</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">TEFMT</subfield>
  <subfield code="c">TEFMT</subfield>
  <subfield code="d">TEF</subfield>
  <subfield code="d">BKX</subfield>
  <subfield code="d">EHH</subfield>
  <subfield code="d">NYP</subfield>
  <subfield code="d">UtOrBLW</subfield>
</datafield>
</record>



Test the 'standard' namespace with collection and branch
--------------------------------------------------------


>>> flat_marc = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MUSIC",
... ".000. |ajm a0c a",
... ".001. |aocn769144454",
... ".003. |aOCoLC",
... ".005. |a20140415031111.0",
... ".007. |asd fsngnnmmned",
... ".008. |a111222s2012    nyu||n|j|         | eng d",
... ".024. 1 |a886979578425",
... ".028. 00|a88697957842",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(Sirsi) a1001499",
... ".035.   |a(OCoLC)769144454",
... ".035.   |a(CaAE) a1001499",
... ".040.   |aTEFMT|cTEFMT|dTEF|dBKX|dEHH|dNYP|dUtOrBLW"]
>>> xml = MarcXML(flat_marc)
>>> print(xml.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000njm a2200000 a 4500</leader>
<controlfield tag="001">ocn769144454</controlfield>
<controlfield tag="003">OCoLC</controlfield>
<controlfield tag="005">20140415031111.0</controlfield>
<controlfield tag="007">sd fsngnnmmned</controlfield>
<controlfield tag="008">111222s2012    nyu||n|j|         | eng d</controlfield>
<datafield tag="024" ind1="1" ind2=" ">
  <subfield code="a">886979578425</subfield>
</datafield>
<datafield tag="028" ind1="0" ind2="0">
  <subfield code="a">88697957842</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(Sirsi) a1001499</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(OCoLC)769144454</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">(CaAE) a1001499</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">TEFMT</subfield>
  <subfield code="c">TEFMT</subfield>
  <subfield code="d">TEF</subfield>
  <subfield code="d">BKX</subfield>
  <subfield code="d">EHH</subfield>
  <subfield code="d">NYP</subfield>
  <subfield code="d">UtOrBLW</subfield>
</datafield>
</record>


Test create marc XML data from reading a flat file.
---------------------------------------------------
Note issues to fix: 
 * Concatinate multiline strings onto one line.
 * Add include tags.
 * Remove collection and XML namespace declaration.

>>> flat_marc = [
... "*** DOCUMENT BOUNDARY ***",
... "FORM=MARC",
... ".000. |aam i0n a",
... ".001. |aLSC4152857",
... ".003. |aCaAE",
... ".008. |a211125s2021    nyua   j b    000 0 eng c",
... ".020.   |a0593380339 (lib. bdg.)",
... ".020.   |a9780593380338 (lib. bdg.)",
... ".035.   |aLSC4152857",
... ".040.   |aNJQ/DLC|beng|erda|cNJQ|dDLC",
... ".050. 00|aQL638.9|b.P4345 2019",
... ".082. 04|a636.8|223",
... ".092.   |aJ 636.8 PER",
... ".100. 1 |aPerl, Erica S.",
... ".245. 10|aCats! /|cby Erica S. Perl ; illustrations by Michael Slack.",
... ".264.  1|aNew York, NY :|bScholastic, Inc.,|c[2021]",
... ".264.  4|ac©2021",
... ".300.   |a48 pages :|bcolour illustrations.",
... ".336.   |atext|2rdacontent",
... ".337.   |aunmediated|2rdamedia",
... ".338.   |avolume|2rdacarrier",
... ".490. 1 |aTruth or lie",
... ".490. 1 |aStep into reading. Science reader. Step 3, Reading on your own",
... ".504.   |aIncludes bibliographical references and Internet addresses.",
... ".650.  0|aCats|vMiscellanea|vJuvenile literature.",
... ".650.  0|aCats|vJuvenile literature.",
... ".700. 1 |aSlack, Michael,|d1969-",
... ".830.  0|aTruth or lie",
... ".830.  0|aStep into reading.|pScience reader.|nStep 3,|pReading on your own",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679371|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679306|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679330|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679348|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679298|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679363|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679314|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679322|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".949.   |aJ 636.8 PER|wDEWEY|i31221122679355|kON-ORDER|lJUVNONF|mEPLZORDER|p23.99|tJBOOK|xNONFIC|zJUVENILE",
... ".596.   |a1 11 12 16 18",
... ]
>>> xml = MarcXML(flat_marc)
>>> print(xml.__str__(pretty=True))
<?xml version="1.0" encoding="UTF-8"?>
<record>
<leader>00000nam a2200000 i 4500</leader>
<controlfield tag="001">LSC4152857</controlfield>
<controlfield tag="003">CaAE</controlfield>
<controlfield tag="008">211125s2021    nyua   j b    000 0 eng c</controlfield>
<datafield tag="020" ind1=" " ind2=" ">
  <subfield code="a">0593380339 (lib. bdg.)</subfield>
</datafield>
<datafield tag="020" ind1=" " ind2=" ">
  <subfield code="a">9780593380338 (lib. bdg.)</subfield>
</datafield>
<datafield tag="035" ind1=" " ind2=" ">
  <subfield code="a">LSC4152857</subfield>
</datafield>
<datafield tag="040" ind1=" " ind2=" ">
  <subfield code="a">NJQ/DLC</subfield>
  <subfield code="b">eng</subfield>
  <subfield code="e">rda</subfield>
  <subfield code="c">NJQ</subfield>
  <subfield code="d">DLC</subfield>
</datafield>
<datafield tag="050" ind1="0" ind2="0">
  <subfield code="a">QL638.9</subfield>
  <subfield code="b">.P4345 2019</subfield>
</datafield>
<datafield tag="082" ind1="0" ind2="4">
  <subfield code="a">636.8</subfield>
  <subfield code="2">23</subfield>
</datafield>
<datafield tag="092" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
</datafield>
<datafield tag="100" ind1="1" ind2=" ">
  <subfield code="a">Perl, Erica S.</subfield>
</datafield>
<datafield tag="245" ind1="1" ind2="0">
  <subfield code="a">Cats! /</subfield>
  <subfield code="c">by Erica S. Perl ; illustrations by Michael Slack.</subfield>
</datafield>
<datafield tag="264" ind1=" " ind2="1">
  <subfield code="a">New York, NY :</subfield>
  <subfield code="b">Scholastic, Inc.,</subfield>
  <subfield code="c">[2021]</subfield>
</datafield>
<datafield tag="264" ind1=" " ind2="4">
  <subfield code="a">c©2021</subfield>
</datafield>
<datafield tag="300" ind1=" " ind2=" ">
  <subfield code="a">48 pages :</subfield>
  <subfield code="b">colour illustrations.</subfield>
</datafield>
<datafield tag="336" ind1=" " ind2=" ">
  <subfield code="a">text</subfield>
  <subfield code="2">rdacontent</subfield>
</datafield>
<datafield tag="337" ind1=" " ind2=" ">
  <subfield code="a">unmediated</subfield>
  <subfield code="2">rdamedia</subfield>
</datafield>
<datafield tag="338" ind1=" " ind2=" ">
  <subfield code="a">volume</subfield>
  <subfield code="2">rdacarrier</subfield>
</datafield>
<datafield tag="490" ind1="1" ind2=" ">
  <subfield code="a">Truth or lie</subfield>
</datafield>
<datafield tag="490" ind1="1" ind2=" ">
  <subfield code="a">Step into reading. Science reader. Step 3, Reading on your own</subfield>
</datafield>
<datafield tag="504" ind1=" " ind2=" ">
  <subfield code="a">Includes bibliographical references and Internet addresses.</subfield>
</datafield>
<datafield tag="596" ind1=" " ind2=" ">
  <subfield code="a">1 11 12 16 18</subfield>
</datafield>
<datafield tag="650" ind1=" " ind2="0">
  <subfield code="a">Cats</subfield>
  <subfield code="v">Miscellanea</subfield>
  <subfield code="v">Juvenile literature.</subfield>
</datafield>
<datafield tag="650" ind1=" " ind2="0">
  <subfield code="a">Cats</subfield>
  <subfield code="v">Juvenile literature.</subfield>
</datafield>
<datafield tag="700" ind1="1" ind2=" ">
  <subfield code="a">Slack, Michael,</subfield>
  <subfield code="d">1969-</subfield>
</datafield>
<datafield tag="830" ind1=" " ind2="0">
  <subfield code="a">Truth or lie</subfield>
</datafield>
<datafield tag="830" ind1=" " ind2="0">
  <subfield code="a">Step into reading.</subfield>
  <subfield code="p">Science reader.</subfield>
  <subfield code="n">Step 3,</subfield>
  <subfield code="p">Reading on your own</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679371</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679306</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679330</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679348</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679298</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679363</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679314</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679322</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
<datafield tag="949" ind1=" " ind2=" ">
  <subfield code="a">J 636.8 PER</subfield>
  <subfield code="w">DEWEY</subfield>
  <subfield code="i">31221122679355</subfield>
  <subfield code="k">ON-ORDER</subfield>
  <subfield code="l">JUVNONF</subfield>
  <subfield code="m">EPLZORDER</subfield>
  <subfield code="p">23.99</subfield>
  <subfield code="t">JBOOK</subfield>
  <subfield code="x">NONFIC</subfield>
  <subfield code="z">JUVENILE</subfield>
</datafield>
</record>