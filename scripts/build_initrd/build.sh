#!/bin/bash -e

export kVer=${1:-`uname -r`}

docker build -t dracut --build-arg kVer=$kVer .
docker run --rm dracut cat /initrd.img > initrd-$kVer.img

