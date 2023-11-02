# Ren

Ren is a bash script for renaming multiple files in Linux. It is inspired by [Multi-Rename Tool](https://www.ghisler.ch/wiki/index.php?title=Multi-rename_tool) that comes with Windows only program called [Total Commander](https://www.ghisler.com/).

The script is mainly a practical exercise for me to learn bash command language, combined with a benefit of getting a useful tool in the process.

## Description

Ren renames supplied filenames according to the specified rule. The rule is a Perl substitution regular expression operator. It describes what parts of the filenames to rename and how.

Ren pretty much repeats [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program by Larry Wall for multi-renaming files, except it allows to include a counter, or a sequential number in the other words, in filenames. The way it works is that the Perl substitution expression can contain the counter placeholder `[C]`, which then gets replaced with the actual counting number of the file when multiple files are renamed.

[Rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program is great on its own and can be used as is, but the need of having a counter in the filename when renaming multiple files is why we have Ren here.

## Installation

First, make sure that [rename](https://manpages.debian.org/stretch/rename/rename.1.en.html) program is installed on your system. It comes pre-installed in most Debian based distributions.

Then run the following commands in the terminal to install Ren:

```
git clone https://github.com/LinogeFly/ren &&
cp ren/ren.sh ~/bin/ren &&
chmod u+x ~/bin/ren &&
rm -rf ren
```

## Quick start

Let's learn how to include a counter in filenames with a simple example.

Imagine we have a bunch of files we want to rename. For example, a folder full of clip-art cat images downloaded from different places. We want to organize them a little by renaming the files so that each filename consists of a certain name plus a numeric index.

Let's say we got files like this:

```
xcgLxzxki.png
hohRowJ_cat-cartoon-clip-art-cartoon-cute-cat-clipart.png
40-402764_png-kid-quilts-cartoon-ginger-cat.png
13488685211757.png
```

And we want them to look like this:

```
clipart-cat-1.png
clipart-cat-2.png
clipart-cat-3.png
clipart-cat-4.png
```

The following simple command will do the renaming:

```shell
ren 's/.*/clipart-cat-[C].png/' *.png
```

As you can see Ren is called with two arguments. The expression `'s/.*/clipart-cat-[C].png/'` describes the rule on how to rename files, and `*.png` wildcard pattern tells to rename all .png files in the folder. The expression is a Perl substitution regular expression operator that contains `[C]` substring. The substring is the counter placeholder that defines where to include the counter in filenames.

## Usage

The syntax of the script:

```shell
ren [ -h|-v ] [ -n ] perlexpr files
```

### Options

```
-n, --dry-run        Print names of files to be renamed,
                     but don't rename.
-h, --help           Print synopsis, options and examples.
-v, --version        Print version number.
```

### Perl expression argument

Specified as the first argument. The argument is a Perl substitution regular expression operator. The basic form of the operator is:

```
s/PATTERN/REPLACEMENT/
```

The PATTERN is the regular expression for the text that we are looking for in the filename.

The REPLACEMENT is a specification for the text or regular expression that we want to use to replace the found text with. For example, we can replace all occurrences of **dog** in the filename with **cat** using `s/cat/dog/` regular expression.

The REPLACEMENT can also contain the counter placeholder `[C]`, which adds a sequential number of the file to the filename.

To include square bracket characters `[` and `]` in the REPLACEMENT, use a forward slash `\` character to escape the brackens, like `\[` and `\]`.

### Files argument

Specified as the second argument. The argument is a filename, a list of filenames or a glob wildcard pattern of file that need to be renamed.

## Counter placeholder

The basic form of the counter placeholder is `[C]`. It adds a sequential number of the file to the filename with the default parameters. By default counting starts at 1, with the step of 1 and without formatting. The default parameters can be changed when using the counter placeholder.

- **Start at** parameter sets a starting number for the counter. Can be defined using `[CN]` format, where N is the starting number for the counter.

- **Step by** parameter sets the counter step. Can be defined using `[C+S]` format, where S is the counter step value.

- **Digits width** parameter formats the counter by setting a fixed width. Can be defined using `[C:W]` format, where W is the counter width.

### Examples

As an example, let's say we have files like this:

```
pussy-cat.jpg
good-boi-doggo-doggo.jpg
nasty-little-ferret.jpg
```

Then running `ren 's/.*/pet-[C10].jpg/' *.jpg` command with **start at** parameter set to 10 will rename files into this:

```
pet-10.jpg
pet-11.jpg
pet-12.jpg
```

Running `ren 's/.*/pet-[C+5].jpg/' *.jpg` command with **step by** parameter set to 5 will rename files into this:

```
pet-1.jpg
pet-6.jpg
pet-11.jpg
```

Running `ren 's/.*/pet-[C:3].jpg/' *.jpg` command with **digits width** parameter set to 3 will rename files into this:

```
pet-001.jpg
pet-002.jpg
pet-003.jpg
```

Also all parameters can be set at the same time, for example `[C10+5:3]`.

## How-to

### Prefix/suffix files

Original filename can be used in the REPLACEMENT part of the rename regular expression. It can be useful for adding a prefix or a suffix to files. For example, running `ren 's/(.*)/S01E[C1:2] $1/' *.mkv` command for the following files:

```
Initial_D_First_Stage_-_01_(DVDRip_960x720_x264_AC3).mkv
Initial_D_First_Stage_-_02_(DVDRip_960x720_x264_AC3).mkv
Initial_D_First_Stage_-_03_(DVDRip_960x720_x264_AC3).mkv
```

will prefix all files with TV shows standard naming convention, like this:

```
S01E01 Initial_D_First_Stage_-_01_(DVDRip_960x720_x264_AC3).mkv
S01E02 Initial_D_First_Stage_-_02_(DVDRip_960x720_x264_AC3).mkv
S01E03 Initial_D_First_Stage_-_03_(DVDRip_960x720_x264_AC3).mkv

```

### Change files extension

For example, to change files extension form `.jpeg` to `.jpg` run the following command:

```
ren 's/(.*).jpeg/$1.jpg/' *.jpeg
```

## To-do

- [ ] Add standard input support (`stdin`).
- [ ] Add progress bar in case if we run `rename` separately for each file.

## Running tests

Make sure you have [shUnit2](https://github.com/kward/shunit2/) program installed on your system.

To run the tests execute the following script in the terminal:

```shell
./ren.tests.sh
```
