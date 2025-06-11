---
layout: post
title:  "Thank You and Goodbye, Python"
date:   2025-06-10 12:12:12 -0000
categories: p
published: true
---

Python has been my go to language for years. It really has become my happy place. I've gotten really fast at converting my thoughts into python code. But it's time for a change.

Python is simple, probably the first language people learn. Yet python can be complex and deep. You can do metaprogramming, treat anything dynamically, add static type checking, functional programming, GPU programming, you name it.

Not only can you do it all in python, you can pretty much find a package for any task. There is a certain *peace of mind* when you can find tools that others have built in order to quickly accomplish your task at hand.

---

I really wish this wasn't the case, but there are so many negatives to Python that have caused me to look for alternatives. Here are the biggest things:

**One**. Python does not catch the simple errors that compiled languages do. Syntax errors, type errors, you don't know what might happen until you actually *run* the code. But wait! Did you run through **all** paths in the code? Errors may be lurking in code branches that were not executed. Watch out for error paths!

In order to work around this inherent aspect of Python, we need to take testing extremely seriously, measure code coverage, and check every path. In my opinion this is a burden that should be handled by the compiler. That's not to say that we *shouldn't* test everything thoroughly, regardless of the language, but that a 100k line Python project compared to a 100k line `<insert compiled language here>` project start at differing levels of *correctness*.

Python has no real type checking. I know mypy exists. The typing hints in python could have been (and could still be) an opt-in way to do type checking like mypy and TypeScript. Type hints today are little more than documentation, and at best a red squiggly given by linters. Coming from languages with static typing is just a breath of fresh air compared to Python. Linters are not a suitable replacement for compilers. And programming without a compiler is a recipe for wasted time.

**Two**. Python installation and package management is broken. Pip, conda, pipenv, poetry, venv, virtualenv. The situation is so messed up you can look at any other language and their situation will probably be better. Even Javascript.

Python is used both by the user and the system in Ubuntu. You can easily bork your system by writing a hello world SQL program and installing some dependencies. Sure it gives a warning now for "managed" python environments, but I guarantee the number of people that have broken their systems by just **installing** python packages or by daring to *change the default python version* is sobering. I am among this crowd.

The fact that the only *safe* way to use python is within a isolated environment that is a third party tool fills my hard equally with sadness and rage. It's clear that a first-party solution should have been built into the language from day one.

**Three**. Python is no longer a suitable scripting language. This follows from the previous point about packages and environments. If I want to run `myHelperApp.py` that does some utility function, I will now need to run it in an isolated environment, like conda or even docker. This is very different than being able to run a `foo.bash` script anywhere, which is expected to just work!

The caveat here is that if your python scripts *do not install any third party package*, just stick to the standard libraries, *and* don't use recently added python syntax from newish python versions, then scripting for python will be ok.

**Four**. A little point: the underscores for `_private` variables, and even `__reallyPrivate` are not good design. Same for `__dunder__` methods. Just add some keywords, stop hiding functionality in the identifier naming rules.

---

I love you Python, but it's time to take a break. I'll be trying other languages. Rust, Go, and Ruby are top of mind.

Peace.

---

P.S. concerning runtime speed, I have not cared at all about it 99.7% of the time. But the times where I do care about speed using python, silly things like:
```python
saved = x.y.z.foo
for n in range(1_000_000_000):
    saved(n)
```
will be faster than
```python
for n in range(1_000_000_000):
    x.y.z.foo(n)
```
because every `.` member access is essentially a dictionary access on an objects set of variables and methods.

Sacrificing the readability of the source code is a big ask, Python.
