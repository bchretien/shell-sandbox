#!/bin/sh
# This script intends to make a mosaic out of multiple videos. For now only
# a 2x2 mosaic (2, 3 or 4 videos) is supported.
# See: http://trac.ffmpeg.org/wiki/Create%20a%20mosaic%20out%20of%20several%20input%20videos

# Global parameters
NUM_VID=$#
NUM_COLS=2

if [ $NUM_VID -eq 1]; then
    # One video is not enough to make a mosaic...
    exit 2
fi

NUM_ROWS=$((($NUM_VID+$NUM_COLS-1)/$NUM_COLS))

# Use the first video to fix the video size
ELT_WIDTH=`ffprobe -v quiet -show_streams $1 \
    | grep -i width \
    | awk 'BEGIN{FS="="}{print $2}'`
ELT_HEIGHT=`ffprobe -v quiet -show_streams $1 \
    | grep -i height \
    | awk 'BEGIN{FS="="}{print $2}'`
let "ELT_RATIO=$ELT_WIDTH/$ELT_HEIGHT"

let "MOSAIC_WIDTH=$NUM_COLS*$ELT_WIDTH"
let "MOSAIC_HEIGHT=$NUM_ROWS*$ELT_HEIGHT"

# ffmpeg parameter list
param=""

# Add videos to the parameter list
for var in "$@"
do
    param=$param" -i $var"
done

# Prepare filter
param=$param" -filter_complex \""

# We use white as the background color
param=$param"color=size=${MOSAIC_WIDTH}x${MOSAIC_HEIGHT}:color=white [base];"

let "max_index=$NUM_VID-1"
for i in `seq 0 $max_index`
do
    param=$param" [$i:v] setpts=PTS-STARTPTS, scale='if(gt(a,${ELT_RATIO}),${ELT_WIDTH},-1)':'if(gt(a,${ELT_RATIO}),-1,${ELT_HEIGHT})' [v$i];"
done

param=$param" [base][v0] overlay=shortest=1"

if [ $NUM_VID -ge 2 ]; then
    param=$param"[tmp1]; [tmp1][v1] overlay=shortest=1:x=${ELT_WIDTH}"
fi

if [ $NUM_VID -ge 3 ]; then
    param=$param"[tmp2]; [tmp2][v2] overlay=shortest=1:y=${ELT_HEIGHT}"
fi

if [ $NUM_VID -ge 4 ]; then
    param=$param" [tmp3]; [tmp3][v3] overlay=shortest=1:x=${ELT_WIDTH}:y=${ELT_HEIGHT}"
fi

param=$param"\" -c:v libx264 output.mkv"

echo $param

# Run command
eval ffmpeg ${param}
