package DBIx::Class::Schema::Journal::DB::AuditLog;

use base 'DBIx::Class::Schema::Journal::DB::Base';
__PACKAGE__->table(__PACKAGE__->table);

__PACKAGE__->add_columns(
                           ID => {
                               data_type => 'integer',
#                               is_auto_increment => 1,
                               is_nullable => 0,
                           },
                           create_id => {
                               data_type => 'integer',
                               is_nullable => 0,
                               is_foreign_key => 1,
                           },
                           delete_id => {
                               data_type => 'integer',
                               is_nullable => 1,
                               is_foreign_key => 1,
                           });
__PACKAGE__->set_primary_key('ID');

  __PACKAGE__->belongs_to('created', 'DBIx::Class::Schema::Journal::DB::Change', 'create_id');
  __PACKAGE__->belongs_to('deleted', 'DBIx::Class::Schema::Journal::DB::Change', 'delete_id');

sub new
{
    my ($self, $data, @rest) = @_;
    my $source = $data->{-result_source};

    $data->{created} = { 
#        ID => \'DEFAULT',
#        ID => 1,
        changeset_id => $source->schema->current_changeset,
        %{$data->{created}||{}}, 
    };

    $self->next::method($data, @rest);
}                           

1;
