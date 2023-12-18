# Run tests

.PHONY:
	test

test_libs:
	python3 ws2.py 
	python3 record.py 
	python3 oclc4.py 
