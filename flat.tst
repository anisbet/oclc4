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
... ".035.   |a(Sirsi) o779882439",
... ".035.   |a(Sirsi) o779882439",
... ".035.   |a(OCoLC)779882439",
... ".035.   |a(CaAE) o779882439",
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
.035.   |a(Sirsi) o779882439
.035.   |a(Sirsi) o779882439
.035.   |a(OCoLC)779882439
.035.   |a(CaAE) o779882439


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