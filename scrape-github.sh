#!/usr/bin/bash

#Checks arguments for a token file (will be improved)
if [ ${#@} -lt 1 ]; then
    echo "usage:[your github token file]"
    exit 1;
fi

GITHUB_TOKEN=`cat $1`
EXPRESSION="org.checkerframework.checker.*.qual"

rest_call (){
    curl --request GET \
    --url "https://api.github.com/search/code?q=${EXPRESSION}&page=${PAGE}" \
    --header "Authorization: Bearer $GITHUB_TOKEN"
}

getHeader (){
    curl -I -s --request GET \
    --url "https://api.github.com/search/code?q=${EXPRESSION}" \
    --header "Authorization: Bearer $GITHUB_TOKEN"
}
 
# Run the getPages function to print out the header information of the api call, run awk and grep to extract the final page
getHeader > header.txt
headerFile=header.txt
last_page=$(grep '^link:' header.txt | sed -e 's/^link:.*page=//g' -e 's/>.*$//g')
page=1
# Main loop, iterate until the page is not less than, needs to be changed but for now keep it. Does not consider file page

echo $last_page
# Check header if there is an error code
if [[ -f $headerFile ]]; then
    code=$(grep "^HTTP" header.txt)
    if [[ "$code" == *"200"* ]]; 
    then
        [ -z "$last_page" ] && { echo "[LAST PAGE NOT SET]"; exit 1;} 
        echo "[Header Call Successful]"
        while [ $page -lt $last_page ]
        do 
            echo "[Making Call...]"
            rest_call | grep "html_url" >> links.txt
            echo "[Sleeping for 10 seconds]"
            sleep 10 
            page=$((page+1))
            echo "CURRENT ITERATION ${page}, STOPS AT ${last_page}"
        done
    elif [[ "$code" == *"403"* ]]; then
        echo "[ERROR] 403 Code"
        exit 0
    elif [[ -z "$code" ]]; then
        if grep -q "rate" "$File"; then
            echo "[Too many calls, exiting...]"
            exit 0
        fi
    else 
        echo "[ERROR] OTHER "
        exit 0
    fi
else
    echo "[ERROR] header does not exist"
    exit 0
fi












