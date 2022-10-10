#!/usr/bin/bash

#Checks arguments for a token file (will be improved)
if [ ${#@} -lt 1 ]; then
    echo "usage:[your github token file]"
    exit 1
fi

GITHUB_TOKEN=$(cat "$1")

#are longer than 256 characters (not including operators or qualifiers).
#have more than five AND, OR, or NOT operators.

EXPRESSIONS=("id+'org.checkerframework'+version")
#"Annotations+from+the+Checker+Framework:+nullness,+interning,+locking" 

rest_call (){
    curl --request GET \
    --url "https://api.github.com/search/code?q="${EXPRESSION}"&page=${page}" \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}"
}       

getHeader (){
    curl -I -s --request GET \
    --url "https://api.github.com/search/code?q="${EXPRESSION}"" \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}"
}
 
# Run the getPages function to print out the header information of the api call, run awk and grep to extract the final page
for i in ${!EXPRESSIONS[@]};
do
    #Pull each expression,
    EXPRESSION=${EXPRESSIONS[i]}
    #If no expression, stop. 
    if [ -z "$EXPRESSION" ]
    then
      echo "[Expression not set]" 
      exit 0
    fi

    getHeader > header.txt
    echo "[SLEEPING AFTER HEADER]"
    cat header.txt 
    sleep 60 #Sleep after getHeader to not cause rate limiting. 
    headerFile=header.txt #Save header output

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
                echo "[Making Call... Wating 45 seconds]"
                sleep 60
                rest_call > response.json
                cat ./response.json
                jq ".items[].repository.html_url?" response.json >> links.txt
                rm ./response.json
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
            rm ./header.txt
            exit 0
        fi
    else
        echo "[ERROR] header does not exist"
        exit 0
    fi
    echo "[Successfully Completed]"
    echo "[Cleaning Directory]"
    uniq links.txt >> output.txt
    rm ./links.txt
done

rm ./header.txt
rm ./links.txt
rm ./response.json
