#!/bin/bash
# Commentaire
backup_path="/root"
backup_dir="databases"
backup_logs="/root/backups.logs"
    
# Commentaire
dest="/mnt/backups/centos"
    
# Commentaire
timestamp=$(date "+%H-%M-%S_%d-%m-%y")
hostname=$(hostname -s)
archive_file="$hostname-$timestamp.tgz"

# Commentaire
tar -zcf $dest/$archive_file -C $backup_path $backup_dir

# Commentaire
echo "Backup completed at $timestamp" >> $backup_logs
