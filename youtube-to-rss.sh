#!/bin/sh


# Config
channelid=''
apikey='AIzaSyCdJeEu_WsIn-ckh2QGX5hnJlPSivRlA0Q'
urls="$HOME/.newsboat/urls"
youtuberss="https://www.youtube.com/feeds/videos.xml?channel_id="


# Check if urls file is missing..
if [ ! -f "$urls" ]; then
    echo "$urls is not found. Please create the file first or give the correct location."
    exit
fi


# First time setup to set channel ID.
if [ -z $channelid ]; then
    echo "First time setup. The default API key will not work, you need to edit it with a working one. Also edit your channel ID into the script or add it now:"
    read -r newid
    editrow=$(grep -n -m 1 "channelid=''" "$0" | cut -d : -f 1)
    sed -i "${editrow}s/channelid=''/channelid='$newid'/" $0
    channelid=$newid
fi


# Halt if files already exist with these names.
if [ -f lastreq.json ] || [ -f titles.json ] || [ -f channelids.json ]; then
    echo "Files named 'lastreq.json', 'titles.json' or 'channelids.json' already exist in the working directory. These would be overwritten so the script has halted. Delete these files before running this again."
    exit
fi


# Cleanup of temp files.
cleanup () {
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
    if [ -n "$nextPageToken" ]; then
        curl -s "https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&channelId=$channelid&maxResults=50&pageToken=$nextPageToken&key=$apikey" \
        --header "Accept: application/json" --compressed | jq . > lastreq.json
    else
        curl -s "https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&channelId=$channelid&maxResults=50&key=$apikey" \
        --header "Accept: application/json" --compressed | jq . > lastreq.json
    fi

    # Catch errors
    if [ "$(jq .error.code lastreq.json)" != "null" ]; then
        echo "Code: $(jq .error.code lastreq.json), Error: $(jq .error.errors[].message lastreq.json)"
        cleanup
        exit
    fi

    retrieved=$(jq '.items | length' lastreq.json)
    nextPageToken=$(jq -r .nextPageToken lastreq.json)
    total=$(( total + retrieved ))
    echo "Retrieved $total out of $(jq .pageInfo.totalResults lastreq.json)."
    jq -r .items[].snippet.title lastreq.json >> titles.json
    jq -r .items[].snippet.resourceId.channelId lastreq.json >> channelids.json
    # Break out if next page doesn't exist
    if [ "$nextPageToken" = "null" ]; then
        echo "Successfully retrieved $total channels out of $(jq .pageInfo.totalResults lastreq.json)."
        break;
    fi
done


# Add new channels which aren't on urls yet.
printf "\nAdd tags to imported Youtube channels? (or leave  empty)   "
read -r tag
linecount=$(wc -l < channelids.json)
updated=false
for i in $( seq 1 "$linecount" ); do
    channelid=$(sed "${i}q;d" channelids.json)
    title=$(sed "${i}q;d" titles.json)
    if ! grep -q "$channelid" "$urls"; then
        echo "Adding $title ($channelid)"
        updated=true
        if [ "$tag" != "" ]; then
            echo "${youtuberss}$(sed "${i}q;d" channelids.json) \"~$title\" \"$tag\" #Automated" >> "$urls"
        else
            echo "${youtuberss}$(sed "${i}q;d" channelids.json) \"~$title\" #Automated" >> "$urls"
        fi
    fi
done
if [ "$updated" = true ]; then
    printf "All new subscriptions added!\n"
else
    printf "Nothing to do.\n"
fi


# Delete channels that have been added with this tool, but you no longer subscribe to.
printf "\nDelete channels which have been added with this tool, but you no longer subscribe to? (y/n)   "
read -r delete
linecount=$(wc -l < "$urls")
updated=false
if [ "$delete" = "y" ] || [ "$delete" = "Y" ]; then
    : $((i=linecount))
    while [ "$((i>=1))" -ne 0 ]; do
        line=$(sed "${i}q;d" "$urls")
        if test "${line#*'#Automated'}" != "$line"; then
            channelid=$(echo "$line" | sed 's/ .*//' | cut -d= -f 2)
            title=$(sed "${i}q;d" "$urls" | sed 's/^[^"]*"\([^"]*\)".*/\1/' | sed 's/~//')
            if ! grep -q "$channelid" channelids.json; then
                echo "$title ($channelid) has been unsubscribed, deleting."
                updated=true
                removeline=$(grep -n "$channelid" "$urls" | cut -d : -f 1)
                sed -i "${removeline}d" "$urls"
            fi
        fi
        : $((i -= 1))
    done
    if [ "$updated" = true ]; then
        printf "All subscriptions up-to date!\n"
    else
        printf "Nothing to do.\n"
    fi
else
    echo "Exiting."
fi


cleanup
exit
