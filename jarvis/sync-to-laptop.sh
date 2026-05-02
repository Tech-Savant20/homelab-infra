#!/bin/bash
# Usage: ./sync-to-laptop.sh "movie|series|anime" "/path/to/file"

TYPE=$1
SOURCE=$2
LAPTOP_IP="<LAPTOP_TAILSCALE_IP>"
LAPTOP_USER="<LAPTOP_USERNAME>"
SSH_KEY="/home/uday/.ssh/laptop_key"

case "$TYPE" in
    movie)
        DEST="C:/jarvis jellyfin/movies/"
        ;;
    series)
        DEST="C:/jarvis jellyfin/series/"
        ;;
    anime)
        DEST="C:/jarvis jellyfin/anime/"
        ;;
    *)
        echo "Unknown type: $TYPE. Use movie, series, or anime"
        exit 1
        ;;
esac

# Convert Radarr's /data path to actual host path
HOST_SOURCE=$(echo "$SOURCE" | sed 's|/data|/opt/media|g')

scp -i $SSH_KEY -r "$HOST_SOURCE" "$LAPTOP_USER@$LAPTOP_IP:$DEST"
echo "Transfer complete: $HOST_SOURCE → Laptop $DEST"
