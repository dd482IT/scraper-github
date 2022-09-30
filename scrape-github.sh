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
#getHeader > header.txt
last_page=$(grep '^link:' header.txt | sed -e 's/^link:.*page=//g' -e 's/>.*$//g')
echo "$last_page"
page=1

# Main loop, iterate until the page is not less than, needs to be changed but for now keep it. Does not consider file page
while [ $page -lt $last_page ]
do 
    echo "Making Call..."
    rest_call > allOutput.txt
    echo "Sleeping for 5 seconds"
    sleep 5 
    page=$((page+1))
    echo "CURRENT ITERATION ${page}, STOPS AT ${last_page}"
done

#rest_call > return.json
#cat return.json | jq '.items[].html_url' > output.txt

