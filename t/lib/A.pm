package A;
use parent qw/DBIx::Class::Schema/;

use strict;
use warnings;

__PACKAGE__->load_components( 'VersionControl' );
__PACKAGE__->load_namespaces( default_resultset_class => '+A::ResultSet' );

1;

