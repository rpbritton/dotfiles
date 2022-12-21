#!/bin/bash

set -e

MELT_SCRIPT=""
VIDEO_FILE=""
FORCE_RENDER=0
VIDEO_TITLE=""
VIDEO_PLAYLIST=""
SUSPEND_AFTER=0
YOUTUBE_UPLOAD="$HOME/git/youtube-upload/bin/youtube-upload"

# Retrieve arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        -s|--script)
            MELT_SCRIPT=$2
            shift 2
        ;;
        -t|--title)
            VIDEO_TITLE=$2
            shift 2
        ;;
        -p|--playlist)
            VIDEO_PLAYLIST=$2
            shift 2
        ;;
        -f|--force)
            FORCE_RENDER=1
            shift 1
        ;;
        --suspend)
            SUSPEND_AFTER=1
            shift 1
        ;;
        *)
            echo "Unexpected arguments: '$1'"
            exit 1
        ;;
    esac
done

# Validate melt script
if [[ ! -f $MELT_SCRIPT ]] || [[ $MELT_SCRIPT != *".mlt" ]]
then
    echo "Melt script invalid: '$MELT_SCRIPT'"
    exit 1
fi

# Ensure video title
if [[ -z $VIDEO_TITLE ]]
then
    echo "Please provide a video title"
    exit 1
fi

# Retrieve video file
VIDEO_FILE=$(xq -r '.mlt.consumer."@target"' $MELT_SCRIPT)
echo "Using video file '$VIDEO_FILE'"

# Render video file
if [[ ! -f $VIDEO_FILE ]] || [[ $FORCE_RENDER == 1 ]]
then
    echo "Starting video render."
    melt $MELT_SCRIPT
    echo "Finished video render."
else
    echo "Video file found, not rendering..."
fi

# Upload to youtube
echo "Starting upload to youtube"
$YOUTUBE_UPLOAD \
--title="$VIDEO_TITLE" \
--playlist="$VIDEO_PLAYLIST" \
--privacy=unlisted \
--client-secrets="$HOME/bin/secrets/youtube_uploader_client_secrets.json" \
$VIDEO_FILE
echo "Finished upload to youtube."

# Suspend when done
if [[ $SUSPEND_AFTER == 1 ]]
then
    echo "Suspending computer."
    systemctl suspend
fi
