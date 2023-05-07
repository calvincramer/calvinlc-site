# Install Ruby / Jekyll
1. `sudo apt-get install ruby-full build-essential zlib1g-dev`
2. Add to rc:
```sh
export GEM_HOME="${HOME}/gems"
export PATH="${HOME}/gems/bin:${PATH}"
```
3. `gem install jekyll bundler`


# Run locally
- run in `site/`
```sh
bundle exec jekyll serve
```

# Build and Deploy Site
- run in `site/`
- `bundle install`
- if need to commit, then commit




# ETC
```sh
dig www.calvinlc.com +nostats +nocomments +nocmd
```