#!/bin/bash -e

NAME=github_meta_runner

GITHUB_UID=$(id -u github)

docker build -t $NAME \
	--build-arg GITHUB_UID=$GITHUB_UID \
	--build-context munge=/etc/munge/ \
	--build-context slurm=/etc/slurm/ \
	.

docker rm -f $NAME || true

export TOKEN=`grep github_runner_pat /cluster/secrets | awk '{print $2}'`

docker run --name $NAME \
	--restart=unless-stopped -d --net=web \
	-e ORG -e TOKEN \
	$NAME

