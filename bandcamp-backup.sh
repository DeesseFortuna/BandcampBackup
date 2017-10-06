#!/bin/bash
#bandcamp-backup.v0.1.0 https://github.com/DeesseFortuna/backup-bandcamp

URL="$1" #ex. https://555notreal.bandcamp.com/music
ARTIST="$2" #ex. 555notreal (no spaces)

BB_WD=`echo $(pwd)` #store working directory
echo $BB_WD

BB_TMP=`mktemp -d` #make temp dir

# check if tmp dir was created
if [[ ! "$BB_TMP" || ! -d "$BB_TMP" ]]; then
  echo "Could not create temp directory"
  exit 1
fi

function cleanup { # deletes the temp directory
  rm -rf "$BB_TMP"
  printf "\nDeleted temp working directory %s\n" $BB_TMP
}

trap cleanup EXIT # register the cleanup function to be called on the EXIT signal

cd "$BB_TMP"
printf "\nFetching page...\n"
wget -O index.temp $URL #get the page, save to specific temp filename

BB_ALB_DIR=$(mktemp albumdirlist.XXXXXXXXXX) # duplicates used for doing simple one-liners
BB_ALB_DIR2=$(mktemp albumdirlist2.XXXXXXXXXX) # and shuffling back and forth
BB_TRA_DIR=$(mktemp trackdirlist.XXXXXXXXXX) # instead of rewriting the original file
BB_TRA_DIR2=$(mktemp trackdirlist2.XXXXXXXXXX)

grep -o '"\/album\/.*">' index.temp > "$BB_ALB_DIR" #grep out the album urls
grep -o '"\/track\/.*">' index.temp > "$BB_TRA_DIR" #grep out the track urls
rm index.temp #delete temp index page(s)

sed -e 's/^"//' "$BB_ALB_DIR" > "$BB_ALB_DIR2" #trim preceding double quote
sed -e 's/^"//' "$BB_TRA_DIR" > "$BB_TRA_DIR2"
rm $BB_ALB_DIR $BB_TRA_DIR

N_ALBUMS=`cat "$BB_ALB_DIR2" | wc -l` #get the length of albumdirlist2 (# of albums)
N_TRACKS=`cat "$BB_TRA_DIR2" | wc -l` #get length of trackdirlist2 (# of tracks)

printf "Found %s album and %s track directories:\n" $N_ALBUMS $N_TRACKS
sed -e 's/">$//' "$BB_ALB_DIR2" | tee -a "$BB_ALB_DIR" #trim trailing "> and print to console
sed -e 's/">$//' "$BB_TRA_DIR2" | tee -a "$BB_TRA_DIR"
rm $BB_ALB_DIR2 $BB_TRA_DIR2

BB_ALB_T=$(mktemp albumlist.XXXXXXXXXX) #these will hold the humanized strings
BB_ALB_T2=$(mktemp albumlist2.XXXXXXXXXX) #used for directories 
BB_TRA_T=$(mktemp tracklist.XXXXXXXXXX)  #and displaying item progress
BB_TRA_T2=$(mktemp tracklist2.XXXXXXXXXX)

sed -e 's/^\/album\///' "$BB_ALB_DIR" > "$BB_ALB_T" #trim preceding /album/
sed -e 's/^\/track\///' "$BB_TRA_DIR" > "$BB_TRA_T" #trim preceding /track/
sed -e 's/-/ /g' "$BB_ALB_T" > "$BB_ALB_T2" #replace - with ' '
sed -e 's/-/ /g' "$BB_TRA_T" > "$BB_TRA_T2"
rm $BB_ALB_T $BB_TRA_T

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> "$BB_ALB_T"
done < "$BB_ALB_T2"
rm $BB_ALB_T2

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'`
	echo $Target >> "$BB_TRA_T"
done < "$BB_TRA_T2"
rm $BB_TRA_T2

printf "\nGenerated these pretty directory names:\n"
printf "..............Albums..............\n"
cat "$BB_ALB_T"
printf "..............Tracks..............\n"
cat "$BB_TRA_T"

printf "\nMaking artist directory...\n"
mkdir "$BB_WD/$ARTIST/"
if [[ ! "$BB_WD/$ARTIST" || ! -d "$BB_WD/$ARTIST" ]]; then
  echo "Could not create artist directory"
  exit 1
fi
printf "\nDirectory %s/%s/ made.\n" $BB_WD $ARTIST

printf "Making album directories..."
IFS=; while read -r line; do #reads whole lines instead of single words like `while IFS= read -r`
	mkdir "$BB_WD/$ARTIST/$line/"
	if [[ ! "$BB_WD/$ARTIST/$line" || ! -d "$BB_WD/$ARTIST/$line" ]]; then
	  echo "Could not create album directory"
	  exit 1
	fi
	printf "\nDirectory %s/%s/%s made." $BB_WD $ARTIST $line
done < "$BB_ALB_T"

ROOTURL="${URL%/music}" #removing /music/ from end of URL, for use with youtube-dl below

printf "\n\nStarting album downloads...\n"

COUNT=1; IFS=; while read -r line; do
	printf "\nProgress: Album #%s/%s\n" $COUNT $N_ALBUMS
	ALBUM=`tail -n+$COUNT "$BB_ALB_T" | head -n1`
	printf "\nDownloading album: %s\n" $ALBUM
	youtube-dl -w --no-post-overwrites -f bestaudio -x --audio-quality=0 --audio-format=mp3 -o "$BB_WD/$ARTIST/$ALBUM/%(title)s.%(ext)s" $ROOTURL$line 
	  #take best audio, convert to 320kbps MP3, format TITLE.EXT
	let "COUNT++"
done < "$BB_ALB_DIR"

printf "\nStarting track downloads...\n"


COUNT=1; IFS=; while read -r line; do
	printf "\nProgress: Track #%s/%s\n" $COUNT $N_TRACKS
	TRACK=`tail -n+$COUNT "$BB_TRA_T" | head -n1`
	printf "\nDownloading track: %s\n" $TRACK
	youtube-dl -w --no-post-overwrites -f bestaudio -x --audio-quality=0 --audio-format=mp3 -o "$BB_WD/$ARTIST/%(title)s.%(ext)s" $ROOTURL$line 
	  #take best audio, convert to 320kbps MP3, format TITLE.EXT
	let "COUNT++"
done < "$BB_TRA_DIR"

printf "\nDone!\n"
