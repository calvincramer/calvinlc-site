---
layout: post
title:  "All of the Names"
date:   2024-01-02 12:12:12 -0000
categories: p
published: true
---

A list of all of the names in the US from Social Security Card applications since 1880, for fun and definitely not for profit.

<br>

The original dataset is available [here](https://catalog.data.gov/dataset/baby-names-from-social-security-card-applications-national-data).

I wrote a script to parse and collect the data into complete sets, for a few different categories. [The code is here](https://github.com/calvincramer/us-names). The dataset is split up into files per year, which I just combined all together. It would be interesting to see some visualizations of the data over time, or time and location if that data exists.

There's around 43k unique male names and 70k unique female names. The male and female counts are combined together if there are any number of male and female for that name. For example if there are one million male `Carl`s and five female `Carl`s then the female count file will show one million and five Carls. I only needed the unique names so didn't care to fix this.

A few diamonds in the rough which gave me a chuckle (apologies to anyone out there in this list):
- Willibaldo
- Wyzdom
