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

    return if($self->in_storage);
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

sub delete
{
    my ($self, @rest) = @_;
    $self->next::method(@rest);

    if(!$self->in_storage)
    {
        my $s_name = $self->result_source->source_name();
        my $al = $self->result_source->schema->_journal_schema->resultset("${s_name}AuditLog");
        my ($pri, $too_many) = map { $self->get_column($_)} $self->primary_columns;
        if(defined $pri && defined $too_many) 
        {
            $self->throw_exception( "More than one possible key found for auto-inc on ".ref $self );
        }

        if($pri)
        {
            my $alentry = $al->find({ID => $pri});
            $self->throw_exception( "No audit_log entry found for ".ref($self) . " item $pri" ) if(!$alentry);
             
            ## bulk_update doesnt do "create new item on update of rel-accessor with hashref, yet
            my $change = $self->result_source->schema->_journal_schema->resultset('Change')->create({ changeset_id => $self->result_source->schema->_journal_schema->current_changeset });
            $alentry->delete_id($change->ID);
            $alentry->update();
        }
    }
    
}

## On update, copy previous row's contents to AuditHistory

sub update 
{
    my ($self, $upd, @rest) = @_;

    if($self->in_storage)
    {
        my $s_name = $self->result_source->source_name();
        my $ah = $self->result_source->schema->_journal_schema->resultset("${s_name}AuditHistory");

        my $obj = $self->result_source->resultset->find( $self->ident_condition );
        $ah->create({
            $obj->get_columns
            });
    }

    $self->next::method($upd, @rest);
}



1;
