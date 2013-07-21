#!/bin/sh
# This scripts intends to make a mosaic out of multiple videos. For now only
# a 2x2 mosaic is supported.
# See: http://trac.ffmpeg.org/wiki/Create%20a%20mosaic%20out%20of%20several%20input%20videos

# Global parameters
NUM_VID=$#
NUM_COLS=2
let "NUM_ROWS=$NUM_VID/$NUM_COLS"
MOSAIC_WIDTH=800
MOSAIC_HEIGHT=600
let "ELT_WIDTH=$MOSAIC_WIDTH/$NUM_COLS"
let "ELT_HEIGHT=$MOSAIC_HEIGHT/$NUM_ROWS"
let "ELT_RATIO=$ELT_WIDTH/$ELT_HEIGHT"

# ffmpeg parameter list
param=""

# Add videos to the parameter list
for var in "$@"
do
    param=$param" -i $var"
done

# Prepare filter
param=$param" -filter_complex "
param=$param" \"nullsrc=size=${MOSAIC_WIDTH}x${MOSAIC_HEIGHT} [base];"

let "max_index=$NUM_VID-1"
for i in `seq 0 $max_index`
do
    param=$param" [$i:v] setpts=PTS-STARTPTS, scale='if(gt(a,${ELT_RATIO}),${ELT_WIDTH},-1)':'if(gt(a,${ELT_RATIO}),-1,${ELT_HEIGHT})' [v$i];"
done

param=$param" [base][v0] overlay=shortest=1                 [tmp1];"
param=$param" [tmp1][v1] overlay=shortest=1:x=${ELT_WIDTH}  [tmp2];"
param=$param" [tmp2][v2] overlay=shortest=1:y=${ELT_HEIGHT} [tmp3];"
param=$param" [tmp3][v3] overlay=shortest=1:x=${ELT_WIDTH}:y=${ELT_HEIGHT}"
param=$param"\" -c:v libx264 output.mkv"

echo $param

# Run command
eval ffmpeg ${param}
