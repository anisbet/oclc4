# Run tests

.PHONY:
	test

production:
	scp flatcat.sh sirsi@edpl.sirsidynix.net:~/Unicorn/EPLwork/anisbet/OCLC

test_libs:
	python3 ws2.py 
	python3 record.py 
	python3 oclc4.py 
