# Ren

Bash script for renaming multiple files in Linux.

This script is mainly about learning bash command language, combined with a benefit of getting a useful tool for me in the process.

## Introduction

The functionality of the script is inspired by [Multi-Rename Tool](https://www.ghisler.ch/wiki/index.php?title=Multi-rename_tool) that comes with Windows only program called [Total Commander](https://www.ghisler.com/).

Internally, Ren uses [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program for multi-renaming files that takes a Perl expression as a rule on how to rename files supplied as a argument. If you are familiar with [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program then Ren will be very easy to get a hang of.

What Ren does, on top of [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program, is that it adds a possibility to use a counter placeholder in the expression argument. During renaming, all files get the placeholder replaced with the counter, or the sequential number of a file.

## Installation

Make sure that [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program by Larry Wall is installed on your system. It comes pre-installed in most Debian based distributions.

Run the following commands in the terminal:

```
git clone https://github.com/LinogeFly/ren &&
cp ren/ren.sh ~/bin/ren &&
chmod u+x ~/bin/ren &&
rm -rf ren
```

## Usage

For example, let's say we have multiple clip-art cat images downloaded from all over the places. We want to organize them a little bit by giving all the files a certain name plus an index.

Let's say we want this files:

```
xcgLxzxki.png
hohRowJ_cat-cartoon-clip-art-cartoon-cute-cat-clipart.png
40-402764_png-kid-quilts-cartoon-ginger-cat.png
13488685211757.png
```

To look like this:

```
clipart-cat-1.png
clipart-cat-2.png
clipart-cat-3.png
clipart-cat-4.png
```

To do that, we run `ren` script like this:

```
ren 's/.*/clipart-cat-[C].png/' *.png
```

The key part here is `[C]`, which is the counter placeholder. It gets replaced during renaming with the sequential number of a file.

### Dry run

To run the script in a dry run mode use `-n` option argument.

### Counter placeholder formats

In addition to default `[C]` format, the counter placeholder can include options.

- `[C10]` format includes **Start at** option of 10.
- `[C+5]` format includes **Step by** option of 5.
- `[C:3]` format includes **Digits width** option of 3.

The counter placeholder can include all of the described options at the same time, for example `[C10+5:3]`.

## To-do

- [ ] Make it possible for a counter placeholder to appear multiple times.
- [ ] Counter placeholder should only be replaced if included in the last part of the expression. This is fine `'s/a/b[C]/'`, but this is not `'s/a[C]/b/'`.
- [ ] If counter placeholder is not present in the expression, we should not rename files one by one. Instead, we need rename them all at once by running `rename` program with passed the list of files and the expression to it.
- [ ] Error handling for invalid counter placeholder format.
- [ ] Add standard input support (`stdin`).
- [x] Fix the issue with arguments being position sensitive. For example, `ren -n 's/a/b/'` works, but `ren 's/a/b/' -n` does not.
- [x] Add `--help` option support.
- [x] Add `--version` option support.
- [x] Counter placeholder should not be case sensitive.
- [x] Add **Start at** option support.
- [x] Add **Step by** option support.
- [x] Add **Digits width** option support.
- [x] Add support for file expansion. Instead of passing a list of files it should be possible to pass a pattern with wildcards. For example, `*.bak`.

## Running tests

Make sure you have [shUnit2](https://github.com/kward/shunit2/) program installed on your system.

To run the text just execute the following script in the terminal:

```
./ren.tests.sh
```
