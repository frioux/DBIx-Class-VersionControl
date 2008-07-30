package DBIx::Class::Schema::Journal::DB::AuditHistory;

use base 'DBIx::Class';

sub journal_define_table {
    my ( $class, $source ) = @_;

    $class->load_components(qw(Core));

    $class->table($source->name . "_audit_history");
    
    $class->add_columns(
        audit_history_id => {
            data_type => 'integer',
            is_nullable => 0,
            is_primary_key => 1,
            is_auto_increment => 1,
        },
        audit_change_id => {
            data_type => 'integer',
            is_nullable => 0,
            is_foreign_key => 1,
        },
    );

    $class->set_primary_key("audit_history_id");

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

        $class->add_column($column => \%hist_info);
    }
                           
    $class->belongs_to('change', 'DBIx::Class::Schema::Journal::DB::ChangeLog', 'audit_change_id');
}

1;
