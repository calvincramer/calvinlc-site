---
layout: post
title:  "The Pragmatic Programmer"
date:   2025-01-24 12:12:12 -0000
categories: p
published: true
---

My thoughts and takeaways from David Thomas' and Andrew Hunt's *"The Pragmatic Programmer"*.

---


#### Kaizen
*Kaizen* is described as the Japanese term for *"continually making small improvements"*. This part popped out to me since it highlights the importance of actually using your software and improving the imperfections you find. *Kaizen* also reminds me of *Digital Gardening*, which I honestly don't know much about, but it sounds really pleasant and something that I could enjoy.

*Kaizen* also related to the advice *Don't outrun your headlights, it's impossible to know the future*, by taking small steps. These two things put value in software quality and incremental progress which I am fully behind on.

#### Good Enough Software
An opposing force to *Kaizen*, the *"Good enough software"* message tells us to *know when to stop*. Don't waste your time on things that no one will appreciate. Programmers have the tendency of perfectionism, and David and Andrew are warning us that its is usually a waste of time (unless the perfectionism pays off, then by all means strive for it!). The authors also mention *over-engineering*, which is a lesson I intend to follow: try the simplest solution first; don't do the complicated solution unless absolutely necessary.

I also liked tip 36, which is *"you can't write perfect software"*. Keeping focused on the ultimate goal rather than being distracted by perfection will really help do *more* while intentionally ignoring *distractions*.

#### ETC Principle
The *"Easy to Change"* principle describes **things that are easy to change as good. And good things are easy to change**.

This principle is very applicable, and is an especially enticing principle since the authors state *"every design principle is a special case of ETC"*. I tend to agree with this thinking, and will adopt this principle as a kind of universal theory of software engineering. At least until there is evidence to the contrary, or a principle with more explanatory power comes along.

#### The Tracer Bullet Model
I enjoyed learning about the *Tracer Bullet Model*, which is like the *prototyping model* but how I imagine good engineers actually prototype. *Tracer Bullet* creates a skeleton architecture **PoC** which actually solves some use-case of your problem. It uses test data, and stubs out functionality. Then over time pieces of the architecture are implemented and additional use-cases are added. This allows for requirements to not be specified upfront (don't try to predict the future by specifying all requirements before writing any code). Then everyone can work with a working program and make changes from there. Having a working model that non-engineers can look at and use is very important.

I prototyping model in the book I felt was setup as a straw man, in that prototypes aren't completely thrown away in the real world. The prototype model describes that prototypes be thrown away after being given to the customer (internal or external) and only knowledge being retained in the next iteration. If we were to follow this model, I would predict a large majority of the code would be duplicated between successive prototypes, since *source code is essentially domain knowledge written down*. In reality, I think most SWEs do something in-between prototyping and tracer bullet.

I intend to follow the tracer bullet model next chance I get and have high hopes for it.

#### Interfaces > Inheritance
I started out programming learning Java, and went through the OOP self-deprogramming years ago. So I was validated with tip 52: *"interfaces are better than inheritance for polymorphism"*.

Interfaces and functional programming (not to the lambda calculus extreme, just focus on functions first) help maintain what's actually important - the operations. OOP on the other hand is mostly a distraction thinking about the relationship among data and what data *owns* what operations and restrictive labeling and categorizing. Like a 1800's scientist trying to organize the whole world.

That's not to say OOP doesn't have it's place. I'll would just recommend to junior engineers to try functions and interfaces first, and if your really need OOP then use it. The grass is greener on the other side, and you don't need to write 2000 lines of OOP code that could be written in 300 of functional code!

#### Parallel vs Sequential Thinking
This is a long term goal of mine - to get more comfortable and experienced writing parallelized code. It is also a double-edged sword. Often the simplest way to write a program is the sequential version, and the sequential version is often enough to solve the problem.

Unfortunately, I find it easier to express an algorithm in terms of a parallelized DAG (directed acyclic tree) of steps rather than to actually implement said DAG in code. Maybe its the languages I've been using (Python, Typescript) that don't lend well to this implementation, or me not using some library that makes the DAG to code mapping easy. I've had success with parallelization in Rust, but Rust is... you all know... too much difficultly compared to the loss of productivity.

My long term goal is to *get to a point that implementing an optimally parallelized algorithm becomes as beautiful in code as the DAG of steps looks*.

### Conclusion
David and Andrew's *"The Pragmatic Programmer"* is filled with beautiful and valuable gems. I wish I would have read it earlier in my career, so therefore I recommend it for those starting their journey in coding. Even for those with decades of experience, flip through this book to make sure you aren't missing something, or to adjust yourself to better practices.

Take these author's experience and tips to heart. Actively apply them in your next projects. They will make you a better programmer and will make you and the people you work with happier.