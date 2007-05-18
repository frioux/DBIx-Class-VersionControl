use ExtUtils::MakeMaker;

WriteMakefile(
     NAME          => 'DBIx::Class::Journal',
     VERSION_FROM  => 'lib/DBIx/Class/Schema/Journal.pm',
     PREREQ_PM     => { 'DBIx::Class'           => 0.08,
                        'DBD::SQLite'           => 0.12,
                    },
);
