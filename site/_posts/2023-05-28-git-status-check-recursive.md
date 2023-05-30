---
layout: post
title:  "Drowning in Git Clones"
date:   2023-05-06 12:12:12 -0000
categories: p
published: true
---

At some point in the past few years I realized that working on a more and more git repos simultaneously led to me forgetting which clone are kept up to date and what changes they have, so I created a little tool to see the `git status` of many clones at once. I'm really surprised at how useful it has been for my workflow, and how I consistently use it every day. This tool essentially looks for git clones recursively (like `find`) and prints a one-line `git status` summary.

The first version of this tool was written in ***python*** (uhg how slow, I know!). The code for the first version looks like it was written in a hurried state. I was probably fed up with the issue and made this tool quickly to then move on with other tasks.

At first I was *determined* to make a new version in a compiled language in order to optimize for execution speed and correctness. After all, who would want to use my suboptimal **interpreted** script, rather than a *extremely fast* compiled C or Golang program?

***I have since concluded that spending time on a reimplementation is and has been a waste of time***. The first version - even in its hacky and hurried state - worked fine, **great** even. It's worked pretty much perfectly for a long time. A reimplementation would have no benefit other than an unnoticeable speed improvement and to avoid embarrassment by not using the best fastest language of the month.

Here is the <A href="#python-code">Python implementation</A>. Here's a similar implementation for <A href="#bash-code">Bash</A> that works well too, and has color. Here's an example of what the outputs look like:
```sh
user@linux:~/repos $ git-status-check-recursive
# Python version
#### /home/user/repos
./foo         Good
./bar ....... (modifications)
./baz ....... (untracked files)
./baf         Good

# Bash version (has color not shown here)
./foo/.git    good
./bar/.git    (2 commits behind) (unstaged changes) (untracked changes)
./baz/.git    (3 commits ahead) (staged changes)
./baf/.git    (2 commits behind) (unstaged changes) (1 stash)
```
<br>
This project has been a lesson for me in recognizing what efforts are actually necessary - the classic lesson of "*premature optimization is the root of all evil*". I guess this is repentance for my sins :^)

<br>
<br>
<br>
<br>
<br>

---

<br>
<br>

## Extra Unnecessary Research, Feel Free To Skip!

### Possible Clone States
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

So now we have five (mostly) independent states to track, not considering submodules. I decided to combine the categories of "changes to tracked files" and "changes to untracked file", since most of the time I don't care to differentiate these two groups. An example of one possible clone status is (1) untracked changes to `README.md`, (2) changes to `foo.txt` are staged, (3) our branch is behind by 5 commits, (4) we have two stashes, and (5) there is a bisect in progress.

If there are more states please not covered let me know!

### Testing
In order to check our status reports correctly, we need to go through each possible state. I made a bash script to make a clone in every permutation of states. From this I learned that a merge cannot be started with there are changes in staging. I also learned that `git rebase` is more picky; it cannot be started if there are any changes in staging or any unstaged changes.

### How Does Version 1 Handle All Possible States?
~~details removed~~

The first version doesn't handle rebase, so I fixed it.

### Getting The Status Information
The python version found the status of a clone by running `git status` in a subprocess, and then checking for particular substrings in the output. For example, if `HEAD detached at` was in the output then we know that the head is detached, simple and morbid!

There are porcelain v1 and v2 formats that are better for programmatic use. TLDR use porcelain v1:
- first character - main category of change
    - 1 --> ordinary changes
    - 2 --> renamed things
    - u --> unmerged
    - ? --> untracked
    - ! --> ignored
- `XY` - X is for staged, Y is for unstaged
    - M - modified
    - A - added
    - D - deleted
    - R - renamed
    - C - copied
    - U - unmerged (`u UU` = both modified, `u AA` = both added)
- `--branch` gives:
    - `branch.oid <commit> | (initial)` - Current commit
    - `branch.head <branch> | (detached)` - Current branch
    - `branch.upstream <upstream_branch>` - If upstream is set
    - `branch.ab +<ahead> -<behind>` - If upstream is set and the commit is present

