#!/usr/bin/perl
use strict;
use warnings;
use threads;
use Crypt::Lite;
use File::Slurp;
use Net::IMAP::Simple;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple;
use Email::Simple::Creator;
use HTML::Strip;
use Term::ANSIColor;
use List::MoreUtils qw(firstidx);

# Include Kaiser Modules
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(abs_path $0) . '/lib/';

use Kaiser::Config;
use Kaiser::Accounts;


my $HOME = $ENV{"HOME"};
my $PATH = "${HOME}/.kaiser";

# Make sure 'print' flushes 
BEGIN { $| = 1 }

# Arguments: string of message to show, then all the allowed responses
# returns index of chosen response in the response array
sub inputSelection {
	if(scalar(@_) < 2) {
		die "Invalid arguments in subroutine inputSelection()\n";
	}

	my ($message, @allowedInput) = @_;

	my $input = '';
	my $index = -1;

	while( $index < 0 ) {
		print "${message}";
		$input = <STDIN>;
		chomp($input);

		for(my $i = 0; $i < scalar(@allowedInput); $i++) {
			my $allowed = $allowedInput[$i];

			if($allowedInput[$i] eq $input) {
				return $input;
			}
		}
	}

	return -1;
}

# Prompts for an email address
sub inputEmailAddress() {
	my $input = <STDIN>;
	chomp($input);

	while($input !~ /^(\w|\-|\_|\.)+\@((\w|\-|\_)+\.)+[a-zA-Z]{2,}$/) {
		print "Invalid email address\nTry again: ";
		$input = <STDIN>;
		chomp($input);
	}

	return $input;
}

sub processInput {
	my $imapServer = $_[0];
	my $senderAddress = $_[1];
	my $senderPassword = $_[2];

	# Read the inbox file
	open(INBOX_FILE, "<${PATH}/${senderAddress}.txt") or die "Could not read from file system\n";

	my $messageNumber;
	while (my $line = <INBOX_FILE>) {
		chomp($line);
		if($line =~ /End of message \d+/) {
			$line =~ m/(\d+)/; # Extract message number
			$messageNumber = $1;

			my $shouldDelete = 0;
			my $shouldArchive = 0;

			# If the next line is not "-----Delete-this-email-----",
			# then delete this email
			$line = <INBOX_FILE>;
			chomp($line);

			if($line !~ /Delete/) {
				# Delete email $messageNumber
				$shouldDelete = 1;
			} else {
				# Advance in the possible actions
				$line = <INBOX_FILE>;
				chomp($line);
			}

			if($line !~ /Archive/) {
				# Archive email $messageNuber
				$shouldArchive = 1;
			} else {
				# Advance in the possible actions
				$line = <INBOX_FILE>;
				chomp($line);
			}

			if($line =~ /Reply/) {
				# Send a reply
				# First, read the reply response
				my $response = "";
				while($line = <INBOX_FILE>) {
					if($line =~ /---------------------------/) {
						last;
					} else {
						$response = $response . $line;
					}
				}

				# If the response is not blank, then do the reply send
				if($response !~ /^\s*$/) {
					# Get the email to know the sender / subject
					my $email= Email::Simple->new( join '', @{ $imapServer->get($messageNumber) } );
					my $subject = "Re: " . $email->header('Subject');
					my $recipient = $email->header('From');
					sendEmail($senderAddress, $senderPassword, $recipient, $subject, $response);
				}
			}

			if($shouldDelete) {
				print "Deleting message ${messageNumber}...\n";
				$imapServer->delete($messageNumber);
			} elsif ($shouldArchive) {
				print "Available server flags: " . join(", ", $imapServer->flags) . "\n";
				print "Archiving message ${messageNumber}...\n";
				$imapServer->add_flags($messageNumber, qw(\Deleted));
			}

		}
	}

}

