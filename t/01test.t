use strict;
use warnings;  

use Test::More;
use lib qw(t/lib);
use DBICTest;
use Data::Dumper;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 2 );
}

my $schema = DBICTest->init_schema(no_populate => 1);

ok($schema, 'Created a Schema');
isa_ok($schema->_journal_schema, 'DBIx::Class::Schema::Journal::DB');

