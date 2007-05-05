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
        print STDERR "Schema: ", ref($self->result_source->schema), "\n";
        my $al = $self->result_source->schema->_journal_schema->resultset("${s_name}AuditLog");
        $al->create({
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
