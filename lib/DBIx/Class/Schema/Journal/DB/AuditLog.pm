package DBIx::Class::Schema::Journal::DB::AuditLog;

use base 'DBIx::Class::Core';

sub journal_define_table {
    my ( $class, $source, $schema_class ) = @_;

    $class->table($source->name . '_audit_log');

    # the create_id is the id of first insertion of the row
    # so we always know where to roll back to
    # and presumably should be supplied on every insert

    $class->add_columns(
        create_id => {
            data_type => 'integer',
            is_nullable => 0,
            is_foreign_key => 1,
        },
        delete_id => {
            data_type => 'integer',
            is_nullable => 1,
            is_foreign_key => 1,
        }
    );

    foreach my $column ( $source->primary_columns ) {
        $class->add_column( $column => { %{ $source->column_info($column) } } );
    }

    $class->set_primary_key( $source->primary_columns );

    $class->belongs_to(created => "${schema_class}::ChangeLog", 'create_id');
    $class->belongs_to(deleted => "${schema_class}::ChangeLog", 'delete_id');
}

1;
