#!/bin/perl

use strict;
use warnings;
use Net::IMAP::Simple;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple;
use Proc::Daemon;

Proc::Daemon::Init;

# Include Kaiser Modules
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(abs_path $0) . '/lib/';

use Kaiser::Config;
use Kaiser::Accounts;

my $HOME = $ENV{"HOME"};
my $PATH = "${HOME}/.kaiser";

# Send a notification through GNOME
# Arguments: Email Address, Number of unread messages
sub notify($$) {
	my $text = $_[0];
	my $unread = $_[1];

	if($unread > 1) {
		$unread = "Kaiser: 1 new message";
	} else {
		$unread = "Kaiser: ${unread} new messages";
	}

	system("notify-send --hint int:transient:1 -a \"Kaiser\" -i \"/usr/local/etc/kaiser-gmail/icon.png\" -t 10000 \"${unread}\" \"${text}\"");
}

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

while ($continue != 0) {
	# Load config and accounts 
	Kaiser::Config::load_config($PATH);
	Kaiser::Accounts::load_accounts($PATH);

	# Get accounts
	my @accounts = Kaiser::Accounts::get_accounts();

	my $receiving_addresses = "";
	my $unread_total = 0;

	# See if any account has unread messages
	for (my $i = 0; $i < scalar(@accounts); $i++ ) {
		print("Fetching messages for " . $accounts[$i]{'address'} . "\n");
		my $imap_server = Net::IMAP::Simple->new('imap.gmail.com', port=>993, use_ssl=>1) || next;
		$imap_server->login($accounts[$i]{'address'}, $accounts[$i]{'password'}) || next;
		my ($unread, $recent, $total) = $imap_server->status();

		if ($unread) {
			$unread_total += $unread;
			
			# Add this as a receiving address
			if(! $receiving_addresses eq "") {
				$receiving_addresses .= "\n"
			}
			$receiving_addresses .= $accounts[$i]{'address'} . ": ${unread} unread"
		}
	}

	if($unread_total) {
		notify($receiving_addresses, $unread_total);
	} else { 
		print("No new messages\n");
	}
	
	# Wait the time between syncs
	print("Sleeping\n");
	sleep(Kaiser::Config::get_synctime());
}

print("Quitting...\n");
