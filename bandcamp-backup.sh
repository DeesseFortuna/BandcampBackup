#!/bin/bash
URL="$1" #give me the MUSIC directory with no trailing slash, i.e. https://artist.bandcamp.com/music
ARTIST="$2" #no spaces, you can rename it after (yes I'm lazy) 

printf "\nPre-execution cleanup"
rm ./index.temp*
rm ./*.list

printf "\nFetching page..."
wget -O index.temp $URL #get the page

grep -o '"\/album\/.*">' index.temp > albumdirlist.list #grep out the album urls
grep -o '"\/track\/.*">' index.temp > trackdirlist.list #grep out the track urls
rm ./index.temp* #delete temp index page(s)

sed -e 's/^"//' albumdirlist.list > albumdirlist2.list #trim preceding double quote
sed -e 's/^"//' trackdirlist.list > trackdirlist2.list #trim preceding double quote
rm ./albumdirlist.list
rm ./trackdirlist.list

N_ALBUMS=`cat albumdirlist2.list | wc -l` #get the length of albumdirlist2 (# of albums)
N_TRACKS=`cat trackdirlist2.list | wc -l` #get length of trackdirlist2 (# of tracks)

printf "\nFound %s album and %s track directories:\n" $N_ALBUMS $N_TRACKS
sed -e 's/">$//' albumdirlist2.list | sudo tee -a albumdirlist.list #trim trailing "> and print to console
sed -e 's/">$//' trackdirlist2.list | sudo tee -a trackdirlist.list #trim trailing "> and print to console
rm ./albumdirlist2.list
rm ./trackdirlist2.list

sed -e 's/^\/album\///' albumdirlist.list > albumlist.list #trim preceding /album/
sed -e 's/^\/track\///' trackdirlist.list > tracklist.list #trim preceding /track/
sed -e 's/-/ /g' albumlist.list > albumlist2.list #replace - with ' '
sed -e 's/-/ /g' tracklist.list > tracklist2.list #replace - with ' '
rm ./albumlist.list
rm ./tracklist.list

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> albumlist.list
done < albumlist2.list
rm ./albumlist2.list

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> tracklist.list
done < tracklist2.list
rm ./tracklist2.list

printf "\nGenerated these pretty directory names:\n"
printf "..............Albums..............\n"
cat albumlist.list
printf "..............Tracks..............\n"
cat tracklist.list

printf "\nMaking artist directory...\n"
mkdir "$ARTIST"
printf "\nDirectory %s made." $ARTIST


printf "\nDescending to ./%s\n" $ARTIST
cd "$ARTIST"

printf "\nMaking album directories..."
IFS=; while read -r line; do
	mkdir "$line"
	printf "\nDirectory %s made." $line
done < ./../albumlist.list

ROOTURL="${URL%/music}" #removing /music/ from end of URL, for use with youtube-dl below

printf "\n\nStarting album downloads...\n"

COUNT=1
IFS=; while read -r line; do
	echo "Progress: Item #" $COUNT "/" $N_ALBUMS ":"
	ALBUM=`tail -n+$COUNT ./../albumlist.list | head -n1`
	printf "\nDescending to ./%s\n" $ALBUM
	cd "$ALBUM"
	echo "Downloading album:" $ALBUM
	youtube-dl -f bestaudio -x --audio-quality=0 --audio-format=mp3 -o "%(title)s.%(ext)s" $ROOTURL$line 
		#take best audio, convert to 320kbps MP3, format TITLE.EXT
	printf "Ascending...\n"
	cd ..
	let "COUNT++"
done < ./../albumdirlist.list

printf "\nStarting track downloads...\n"

COUNT=1
IFS=; while read -r line; do
	echo "Progress: Item #" $COUNT "/" $N_TRACKS ":"
	TRACK=`tail -n+$COUNT ./../tracklist.list | head -n1`
	echo "Downloading track:" $TRACK
	youtube-dl -f bestaudio -x --audio-quality=0 --audio-format=mp3 -o "%(title)s.%(ext)s" $ROOTURL$line 
		#take best audio, convert to 320kbps MP3, format TITLE.EXT
	let "COUNT++"
done < ./../trackdirlist.list

printf "\nAscending..."
cd ..

printf "\nCleaning up temp files..."
rm ./*.list

printf "\nDone!\n"
