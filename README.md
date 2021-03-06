youtube-to-rss.sh <img src="./newsboat.svg" alt="Newsboat logo" align="right" height="60" width="60" vspace="6"/>
=================

About
-----
Import and keep your Youtube subscriptions in Newsboat up-to-date with ease.
The script uses Youtube API to request your subscriptions based on the given
channel id and adds them to your Newsboat `urls` file if they are not there yet.
It sets a `#Automated` tag next to the entries generated by this script, and
this is used when deleting expired subscriptions.

Improvements
------------
Newsboat itself has an import function which does serve a basic purpose of
importing the OPML file exported from Youtube subscription manager and adds
them to your `urls` file. The way this script improves on top of this, is that 
it allows you to easily add and delete subscriptions without having to manually 
export them from the Youtube's website. Made into POSIX compliant from the
previous bash version of the script.

**Changelog 21.1.2021**\
Added option to pass options as arguments to allow it to be ran as a cron job
for example.

Usage
-----
+ Download the script for example by running `git clone https://github.com/Jertzukka/youtube-to-rss.sh`
+ Get your Channel ID by navigating Youtube to Settings and Advanced Settings. 
You can edit the Channel ID straight into the script into `channelid=''` or 
enter it when the script is ran first time and it's asked.
+ You need to get a Youtube Data API v3 key and insert it into `apikey=''`,
first I tried to provide mine for public use, but they're abused. Help for getting
the API key can be found here: https://developers.google.com/youtube/v3/getting-started
+ If necessary, make the file executable by running `chmod +x ./youtube-to-rss.sh`
+ Run the script with `./youtube-to-rss.sh`

If you'd like to run this periodically without user input for example as a cron job,
you can pass options into the script as arguments:

    ./youtube-to-rss.sh [-t <TAG>] [-d <y/n>]

Dependencies
------------
+ **sh**
+ **jq**, lightweight and flexible command-line JSON processor.
