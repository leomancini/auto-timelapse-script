#!/usr/bin/env bash

USER=INSERT_USER_HERE
SERVER=INSERT_SERVER_HERE
SERVER_ROOT=INSERT_SERVER_ROOT_HERE

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

printf "\nInitializing variables...\\n"

IMG_TYPE=jpg
CAMERA_FORMATTED=$(echo $CAMERA | tr 'a-z' 'A-Z')
SERVER_PATH=$SERVER_ROOT/nest-cam-timelapse/images/$CAMERA_FORMATTED

printf "Creating temporary directory on local machine...\\n"

mkdir -p ./.auto-timelapse-temp/
mkdir ./.auto-timelapse-temp/$RUNTIME/

printf "Creating temporary directory on remote host machine...\\n"

ssh $USER@$SERVER "mkdir -p /$SERVER_ROOT/.auto-timelapse-temp/ && mkdir /$SERVER_ROOT/.auto-timelapse-temp/$RUNTIME/"

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
    echo "/$SERVER_PATH/$date.$IMG_TYPE" >> ./.auto-timelapse-temp/$RUNTIME/images.txt
    dateTs=$(($dateTs+$offset))
    ((i=i+1))
done

printf "Copying list of images to remote host machine...\\n"

scp -q ./.auto-timelapse-temp/$RUNTIME/images.txt $USER@$SERVER:/$SERVER_ROOT/.auto-timelapse-temp/$RUNTIME/

printf "Packaging ${PURPLE}$i${NC} images into archive file...\\n"

ssh $USER@$SERVER "tar -cf /$SERVER_ROOT/.auto-timelapse-temp/$RUNTIME/images.tar -T /$SERVER_ROOT/.auto-timelapse-temp/$RUNTIME/images.txt > /dev/null 2>&1"

printf "${CYAN}Downloading images for range${NC} ${PURPLE}$START${NC} ${CYAN}through${NC} ${PURPLE}$END${NC}${CYAN}...${NC}\\n\n"

scp -T $USER@$SERVER:"/$SERVER_ROOT/.auto-timelapse-temp/$RUNTIME/images.tar" ./.auto-timelapse-temp/$RUNTIME/

printf "\n${GREEN}# # # # FINISHED DOWNLOADING IMAGES # # # #${NC}\\n\n"

printf "Unpacking archive file...\\n"

tar -xf ./.auto-timelapse-temp/$RUNTIME/images.tar -C ./.auto-timelapse-temp/$RUNTIME/

printf "${CYAN}Starting timelapse creation...${NC}\\n\n"

ffmpeg -loglevel error -stats -r $FPS -pattern_type glob -i "./.auto-timelapse-temp/$RUNTIME/$SERVER_PATH/*.jpg" -s 1280x720 -vcodec libx264 ./$START-to-$END-at-$FPS-fps.mp4

printf "\n${GREEN}# # # # FINISHED TIMELAPSE CREATION # # # #${NC}\\n\n"

echo "Cleaning up..."

ssh $USER@$SERVER "rm -r /$SERVER_ROOT/.auto-timelapse-temp/"

rm -r ./.auto-timelapse-temp/

printf "\n${GREEN}# # # # DONE # # # #${NC}\\n\n"
printf "Output: ${PURPLE}$START-to-$END-at-$FPS-fps.mp4${NC}\\n\n"
