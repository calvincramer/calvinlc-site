---
layout: post
title:  "Noise for Free"
date:   2024-06-24 12:12:12 -0000
categories: p
published: true
---

Brown noise generator for free. No network required. No more 12 hour youtube video.

<br>

We're using the `play` command from the [SoX](https://github.com/rbouqueau/SoX) project.
```sh
apt install sox
```

Then in your `.[bash,zsh]_aliases`:
```sh
alias brown-noise="nohup play -q -n -t alsa synth brownnoise vol -8dB </dev/null 1>/dev/null 2>&1 &; disown %1"
alias brown-noise-stop='pkill --full "play -q -n -t alsa synth brownnoise vol -8dB"'
```

I'm not too happy with `nohup` in solving the *"spawn a background disowned task please"* pattern. Let me know if there's a better way.