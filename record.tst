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