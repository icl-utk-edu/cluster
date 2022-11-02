#!/bin/sh

host=$1

if [[ -z $host ]]
then
	echo Need host name!
	exit
fi

echo ssh root@$host ipa-client-install --server vm0.icl.utk.edu --domain icl.utk.edu  --mkhomedir -p gragghia

echo ssh root@$host ipa-client-automount --server=vm0.icl.utk.edu --location=default --unattended


