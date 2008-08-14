package DBIx::Class::Journal;

use base qw/DBIx::Class/;

use strict;
use warnings;

our $VERSION = '0.900001_02';

## On create/insert, add new entry to AuditLog

# sub new
# {
#     my ($class, $attrs, @rest) = @_;

#     $class->result_source->schema->_journal_schema->current_user(delete $attrs->{user_id});

#     $class->next::method($attrs, @rest);
# }

sub _journal_schema {
    my $self = shift;
    $self->result_source->schema->_journal_schema;
}

sub insert
{
    my ($self, @args) = @_;

    return if($self->in_storage);

    my $res = $self->next::method(@args);

    $self->journal_log_insert();

    return $res;
}

sub journal_log_insert
{
    my ($self) = @_;

    if ( $self->in_storage ) {
        my $j = $self->_journal_schema;
        my $change_id = $j->journal_create_change()->id;
        $j->journal_update_or_create_log_entry( $self, create_id => $change_id );
        $j->journal_record_in_history( $self, audit_change_id => $change_id );
    }
}

## On delete, update delete_id of AuditLog

sub delete
{
    my ($self, @rest) = @_;
    $self->next::method(@rest);
    $self->journal_log_delete(@rest);
}

sub journal_log_delete
{
    my ($self) = @_;

    unless ($self->in_storage) {
        my $j = $self->_journal_schema;
        $j->journal_update_or_create_log_entry( $self, delete_id => $j->journal_create_change->id );
    }
}

## On update, copy previous row's contents to AuditHistory

sub update 
{
    my ($self, $upd, @rest) = @_;
    $self->journal_log_update($upd, @rest);
    $self->next::method($upd, @rest);
}

sub journal_log_update 
{
    my ($self, $upd, @rest) = @_;

    if($self->in_storage)
    {
        my $j = $self->_journal_schema;

        my $change = $j->journal_create_change;
        my $prev = $self->result_source->resultset->find( $self->ident_condition );
        $j->journal_record_in_history( $prev, audit_change_id => $change );
    }
}

=head1 NAME

DBIx::Class::Journal - auditing for tables managed by DBIx::Class

=head1 SYNOPSIS

  package My::Schema;
  use base 'DBIx::Class::Schema';

  __PACKAGE__->load_components(qw/+DBIx::Class::Schema::Journal/);

  __PACKAGE__->journal_connection(['dbi:SQLite:t/var/Audit.db']);
  __PACKAGE__->journal_user(['My::Schema::User', {'foreign.userid' => 'self.user_id'}]);


 ########

  $schema->changeset_user($user->id);
  my $new_artist = $schema->txn_do( sub {
   return = $schema->resultset('Artist')->create({ name => 'Fred' });
  });


=head1 DESCRIPTION

The purpose of this L<DBIx::Class> component module is to create an
audit-trail for all changes made to the data in your database (via a
DBIx::Class schema). It creates changesets and assigns each
create/update/delete operation an id. The creation and deletion date
of each row is stored, as well as the previous contents of any row
that gets changed.

All queries which want auditing should be called using
L<DBIx::Class::Schema/txn_do>, which is used to create changesets for
each transaction.

To track who did which changes, the user_id (an integer) of the
current user can be set, a session_id can also be set, both are
optional.

To access the auditing schema to look at the auditdata or revert a
change, use C<< $schema->_journal_schema >>.

=head2 TABLES

The journal schema contains a number of tables. 

=over

=item ChangeSet

Each changeset row has an auto-incremented ID, optional user_id and
session_id, and a set_date which defaults to the current datetime.

A ChangeSet has_many Changes.

=item ChangeLog

Each change/operation done in the transaction is recorded as a row in
the ChangeLog table. It contains an auto-incrementing ID, the
changeset_id and an order column for the ordering of each change in
the changeset.

=item AuditLog

For every table in the original database that is to be audited, an
AuditLog table is created. Each auditlog row has an id which will
contain the primary key of the table it is associated with. (NB:
currently only supports integer-based single column PKs). The
create_id and delete_id fields contain the IDs of the Changes that
created or deleted this row.

=item AuditHistory

For every table in the original database to be audited, an
AuditHistory table is created. Each row has a change_id field
containing the ID of the ChangeLog row. The other fields correspond to
all the fields from the original table. Each time a column value in
the original table is changed, the entire row contents before the
change are added as a new row in this table.

=back

=head2 METHODS

=over

=item journal_connection \@connect_info

Set the connection information for the database to save your audit
information to.

Leaving this blank assumes you want to store the audit data into your current
database. The storage object will be shared by the regular schema and the
journalling schema.

=item journal_sources \@source_names

Set a list of source names you would like to audit, if unset, all
sources are used.

NOTE: Currently only sources with a single-column PK are supported, so
use this method if you have sources with multi-column PKs.

=item journal_storage_type $type

Enter the special storage type of your journal schema if needed. See
L<DBIx::Class::Storage::DBI> for more information on storage types.

=item journal_user \@rel

The user_id column in the L</ChangeSet> will be linked to your user id
with a belongs_to relation, if this is set with the appropriate
arguments.

=item journal_deploy_on_connect $bool

If set to a true value will cause C<journal_schema_deploy> to be called on
C<connect>.

Not reccomended, but present for backwards compatibility.

=item changeset_user $user_id

Set the user_id for the following changeset(s). This must be an integer.

=item changeset_session $session_id

Set the session_id for the following changeset(s). This must be an integer.

=item txn_do $code_ref, @args

Overloaded L<DBIx::Class::Schema/txn_do>, this must be used to start a
new changeset to cover a group of changes. Each subsequent change to
an audited table will use the changeset_id created in the most recent
txn_do call.

Currently nested C<txn_do> calls cause a single ChangeSet object to be created.

=back

=head1 SEE ALSO

L<DBIx::Class> - You'll need it to use this.

=head1 NOTES

Only single-column integer primary key'd tables are supported for auditing so far.

Updates made via L<DBIx::Class::ResultSet/update> are not yet supported.

No API for viewing or restoring changes yet.

Patches for the above welcome ;)

=head1 AUTHOR

Jess Robinson <castaway@desert-island.me.uk>

Matt S. Trout <mst@shadowcatsystems.co.uk> (ideas and prodding)

=head1 LICENCE

You may distribute this code under the same terms as Perl itself.

=cut

1;
