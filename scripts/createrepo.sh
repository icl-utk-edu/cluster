#!/bin/sh

if [ ! $1 ]
  then
  echo "Need a repo directory."
  exit
fi

cd $1
cp -a repodata repodata.bak
createrepo -s sha -g yumgroups.xml .
rm -rf .olddata
createrepo -s sha -g yumgroups.xml .
mv repodata.bak/.svn repodata/
rm -rf repodata.bak

