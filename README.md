# backup-bandcamp
This is a Bash script to backup bandcamp pages in a pretty Artist/Album/Track.mp3 folder structure.

## Dependencies
- [youtube-dl](https://github.com/rg3/youtube-dl/)
- Bash (Bash on Ubuntu on Windows or Cygwin may work too - no guarantees)
- wget

## Optional considerations
- [aria2c](https://github.com/aria2/aria2) (optional - speeds up downloads by splitting files to download in parallel)
- you'll also need to run the following to make aria2 work with youtube-dl (thanks [tobbez](https://github.com/tobbez/youtube-dl-aria)):

```sh
$ mkdir -p ~/.config/youtube-dl/
cat > ~/.config/youtube-dl/config <<EOF
-o "[%(upload_date)s][%(id)s] %(title)s (by %(uploader)s).%(ext)s"
--external-downloader aria2c
--external-downloader-args "-c -j 3 -x 3 -s 3 -k 1M"
EOF
```

## Usage
```sh
sudo chmod +x bandcamp-backup.sh
sudo bash bandcamp-backup.sh https://artistname.bandcamp.com/ ArtistName
```
(superuser is required to create the subdirectories)

## Flaws/Caveats/Future Development
- No support for multiple pages (easy enough to do manually - write a quick parent script to call this one for every page)
- Only supports **single word artist folder names** (easy enough to change after downloading)
- Doesn't tag the downloaded files - though if they were tagged before uploading, those will be retained. Otherwise on Windows I suggest [foobar2000](https://www.foobar2000.org) with the excellent [discogs plugin](https://bitbucket.org/zoomorph/foo_discogs). For bulk manual tagging based on filename, or renaming based on tag, there is [mp3tag](http://www.mp3tag.de/en/download.html) by Florian Heidenreich.
- Can miss some non-standard symbols in album names. This is because the album name is extracted from the URL referring to it.

#### Disclaimer
- By downloading and/or using this script you agree you own the rights to the content you will be backing up (or have purchased it yourself) and are not infringing on your local copyright law. Use at your own risk, and don't be a coconut.
