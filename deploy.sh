#!/usr/bin/env bash

set -xue

HOST=chi211.greengeeks.net

if ps aww -o command | grep "jekyll serve" | grep -vq "grep"; then
    echo "jekyll already running, will run into error when building"
    exit 1
fi

cd "$(dirname ${BASH_SOURCE[0]})"
cd site

# Build to "_site/" folder
JEKYLL_ENV=production bundle exec jekyll build

# Deploy
tar -czf site.tar.gz -C _site/ .
scp -q site.tar.gz calvinlc@${HOST}:/home/calvinlc
ssh -t calvinlc@${HOST} '
    cd /home/calvinlc &&
    rm -rf public_html &&
    mkdir public_html &&
    mv site.tar.gz public_html &&
    cd public_html &&
    tar -xf site.tar.gz &&
    rm site.tar.gz
'
echo "Good"
