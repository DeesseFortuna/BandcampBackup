#!/bin/bash
URL="$1" #give me the ROOT directory with no trailing slash, i.e. https://artist.bandcamp.com
ARTIST="$2" #no spaces, can rename after (yes I'm lazy) 

printf "\nPre-execution cleanup"
rm ./index.temp*
rm ./*.list

printf "\nFetching page..."
wget -O index.temp $URL #get the page

grep -o '"\/album\/.*">' index.temp > dirlist.list #grep out the album urls
rm ./index.temp* #delete temp index page(s)

sed -e 's/^"//' dirlist.list > dirlist2.list #trim preceding double quote
rm ./dirlist.list

NUMBER=`cat dirlist2.list | wc -l` #get the length of dirlist2 (# of albums)

printf "\nFound %s album directories:" $NUMBER
sed -e 's/">$//' dirlist2.list | sudo tee -a dirlist.list #trim trailing "> and print to console
rm ./dirlist2.list

sed -e 's/^\/album\///' dirlist.list > albumlist.list #trim preceding /album/
sed -e 's/-/ /g' albumlist.list > albumlist2.list #replace - with ' '
rm ./albumlist.list

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> albumlist.list
done < albumlist2.list
rm albumlist2.list

printf "\nGenerated these pretty directory names:"
cat albumlist.list

printf "\nMaking artist directory..."
mkdir "$ARTIST"

printf "\nDescending to ./%S" $ARTIST
cd "$ARTIST"

printf "\nMaking album directories..."
while IFS= read -r line; do
	mkdir "$line"
	printf "\nDirectory %s made." $line
done < ./../albumlist.list

printf "\nStarting downloads..."

COUNT=1
while IFS= read -r line; do
	echo "Progress: Item #" $COUNT "/" $NUMBER ":"
	ALBUM=`tail -n+$COUNT ./../albumlist.list | head -n1`
	echo "Descending to ./" $ALBUM
	cd "$ALBUM"
	echo "Downloading" $ALBUM
	youtube-dl -f bestaudio -x --audio-quality=0 --audio-format=mp3 -o "%(title)s.%(ext)s" $URL$line
	echo "Ascending..."
	printf "\n"
	cd ..
	let "COUNT++"
done < ./../dirlist.list

printf "\nAscending..."
cd ..

printf "\nCleaning up temp files..."
rm ./*.list

printf "\nDone!"
