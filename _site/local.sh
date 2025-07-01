#!/usr/bin/env bash

set -e
set -x

cd "$(dirname ${BASH_SOURCE[0]})"

JEKYLL_ENV=local bundle exec jekyll serve