# Shows emails, starting with those unread
sub showEmailList {
	my @accounts = Kaiser::Accounts::get_accounts();
	my $accountSelection = Kaiser::Accounts::pick_account();

	my $accountAddress = $accounts[$accountSelection]{'address'};
	my $accountPassword = $accounts[$accountSelection]{'password'};

	my $messagesToFetch = -1;
	if( scalar(@_) == 1) {
		$messagesToFetch = $_[0];
	}

	# Open connection to IMAP server
	print "Contacting server...\n";
	my $imapServer = Net::IMAP::Simple->new('imap.gmail.com', port=>993, use_ssl=>1) || die "Unable to connect to Gmail\n";
	$imapServer->login($accountAddress, $accountPassword) || die "Unable to login\n";
	print "\n";

	my $messageCount = $imapServer->select('INBOX');

	# Select the folder (use inbox for now)
	my ($unreadMessages, $recentMessages, $totalMessages) = $imapServer->status();

	my $inboxText = "";

	$inboxText = $inboxText . "There are ${unreadMessages} unread messages of ${totalMessages} in the inbox\n\n";

	if($messagesToFetch == 0) {
		$messagesToFetch = $unreadMessages;
	} elsif ($messagesToFetch < 0) {
		$messagesToFetch *= -1;
		$messagesToFetch += $unreadMessages;
	}

	#my @email_threads = ( );
	#my @emails = ( );
	#for(my $i = $messageCount; $i > $messageCount - $messagesToFetch && $i > 0; $i--){ 
	#	my $thread = threads->new( sub { 
	#		my $index = $i;
	#		my $email= Email::Simple->new( join '', @{ $imapServer->get($i) } );
	#		@emails[$index] = $email;
	#	});
	#	push(@email_threads, $thread);
	#}

	# Iterate through messages
	for(my $i = $messageCount; $i > $messageCount - $messagesToFetch && $i > 0; $i--){ 
		my $unread = 1;

		if($imapServer->seen($i)) {
			$unread = 0;
		}

		my $email= Email::Simple->new( join '', @{ $imapServer->get($i) } );

		my $htmlStripper = HTML::Strip->new();

		my $emailBody = $htmlStripper->parse( $email->body );

		if($unread) {
			$inboxText = $inboxText . "* ";
		} else {
			$inboxText = $inboxText . "* ";
		}

		$inboxText = $inboxText . $email->header('Subject');
		$inboxText = $inboxText . "\n  | " . $email->header('From');
		$inboxText = $inboxText . "\n  | " . $email->header('Date');
		$inboxText = $inboxText . "\n  | \n";

		foreach( split('\n|\r', $emailBody) ) {
			if( $_ =~ /[a-zA-Z]+ [a-zA-Z][a-zA-Z][a-zA-Z] \d+, \d+ \d+:\d+.+, ".+"\s+[a-zA-Z]+:/) {
				last;
			} elsif ( $_ !~ /^>.*$/ && $_ !~ /^\s*$/ ) {
				$inboxText = $inboxText .  "  |   " . $_ . "\n";
			}
		}

		$inboxText = $inboxText . "  | \n";
		$inboxText = $inboxText . "  |------------------------\n";
		$inboxText = $inboxText . "  | End of message ${i}\n";
		$inboxText = $inboxText . "-----Delete-this-email-----\n";
		$inboxText = $inboxText . "----Archive-this-email-----\n";
		$inboxText = $inboxText . "---Reply-below-this-line---\n\n\n";
		$inboxText = $inboxText . "---------------------------\n\n";
	}

	# Open a file, write the inbox text to it
	open(INBOX_FILE, ">${PATH}/${accountAddress}.txt") or die "Could not write to file system\n";
	print(INBOX_FILE $inboxText);
	close(INBOX_FILE);

	# Now open the file in the text editor
	system(Kaiser::Config::get_editor() . " ${PATH}/${accountAddress}.txt");

	# See if the user replied/deleted anything
	processInput($imapServer, $accountAddress, $accountPassword);

	# Remove once done
	system("rm ${PATH}/${accountAddress}.txt");
}

