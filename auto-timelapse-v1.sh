#!/usr/bin/env bash

RUNTIME=$(date +%s)

RED='\033[0;31m'
GREEN='\033[1;92m'
CYAN='\033[1;96m'
PURPLE='\033[1;95m'
NC='\033[0m'

echo -n "Camera: "
read CAMERA

echo -n "Start Time: "
read START

echo -n "End Time: "
read END

echo -n "FPS: [15, 30, 60] "
read FPS

CAMERA_FORMATTED=$(echo $CAMERA | tr 'a-z' 'A-Z')

printf "\nInitializing variables...\\n"

USER=INSERT_USER_HERE
SERVER=INSERT_SERVER_HERE
SERVER_ROOT=INSERT_SERVER_ROOT_HERE
SERVER_PATH=INSERT_SNAPSHOTS_PATH_HERE/$CAMERA_FORMATTED
IMG_TYPE=jpg

printf "Creating temporary directory...\\n"

mkdir -p ./.auto-timelapse-temp/
mkdir ./.auto-timelapse-temp/$RUNTIME/

IMGS_TO_DOWNLOAD=""

printf "Building range of images to download...\\n"

# Based on: https://stackoverflow.com/questions/4434782/loop-from-start-date-to-end-date-in-mac-os-x-shell-script
sDateTs=`date -j -f "%Y-%m-%d-%H-%M" $START "+%s"`
eDateTs=`date -j -f "%Y-%m-%d-%H-%M" $END "+%s"`
dateTs=$sDateTs
offset=60
i=0

while [ "$dateTs" -le "$eDateTs" ]
do
    date=`date -j -f "%s" $dateTs "+%Y-%m-%d-%H-%M"`
    IMGS_TO_DOWNLOAD="$IMGS_TO_DOWNLOAD $SERVER_PATH/$date.$IMG_TYPE "
    dateTs=$(($dateTs+$offset))
    ((i=i+1))
done

printf "Looking to download ${PURPLE}$i${NC} images...\\n\n"

printf "${CYAN}Downloading images for range${NC} ${PURPLE}$START${NC} ${CYAN}through${NC} ${PURPLE}$END${NC}${CYAN}...${NC}\\n\n"

scp -T $USER@$SERVER:"$IMGS_TO_DOWNLOAD" ./.auto-timelapse-temp/$RUNTIME/

printf "\n${GREEN}# # # # FINISHED DOWNLOADING IMAGES # # # #${NC}\\n"

printf "\n${CYAN}Starting timelapse creation...${NC}\\n\n"

ffmpeg -loglevel error -stats -r $FPS -pattern_type glob -i "./.auto-timelapse-temp/$RUNTIME/*.jpg" -s 1280x720 -vcodec libx264 ./$START--$END.mp4

printf "\n${GREEN}# # # # FINISHED TIMELAPSE CREATION # # # #${NC}\\n\n"

echo "Cleaning up..."

rm -r ./.auto-timelapse-temp/$RUNTIME/

printf "\n${GREEN}# # # # DONE # # # #${NC}\\n\n"
printf "Output: ${PURPLE}$START--$END.mp4${NC}\\n\n"
