#!/bin/bash
USER="****"
PASSWORD="*****"
DB_CONNECTION_STRING="127.0.0.1:1545/DB_SERVICE_NAME"
QUERY="some Query to select from db"
current_date=$(date '+%Y-%m-%d %H:%M:%S')

#query to get Raw data from db
result=$(sqlplus -s <<EOF
$USER/$PASSWORD@$DB_CONNECTION_STRING
SET PAGESIZE 0
SET LINESIZE 1000
SET FEEDBACK OFF
SET HEADING OFF
$QUERY;
EXIT;
EOF
)

#check if result is empty
if [[ -z "$result" ]]; then
    echo $current_date "****************** start sending 220 ******************" >> /home/sipa/bashscript/220.log
    echo "$current_date result of query is empty: $result" >> /home/sipa/bashscript/220.log
    exit 1
fi

#format Raw data to send to api
formatted=""
while IFS= read -r line; do
    # Replace %2C with %252C inside each line
    line=$(echo "$line" | sed 's/%2C/%252C/g')
    # Replace %252C with '%'2C inside each line
    line=$(echo "$line" | sed 's/%252C/%27%2C/g')
    if [ -z "$formatted" ]; then
        formatted="$line"
    else
        formatted="$formatted%2C$line"
    fi
done <<< "$result"

# Replace " with ' in formatted
formatted=$(echo "$formatted" | sed 's/"/'\''/g')

#update db to initiate system to send 220 
while IFS= read -r line; do
        sqlplus -s $USER/$PASSWORD@$DB_CONNECTION_STRING <<EOF
        update fnvsipa.kh4rqolog set kh4revind472=0 where kh4recid470 = '${line}';
        COMMIT;
EOF
done <<< "$result"



# Perform the curl request
CURL_RES=$(curl -X GET 'http://127.0.0.1:8000/invoke?operation=postMultiSettelment&objectname=com.tosan.sipa%3Atype%3Dutility%2CserviceType%3Dlog%2Cname%3Dsettelment&value0='"$formatted"'&type0=java.lang.String' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:73.0) Gecko/20100101 Firefox/73.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,/;q=0.8' \
-H 'Accept-Language: en-US,en;q=0.5' \
-H 'Authorization: Basic c2lwYWNvbnNvbGU6MjE5MDUyMDIwODI5' \
-H 'Connection: keep-alive' \
-H 'Referer: http://127.0.0.1:8000/mbean?objectname=com.tosan.sipa%3Atype%3Dutility%2CserviceType%3Dlog%2Cname%3Dsettelment' \
-H 'Upgrade-Insecure-Requests: 1')

# Log the output
echo $current_date "formated diags: " $formatted >> /home/sipa/bashscript/220.log
echo $current_date "******************** CURL RESULT ******************" >> /home/sipa/bashscript/220.log
echo $current_date "CURL_RESULT:" >> /home/sipa/bashscript/220.log
echo $CURL_RES >> /home/sipa/bashscript/220.log
echo $current_date "RESULT:" $result >> /home/sipa/bashscript/220.log