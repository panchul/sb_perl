#!/usr/bin/perl

undef $/;

$_ = <>;

s/_\x08(.)/$1/ge;
s/(.)\x08\1/$1/ge;
s/\x2b\x08o/_/ge;

print;

