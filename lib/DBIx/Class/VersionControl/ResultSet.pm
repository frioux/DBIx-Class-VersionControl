package DBIx::Class::VersionControl::ResultSet;

use DBIx::Class::VersionControl::Util 'parse_date';

sub before { shift->search({ date => { '<' => parse_date(shift) }) }

sub after { shift->search({ date => { '>' => parse_date(shift) }) }

1;
