#! /bin/sh

script="ren.sh"
tempDir=".temp"

oneTimeSetUp() {
    rm -rf "$tempDir"
    mkdir -p "$tempDir"
}

setUp() {
    touch "$tempDir/file"
    touch "$tempDir/file with spaces"
}

oneTimeTearDown() {
    rm -rf "$tempDir"
}

tearDown() {
    rm -f $tempDir/*
}

test_should_not_rename_when_dry_run_argument_is_set() {
    ./$script -n 's/1/2/' "$tempDir/file" > /dev/null
    ./$script --nono 's/1/2/' "$tempDir/file" > /dev/null

    assertTrue '[ -f "$tempDir/file" ]'
}

test_should_substitute_substring_in_filename() {
    ./$script 's/file/file2/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file2" ]'
    assertTrue '[ -f "$tempDir/file2 with spaces" ]'
}

test_should_substitute_whole_filename() {
    ./$script 's/(.*)/$1-new/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-new" ]'
    assertTrue '[ -f "$tempDir/file with spaces-new" ]'
}

test_should_rename_multiples_files_in_a_folder() {
    ./$script 's/(.*)/$1-new/' $tempDir/*

    assertTrue '[ -f "$tempDir/file-new" ]'
    assertTrue '[ -f "$tempDir/file with spaces-new" ]'
}

test_should_add_counter_to_filename() {
    ./$script 's/(.*)/$1-[C]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-2" ]'
}

test_should_add_counter_to_multiples_files_in_a_folder() {
    ./$script 's/(.*)/$1-[C]/' $tempDir/*

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-2" ]'
}

test_should_add_counter_to_filename_ignoring_counter_placeholder_case() {
    ./$script 's/(.*)/$1-[c]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-1" ]'
}

test_should_not_add_counter_to_filename_when_counter_placeholder_is_escaped_1(){
    ./$script 's/(.*)/$1-\[C]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-[C]" ]'
}

test_should_not_add_counter_to_filename_when_counter_placeholder_is_escaped_2(){
    ./$script 's/(.*)/$1-[C\]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-[C]" ]'
}

test_should_not_add_counter_to_filename_when_counter_placeholder_is_escaped_3(){
    ./$script 's/(.*)/$1-\[C\]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-[C]" ]'
}

test_should_add_counter_to_filename_with_starting_at_option() {
    ./$script 's/(.*)/$1-[C10]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-10" ]'
}

test_should_add_counter_to_filename_with_step_by_option() {
    ./$script 's/(.*)/$1-[C+5]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-6" ]'
}

test_should_add_counter_to_filename_with_digits_width_option() {
    ./$script 's/(.*)/$1-[C:3]/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file-001" ]'
}

test_should_add_counter_to_filename_with_all_options() {
    ./$script 's/(.*)/$1-[C10+5:3]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-010" ]'
    assertTrue '[ -f "$tempDir/file with spaces-015" ]'
}

# Run the tests by loading and running shUnit2.
. shunit2
