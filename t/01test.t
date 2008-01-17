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
        : ( tests => 12 );
}

my $schema = DBICTest->init_schema(no_populate => 1);

ok($schema, 'Created a Schema');
isa_ok($schema->_journal_schema, 'DBIx::Class::Schema::Journal::DB', 'Actually have a schema object for the journaling');
isa_ok($schema->_journal_schema->source('CDAuditHistory'), 'DBIx::Class::ResultSource', 'CDAuditHistory source exists');
isa_ok($schema->_journal_schema->source('ArtistAuditLog'), 'DBIx::Class::ResultSource', 'ArtistAuditLog source exists');

my $artist;
my $new_cd = $schema->txn_do( sub {
    $artist = $schema->resultset('Artist')->create({
        name => 'Fred Bloggs',
    });
    return  $schema->resultset('CD')->create({
        title => 'Angry young man',
        artist => $artist,
        year => 2000,
    });
});
isa_ok($new_cd, 'DBIx::Class::Journal', 'Created CD object');

my $search = $schema->_journal_schema->resultset('CDAuditLog')->search();
ok($search->count, 'Created an entry in the CD audit log');

$schema->txn_do( sub {
    $new_cd->year(2003);
    $new_cd->update;
} );

is($new_cd->year, 2003,  'Changed year to 2003');
my $cdah = $schema->_journal_schema->resultset('CDAuditHistory')->search();
ok($cdah->count, 'Created an entry in the CD audit history');

$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something',
        artist => $artist,
        year => 1999,
    });
} );

$schema->txn_do( sub {
    $new_cd->delete;
} );

my $alentry = $search->find({ ID => $new_cd->get_column($new_cd->primary_columns) });
ok(defined($alentry->deleted), 'Deleted set in audit_log');

$schema->changeset_user(1);
$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something 2',
        artist => $artist,
        year => 1999,
    });
} );

ok($search->count > 1, 'Created an second entry in the CD audit history');

my $cset = $schema->_journal_schema->resultset('ChangeSet')->find(5);
is($cset->user_id, 1, 'Set user id for 5th changeset');

$schema->changeset_session(1);
$schema->txn_do( sub {
    $schema->resultset('CD')->create({
        title => 'Something 3',
        artist => $artist,
        year => 1999,
    });
} );

my $cset2 = $schema->_journal_schema->resultset('ChangeSet')->find(6);
is($cset2->session_id, 1, 'Set session id for 6th changeset');

