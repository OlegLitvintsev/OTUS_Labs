#!/bin/bash

# variables
LOGFILE="/home/vagrant/access-4560-644067.log"
TEMPFILE="/home/vagrant/temp.log"
REPORT="/home/vagrant/report.txt"
IPs="10"
URLs="10"
SUCCESS_RESPONSE_CODE="200"
IFS=$'\n'
SEND_TO="webadmin@otus.ru"

# functions
filter_errors(){
grep -v $SUCCESS_RESPONSE_CODE
}


request_ips(){
awk '{print $1}'
}


request_return_codes(){
awk '{print $9}'
}

request_pages(){
awk '{print $7}'
}

wordcount(){
sort \
| uniq -c
}

sort_desc(){
sort -rn
}

return_kv(){
awk '{print $1, $2}'
}

return_error_requests(){
awk '{print $7}'
}


request_pages(){
awk '{print $7}'
}

return_top_IPs(){
head -$IPs
}

return_top_URLs(){
head -$URLs
}

# actions
get_request_ips(){
echo ""
echo "Top $IPs requesters IP's:"
echo "========================="

cat $TEMPFILE \
| request_ips \
| wordcount \
| sort_desc \
| return_kv \
| return_top_IPs
echo ""
}

get_request_pages(){
echo "Top $URLs requested pages:"
echo "=========================="
cat $TEMPFILE \
| request_pages \
| wordcount \
| sort_desc \
| return_kv \
| return_top_URLs
echo ""
}

get_request_errors(){
echo "Error requests:"
echo "==============="
cat $TEMPFILE \
| filter_errors \
| return_error_requests \
| wordcount \
| sort_desc
echo ""
}

get_return_codes(){
echo "Return codes:"
echo "============="
cat $TEMPFILE \
| request_return_codes \
| wordcount \
| sort_desc
echo ""
}

# executing

if [[ "$(ps -ef | grep anlog.sh | grep -v grep | wc -l)" -gt 2 ]]
  then
        echo "Script already running"
        exit 1
fi

if  [ ! -f $TEMPFILE ]
then
    tflg=0
else
    tflg=$(date -r $TEMPFILE +%s)
    rm -f $TEMPFILE
fi

for var in $(cat $LOGFILE)
do
   if [[ "$(date -d "$(echo $var | awk '{print $4}' | sed 's/\[//;s/:/ /;s/\// /;s/\// /')" +%s)" -gt "($tflg + 3600)" ]]
      then
        echo $var >> $TEMPFILE
   fi
done

if  [ -f $REPORT ]
then

    rm -f $REPORT
fi


echo "=================== This report is based on the log events for the interval " >> $REPORT
date -d@$tflg >> $REPORT
date  -r $TEMPFILE >> $REPORT

get_request_ips >> $REPORT
get_request_pages >> $REPORT
get_request_errors >> $REPORT
get_return_codes >> $REPORT

# mail -s 'NGINX logs report' -a $REPORT $SEND_TO
