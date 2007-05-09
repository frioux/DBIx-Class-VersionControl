package DBIx::Class::Schema::Journal::DB::Change;

use base 'DBIx::Class';

# __PACKAGE__->load_components(qw/Core/);
__PACKAGE__->load_components(qw/Ordered Core/);
__PACKAGE__->table('change');

__PACKAGE__->add_columns(
                         ID => {
                             data_type => 'integer',
                             is_auto_increment => 1,
                             is_primary_key => 1,
                             is_nullable => 0,
                         },
                         changeset_id => {
                             data_type => 'integer',
                             is_nullable => 0,
                             is_foreign_key => 1,
                         },
                         order_in => {
                             data_type => 'integer',
                             is_nullable => 0,
                         },
                         );


__PACKAGE__->set_primary_key('ID');
__PACKAGE__->add_unique_constraint('setorder', [ qw/changeset_id order_in/ ]);
__PACKAGE__->belongs_to('changeset', 'DBIx::Class::Schema::Journal::DB::ChangeSet', 'changeset_id');

 __PACKAGE__->position_column('order_in');
 __PACKAGE__->grouping_column('changeset_id');
1;
