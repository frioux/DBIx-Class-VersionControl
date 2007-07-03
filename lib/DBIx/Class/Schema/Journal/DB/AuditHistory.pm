package DBIx::Class::Schema::Journal::DB::AuditHistory;

use base 'DBIx::Class::Schema::Journal::DB::Base';
__PACKAGE__->table(__PACKAGE__->table);

__PACKAGE__->add_columns(
                           change_id => {
                               data_type => 'integer',
                               is_nullable => 0,
                           });
__PACKAGE__->belongs_to('change', 'DBIx::Class::Schema::Journal::DB::Change', 'change_id');

sub new
{
    my ($self, $data, @rest) = @_;
    my $source = $data->{-result_source};

    $data->{change} = { 
#        ID => \'DEFAULT',
        changeset_id => $source->schema->current_changeset,
        %{$data->{change}||{}}, 
    };

    $self->next::method($data, @rest);
}                           

1;
