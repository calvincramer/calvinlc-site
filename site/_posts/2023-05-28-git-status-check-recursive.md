---
layout: post
title:  "Drowning in Git Clones"
date:   2023-05-06 12:12:12 -0000
categories: p
---

At some point in the past few years I realized that working on a more and more git repos simultaneously led to forgetting if each clone is kept up to date, so I created a little tool to see the status of many clones at once. I'm really surprised at how useful it has been for my workflow. This tool is essentially looks for git clones recursively like `find` and prints a one-line `git status` message for each.

The first version of this tool was written in *python* (uhg how slow!). I looked at the code recently in order to make improvements, and based upon the various issues I reckon it was probably written in a hurried state so I could quickly move on with something else.

When I first considered to make a writeup for this I thought it would be necessary for a rewrite optimizing execution time and correctness. *I've concluded this is a waste of time*. The first version - even in its crappy state - worked fine, *good* even.

Here is the [Python Code TODO INTERNAL LINK](#Python Code), and also a simple bash version . Here's an example run using the bash version.

```sh
user@linux:~/repos $ git-status-check-recursive
./foo/.git    good
./bar/.git    (2 commits behind) (unstaged changes) (untracked changes)
./baz/.git    (3 commits ahead) (staged changes)
./baf/.git    (2 commits behind) (unstaged changes) (1 stash)
```

This project has been a lesson in recognizing what effort is actually necessary - the classic "*premature optimization is the root of all evil*".

I will summarize the outcomes of the
<br>
<br>
<br>
<br>
<br>

---


## Extra Unnecessary Research, Feel Free To Skip!
The first version is pretty fast; as fast as it takes to run `git status` on each clone. `git status` actually caches its result, so if nothing changed then it runs fast!

### What to improve / why create a new version?
- speed
    - we have a responsibility to make sure our tools are fast, not to hide behind modern fast hardware
    - I don't trust python, need a quantifiable excuse to migrate away from it
- flexibility
    - I can needing a similar tool, for example to fetch or pull all repos recursively
- python was a good choice for the first implementation, not it's time to move away from the proof of concept / scripting language
- finding out states in git that I missed

### All possible states a clone can be in?
In the first version I started out by just going over the git states I knew and have seen before:
- untracked and uncommitted changes (aka untracked - new files not seen by git before)
- tracked and uncommitted changed (aka modified)
- added changes (aka staged, what will be committed)
- local commit not pushed (your branch is ahead by `N` commits!)
- branch behind remote by `N` commits
- clean state with a remote branch (your branch is up to date with origin/X)
- clean state without a remote branch (branch local to your clone)
- detached head without changes
- detached head with changes
- no commits yet (new repo)

but I know at least of `git stash` which I haven't handled yet, since I never use it (unintentional avoidance maybe, I just commit and then squash later). So here are all of the possible states a clone can be in, broken down into multiple independent areas. After all, the whole point of this tool is to provide this information in a clear manner!

1. *working directory*
    1. no changes
    2. changes to tracked/untracked files
2. *staging area*
    1. nothing staged
    2. things staged
3. *head status*
    1. no change - head is at remote head
    2. detached
    3. ahead by N commits
    4. behind by N commits
    5. ahead by N commits and behind by M commits
4. *stash / index*
    1. no stashes
    2. `N` stashes where `N` > 1
5. *special operations in progress*
    1. no special operations in progress
    2. merge in progress
        - only happens when there are conflicts
        - will cause conflicts to be put in working directory
        - will cause merged files to be put in staging
        - run `git commit` or `git merge --continue` to continue
    3. rebase in progress
        - happens on conflict
        - cant do rebase with staged or unstaged changes changes will
    4. cherry-pick in progress
        - happens on conflict
        - can't do when things staged
    5. bisect in progress

So now we have five (mostly) independent states to track, not considering submodules I know. I decided to combine the categories of "changes to tracked files" and "changes to untracked file", since most of the time I don't care to differentiate these two groups. An example of one possible clone status is (1) untracked changes to `README.md`, (2) changes to `foo.txt` are staged, (3) our branch is behind by 5 commits, (4) we have two stashes, and (5) there is a bisect in progress.

If there are more states please let me know!

### Enumerating all possible states for testing
In order to check our status reports correctly, we need to go through each possible state. I made a bash script to do this called `make-test-clones.sh`. I learned that a merge cannot be started with there are changes in staging. I also learned rebase is more picky; it cannot be started if there are any changes in staging or if there are any unstaged changes.

This little script is actually good to get used to what `git status` should print, for beginners.

### Seeing how version 1 handles all states
How does the first version handle the different possible states? Not so well:
```sh
...
./WORKn-STAGEn-HEADa-STASHn-SPn .................. (commits to push)
Traceback (most recent call last):
  File "/home/cjc/repos/linux-scripts/git-status-check-recursive", line 182, in <module>
    print_repo_statuses(base_dir, PRINT_WIDTH, parse_args())
  File "/home/cjc/repos/linux-scripts/git-status-check-recursive", line 161, in print_repo_statuses
    status = get_git_status_string(std_out.decode('utf-8'))
  File "/home/cjc/repos/linux-scripts/git-status-check-recursive", line 125, in get_git_status_string
    raise ValueError(f'Cannot interpret git status message or logic error: [[[[[\n{status}\n]]]]]')
ValueError: Cannot interpret git status message or logic error: [[[[[
interactive rebase in progress; onto 2f2aa8f
Last commands done (2 commands done):
   pick a74339b add script
   pick 2c6d853 Edit readme
Next commands to do (6 remaining commands):
   pick 65fb454 conflict please
   pick f4bb92e random commit for padding
  (use "git rebase --edit-todo" to view and edit)
You are currently rebasing branch 'main' on '2f2aa8f'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")

]]]]]
```
The first version doesn't handle rebase, and actually crashes if it doesn't find any information from the output of `git status`. Let's patch it so returns an error rather than crashing (`version-2-py`), how does this stack up?
- any special state such as rebase, merge, cherry-pick in progress is not recognized
- anything in stashed is not recognized

Let's improve this.

## How to get git status in better way than calling `git status`?
The python version found the status of a clone by running `git status` in a subprocess, and then checking for particular substrings in the output. For example, if `HEAD detached at` was in the output then we know that the head is detached, simple and morbid!

Porcelain v1 guide
```sh
?? # untracked
 M # unstaged modifications
A  # staged / added changes

```
Porcelain v2 guide:
    - Main categories of lines (first character)
        - 1 --> orginary changes
        - 2 --> renamed things
        - u --> unmerged
        - ? --> untracked
        - ! --> ignored
    - XY - X is for staged, Y is for unstaged
        - M - modified
        - A - added
        - D - deleted
        - R - renamed
        - C - copied
        - U - unmerged (`u UU` = both modified, `u AA` = both added)
    - `--branch` gives:
```
# branch.oid <commit> | (initial)        Current commit.
# branch.head <branch> | (detached)      Current branch.
# branch.upstream <upstream_branch>      If upstream is set.
# branch.ab +<ahead> -<behind>           If upstream is set and the commit is present.
```

Options:
1. `git status --show-stash --branch`
    - can get info?
        - [x] empty directory
        - [x] changes in working directory?
        - [x] changes in staging
        - [x] head detached?
        - [x] head ahead?
        - [x] head behind?
        - [x] head ahead and behind? `Your branch and 'origin/main' have diverged, and have 3 and 2 different commits each, respectively.`
        - [x] stashed changes?
        - [x] merge in progress?
        - [x] rebase in progress?
        - [x] cherry pick in progress?
        - [x] bisect in progress?
    - summary:
        - text based, which is brittle
        - can get all info, good
2. `git status --porcelain=v2 --show-stash --branch` (show stash unecessary)
    - can get info?
        - [x] empty directory   `branch.oid (initial)`
        - [x] changes in working directory? `XY`
        - [x] changes in staging `XY`
        - [x] head detached? `branch.head (detached)`
        - [x] head ahead?   `branch.ab +AHEAD -BEHIND`
        - [x] head behind?
        - [x] head ahead and behind? `branch.ab +3 -2`
        - [ ] stashed changes? - **NO**
        - [x] merge in progress? - look for any `u` at the first character
        - [x] rebase in progress? - look for any `u` at the first character
        - [x] cherry pick in progress? - look for any `u` at the first character
        - [ ] bisect in progress? - **NO**
    - summary:
        - consistent text format, less brittle
        - doesn't check stash even though we give `--show-stash`
        - very easy to get info about head being ahead/behind/detatched
        - merge, rebase, and cherry-pick are all combined into a `u` (unmerged) line, not good if we want to tell which one of these is in progress
        - doesn't tell if bisect in progress
3. `git status --porcelain=v1 --show-stash --branch` TODO
    - can get info?
        - [x] empty directory -- `## No commits yet on master`
        - [x] changes in working directory?
        - [x] changes in staging
        - [x] head detached? - `## HEAD (no branch)`
        - [x] head ahead? - `## main...origin/main [ahead 3]`
        - [x] head behind? - `## main...origin/main [behind 2]`
        - [x] head ahead and behind? `## main...origin/main [ahead 3, behind 2]`
        - [ ] stashed changes? - **NO**
        - [x] merge in progress? - `look for any UU or AA`
        - [x] rebase in progress? - `look for any UU or AA`
        - [x] cherry pick in progress? - `look for any UU or AA`
        - [ ] bisect in progress? - **NO**
    - summary:
        - similar to porcelain v2
        - same limitation with merge, rebase, cherry-pick
4. `git ls-files -t --cached --deleted --others --stage --modified` TODO
    - worse version than `git status`
5. `.git` folder TODO
    - maybe, don't want to go down this rabbit hole though
6. `git status --short --branch --show-stash`
    - very similar to porcelain v1 (basically the same), but with color!
    - also all paths will be relative to the root of the clone

So the regular `git status --show-stash --branch` can get all the info we want in one command, which is nice, but we need to be careful parsing it. On the other hand `git status --porcelain=v2 --show-stash --branch` is promising being easy to parse (that's the whole point!), but we need to solve two problems: (1) run another command to see how many stash entries there are (why is `--show-stash` being ignore, how sad!), and (2) differentiate between ongoing merge, rebase, cherry-pick, and bisect.

Solving (1) is as easy as running something like `git stash list -z --pretty=format:'A' | tr -d '\0' | wc -c`. Or looking at `.git/logs/refs/stash`

Luckily solving (2) is easy since git has files under `.git` that reveal what is going on:
- `.git/BISECT_LOG`
- `.git/CHERRY_PICK_HEAD`
- `.git/MERGE_HEAD`
- `.git/REBASE_HEAD`

Hopefully these files have been around for a while, and won't change for a while.

### Poor man's recursive status check
Before we go on, it's important to say that this does not need to be overly complicated. It can just be a disgusting golfed (poorly) shell command!
```sh
find . -type d -name '.git' -exec bash -c 'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo' \;
```

Or as a `bash` alias:
```sh
alias git-status-check-recursive='find . -type d -name '"'"'.git'"'"' -exec bash -c '"'"'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo'"'"' \;'
```

This approach is suprisingly usable and fast.

### Benchmarking
I set up a benchmark to see if see if we can actually do better. `bench.sh` - warning this it clones around 85 MiB worth of clones.

- original version: **10** milliseconds per clone
    - 0.12s / iter

- poor mans version: **16** milliseconds per clone

Wow! I expected python to be much slower.

### Version 3 - golang
In this version we're going to do the same thing that the poor man's version did where we are using `find` for to find each clone, then our program written in golang will print the status.

TODO


### Version 4 - can we do better than UNIX `find`?
In this version we're going to see if we can be faster than `find`, with its paltry 40 years of existence (just about, as of December 2022). `find` was first released in UNIX System V, back in 1983!

Jokes aside, I think the commands under `find -exec` run syncronously, as evidenced by when `find` finds 10 results and execs a one second sleep for each, the whole command takes 10 seconds.

TODO



### Future Improvments
- Git submodules - I'll need to rip this fear BAND-AID(®) off some day.
- checking `git status` while a `git clone` is happening, will show `No commits yet` like a new repo.


### Etc, not sure where to include
- Note `git stash` takes the **staged** and **tracked** changes, but not **untracked** changes
- During writing this I've mixed up "stashed" and "staged" many times, let me know if there are any mixups still!
- doing a `git merge` when there are staged changes will cause the merge to fail and the return code to 128 is set
- doing a `git merge` and conflicts happen will set return code to 1
- `git cherry - Find commits yet to be applied to upstream` cool, never used this before
- https://github.com/robertgzr/porcelain




---

[^1]: asdf asdf

[^2]: this is the footnote text


---

# Python Code
asdf









