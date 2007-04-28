package DBIx::Class::Schema::Journal::DB::Base;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('');


1;
