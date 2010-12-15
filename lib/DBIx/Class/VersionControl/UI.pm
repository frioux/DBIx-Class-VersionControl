package DBIx::Class::VersionControl::UI;

use Sub::Exporter -setup => {
   exports => [qw(versions_of versioned changed)],
};

sub versions_of { shift->versions_of }

sub versioned { shift->versioned }

sub changed { shift->changed }

1;
