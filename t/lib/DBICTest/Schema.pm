package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_components(qw/+DBIx::Class::Schema::Journal/);

__PACKAGE__->journal_user(['DBICTest::Schema::Artist', {'foreign.artistid' => 'self.user_id'}]);

no warnings qw/qw/;
__PACKAGE__->load_classes(qw/
  Artist
  CD
  Track
/
);

1;
