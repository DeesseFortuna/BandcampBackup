#!/bin/bash
URL="$1"
ARTIST="$2"

echo ""
echo "Pre-execution cleanup"
rm ./index.html*
rm ./*.txt

echo ""
echo "Fetching page..."
wget $URL #get the page

grep -o '"\/album\/.*">' index.html > dirlist.txt #grep out the album urls
rm ./index.html* #delete temp index page(s)

sed -e 's/^"//' dirlist.txt > dirlist2.txt #trim preceding double quote
rm ./dirlist.txt

NUMBER=`cat dirlist2.txt | wc -l` #get the length of dirlist2 (# of albums)

echo ""
echo "Found" $NUMBER "album directories:"
sed -e 's/">$//' dirlist2.txt | sudo tee -a dirlist.txt #trim trailing "> and print to console
rm ./dirlist2.txt 

sed -e 's/^\/album\///' dirlist.txt > albumlist.txt #trim preceding /album/
sed -e 's/-/ /g' albumlist.txt > albumlist2.txt #replace - with ' '
rm ./albumlist.txt

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> albumlist.txt
done < albumlist2.txt
rm albumlist2.txt

echo ""
echo "Generated these pretty directory names:"
cat albumlist.txt

echo ""
echo "Making artist directory..."
mkdir "$ARTIST"

echo ""
echo "Descending to ./" $ARTIST
cd "$ARTIST"

echo ""
echo "Making album directories..."
while IFS= read -r line; do
	mkdir "$line"
	echo "Directory" $line "made."
done < ./../albumlist.txt

echo ""
echo "Starting downloads..."

COUNT=1
while IFS= read -r line; do
	echo "Progress: Item #" $COUNT "/" $NUMBER ":"
	ALBUM=`tail -n+$COUNT ./../albumlist.txt | head -n1`
	echo "Descending to ./" $ALBUM
	cd "$ALBUM"
	echo "Downloading" $ALBUM
	youtube-dl --audio-quality=0 --audio-format=mp3 -o "%(title)s.%(ext)s" $URL$line
	echo "Ascending..."
	echo ""
	cd ..
	let "COUNT++"
done < ./../dirlist.txt

echo ""
echo "Ascending..."
cd ..

echo ""
echo "Cleaning up temp files..."
rm ./*.txt


echo ""
echo "Done!"
