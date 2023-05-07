# Install Ruby / Jekyll
1. `sudo apt-get install ruby-full build-essential zlib1g-dev`
2. Add to rc:
```sh
export GEM_HOME="${HOME}/gems"
export PATH="${HOME}/gems/bin:${PATH}"
```
3. `gem install jekyll bundler`


# Run locally
`local.sh`

# Build and Deploy Site
`deploy.sh`


# ETC
- See resolution of website
```sh
dig www.calvinlc.com +nostats +nocomments +nocmd
```

- ssh to website host
```sh
ssh calvinlc@chi110.greengeeks.net
```

# Jekyll / Ruby Notes
```sh
_layouts    # Generic HTML templates
_includes   # HTML partial things, like templates too

_sass  # CSS

_site       # Generated site
_plugins
_data       # ?


```
- https://jekyllrb.com/docs/front-matter/
- uses Kramdown for rendering markdown
- `bundle info --path minima`
- uses `liquid` for variable substitution
    - https://jekyllrb.com/docs/liquid/