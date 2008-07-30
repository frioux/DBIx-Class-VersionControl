package DBIx::Class::Schema::Journal::DB::AuditLog;

use base 'DBIx::Class';

sub journal_define_table {
    my ( $class, $source ) = @_;

    $class->load_components(qw(Core));

    $class->table($source->name . "_audit_log");

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

    $class->belongs_to('created', 'DBIx::Class::Schema::Journal::DB::ChangeLog', 'create_id');
    $class->belongs_to('deleted', 'DBIx::Class::Schema::Journal::DB::ChangeLog', 'delete_id');
}

1;
