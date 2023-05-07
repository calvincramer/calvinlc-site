#!/usr/bin/env bash

set -e
set -x

cd "$(dirname ${BASH_SOURCE[0]})"
cd site

# Build to "_site/" folder
JEKYLL_ENV=production bundle exec jekyll build

# Deploy
tar -czf site.tar.gz -C _site/ .
scp site.tar.gz calvinlc@chi110.greengeeks.net:/home/calvinlc
ssh calvinlc@chi110.greengeeks.net '
    cd /home/calvinlc &&
    rm -rf public_html &&
    mkdir public_html &&
    mv site.tar.gz public_html &&
    cd public_html &&
    tar -xf site.tar.gz &&
    rm site.tar.gz
'

