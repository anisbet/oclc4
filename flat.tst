Test Flat object
================
>>> from flat import Flat

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
>>> flat = Flat(r)


Test __str__() method
---------------------

>>> print(flat)
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

>>> flat.__repr__()
TCN        : ocn779882439
OCLC number:    779882439
Action     :          set


Test Reject tags
----------------
>>> r.append('.500.   |aOn-order.')
>>> flat = Flat(r, rejectTags={'500':'On-order', '900': 'Non circ item'})
>>> flat.__repr__()
TCN        : ocn779882439
OCLC number:    779882439
Action     :       ignore
>>> print(flat)
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
>>> flat.asSlimFlat()
*** DOCUMENT BOUNDARY ***
FORM=MUSIC
.001. |aocn779882439
.035.   |a(Sirsi) o779881111
.035.   |a(Sirsi) o779882222
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779883333


Test update OCLC number and output slim flat file
--------------------------

>>> flat.updateOclcNumber('12345678')
>>> flat.asSlimFlat()
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
>>> flat.asSlimFlat(test_slim_file)
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

>>> flat.asSlimFlat(test_slim_file)
>>> with open(test_slim_file, 'rt') as f:
...     lines = f.readlines()
...     f.close()
>>> print(lines)
['*** DOCUMENT BOUNDARY ***\n', 'FORM=MUSIC\n', '.001. |aocn779882439\n', '.035.   |a(Sirsi) o779881111\n', '.035.   |a(Sirsi) o779882222\n', '.035.   |a(OCoLC)12345678|z(OCoLC)779882439\n', '.035.   |a(CaAE) o779883333\n', '*** DOCUMENT BOUNDARY ***\n', 'FORM=MUSIC\n', '.001. |aocn779882439\n', '.035.   |a(Sirsi) o779881111\n', '.035.   |a(Sirsi) o779882222\n', '.035.   |a(OCoLC)12345678|z(OCoLC)779882439\n', '.035.   |a(CaAE) o779883333\n']
>>> os.unlink(test_slim_file)