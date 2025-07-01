---
layout: post
title:  "Fourier's Cat"
date:   2025-02-16 12:12:12 -0000
categories: p
published: true
---

An authentic picture of Joseph Fourier's cat from the 1800s, provided by shoddy computer vision.

---

![Image]({{ '/assets/ft-fun.jpg' | relative_url }}){: width="400" .center-image }

*The profile icon I use on this website and most sites are generated with a broken program*. It has a *bug* which produces nice looking results. Is it really a bug then?

The original intention of this script is to explore compressing images by removing low-frequency noise from images. The main idea is that when we look at images we care about the details, which is the high-frequency information. So the program does some mapping between spatial and frequency domains thanks to good ol' [Fourier](https://en.wikipedia.org/wiki/Joseph_Fourier) who we ~~fondly~~ remember from our calculus classes.

Kudos to you if you find the bug. You did good. I think it's better with the bug, so please no squashing :^)

---

Install: `python3 -m pip install numpy opencv-python`

`ft-fun.py`
```py
#!/usr/bin/env python3
import argparse
from os.path import isfile, basename, join, dirname
from cv2 import imread, IMREAD_COLOR, imwrite
import numpy as np
from numpy.fft import fftshift, fft2, ifft2, ifftshift
parser = argparse.ArgumentParser()
parser.add_argument("-f", required=True, type=str, metavar="<file path>", help="Input file")
parser.add_argument("-w", required=False, default=100, type=int, metavar="<int>", help="Width")
args = parser.parse_args()
assert args.f is not None, "Need to give input file with -f"
assert isfile(args.f), "Input file does not exist or is not a file"
f_parts = basename(args.f).split(".")
out_path = join(dirname(args.f), f"{f_parts[0]}-ft-fun-{args.w}-ft-fun.{'.'.join(f_parts[1:])}")
img = np.ndarray.astype(imread(args.f, IMREAD_COLOR), dtype=np.double)  # bgr >:(
ch = img.shape[0] // 2
cw = img.shape[1] // 2
hw = args.w // 2
out = np.zeros(img.shape)
for chan_idx in range(img.shape[2]):
    c = fftshift(fft2(img[:, :, chan_idx] / 256.0))
    c[ch - hw : ch + hw, cw - hw : cw + hw] = 0
    out[:, :, chan_idx] = np.around(np.real(ifft2(ifftshift(c))) * 256.0).astype("uint8")
print(f"Writing to {out_path}")
imwrite(out_path, out)
```