Other sources:
- `git status --show-stash --branch` - don't use, format is brittle, but has all the information needed
- `git status --porcelain=v2 --show-stash --branch` - show stash doesn't actually do anything
- `git status --porcelain=v1 --show-stash --branch` - v2 is better
- `git ls-files -t --cached --deleted --others --stage --modified` - a worse version of `git status`
- `.git` folder - no thanks to that rabbit hole
- `git status --short --branch --show-stash` - like porcelain v1 but *with color*

Porcelain v2 doesn't show the status of in process merges, rebase, cherry-pick, and bisect. Also we want to show the state of the stash. THis information can be easily retrieved with these files:
- `.git/BISECT_LOG`
- `.git/CHERRY_PICK_HEAD`
- `.git/MERGE_HEAD`
- `.git/REBASE_HEAD`

### Benchmarking
~~details removed~~

The python version has an overhead per clone of 10 milliseconds, the bash version is 16 milliseconds.

### Version 3 - golang
~~details removed~~

### Version 4 - can we do better than UNIX `find`?
~~details removed~~

(future me - SMH)

<br>
<br>

---

<br>
<br>

## Python Code
```python
#!/usr/bin/python3
import os
from subprocess import run, Popen, DEVNULL, PIPE, STDOUT
import argparse

BASE_DIRS = [os.getcwd()]   # Directories to search for git clones from:
SKIP = set([])              # Skip over certain directories (folder name only)
SKIP_FETCH = set([])        # Skip 'git fetch' stage

def find_git_clones(_dir: str):
    try:
        list_dir = os.listdir(_dir)
    except PermissionError as perm_err:
        return
    if '.git' in list_dir:
        yield _dir
    else:
        for d_abs in sorted([os.path.join(_dir, d) for d in list_dir]):
            if os.path.isdir(d_abs) and os.path.split(d_abs)[-1] not in SKIP:
                yield from find_git_clones(d_abs)

def get_git_status_string(status: str) -> str:
    """ Map the `git status` response to a simple one-line status """
    detached_head = 'HEAD detached at' in status
    working_tree_clean = 'nothing to commit, working tree clean' in status
    local_branch_up_to_date = 'Your branch is up to date with' in status
    local_branch_behind = 'Your branch is behind' in status
    local_branch_ahead = 'Your branch is ahead of' in status
    local_branch_needs_to_be_pushed_upstream = \
        (not local_branch_up_to_date) \
        and (not local_branch_ahead) \
        and working_tree_clean \
        and (not detached_head)
    local_has_stages_changes = 'Changes to be committed' in status
    local_has_untracked = 'Untracked files' in status
    local_has_tracked_modifications = 'Changes not staged for commit' in status
    submodules_have_new = '(new commits)' in status
    no_commits = 'No commits yet' in status
    ret = ''
    if detached_head:
        ret += ' (detached head)'
    if local_branch_up_to_date and working_tree_clean:
        ret += 'Good'
    if local_branch_behind and working_tree_clean:
        # Get number of commits behind from status
        # Bad way to do this, should do in better way like:
        # git rev-list <branch>..origin/<branch> --count
        end = status.index(' commit')
        start = end - 1
        while start > 0 and status[start] != ' ':
            start -= 1
        start += 1
        n_commits = int(status[start:end].strip())
        ret += f" (Behind by {n_commits} commit{'s' if n_commits > 1 else ''})"
    if local_branch_ahead:
        ret += ' (commits to push)'
    if local_has_stages_changes:
        ret += ' (staged changes to be committed)'
    if local_has_untracked:
        ret += ' (untracked files)'
    if local_branch_needs_to_be_pushed_upstream:
        ret += ' (local branch needs to be pushed upstream)'
    if local_has_tracked_modifications:
        if submodules_have_new:
            ret += ' (modifications or submodules out-of-date)'
        else:
            ret += ' (modifications)'
    if no_commits:
        ret += ' (no commits - empty repository or maybe currently cloning)'
    if ret == '':
        ret += ' (NADA)'
    return ret.strip()

def print_repo_statuses(base_dir, args):
    """ Print repos from the git_repo_paths global """
    prev_git_path_rel = None
    for git_path_abs in find_git_clones(base_dir):
        os.chdir(git_path_abs)
        # Get the directory path from where the script was called from, not abs
        git_path_rel = git_path_abs[len(base_dir) + 1:]
        if git_path_rel in SKIP:
            continue
        if args.fetch and git_path_rel not in SKIP_FETCH:
            run(['git', 'fetch', 'origin'], stdout=DEVNULL, stderr=DEVNULL)
        out = Popen(['git', 'status'], stdout=PIPE, stderr=STDOUT)
        std_out, std_err = out.communicate()
        # Separate top-level directories with empty line
        if prev_git_path_rel != None:
            _split_prev = prev_git_path_rel.split(os.sep)
            _split_cur = git_path_rel.split(os.sep)
            if len(_split_prev) > 1 or len(_split_cur) > 1:
                if _split_prev[0] != _split_cur[0]:
                    print()
        prev_git_path_rel = git_path_rel
        # Print repo and ... and status string
        status = get_git_status_string(std_out.decode('utf-8'))
        _path = './' + git_path_rel
        if status != 'Good':
            _path = f'{_path} {"." * (args.width - 1 - len(_path))}'
        else:
            _path = '{:{}}'.format(_path, args.width)
        print(_path, end='')
        print(' ', end='')
        print(get_git_status_string(std_out.decode('utf-8')))

def parse_args():
    parser = argparse.ArgumentParser(
        description="Find git repos recursively and print git status",
    )
    parser.add_argument(
        '--fetch',
        default=False,
        action='store_true',
        help='Fetch origin to see how many commits behind',
    )
    parser.add_argument(
        '--width',
        default=50,
        type=int,
        help="Column to start printing status at",
    )
    return parser.parse_args()

if __name__ == '__main__':
    for base_dir in BASE_DIRS:
        print(f"#### {base_dir}")
        print_repo_statuses(base_dir, parse_args())
```

