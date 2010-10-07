package DBIx::Class::VersionControl::Util;

# parse the following at some point
# (list taken from git test suite, t/t0006-date.sh)
=pod

now                  => '2009-08-30 19:20:00'
'5 seconds ago'      => '2009-08-30 19:19:55'
5.seconds.ago        => '2009-08-30 19:19:55'
10.minutes.ago       => '2009-08-30 19:10:00'
yesterday            => '2009-08-29 19:20:00'
3.days.ago           => '2009-08-27 19:20:00'
3.weeks.ago          => '2009-08-09 19:20:00'
3.months.ago         => '2009-05-30 19:20:00'
2.years.3.months.ago => '2007-05-30 19:20:00'

'6am yesterday'      => '2009-08-29 06:00:00'
'6pm yesterday'      => '2009-08-29 18:00:00'
'3:00'               => '2009-08-30 03:00:00'
'15:00'              => '2009-08-30 15:00:00'
'noon today'         => '2009-08-30 12:00:00'
'noon yesterday'     => '2009-08-29 12:00:00'

'last tuesday'       => '2009-08-25 19:20:00'
'July 5th'           => '2009-07-05 19:20:00'
'06/05/2009'         => '2009-06-05 19:20:00'
'06.05.2009'         => '2009-05-06 19:20:00'

'Jun 6, 5AM'         => '2009-06-06 05:00:00'
'5AM Jun 6'          => '2009-06-06 05:00:00'
'6AM, June 7, 2009'  => '2009-06-07 06:00:00'
=cut

sub parse_date { }

1;
