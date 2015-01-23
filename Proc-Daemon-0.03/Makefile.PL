use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	 => 'Proc::Daemon',
    DISTNAME	 => 'Proc-Daemon',
    VERSION_FROM => 'Daemon.pm', # finds $VERSION
    dist	 => { COMPRESS => 'gzip', SUFFIX => 'gz'},
);
