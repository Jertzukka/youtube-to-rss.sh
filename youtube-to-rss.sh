# Config
apikey="AIzaSyCdJeEu_WsIn-ckh2QGX5hnJlPSivRlA0Q"
channelid="UCaBX7ogjBF_oeYo20zO_Y9h"
urls="$HOME/.newsboat/urls"
youtuberss="https://www.youtube.com/feeds/videos.xml?channel_id="


if [[ $channelid = "UCaBX7ogjBF_oeYo20zO_Y9h" ]]; then
    echo "Change the channelid on the script to yours to retrieve your subscriptions."
    exit
fi


# Halt if files already exist with these names.
if [ -f lastreq.json ] || [ -f titles.json ] || [ -f channelids.json ]; then
    echo "Files named 'lastreq.json', 'titles.json' or 'channelids.json' already exist in the working directory. These would be overwritten so the script has halted. Delete these files before running this again."
    exit
fi


# Cleanup of temp files.
function cleanup () {
    if [ -f lastreq.json ]; then rm lastreq.json; fi
    if [ -f titles.json ]; then rm titles.json; fi
    if [ -f channelids.json ]; then rm channelids.json; fi
}


# Trap interrupt to remove temporary files.
trap '
    echo " --- Cleaning up!"
    cleanup
    exit
' INT


# Request all subscriptions from Youtube API and write channelids and titles into files.
while true; do
    # Change request based on whether we have a newPageToken yet
    if [ ! -z "$nextPageToken" ]; then
        curl -s "https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&channelId=$channelid&maxResults=50&pageToken=$nextPageToken&key=$apikey" \
        --header "Accept: application/json" --compressed | jq . > lastreq.json
    else
        curl -s "https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&channelId=$channelid&maxResults=50&key=$apikey" \
        --header "Accept: application/json" --compressed | jq . > lastreq.json
    fi
    retrieved=$(jq '.items | length' lastreq.json)
    nextPageToken=$(jq -r .nextPageToken lastreq.json)
    total=$(( $total + $retrieved ))
    echo "Retrieved $total out of $(jq .pageInfo.totalResults lastreq.json)."
    jq -r .items[].snippet.title lastreq.json >> titles.json
    jq -r .items[].snippet.resourceId.channelId lastreq.json >> channelids.json
    # Break out if next page doesn't exist
    if [[ $nextPageToken = "null" ]]; then
        echo "Successfully retrieved $total channels out of $(jq .pageInfo.totalResults lastreq.json)."
        break;
    fi
done


# Add new channels which aren't on urls yet.
printf "\nAdd tags to imported Youtube channels? (or leave  empty)   "
read tag
linecount=$(wc -l <channelids.json)
for i in $( seq 1 $linecount ); do
    channelid=$(sed "${i}q;d" channelids.json)
    title=$(sed "${i}q;d" titles.json)
    if ! grep -q $channelid $urls; then
        echo "Adding $title."
        if [[ $tag != "" ]]; then
            echo "${youtuberss}$(sed "${i}q;d" channelids.json) \"~$title\" \"$tag\" #Automated" >> $urls
        else
            echo "${youtuberss}$(sed "${i}q;d" channelids.json) \"~$title\" #Automated" >> $urls
        fi
    fi
done
echo -e "\nAll new subscriptions added!"


# Delete channels that have been added with this tool, but you no longer subscribe to.
printf "\nDelete channels which have been added with this tool, but you no longer subscribe to? (y/n)   "
read delete
linecount=$(wc -l <$urls)
if [[ $delete = "y" ]] || [[ $delete = "Y" ]]; then
    for (( i=$linecount; i>=1; i-- )); do
        line=$(sed "${i}q;d" $urls)
        if [[ $line == *"#Automated"* ]]; then
            channelid=$(echo $line | sed 's/ .*//' | cut -d= -f 2)
            title=$(sed "${i}q;d" titles.json)
            if ! grep -q $channelid $urls; then
                echo "$title has been unsubscribed, deleting."
                removeline=$(grep -n $channelid $urls | cut -d : -f 1)
                sed -e "${removeline}d" $urls
            fi
        fi
    done
    echo -e "\nAll subscriptions up-to date!"
else
    echo "Exiting."
fi

cleanup
exit
