package DBIx::Class::Schema::Journal;

use base qw/DBIx::Class/;

use Scalar::Util 'blessed';
use DBIx::Class::Schema::Journal::DB;

__PACKAGE__->mk_classdata('journal_storage_type');
__PACKAGE__->mk_classdata('journal_connection');
__PACKAGE__->mk_classdata('journal_deploy_on_connect');
__PACKAGE__->mk_classdata('journal_sources'); ## [ source names ]
__PACKAGE__->mk_classdata('journal_user'); ## [ class, field for user id ]
__PACKAGE__->mk_classdata('_journal_schema'); ## schema object for journal
__PACKAGE__->mk_classdata('journal_nested_changesets');

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

    my $journal_schema = DBIx::Class::Schema::Journal::DB->compose_namespace(blessed($self) . '::Journal');

    if($self->journal_connection)
    {
        if($self->journal_storage_type)
        {
            $journal_schema->storage_type($self->journal_storage_type);
        }
        $journal_schema->connection(@{ $self->journal_connection });
    } else {
        $journal_schema->storage( $schema->storage );
    }

    $self->_journal_schema($journal_schema);


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

    if ( $self->journal_nested_changesets ) {
        $self->_journal_schema->nested_changesets(1);
        die "FIXME nested changeset schema not yet supported... add parent_id to ChangeSet here";
    }

    $self->journal_schema_deploy()
        if $self->journal_deploy_on_connect;

    ## Set up relationship between changeset->user_id and this schema's user
    if(!@{$self->journal_user || []})
    {
        #warn "No Journal User set!"; # no need to warn, user_id is useful even without a rel
        return $schema;
    }

    $self->_journal_schema->class('ChangeSet')->belongs_to('user', @{$self->journal_user});
    $self->_journal_schema->storage->disconnect();

    return $schema;
}

sub deploy
{
    my ( $self, $sqlt_args, @args ) = @_;

    $self->next::method($sqlt_args, @args);

    $self->journal_schema_deploy($sqlt_args, @args);
}

sub journal_schema_deploy
{
    my ( $self, $sqlt_args, @args ) = @_;

    $self->_journal_schema->deploy( $sqlt_args, @args );
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
    my $logclass = $self->get_audit_log_class_name($s_name);

    DBIx::Class::Componentised->inject_base($logclass, 'DBIx::Class::Schema::Journal::DB::AuditLog');
    $logclass->journal_define_table($source);

    my $log_source = "${s_name}AuditLog";
    $self->_journal_schema->register_class($log_source, $logclass);
                           

    my $histclass = $self->get_audit_history_class_name($s_name);
    DBIx::Class::Componentised->inject_base($histclass, 'DBIx::Class::Schema::Journal::DB::AuditHistory');
    $histclass->table(lc($s_name) . "_audit_history");
#    $histclass->result_source_instance->name(lc($s_name) . "_audit_hisory");

    foreach my $column ( $source->columns ) {
        my $info = $source->column_info($column);

        my %hist_info = %$info;

        delete $hist_info{$_} for qw(
            is_foreign_key
            is_primary_key
            is_auto_increment
            default_value
        );
        
        $hist_info{is_nullable} = 1;

        $histclass->add_column($column => \%hist_info);
    }
                           
    my $hist_source = "${s_name}AuditHistory";
    $self->_journal_schema->register_class($hist_source, $histclass);

    return ( $log_source, $hist_source );
}

sub txn_do
{
    my ($self, $user_code, @args) = @_;

    my $jschema = $self->_journal_schema;

    my $code = $user_code;

    my $current_changeset = $jschema->_current_changeset;
    if ( !$current_changeset || $self->journal_nested_changesets )
    {
        my $current_changeset_ref = $jschema->_current_changeset_container;

        unless ( $current_changeset_ref ) {
            # this is a hash because scalar refs can't be localized
            $current_changeset_ref = { };
            $jschema->_current_changeset_container($current_changeset_ref);
        }

        # wrap the thunk with a new changeset creation
        $code = sub {
            my $changeset = $jschema->journal_create_changeset( parent_id => $current_changeset );
            local $current_changeset_ref->{changeset} = $changeset->id;
            $user_code->(@_);
        };

    }

    if ( $jschema->storage != $self->storage ) {
        my $inner_code = $code;
        $code = sub { $jschema->txn_do($inner_code, @_) };
    }

    return $self->next::method($code, @args);
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
