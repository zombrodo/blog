# Blog

A personal static site generator, written in Lua.

Mostly written in an exercise to learn LPeg, but also fill a need in which I
wanted to roll my own static blog. Lua is my current flavour of the month, so
thought I might give it a hoon.

This isn't really intended to be used by anyone other than me, but putting it
out there might help someone in need!

## Features

* Markdown parser written with LPeg
* Templating provided by Mustache / Lustache
* ??? (there's a TODO list)

## Should I (you) do this?

Probably not. As stated in the opener, this was more of a personal project, and
there are far more useful languages to do it in. I might make a blog about it,
though.

My main findings (so far):

* Don't parse markdown, find someone who has done it for you.
* LPeg is pretty cool.
* I wish Lua had better filesystem functions, but I kinda understand _why_ it
  doesn't have them.
* `sleep` is a real function on Linux. Some implementations of a `sleep` are
  just `while` loops that count the number of seconds/milliseconds that have
  passed.

## Install

Until I get a rockspec up and running, this'll be a manual process.

#### Note about Windows

I personally use Windows on my computer at home, and tools like LPeg are a
headache to compile on Windows - especially with my ineptitude in play. I've
instead opted to use [Luarocks](https://luarocks.org/) for most of the heavy
lifting, which unfortunately is also sorta painful on Windows.

For the sake of progress, this is all built on WSL using
[Alpine Linux](https://www.microsoft.com/en-nz/p/alpine-wsl/9p804crf0395), which
was relatively easy to get setup.

### Lua

* `apk add lua`
* `apk add lua5.1-dev`
* And adapting the steps on the [Luarocks](https://luarocks.org/) homepage for
  Alpine

When installing Luarocks, there'll be a few other dependencies that need to be
installed - `curl`, `unzip`, and `openssl` are the ones off the top of my head,
but the installer will prompt you as you go.

### Luarocks

The following dependencies are required from `luarocks`:

* `luarocks install luafilesystem`
* `luarocks install lpeg`

### Other

Thinking I could get away without using Luarocks, there's also a version of
[`lustache`](https://github.com/Olivine-Labs/lustache) in the lib folder.
This should be shifted to a Luarocks managed install, eventually.

Tests are written using [`lust`](https://github.com/bjornbytes/lust).

## Running

* `./test.lua` will run the tests.
* `./generate.lua` will generate the

## Generation, in a nutshell

Generation is pretty simple, and follows the below steps:

1. A Render run is specified by the path to the `templates`, and a `writer`.
  * A `template` is the structure of a page - `index`, `head` and `post`
  * A `writer` takes the nodes spat out by the markdown parser, and converts
    into strings. ie. `anchor` node -> `<a href={node.href}>node.content</a>`
  * You can find the default writer in `src/writer/default.lua`
2. Finds all the files in the `post` directory
3. Assumes they're all markdown, and parses it *There's a TODO to filter it down
  to markdown only, when that matters)
4. Uses the nodes from the parse, and writes them as strings. Fetches post
  metadata from the `preamble` node - things like `title`, `date` and `tags`
5. Generates the `head` element by using the template, and metadata
6. Generates the `post` using the template, and outputs from the markdown parse.
7. Writes this file to `build/posts/<title>.html`
8. Repeats steps 3->7 for every post. Collects a list of all the posts
9. Render the `index` using the list of posts
10. Done!


