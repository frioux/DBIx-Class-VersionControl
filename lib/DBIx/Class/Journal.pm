package DBIx::Class::Journal;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/AccessorGroup/);

__PACKAGE__->mk_group_accessors('simple' => qw/
                                journal_dsn
                                journal_sources
                                /);


1;
