#!/bin/bash
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATA_DIR="/home/ubuntu/vaultwarden-data"
BACKUP_NAME="vaultwarden-backup-$TIMESTAMP.tar.gz"
TMP_PATH="/tmp/$BACKUP_NAME"
REMOTE_USER="uday"
REMOTE_HOST="<JARVIS_TAILSCALE_IP>"
REMOTE_DIR="~/backups/vault-oracle"
SSH_KEY="/home/ubuntu/.ssh/jarvis-backup"

tar -czf "$TMP_PATH" -C "$DATA_DIR" .

scp -i "$SSH_KEY" "$TMP_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"

# Clean up local temp file
rm -f "$TMP_PATH"

# On Jarvis, keep only the last 7 backups
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && ls -t vaultwarden-backup-*.tar.gz | tail -n +8 | xargs -r rm --"

echo "Backup completed: $BACKUP_NAME"
