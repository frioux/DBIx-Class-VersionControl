package DBIx::Class::Schema::Journal;

use base qw/DBIx::Class/;

use Scalar::Util 'blessed';
use DBIx::Class::Schema::Journal::DB;

__PACKAGE__->mk_classdata('journal_storage_type');
__PACKAGE__->mk_classdata('journal_connection');
__PACKAGE__->mk_classdata('journal_sources'); ## [ source names ]
__PACKAGE__->mk_classdata('journal_user'); ## [ class, field for user id ]
__PACKAGE__->mk_classdata('_journal_schema');

sub connection
{
    my $self = shift;
    $self->next::method(@_);

   print STDERR join(":", $self->sources), "\n";

    my $journal_schema = DBIx::Class::Schema::Journal::DB->connect(@{ $self->journal_connection || $self->storage->connect_info });
#    print STDERR "conn", $journal_schema->storage->connect_info;
    if($self->journal_storage_type)
    {
        $journal_schema->storage_type($self->journal_storage_type);
    }

    ## get our own private version of the journaling sources
   $self->_journal_schema($journal_schema->compose_namespace(blessed($self) . '::Journal'));

    ## Create auditlog+history per table
    my %j_sources = @{$self->journal_sources} ? map { $_ => 1 } @{$self->journal_sources} : map { $_ => 1 } $self->sources;
    foreach my $s_name ($self->sources)
    {
        next unless($j_sources{$s_name});
        $self->create_journal_for($s_name);
        $self->class($s_name)->load_components('Journal');
#        print STDERR "$s_name :", $self->class($s_name), "\n";
    }

    ## Set up relationship between changeset->user_id and this schema's user
    if(!@{$self->journal_user})
    {
        warn "No Journal User set!";
        return;
    }

    $self->_journal_schema->deploy();
    $self->_journal_schema->class('ChangeSet')->belongs_to('user', @{$self->journal_user});
    $self->_journal_schema->storage->disconnect();
}

sub get_audit_log_class_name
{
    my ($self, $sourcename) = @_;

    return blessed($self->_journal_schema) . "::${sourcename}AuditLog";
}

sub get_audit_history_class_name
{
    my ($self, $sourcename) = @_;

    return blessed($self->_journal_schema) . "::${sourcename}AuditHistory";
}

sub create_journal_for
{
    my ($self, $s_name) = @_;

    my $source = $self->source($s_name);
    my $newclass = $self->get_audit_log_class_name($s_name);
    DBIx::Class::Componentised->inject_base($newclass, 'DBIx::Class::Schema::Journal::DB::AuditLog');
    $newclass->table(lc($s_name) . "_audit_log");
    $self->_journal_schema->register_class("${s_name}AuditLog", $newclass);
                           

    my $histclass = $self->get_audit_history_class_name($s_name);
    DBIx::Class::Componentised->inject_base($histclass, 'DBIx::Class::Schema::Journal::DB::AuditHistory');
    $histclass->table(lc($s_name) . "_audit_history");
#    $histclass->result_source_instance->name(lc($s_name) . "_audit_hisory");
    $histclass->add_columns(
                            map { $_ => $source->column_info($_) } $source->columns
                           );
                           
    $self->_journal_schema->register_class("${s_name}AuditHistory", $histclass);
}

sub txn_do
{
    my ($self, $code) = @_;

    ## Create a new changeset, then run $code as a transaction
    my $cs = $self->_journal_schema->resultset('ChangeSet');
    my $changeset = $cs->create({
        user_id => $self->_journal_schema->current_user(),
        session_id => $self->_journal_schema->current_session(),
    });
    $self->_journal_schema->current_changeset($changeset->ID);

    $self->next::method($code);
}

1;
