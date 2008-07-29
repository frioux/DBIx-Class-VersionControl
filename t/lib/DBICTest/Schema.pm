package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_components(qw/+DBIx::Class::Schema::Journal/);

__PACKAGE__->journal_no_automatic_deploy(1);

__PACKAGE__->journal_connection(['dbi:SQLite:t/var/Audit.db']);

no warnings qw/qw/;
DBICTest::Schema->load_classes(
qw/
  Artist
  CD
  Track
/
);

1;
