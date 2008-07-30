package DBIx::Class::Schema::Journal::DB::ChangeSet;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('changeset');

__PACKAGE__->add_columns(
                         ID => {
                             data_type => 'integer',
                             is_auto_increment => 1,
                             is_primary_key => 1,
                             is_nullable => 0,
                         },
                         user_id => {
                             data_type => 'integer',
                             is_nullable => 1,
                             is_foreign_key => 1,
                         },
                         set_date => {
                             data_type => 'timestamp',
                             is_nullable => 0,
                         },
                         session_id => {
                             data_type => 'varchar',
                             size => 255,
                             is_nullable => 1,
                         },
                         );

sub new {
    my $self = shift->next::method(@_);
    $self->set_date(gmtime); # DateTime->now);
    return $self;
}

__PACKAGE__->set_primary_key('ID');

1;
