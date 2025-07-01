# Install Ruby / Jekyll
1. `sudo apt-get install ruby-full build-essential zlib1g-dev`
2. Add to `.rc` file:
```sh
export GEM_HOME="${HOME}/gems"
export PATH="${HOME}/gems/bin:${PATH}"
```
3. `gem install jekyll bundler`
4. cd `site`
5. `bundle install`

# Run locally
`local.sh`
