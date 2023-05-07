#!/usr/bin/env bash

set -e
set -x

cd "$(dirname ${BASH_SOURCE[0]})"
cd site

bundle exec jekyll serve
