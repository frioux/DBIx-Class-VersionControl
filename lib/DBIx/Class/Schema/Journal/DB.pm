package DBIx::Class::Schema::Journal::DB;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_classdata('nested_changesets');
__PACKAGE__->mk_group_accessors( simple => 'current_user' );
__PACKAGE__->mk_group_accessors( simple => 'current_session' );
__PACKAGE__->mk_group_accessors( simple => '_current_changeset_container' );

DBIx::Class::Schema::Journal::DB->load_classes(qw(ChangeSet ChangeLog));

require DBIx::Class::Schema::Journal::DB::AuditLog;
require DBIx::Class::Schema::Journal::DB::AuditHistory;

sub _current_changeset {
    my $self = shift;
    my $ref = $self->_current_changeset_container;
    $ref && $ref->{changeset};
}

# this is for localization of the current changeset
sub current_changeset {
    my ( $self, @args ) = @_;

    $self->throw_exception("setting current_changeset is not supported, use txn_do to create a new changeset") if @args;

    my $id = $self->_current_changeset;

    $self->throw_exception("Can't call current_changeset outside of a transaction") unless $id;

    return $id;
}

sub journal_create_changeset {
    my ( $self, @args ) = @_;

    my %changesetdata = ( @args, ID => undef );

    delete $changesetdata{parent_id} unless $self->nested_changesets;

    if( defined( my $user = $self->current_user() ) )
    {
        $changesetdata{user_id} = $user;
    }
    if( defined( my $session = $self->current_session() ) )
    {
        $changesetdata{session_id} = $session;
    }

    ## Create a new changeset, then run $code as a transaction
    my $cs = $self->resultset('ChangeSet');

    $cs->create({ %changesetdata });
}

1;
