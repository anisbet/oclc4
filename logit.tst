>>> from logit import logit

Test logging
------------------------------
>>> logit("Hello World!", logFilePrefix='./logit_')
Hello World!

# Run this test manually since the timestamp will always fail because the timestamp changes.
# >>> logit("Hello World!", logFilePrefix='./logit_', timestamp=True)
# Hello World!

>>> logit("Hello World!", logFilePrefix='./logit_')
Hello World!

# Run this test manually since the timestamp will always fail because the timestamp changes.
# >>> logit("Hello World!", logFilePrefix='./logit_', timestamp=True)
# Hello World!

>>> logit("Error World!", level='error', logFilePrefix='./logit_')
*error, Error World!
