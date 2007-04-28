package DBIx::Class::Schema::Journal;

use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata('journal_dsn');
__PACKAGE__->mk_classdata('journal_sources'); ## [ source names ]
__PACKAGE__->mk_classdata('journal_user'); ## [ class, field for user id ]
__PACKAGE__->mk_classdata('_journal_schema');

sub load_classes
{
    my $self = shift;
    $self->next::method(@_);

    $self->_journal_schema((__PACKAGE__ . '::DB')->connect($self->journal_dsn || $self->storage->connect_info));

    my %j_sources = @{$self->journal_sources} ? map { $_ => 1 } @{$self->journal_sources} : map { $_ => 1 } $self->sources;
    foreach my $s_name ($self->sources)
    {
        next unless($j_sources{$s_name});
        $self->create_journal_for($s_name);
    }

    ## Set up relationship between changeset->user_id and this schema's user
    if(!@{$self->journal_user})
    {
        warn "No Journal User set!";
        return;
    }

    DBIx::Class::Schema::Journal::DB::ChangeSet->belongs_to('user', @{$self->journal_user});
}

sub get_audit_log_class_name
{
    my ($self, $sourcename) = @_;

    return __PACKAGE__ . "::DB::${sourcename}AuditLog";
}

sub get_audit_history_class_name
{
    my ($self, $sourcename) = @_;

    return __PACKAGE__ . "::DB::${sourcename}AuditHistory";
}

sub create_journal_for
{
    my ($self, $s_name) = @_;

    my $source = $self->source($s_name);
    my $newclass = $self->get_audit_log_class_name($s_name);
    DBIx::Class::Componentised->inject_base($newclass, 'DBIx::Class');
    $newclass->load_components('Core');
    $newclass->table(lc($s_name) . "_audit_log");
    $newclass->add_columns(
                           ID => {
                               data_type => 'integer',
                               is_nullable => 0,
                           },
                           create_id => {
                               data_type => 'integer',
                               is_nullable => 0,
                           },
                           delete_id => {
                               data_type => 'integer',
                               is_nullable => 1,
                           });
    $newclass->belongs_to('created', 'DBIx::Class::Schema::Journal::DB::Change', 'create_id');
    $newclass->belongs_to('deleted', 'DBIx::Class::Schema::Journal::DB::Change', 'delete_id');
                           

    my $histclass = $self->get_audit_hisory_class_name($s_name);
    DBIx::Class::Componentised->inject_base($histclass, 'DBIx::Class');
    $histclass->load_components('Core');
    $histclass->table(lc($s_name) . "_audit_hisory");
    $histclass->add_columns(
                           change_id => {
                               data_type => 'integer',
                               is_nullable => 0,
                           },
                            map { $_ => $source->column_info($_) } $source->columns
                           );
    $histclass->belongs_to('change', 'DBIx::Class::Schema::Journal::DB::Change', 'change_id');
                           
}

1;
