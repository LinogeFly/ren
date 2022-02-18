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

test_should_show_usage_when_called_with_help_option_argument_1() {
    local result; result=$(./$script -h 's/file/file-new/' "$tempDir/file")

    assertContains "$result" 'Usage:'
    assertFalse '[ -f "$tempDir/file-new" ]'
}

test_should_show_usage_when_called_with_help_option_argument_2() {
    local result; result=$(./$script --help 's/file/file-new/' "$tempDir/file")

    assertContains "$result" 'Usage:'
    assertFalse '[ -f "$tempDir/file-new" ]'
}

test_should_show_version_when_called_with_version_option_argument_1() {
    local result; result=$(./$script -v 's/file/file-new/' "$tempDir/file")

    assertContains "$result" 'Ren version'
    assertFalse '[ -f "$tempDir/file-new" ]'
}

test_should_show_version_when_called_with_version_option_argument_2() {
    local result; result=$(./$script --version 's/file/file-new/' "$tempDir/file")

    assertContains "$result" 'Ren version'
    assertFalse '[ -f "$tempDir/file-new" ]'
}

test_should_exit_with_error_when_called_with_unknown_option_argument() {

    local result; result=$(./$script 's/file/file-new/' -unknown "$tempDir/file" 2>&1)

    assertEquals "1" "$?"
    assertContains "$result" "Unknown option -unknown."
    assertFalse '[ -f "$tempDir/file-new" ]'
}

test_should_exit_with_error_when_expression_is_not_perl_substitute_regular_expression() {

    local result; result=$(./$script '/invalid-perl-substitute-regex/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_1() {

    local result; result=$(./$script 's/file/[file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_2() {
    local result; result=$(./$script 's/file/file]/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_3() {
    local result; result=$(./$script 's/file/[file]/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_4() {
    local result; result=$(./$script 's/file/aa[C]bb]file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_5() {
    local result; result=$(./$script 's/file/aa[bb[C]file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_6() {
    local result; result=$(./$script 's/file/aa[bb[C]cc]file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_7() {
    local result; result=$(./$script 's/file/aa\[C]file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_not_escaped_square_brackets_are_used_without_counter_placeholder_8() {
    local result; result=$(./$script 's/file/aa[C\]file/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" 'Invalid perlexpr argument.'
}

test_should_exit_with_error_when_counter_placeholder_has_invalid_format_1() {
    local result; result=$(./$script 's/file/[Cabc]/' "$tempDir/file" 2>&1)
    
    assertEquals "2" "$?"
    assertContains "$result" "Counter placeholder '[Cabc]' has invalid format."
}

test_should_exit_with_error_when_counter_placeholder_has_invalid_format_2() {
    local result; result=$(./$script 's/file/[C10:3+5]/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" "Counter placeholder '[C10:3+5]' has invalid format."
}

test_should_exit_with_error_when_counter_placeholder_has_invalid_format_3() {
    local result; result=$(./$script 's/file/[C10:5:3]/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" "Counter placeholder '[C10:5:3]' has invalid format."
}

test_should_exit_with_error_when_counter_placeholder_has_invalid_format_4() {
    local result; result=$(./$script 's/file/[C10+5+3]/' "$tempDir/file" 2>&1)

    assertEquals "2" "$?"
    assertContains "$result" "Counter placeholder '[C10+5+3]' has invalid format."
}

test_should_not_rename_when_called_with_dry_run_option_argument() {
    ./$script -n 's/file/file-new/' "$tempDir/file" > /dev/null
    ./$script --dry-run 's/file/file-new/' "$tempDir/file" > /dev/null

    assertFalse '[ -f "$tempDir/file-new" ]'
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

test_should_rename_all_filenames_that_match_glob_file_pattern() {
    ./$script 's/(.*)/$1-new/' $tempDir/*

    assertTrue '[ -f "$tempDir/file-new" ]'
    assertTrue '[ -f "$tempDir/file with spaces-new" ]'
}

test_should_allow_to_use_escaped_square_brackets_in_replacement_expression_1() {
    ./$script 's/file/\[file/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/[file" ]'
    assertTrue '[ -f "$tempDir/[file with spaces" ]'
}

test_should_allow_to_use_escaped_square_brackets_in_replacement_expression_2() {
    ./$script 's/(.*)/$1\]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file]" ]'
    assertTrue '[ -f "$tempDir/file with spaces]" ]'
}

test_should_allow_to_use_escaped_square_brackets_in_replacement_expression_3() {
    ./$script 's/(.*)\/(.*)/$1\/[$2]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/[file]" ]'
    assertTrue '[ -f "$tempDir/[file with spaces]" ]'
}

test_should_allow_to_use_whitespace_characters_in_replacement_expression() {
    ./$script 's/file/file file/' "$tempDir/file"

    assertTrue '[ -f "$tempDir/file file" ]'
}

test_should_add_counter_to_filename() {
    ./$script 's/(.*)/$1-[C]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-2" ]'
}

test_should_add_multiple_counters_to_filename() {
    ./$script 's/(.*)/$1-[C]-[C:3]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-1-001" ]'
    assertTrue '[ -f "$tempDir/file with spaces-2-002" ]'
}

test_should_add_counter_to_all_filenames_that_match_glob_file_pattern() {
    ./$script 's/(.*)/$1-[C]/' $tempDir/*

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-2" ]'
}

test_should_not_add_counter_to_filename_when_counter_placeholder_is_escaped_1(){
    ./$script 's/(.*)/$1-\[C\]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-[C]" ]'
    assertTrue '[ -f "$tempDir/file with spaces-[C]" ]'
}

test_should_not_add_counter_to_filename_when_counter_placeholder_is_escaped_2(){
    ./$script 's/(.*)/$1-\[C\]-[C]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-[C]-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-[C]-2" ]'
}

test_should_allow_to_have_counter_placeholder_like_text_in_pattern_expression_1(){
    touch "$tempDir/file-C"

    ./$script 's/[C]/D/' "$tempDir/file-C"

    assertTrue '[ -f "$tempDir/file-D" ]'
}

test_should_allow_to_have_counter_placeholder_like_text_in_pattern_expression_2(){
    touch "$tempDir/file-C"

    ./$script 's/[C]/[C]/' "$tempDir/file-C"

    assertTrue '[ -f "$tempDir/file-1" ]'
}

test_should_add_counter_to_filename_with_starting_at_option() {
    ./$script 's/(.*)/$1-[C10]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-10" ]'
    assertTrue '[ -f "$tempDir/file with spaces-11" ]'
}

test_should_add_counter_to_filename_with_step_by_option() {
    ./$script 's/(.*)/$1-[C+5]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-1" ]'
    assertTrue '[ -f "$tempDir/file with spaces-6" ]'
}

test_should_add_counter_to_filename_with_digits_width_option() {
    ./$script 's/(.*)/$1-[C:3]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-001" ]'
    assertTrue '[ -f "$tempDir/file with spaces-002" ]'
}

test_should_add_counter_to_filename_with_all_options() {
    ./$script 's/(.*)/$1-[C10+5:3]/' "$tempDir/file" "$tempDir/file with spaces"

    assertTrue '[ -f "$tempDir/file-010" ]'
    assertTrue '[ -f "$tempDir/file with spaces-015" ]'
}

# Run the tests by loading and running shUnit2.
. shunit2