# Have the user select an account and compose an email
sub composeEmail( ) {
	my @accounts = Kaiser::Accounts::get_accounts();
	my $accountSelection = Kaiser::Accounts::pick_account();

	my $senderAddress = $accounts[$accountSelection]{'address'};
	my $senderPassword = $accounts[$accountSelection]{'password'};

	print "Send to: ";
	my $recipient = inputEmailAddress();

	print "Subject: ";
	my $subject = <STDIN>;
	chomp($subject);

	#### Compose the email
	system Kaiser::Config::get_editor() . " ${recipient}.txt";
	open(my $data, '<', "${recipient}.txt") or die "Cancelling...\n";
	
	# Read email text into a string
	my $emailBody = "";
	while (my $line = <$data>) {
	       $emailBody = "${emailBody}\n${line}";
	}


	### Ask what to do
	print "\n";
	my $action = inputSelection("[s]end, [d]iscard, or s[a]ve: ", "s", "d", "a");
	
	if($action eq 's') {
		# Send
		sendEmail($senderAddress, $senderPassword, $recipient, $subject, $emailBody);

		# Delete the email file after successful send
		system "rm -f ${recipient}.txt";
	} elsif ($action eq 'd') {
		# Discard
		system "rm -f ${recipient}.txt";
	} elsif ($action eq 'a') {
		# Save, nothing to do
		exit;
	}

	exit;
}

# Arguments: senderAddress, senderPassword, recierverAddress, subject, body
sub sendEmail {
	if(scalar(@_) != 5) {
		die "Invalid arguments in subroutine sendEmail\n";
	}

	my $senderAddress = $_[0];
	my $senderPassword = $_[1];
	my $receiverAddress= $_[2];
	my $emailSubject = $_[3];
	my $emailBody = $_[4];

	print("Sending email to ${receiverAddress}... ");

	my $email = Email::Simple->create(
		header => [
			From => "${senderAddress}",
			To => "${receiverAddress}",
			Subject => "${emailSubject}",
		],
		body => "${emailBody}",);

	my $sender = Email::Send->new(
		{ mailer => 'Gmail',
		  mailer_args => [ username => "${senderAddress}",
				   password => "${senderPassword}", ]
		});

	$sender->send($email) or die "\nError sending email to ${receiverAddress}\n";
	print("Sent\n");
}

sub print_usage() {
	print "Kaiser Usage: kaiser <read (number of messages to fetch) | compose | list-accounts | add-account | remove-account | config>\n";
}

sub print_config_usage() {
	print "Kaiser Config Usage: \n";
	print "\tkaiser config set-editor <EDITOR>\n";
	print "\tkaiser config set-read-messages <NUMBER TO READ, 0 FOR READ UNREAD>\n";
}



# Load the configuration file and accounts
Kaiser::Config::load_config($PATH);
Kaiser::Accounts::load_accounts($PATH);

if( scalar @ARGV == 0 ) {
	print_usage();
	exit;
}

if($ARGV[0] eq 'compose') {
	composeEmail( );
} elsif ($ARGV[0] eq 'add-account') {
	Kaiser::Accounts::add_account();
} elsif ($ARGV[0] eq 'remove-account') {
	Kaiser::Accounts::remove_account( );
} elsif ($ARGV[0] eq 'list-accounts') {
	Kaiser::Accounts::list_accounts();
} elsif ($ARGV[0] eq 'read') {
	if(scalar(@ARGV) == 2) {
		showEmailList($ARGV[1]);
	} elsif (scalar @ARGV == 1) {
		showEmailList(Kaiser::Config::get_read_messages() );
	} else {
		print_usage();
	}
} elsif ($ARGV[0] eq 'config') {
	if(scalar(@ARGV) != 3) {
		print_config_usage();
	} else {
		if($ARGV[1] eq 'set-editor') {
			Kaiser::Config::set_editor($ARGV[2]);
		} elsif ($ARGV[1] eq 'set-read-messages') {
			Kaiser::Config::set_read_messages($ARGV[2]);
		} else {
			print_config_usage();
		}
	}
} else {
	print_usage();
}

