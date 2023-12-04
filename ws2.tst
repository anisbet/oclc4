Test specialized functions in the oclcws module

>>> from ws2 import WebService
>>> from os.path import exists
>>> from os import unlink

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
>>> ws.success(debug=True)
200
True

Test _is_expired_()
-------------------

>>> ws._is_expired_("2023-01-31 20:59:39Z", debug=True)
True
>>> ws._is_expired_("2050-01-31 00:59:39Z", debug=True)
False
