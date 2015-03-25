#!/bin/bash

. /root/.PASSPHRASE

gun=$(date +%y%m%d)
gunluk="duplicity_${gun}"

/usr/bin/duplicity \
	--exclude **\*.log --log-file="${gunluk}" \
	--rsync-options="--delete-excluded --force" \
	--full-if-older-than 3M \
	--encrypt-sign-key 4D0AC07F /some/path/ gs://backup-bucket

/usr/bin/duplicity remove-all-but-n-full 2 gs://backup-bucket >> "${gunluk}"

cat "${gunluk}" | mailx -s "[Duplicitiy] report (gcs)" mailalias
rm "${gunluk}"

/usr/bin/duplicity \
	--exclude **\*.log --log-file="${gunluk}" \
	--rsync-options="--delete-excluded --force" \
	--full-if-older-than 3M \
	--encrypt-sign-key 4D0AC07F /some/path/ scp://user@server:22/backup/path

/usr/bin/duplicity remove-all-but-n-full 2 scp://user@server:22/backup/path >> "${gunluk}"

cat "${gunluk}" | mailx -s "[Duplicity] report (server)" mailalias
rm "${gunluk}"
