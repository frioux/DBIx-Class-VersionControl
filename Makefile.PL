use inc::Module::Install 0.89;
use strict;
use warnings;

use 5.008001;

# ****** DO NOT ADD OPTIONAL DEPENDENCIES. EVER. --mst ******

name     'DBIx-Class-Journal';
perl_version '5.008001';
all_from 'lib/DBIx/Class/Journal.pm';


test_requires 'Test::TempDir'       => '0.04';

requires 'DBIx::Class'               => '0.08';

tests_recursive ('t');

resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'http://dev.catalyst.perl.org/repos/bast/DBIx-Class-Journal/';

WriteAll();

