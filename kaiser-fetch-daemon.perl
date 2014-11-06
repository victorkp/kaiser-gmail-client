#!/bin/perl

use strict;
use warnings;
use Proc::Daemon;

Proc::Daemon::Init;

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 }

while($continue) {
	# Fetch every 10 minutes

	# Can show notifications through
	# notify-send -a "Kaiser" -t TIMEOUT_MILLIS -i ICON "EMAIL ADDRESS" "MESSAGE"

}
