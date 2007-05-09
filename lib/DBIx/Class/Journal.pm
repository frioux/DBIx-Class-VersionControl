package DBIx::Class::Journal;

use base qw/DBIx::Class/;

## On create/insert, add new entry to AuditLog

# sub new
# {
#     my ($class, $attrs, @rest) = @_;

#     $class->result_source->schema->_journal_schema->current_user(delete $attrs->{user_id});

#     $class->next::method($attrs, @rest);
# }

sub insert
{
    my ($self) = @_;

    ## create new transaction here?
    my $res = $self->next::method();
    if($self->in_storage)
    {
        my $s_name = $self->result_source->source_name();
        my $al = $self->result_source->schema->_journal_schema->resultset("${s_name}AuditLog");
        my ($pri, $too_many) = map { $self->get_column($_)} $self->primary_columns;
        if(defined $pri && defined $too_many) 
        {
            $self->throw_exception( "More than one possible key found for auto-inc on ".ref $self );
        }
        $pri ||= \'NULL';   #'
        $al->create({
            ID => $pri,
#            created => {
#                changeset => $self->result_source->schema->_journal_schema->current_changeset(),
#            },
        });
    }

    return $res;
}

## On delete, update delete_id of AuditLog

## On update, copy previous row's contents to AuditHistory



1;
