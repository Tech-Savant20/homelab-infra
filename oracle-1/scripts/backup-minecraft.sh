#!/bin/bash
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
SERVER_DIR="/home/ubuntu/crafty-4/docker/servers/088cb4ee-1e2d-47f5-a9f5-cac68d4fc06c"
BACKUP_DIR="/mnt/backups"
BACKUP_NAME="minecraft-backup-$TIMESTAMP.tar.gz"

tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$SERVER_DIR" .

# Keep only the last 7 backups, delete older ones
cd "$BACKUP_DIR" && ls -t minecraft-backup-*.tar.gz | tail -n +8 | xargs -r rm --

echo "Backup completed: $BACKUP_NAME"
