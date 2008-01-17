package DBIx::Class::Schema::Journal;

use base qw/DBIx::Class/;

use Scalar::Util 'blessed';
use DBIx::Class::Schema::Journal::DB;

__PACKAGE__->mk_classdata('journal_storage_type');
__PACKAGE__->mk_classdata('journal_connection');
__PACKAGE__->mk_classdata('journal_sources'); ## [ source names ]
__PACKAGE__->mk_classdata('journal_user'); ## [ class, field for user id ]
__PACKAGE__->mk_classdata('_journal_schema'); ## schema object for journal

our $VERSION = '0.01';

use strict;
use warnings;

# sub throw_exception
# {
# }

# sub exception_action
# {
#     my $self = shift;
# #    print STDERR Carp::longmess;
    
#     $self->next::method(@_);
# }

# sub load_classes
# {
#     my $class = shift;


#     $class->next::method(@_);
    
# }

sub connection
{
    my $self = shift;
    my $schema = $self->next::method(@_);

#   print STDERR join(":", $self->sources), "\n";

    my $journal_schema;
    if(!defined($self->journal_connection))
    {
        ## If no connection, use the same schema/storage etc as the user
        DBIx::Class::Componentised->inject_base(ref $self, 'DBIx::Class::Schema::Journal::DB');
          $journal_schema = $self;
    }
    else
    {
        $journal_schema = DBIx::Class::Schema::Journal::DB->connect(@{ $self->journal_connection });
        if($self->journal_storage_type)
        {
            $journal_schema->storage_type($self->journal_storage_type);
        }
    }

    ## get our own private version of the journaling sources
   $self->_journal_schema($journal_schema->compose_namespace(blessed($self) . '::Journal'));

    ## Create auditlog+history per table
    my %j_sources = map { $_ => 1 } $self->journal_sources
                                      ? @{$self->journal_sources}
                                      : $self->sources;
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

    return $schema;
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

    $self->txn_begin;
    my %changesetdata;
    if( defined $self->_journal_schema->current_user() )
    {
        $changesetdata{user_id} = $self->_journal_schema->current_user();
    }
    if( defined $self->_journal_schema->current_session() )
    {
        $changesetdata{session_id} = $self->_journal_schema->current_session();
    }

#         ( 
#           $self->_journal_schema->current_user() 
#           ? ( user_id => $self->_journal_schema->current_user()) 
#           : (),
#           $self->_journal_schema->current_session() 
#           ? ( session_id => $self->_journal_schema->current_session() ) 
#           : () 
#         );
    if(!%changesetdata)
    {
        %changesetdata = ( ID => undef );
    }
    my $changeset = $cs->create({ %changesetdata });
    $self->_journal_schema->current_changeset($changeset->ID);

    $self->next::method($code);
}

sub changeset_user
{
    my ($self, $userid) = @_;

    return $self->_journal_schema->current_user() if(@_ == 1);

    $self->_journal_schema->current_user($userid);
}

sub changeset_session
{
    my ($self, $sessionid) = @_;

    return $self->_journal_schema->current_session() if(@_ == 1);

    $self->_journal_schema->current_session($sessionid);
}


1;
