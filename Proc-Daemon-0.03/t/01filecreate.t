print "1..1\n";

use Proc::Daemon;
use Cwd;

##  Since a daemon will not be able to print terminal output, we
##  have a test daemon create a file, and another process test for
##  its existence.

## Try to make sure we are in the test directory
my $cwd = Cwd::cwd();
   chdir 't'  if ($cwd !~ m|/t$|);
   $cwd = Cwd::cwd();

## Test filename
my $file = join('/', $cwd, ',im_alive');

## Parent process will check if file created.  Child becomes the daemon.
my $pid;
if ($pid = Proc::Daemon::Fork) {
    sleep(5);	# Punt on sleep time, 5 seconds should be enough
    if (-e $file) {
	unlink $file;
	print "ok 1\n";
    } else {
	print "not ok 1\n";
    }
} else {
    Proc::Daemon::Init;
    open(FILE, ">$file") || die;
    close(FILE);
}
