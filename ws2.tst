Test specialized functions in the oclcws module

>>> from ws2 import WebService
>>> import json
>>> import sys
>>> from os.path import exists
>>> json_file = 'prod.json'
>>> configs = {}
>>> if exists(json_file):
...     with open(json_file) as f:
...         configs = json.load(f)
...         client_id = configs['clientId']
...         secret = configs['secret']
... else:
...     sys.stderr.write(f"*error, json config file not found! Expected '{json_file}'")
...     sys.exit()
>>> for (key,value) in configs.items():
...     print(f"{key}: '{value[0:4]}.............{value[-5:-1]}'")
clientId: 'MvPs.............0NMn'
secret: 'tGGC.............kxbF'