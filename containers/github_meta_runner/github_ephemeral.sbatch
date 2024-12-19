#!/bin/bash

#SBATCH -o /tmp/github-slurm-%j.out
#SBATCH --time 300
#SBATCH --constraint docker
#SBATCH --gres github

echo Starting github runner for org=$1 label=$2
cd /apps/docker/icl-build-env/
./run_github_ephemeral.sh $@
