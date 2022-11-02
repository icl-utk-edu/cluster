#!/bin/sh

LOCKFILE=/tmp/.backup.lock
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    #echo "A previous backup process is already running. Exiting..."
    exit
fi

backup ()
{
  local backup_host=$1
  local source=$2
  local extra_options=$3
  rsync -za --log-file=/main/logs/${backup_host}.log --delete --delete-excluded \
       --exclude-from=/main/scripts/backup.excl $extra_options \
       ${backup_host}:$source /main/data/$backup_host \
       || echo Error $backup_host &
}


# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

backup saturn.icl.utk.edu / "--exclude=/var/lib/nfs --exclude=/run --exclude=/var/chroots --exclude=/scratch"

backup venus.icl.utk.edu / "--exclude=/var/lib/nfs --exclude=\"/export/homes/*/*.tgz\" --exclude=\"/export/homes/*/*.tar.*\"  --exclude=\"/export/homes/*/*.old/**\" --exclude=/mnt/scratch"

backup ash2.icl.utk.edu / "-x --exclude=/sw/logs ash2.icl.utk.edu:/sw" 

backup omega0.icl.utk.edu /mnt "--exclude=home/oldhomes"

backup phi.icl.utk.edu / "--exclude=/home --exclude=/nfs"

backup xylitol.icl.utk.edu /var/lib/jenkins "--exclude=jenkins/workspace"

wait

/usr/sbin/zfs snapshot main@`date '+%F_%T'`

rm -f ${LOCKFILE}

