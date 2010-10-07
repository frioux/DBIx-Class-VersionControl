#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class::VersionControl::UI 'versioned', 'versions_of', 'changed';

use A;

my $schema = A->connect;

my $fish = $schema->resultset('BandMate')->create({ name => 'Fish' });
my $hogarth = $schema->resultset('BandMate')->create({ name => 'Steve Hogarth' });

my $marillion = $schema->resultset('Band')->create({ name => 'Marillion', headliner_id => $fish->id });

# first era
$marillion->add_to_cds($_) for (
   { name => q(Script for a Jester's Tear) },
   { name => 'Misplaced Childhood' },
   { name => 'Clutching at Straws' },
);

$marillion->update({ headliner => $hogarth });

# second era
$marillion->add_to_cds($_) for (
   { name => 'Seasons End' },
   { name => 'Holidays in Eden' },
   { name => 'Brave' },
   { name => 'Afraid of Sunlight' },
   { name => 'This Strange Engine' },
   { name => 'Radiation' },
   { name => 'marillion.com' },
   { name => 'Anoraknaphobia' },
   { name => 'Marbles' },
   { name => 'Somewhere Else' },
   { name => 'Happiness is the Road' },
);

# versioned is a minimally reblessed version of the
# result, which "fixes" relationships to include versioning
is versioned($marillion)->headliner->name, 'Steve Hogarth';

# do we want to even allow the following?
is versioned($marillion)->real_result, $marillion;

# I don't think this is the right API.  If anything it
# should be optional to add methods to the reblessed result
is versioned($marillion)->previous->cds->count, 3;
is versioned($marillion)->previous->headliner->name, 'Fish';

# the following is maybe better?
is versions_of($marillion)
   # before can take a result, which it will version if it isn't versioned already
   # a date
   # or an aproxidate (5.days.ago)
   ->before($marillion)
   # duh.
   ->search(undef, { rows => 1})->next
   # reblessed version of rel
   ->cds->count, 3;

is versions_of($marillion)
   # should before be implied?
   ->before
   ->search(undef, { rows => 1})->next
   ->headliner->name, 'Fish';

is versioned($marillion)->cds->count, 14;

# Changed rs should include *just* the cds that were added, in this case
is changed(
   versioned($marillion)->previous->cds_rs,
   versioned($marillion)->cds_rs
)->count, 11;

versions_of($marillion)->before('5.days.ago');
versions_of($marillion)->after('5.days.ago');

versions_of($marillion)->author('frew'); # probably resolves to author_id
