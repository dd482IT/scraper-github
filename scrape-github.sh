#!/usr/bin/bash

#Checks arguments for a token file (will be improved)
if [ ${#@} -lt 1 ]; then
    echo "usage:[your github token file]"
    exit 1
fi

GITHUB_TOKEN=$(cat "$1")
EXPRESSION="import+org.checkerframework.checker.*.qual"

rest_call (){
    curl --request GET \
    --url "https://api.github.com/search/code?q=${EXPRESSION}&page=${page}" \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}"
}       

getHeader (){
    curl -I -s --request GET \
    --url "https://api.github.com/search/code?q=${EXPRESSION}" \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}"
}
 
# Run the getPages function to print out the header information of the api call, run awk and grep to extract the final page
getHeader > header.txt
headerFile=header.txt
last_page=$(grep '^link:' header.txt | sed -e 's/^link:.*page=//g' -e 's/>.*$//g')
page=1
# Main loop, iterate until the page is not less than, needs to be changed but for now keep it. Does not consider file page
# Check header if there is an error code
if [[ -f $headerFile ]]; then
    code=$(grep "^HTTP" header.txt)
    if [[ "$code" == *"200"* ]]; 
    then
        [ -z "$last_page" ] && { echo "[LAST PAGE NOT SET]"; exit 1;} 
        echo "[Header Call Successful]"
        while [ "$page" -lt "$last_page" ]
        do 
            echo "[Making Call...]"
            #rest_call | jq ".items[].repository.html_url?" >> links.txt
            rest_call > response.json
            jq ".items[].repository.html_url?" response.json >> links.txt
            #if grep -q "$link"; then
            #echo "[Sleeping for 10 seconds]"
            #done
            sleep 30
            page=$((page+1))
            echo "CURRENT ITERATION ${page}, STOPS AT ${last_page}"
        done
    elif [[ "$code" == *"403"* ]]; then
        echo "[ERROR] 403 Code"
        exit 0
    elif [[ "$code" == *"401"* ]]; then
        echo "[ERROR] 401 Code"
        exit 0
    elif [[ "$code" == *"422"* ]]; then
        echo "[ERROR] 422 Code"
        exit 0
    else 
        echo "[ERROR] OTHER "
        exit 0
    fi
else
    echo "[ERROR] header does not exist"
    exit 0
fi

uniq links.txt > unique_links.txt












