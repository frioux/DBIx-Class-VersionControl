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
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema(no_populate => 1);

ok($schema, 'Created a Schema');
isa_ok($schema->_journal_schema, 'DBIx::Class::Schema::Journal::DB', 'Actually have a schema object for the journaling');
isa_ok($schema->_journal_schema->source('CDAuditHistory'), 'DBIx::Class::ResultSource', 'CDAuditHistory source exists');
isa_ok($schema->_journal_schema->source('ArtistAuditLog'), 'DBIx::Class::ResultSource', 'ArtistAuditLog source exists');

my $new_cd = $schema->resultset('CD')->create({
    title => 'Angry young man',
    artist => 0,
    year => 2000,
    });

isa_ok($new_cd, 'DBIx::Class::Journal', 'Created CD object');

my $search = $schema->_journal_schema->resultset('CDAuditLog')->search();
ok($search->count, 'Created an entry in the CD audit log');


