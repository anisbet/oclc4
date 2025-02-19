# Run tests
ILS_RUN_DIR=sirsi@edpl.sirsidynix.net:~/Unicorn/EPLwork/anisbet/OCLC
SRC_FILES=ws2.py record.py oclc4.py

run: ${SRC_FILES} runreport.sh
	. /home/anisbet/EPL/OCLC/oclc4/venv/bin/activate
	/home/anisbet/EPL/OCLC/oclc4/runreport.sh

get:
	scp ${ILS_RUN_DIR}/*.log .
	scp ${ILS_RUN_DIR}/*.zip .

deploy:
	scp flatcat.sh ${ILS_RUN_DIR}/

test_src: ${SRC_FILES}
	python3 ${SRC_FILES} 
