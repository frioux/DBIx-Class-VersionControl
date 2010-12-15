#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class::VersionControl::UI 'versioned', 'versions_of', 'changed';

use A;

my $schema = A->connect;
my $v_schema = versioned(A->connect);

my $fish = $schema->resultset('BandMate')->create({ name => 'Fish' });
is $schema->resultset('BandMate')->count, 1;
is $v_schema->resultset('BandMate')->count, 1;

# band_mates:
# { id => 1, name => Fish },

# v_band_mate
# { id => 1, name => Fish, version => 1 },

my $hogarth = $schema->resultset('BandMate')->create({ name => 'Steve Hogarth' });
is $schema->resultset('BandMate')->count, 2;
is $v_schema->resultset('BandMate')->count, 2;

# band_mates:
# { id => 1, name => Fish },
# { id => 2, name => Steve Hogarth }

# v_band_mate
# { id => 1, name => Fish, version => 1 },
# { id => 2, name => Steve Hogarth, version => 1 }

my $marillion = $schema->resultset('Band')->create({ name => 'Marillion', headliner_id => $fish->id });

is $schema->resultset('Band')->count, 1;
is $v_schema->resultset('Band')->count, 1;

# band
# { id => 1, name => Marillion, headliner_id => 1 },

# v_band
# { id => 1, name => Marillion, headliner_id => 1, headliner_version => 1, version => 1 },

# first era
$marillion->add_to_albums($_) for (
   { name => q(Script for a Jester's Tear) },
   { name => 'Misplaced Childhood' },
   { name => 'Clutching at Straws' },
);

# discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1 }

# v_discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1, band_version => 1, version => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1, band_version => 1, version => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1, band_version => 1, version => 1 }

is $schema->resultset('Album')->count, 3;
is $v_schema->resultset('Album')->count, 3;

$marillion->update({ headliner => $hogarth });

is $schema->resultset('Band')->count, 1;
is $v_schema->resultset('Band')->count, 2; # band got copied

# band
# { id => 1, name => Marillion, headliner_id => 2 },

# v_band
# { id => 1, name => Marillion, headliner_id => 2, headliner_version => 1, version => 2 },

is $schema->resultset('Album')->count, 3;
is $v_schema->resultset('Album')->count, 6; # albums got copied

# discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1 }

# v_discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1, band_version => 1, version => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1, band_version => 1, version => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1, band_version => 1, version => 1 }
# { id => 1, name => Script for a Jester's Tear, band_id => 1, band_version => 2, version => 2 }
# { id => 2, name => Misplaced Childhood, band_id => 1, band_version => 2, version => 2 }
# { id => 3, name => Clutching at Straws, band_id => 1, band_version => 2, version => 2 }

# second era
$marillion->add_to_albums($_) for (
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

# discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1 }
# { id => 4, name => 'Seasons End', band_id => 1 },
# { id => 5, name => 'Holidays in Eden', band_id => 1 },
# { id => 6, name => 'Brave', band_id => 1 },
# { id => 7, name => 'Afraid of Sunlight', band_id => 1 },
# { id => 8, name => 'This Strange Engine', band_id => 1 },
# { id => 9, name => 'Radiation', band_id => 1 },
# { id => 10, name => 'marillion.com', band_id => 1 },
# { id => 11, name => 'Anoraknaphobia', band_id => 1 },
# { id => 12, name => 'Marbles', band_id => 1 },
# { id => 13, name => 'Somewhere Else', band_id => 1 },
# { id => 14, name => 'Happiness is the Road', band_id => 1 },


# v_discs
# { id => 1, name => Script for a Jester's Tear, band_id => 1, band_version => 1, version => 1 }
# { id => 2, name => Misplaced Childhood, band_id => 1, band_version => 1, version => 1 }
# { id => 3, name => Clutching at Straws, band_id => 1, band_version => 1, version => 1 }
# { id => 1, name => Script for a Jester's Tear, band_id => 1, band_version => 2, version => 2 }
# { id => 2, name => Misplaced Childhood, band_id => 1, band_version => 2, version => 2 }
# { id => 3, name => Clutching at Straws, band_id => 1, band_version => 2, version => 2 }
# { id => 4, name => 'Seasons End', band_id => 1, band_version => 2, version => 1 },
# { id => 5, name => 'Holidays in Eden', band_id => 1, band_version => 2, version => 1 },
# { id => 6, name => 'Brave', band_id => 1, band_version => 2, version => 1 },
# { id => 7, name => 'Afraid of Sunlight', band_id => 1, band_version => 2, version => 1 },
# { id => 8, name => 'This Strange Engine', band_id => 1, band_version => 2, version => 1 },
# { id => 9, name => 'Radiation', band_id => 1, band_version => 2, version => 1 },
# { id => 10, name => 'marillion.com', band_id => 1, band_version => 2, version => 1 },
# { id => 11, name => 'Anoraknaphobia', band_id => 1, band_version => 2, version => 1 },
# { id => 12, name => 'Marbles', band_id => 1, band_version => 2, version => 1 },
# { id => 13, name => 'Somewhere Else', band_id => 1, band_version => 2, version => 1 },
# { id => 14, name => 'Happiness is the Road', band_id => 1, band_version => 2, version => 1 },

is $schema->resultset('Album')->count, 14;
is $v_schema->resultset('Album')->count, 17;

