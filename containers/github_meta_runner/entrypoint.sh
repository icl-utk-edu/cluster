#!/bin/sh

sudo -u munge munged

sudo -u github --preserve-env=TOKEN /opt/github_meta_runner

echo Done