## Bash Code
Compressed
```bash
#!/usr/bin/env bash
find . -type d -name '.git' -exec bash -c 'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo' \;
```
{:.code-no-wrap}

As an alias:
```bash
alias git-status-check-recursive='find . -type d -name '"'"'.git'"'"' -exec bash -c '"'"'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo'"'"' \;'
```
{:.code-no-wrap}

Uncompressed
```bash
#!/usr/bin/env bash
find . -type d -name '.git' -exec bash -c '
    cd {}/..
    echo -ne "{}\t"
    BLUE="\e[1m"
    GREEN="\e[42m"
    RED="\e[41m"
    MAGENTA="\e[45m"
    RESET="\e[0m"
    status=$(git status --porcelain=v2 --branch -z | tr "\0" "\n")
    good=1
    [[ "${status}" == *"branch.oid (initial)"* ]] && initial=1 && good=0
    if [ "$initial" = "1" ]
        then echo -n "(initial) "
    else [[ "${status}" == *"branch.head (detached)"* ]] && headDet=1 && good=0
        if [ "$headDet" = "1" ]
            then echo -en "(${RED}detached head${RESET}) "
            good="0"
        else ahead=$(echo "${status}" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-)
            [ "${ahead}" == "1" ] || plural1="s"
            [ "${ahead}" != "0" ] && echo -en "(${BLUE}${ahead}${RESET} commit${plural1} ahead) " && good=0
            behind=$(echo "${status}" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-)
            [ "${behind}" == "1" ] || plural2="s"
            [ "${behind}" != "0" ] && echo -en "(${BLUE}${behind}${RESET} commit${plural2} behind) " && good=0
        fi
    fi
    echo "${status}" | grep -q "^[u12] [^.]." && echo -en "(${GREEN}staged changes${RESET}) " && good=0
    echo "${status}" | grep -q "^[u12] .[^.]" && echo -en "(${RED}unstaged changes${RESET}) " && good=0
    echo "${status}" | grep -q "^\?" && echo -en "(${RED}untracked changes${RESET}) " && good=0
    [ -f .git/REBASE_HEAD ] && echo -en "(${MAGENTA}rebasing${RESET}) " && good=0
    [ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${MAGENTA}cherry pick${RESET}) " && good=0
    [ -f .git/MERGE_HEAD ] && echo -en "(${MAGENTA}merging${RESET}) " && good=0
    [ -f .git/BISECT_LOG ] && echo -en "(${MAGENTA}bisecting${RESET}) " && good=0
    numStash=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc --bytes)
    [ "${numStash}" == "1" ] || plural3="es"
    [ "${numStash}" != "0" ] && echo -en "(${BLUE}${numStash}${RESET} stash${plural3}) " && good=0
    [ "$good" == "1" ] && echo -n "good"
    echo
' \;
```

