#!/bin/bash -e

DIR=/apps/spacks/slurm_test
source $DIR/share/spack/setup-env.sh
module load slurm
MUNGED=$(which munged)
sudo -u munge mkdir -p /dev/shm/munge/lib/munge /dev/shm/munge/run/munge /dev/shm/munge/log/munge
sudo -u munge $MUNGED --key-file /etc/munge/munge.key

sudo -u slurm mkdir -p /dev/shm/slurm
SLURMCTLD=`which slurmctld`
sudo $SLURMCTLD -s -f $DIR/slurm.conf

GPUs=$(nvidia-smi -L | wc -l)
SLURMD=`which slurmd`
sudo $SLURMD -s -Z --conf-server morphine --conf gpu:tesla:$GPUs

