#!/usr/bin/perl

# run 'perl load_yaml.pl load_yaml_test_data.txt 
#

# might have to do this:
#  cpan App::cpanminus
#  sudo cpan App::cpanminus
#  sudo cpanm File::Slurp
#  sudo cpanm YAML::XS
#  sudo cpanm Data::Dumper
#

use strict;
# use warnings FATAL => 'all';

use File::Slurp;
use YAML::XS;
use Data::Dumper;

print Dumper Load scalar read_file(shift);

#$VAR1 = {
#'department' => [
#    'foo',
#    'bar'
#],
#    'location' => [
#    'baz',
#    'biff'
#],
#    'name' => 'Dorky Dork'
#};