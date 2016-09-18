#!/usr/bin/perl

#
# Remove the trailing \r that windows applications add.
# Run it as:
#  convert_dos2unix.p. < input_file > output_file
#

undef $/;

$_ = <>;

# s/(.)\x0d\x0a$/($1)\x0a/ge;
s/\r//ge;

print;

