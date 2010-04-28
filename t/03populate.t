use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use DBD::SQLite; use SQL::Translator";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite and SQL::Translator for testing' )
        : ( tests => 17 );
}

use lib qw(t/lib);
use DBICTest;

# connect to db and deploy only the original db schema, not journal schema
my $schema = DBICTest->init_schema(no_populate => 1, no_deploy => 1);

ok($schema, 'Created a Schema');
$schema->deploy;

# check we have no journal
my $count = eval {
    $schema->_journal_schema->resultset('ChangeLog')->count;
};
my $e = $@;

is( $count, undef, 'no count' );
like( $e, qr/table.*changelog/, 'missing table error' );

# insert two rows -not- in txn
my ($artistA, $artistB);
#$schema->txn_do(sub {
    $artistA = $schema->resultset('Artist')->create({
        name => 'Fred Bloggs A',
    });

    $artistB = $schema->resultset('Artist')->create({
        name => 'Fred Bloggs B',
    });
#});

# create the journal
$schema->journal_schema_deploy();

# check it is empty
$count = eval { $schema->_journal_schema->resultset('ChangeLog')->count };

is( $@, '', "no error" );
is( $count, 0, "count is 0 (changelog)" );

# run populate
$schema->prepopulate_journal();

# check there is only one changeset
$count = eval { $schema->_journal_schema->resultset('ChangeSet')->count };

is( $@, '', "no error" );
is( $count, 1, "count is 1 (changeset)" );

# check it contains two inserts
$count = eval { $schema->_journal_schema->resultset('ChangeLog')->count };

is( $@, '', "no error" );
is( $count, 2, "count is 2 (changelog)" );

# check audit log has two rows for two inserts
$count = eval { $schema->_journal_schema->resultset('ArtistAuditLog')->count };

is( $@, '', "no error" );
is( $count, 2, "count is 2 (auditlog)" );

# now delete a row
eval {
    my $deleted = $schema->txn_do(sub {
        $artistA->delete;
    });
};

is( $@, '', "no error from deletion journal (create_id not null)" );
is( $artistA->in_storage, 0, "row was deleted" );

# check journal log still has two rows
$count = eval { $schema->_journal_schema->resultset('ArtistAuditLog')->count };

is( $@, '', "no error" );
is( $count, 2, "count is 2 (auditlog 2)" );

# and that one of them has a delete_id
$count = eval {
    $schema->_journal_schema->resultset('ArtistAuditLog')
        ->search({
            artistid => $artistA->id,
            delete_id => { '-not' => undef }
        })->count;
};

is( $@, '', "no error" );
is( $count, 1, "count is 1 (delete_id)" );

