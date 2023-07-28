---
layout: post
title:  "Containers Are Not Bulletproof"
date:   2023-07-27 12:12:12 -0000
categories: p
published: true
---

There was a ticking time bomb on my machine. It finally blew up and took docker with it - or at least it changed my impression of docker containers.

# <nbsp>
<br>

Obligatory PSA that `docker != containers` [^1]

<br>

`$X` years ago when I first joined `$COMPANY`, I was advised to set my machine's *NTP* - Network Time Protocol - settings to a particular NTP server hosted by `$COMPANY`. If I didn't do it then things may not work! How little I knew at the time! So I set the recommended config and forgot about it until a few days ago.

---

There is a ***tool*** for the project I'm working on currently that interacts with various endpoints and services. It's used every day by users and automation alike. Then one day ***tool*** started giving me errors when requesting an auth token. It gave an HTTP `406` error, which means *Not Acceptable*. You tell me HTTP, I've got places to be and things to do, unacceptable! Time to investigate.

---
<br>
<br>

## <nbsp>

I first saw the error on my dev machine. My first thought is try using ***tool*** in a docker container. In the container, it gave the same `406`. WTF? I though docker was supposed to solve all my problems!

---

Next I reached out to my teammates and gave them some commands to run. Luckily the docker container I ran was for executing our test suite, so I could share the *same command* and it should give the exact *same result* on their machines, right? Unfortunately, it worked on *all* of their machines, both in the container and on the bare host. Looks like it's just my machine then.

---

The error message given by ***tool*** did not offer much useful information, or any leads to start the search debugging. So I tried the regular gamut of blind options such as upgrading ***tool*** to the newest pre-compiled version, compiling ***tool*** from source, downgrading ***tool*** to match teammate's version, upgrading `apt` packages, even *rebooting!* Alas, turning it off and on again did not fix the issue.

Maybe ***tool*** was loading some shared libraries? No, `readelf` says it's static. Besides, docker wouldn't load shared libraries from the host, right?!

<br>

### <nbsp>

<br>

Maybe the host's kernel version matters? Does that matter to docker, or does docker abstract that away? Comparing kernel versions with teammates didn't lead to anything actionable.

---

After using docker for so long I was pretty sure docker containers didn't run their own kernel, so they must pass their syscalls to the host kernel. I investigated that path by capturing all the syscalls with `strace`. After my teammate and I grepped and scanned furiously, no delicious fruits of knowledge had emerged.

We tried similarly with *wireshark* for network capture. No fruit from here either. We updated SSL / CA certificates - grasping more straws here - without any luck.

---

This is a good example where I assume the answer *must* lie in something complex. I should have started with the most simple explanations first. Thanks again, Ockham!

<br>

#### <nbsp>

<br>

Finally a tried to login to the project's website over *VNC*. I had been using my laptop to connect to the dev machine located in `$CLASSIFIED`, and logging in over the laptop had been working fine. Logging in graphically on the dev machine finally gave us a *good error message*: something along the lines of **Whoops! Something failed, your credentials are wrong or your system clock is off!**

And after checking the system time with `timedatectl` it said (times and dates not accurate, comments for emphasis):
```sh
$ timedatectl
#              Local time: Thu 2023-01-01 00:00:00 UTC
#          Universal time: Thu 2023-01-01 00:00:00 UTC
#                RTC time: Thu 2023-01-01 00:00:00
#               Time zone: Antarctica/Troll (GMT, +0000)
System clock synchronized: no
              NTP service: n/a
#         RTC in local TZ: no
```

---

So NTP was off, and my clock wasn't synchronized! I wonder how long that has been the case. I reconfigured NTP by poking and prodding at the config and services until NTP was back online and the clock was synchronized. I tried again and the problem was solved, ***tool*** is happy, I am happy!

<br>

##### <nbsp>

<br>

But wait, that means that even in a container the HTTP requests get timestamped with the host's time, or are effected in some way by the lack of host system time being synchronized. Ok, I'm a little surprised at this.

---

So I searched around for some info on what the docker runtime is and isn't (assuming Linux-like machines):
- docker is *not an emulator* like Qemu - it does not take each machine instruction in the container and emulate it's behavior in software. In fact containers run similarly to a normal userland process, on bare metal.
- docker is *not a virtual machine* - it does not run it's own kernel
- docker is *not a hypervisor* - it does not run independent OSes!

The docker runtime is basically:
- linux *namespaces* allowing a docker container to have it's *own resources* without needing to worry about the rest of the system, in terms of the PID space, networking, user UID GID space, and more
- linux *cgroup* allowing putting *resource constraints* (CPU, memory, etc) on the container (as a userland process)
- *chroot* allowing to have an *isolated filesystem* for the container, and to not allow the container to see outside its root folder!

This high level understand is good enough for me now, until I need get involved further... in the next bug, for sure.

---

<br>

###### So what did I learn?<nbsp>

Well this was the first time I encountered an issue plainly coming from the host machine affecting a docker container. Now I've shifted my mental model to one where containers - like user processes - can behave as if they own the *whole CPU* and *memory* address space, and in addition behave as if they own the whole userland part of the operating system, with their own *users*, *groups*, *file system*, *libraries and dependencies*, *processes space*, and *networking*.

...but the host kernel still owns *everything* outside of userland, and the container runtime works with the kernel to enforce how much real system resource can be used.

I see this idea being closer to a phone app than a VM or regular userland process - having heavy constraints and permissions placed on it by the OS / runtime. I've never done iOS or Android app development, nor worked on a phone OS, so let me know if this is off the mark.

---

The other lesson learned is that having someone to debug with and to shoot ideas with is extremely helpful in figuring out these puzzles. Thank you for jumping in to help Mr. Boat Man. I'll make sure to do the same for others whenever I get the chance.

<br>
<br>
<br>

[^1]: *docker* is not the same as *containers*. [OCI](https://opencontainers.org/) and alternatives like [kaniko](https://github.com/GoogleContainerTools/kaniko), [buildah](https://buildah.io/), [vagrant](https://developer.hashicorp.com/vagrant), and [podman](https://podman.io/) are good things too!