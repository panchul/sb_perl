#!/usr/bin/perl

# run 'perl load_hash.pl < load_hash_test_data.txt 
# or just 'load_hash.pl < load_hash_test_data.txt

use strict;
#use warnings FATAL => 'all';

my %hash;
#while (<FILE>)
while (<>)
{
    chomp;
    my ($key, $val) = split /=/;
    print("fitting in the pair \"${key}\" - \"${val}\"\n");
    print (exists $hash{$key});
    print "Exists\n"    if exists $hash{$key};
    print "Defined\n"   if defined $hash{$key};
    print "True\n"      if $hash{$key};

    $hash{$key} .= exists $hash{$key} ? ",$val" : $val;

    print("fitted in the pair \"${key}\" -> \"${hash{$key}}\"\n");
}

print %hash;

print "\n";

print("hash of something is ", $hash{"something"} , "\n");