<!--

### Start
The first version is pretty fast; as fast as it takes to run `git status` on each clone. `git status` actually caches its result, so if nothing changed then it runs fast!

### What to improve / why create a new version?
- speed
    - we have a responsibility to make sure our tools are fast, not to hide behind modern fast hardware
    - I don't trust python, need a quantifiable excuse to migrate away from it
- flexibility
    - I can needing a similar tool, for example to fetch or pull all repos recursively
- python was a good choice for the first implementation, not it's time to move away from the proof of concept / scripting language
- finding out states in git that I missed


### Poor man's recursive status check
Before we go on, it's important to say that this does not need to be overly complicated. It can just be a disgusting golfed (poorly) shell command!
```sh
find . -type d -name '.git' -exec bash -c 'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo' \;
```

Or as a `bash` alias:
```sh
alias git-status-check-recursive='find . -type d -name '"'"'.git'"'"' -exec bash -c '"'"'cd {}/..;echo -ne "{}\t";B="\e[1m";G="\e[42m";R="\e[41m";M="\e[45m";N="\e[0m";s=$(git status --porcelain=v2 -b -z | tr "\0" "\n");g=1;[[ "$s" == *"branch.oid (initial)"* ]] && i=1 && g=0;if [ "$i" = "1" ];then echo -n "(initial) ";else [[ "$s" == *"branch.head (detached)"* ]] && h=1 && g=0;if [ "$h" = "1" ];then echo -en "(${R}detached head$N) ";g="0";else a=$(echo "$s" | grep "# branch.ab " | cut -d" " -f3 | cut -c2-);[ "$a" == "1" ] || z="s";[ "$a" != "0" ] && echo -en "($B$a$N commit$z ahead) " && g=0;b=$(echo "$s" | grep "# branch.ab " | cut -d" " -f4 | cut -c2-);[ "$b" == "1" ] || y="s";[ "$b" != "0" ] && echo -en "($B$b$N commit$y behind) " && g=0;fi;fi;echo "$s" | grep -q "^[u12] [^.]." && echo -en "(${G}staged changes$N) " && g=0;echo "$s" | grep -q "^[u12] .[^.]" && echo -en "(${R}unstaged changes$N) " && g=0;echo "$s" | grep -q "^\?" && echo -en "(${R}untracked changes$N) " && g=0;[ -f .git/REBASE_HEAD ] && echo -en "(${M}rebasing$N) " && g=0;[ -f .git/CHERRY_PICK_HEAD ] && echo -en "(${M}cherry pick$N) " && g=0;[ -f .git/MERGE_HEAD ] && echo -en "(${M}merging$N) " && g=0;[ -f .git/BISECT_LOG ] && echo -en "(${M}bisecting$N) " && g=0;t=$(git stash list -z --pretty=format:"A" | tr -d "\0" | wc -c);[ "$t" == "1" ] || x="es";[ "$t" != "0" ] && echo -en "($B$t$N stash$x) " && g=0;[ "$g" == "1" ] && echo -n "good";echo'"'"' \;'
```

This approach is surprisingly usable and fast.



### Version 4 - can we do better than UNIX `find`?
In this version we're going to see if we can be faster than `find`, with its paltry 40 years of existence (just about, as of December 2022). `find` was first released in UNIX System V, back in 1983!

Jokes aside, I think the commands under `find -exec` run synchronously, as evidenced by when `find` finds 10 results and execs a one second sleep for each, the whole command takes 10 seconds.

TODO



### Future Improvements
- Git submodules - I'll need to rip this fear BAND-AID(®) off some day.
- checking `git status` while a `git clone` is happening, will show `No commits yet` like a new repo.


### Etc, not sure where to include
- Note `git stash` takes the **staged** and **tracked** changes, but not **untracked** changes
- During writing this I've mixed up "stashed" and "staged" many times, let me know if there are any mixups still!
- doing a `git merge` when there are staged changes will cause the merge to fail and the return code to 128 is set
- doing a `git merge` and conflicts happen will set return code to 1
- `git cherry - Find commits yet to be applied to upstream` cool, never used this before
- https://github.com/robertgzr/porcelain



-->
