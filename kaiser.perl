#!/usr/bin/perl
use strict;
use warnings;
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

my $HOME = $ENV{"HOME"};
my $PATH = "${HOME}/.kaiser";

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

sub addAccount( ) {
	print("Adding a Gmail Account\n");

	print("Email address: ");
	my $address = inputEmailAddress();

	print("Password: ");
	my $password = <STDIN>;
	chomp($password);

	# Make the accounts folder if it does not already exist
	system "mkdir -p ${PATH}/accounts";

	# Encrypt and write to file 
	my $crypt = Crypt::Lite->new(debug=>0);
	$password = $crypt->encrypt($password, $address);

	system "echo \"${password}\" >> ${PATH}/accounts/${address}";

	exit;
}

# Return array of hashes with 'address' and 'password'
sub getAccounts( ) {
	opendir(my $accountDir, "${PATH}/accounts/") or die "No accounts. Add one with 'add-account'\n";
	my @accountFiles = readdir($accountDir);

	my @accounts = ();

	foreach(@accountFiles) {
		if($_ eq '.' || $_ eq '..') {
			next;
		}

		my $address = $_;

		open(my $file, '<', "$PATH/accounts/${address}") or die "Could not open account file\n";

		my $password = read_file($file);

		# Decrypt the password
		my $crypt = Crypt::Lite->new(debug=>0);
		$password = $crypt->decrypt($password, $address);

		push @accounts, { address=>$address, password=>$password };

		close($file);
	}

	closedir($accountDir);

	return @accounts;
}

# Argument is whether or not to also print numbers with accounts
sub listAccounts( ) {
	my $showNumbers = 1;

	if(scalar(@_) > 0) {
		$showNumbers = $_[0];
	}

	my @accounts = getAccounts();

	for(my $i = 0; $i < scalar(@accounts); $i++) {
		my $address = $accounts[$i]{'address'};
		my $password = $accounts[$i]{'password'};

		if($showNumbers) {
			print "${i}: ${address}\n";
		} else {
			print "${address}\n";
		}
	}
}

# Returns a reference to a  %account
sub pickAccount( ) {
	my @accounts = getAccounts();

	# If there are no accounts, exit
	if(scalar(@accounts) == 0) {
		print "There are no accounts. Add one with 'add-account'";
		exit;
	}

	# If there is only one account, return it
	if(scalar(@accounts) == 1){
		return 0;
	}

	# Otherwise we need to pick an account
	listAccounts();

	my $selection = -1;
	while($selection < 0 || $selection >= scalar(@accounts)) {
		# While the selection is invalid
		print "Enter number of account: ";
		$selection = <STDIN>;
		chomp($selection);
	}

	return $selection;
}

# Let the user pick an account to delete
sub removeAccount( ) {
	my @accounts = getAccounts();
	my $accountSelection = pickAccount();

	my $accountToRemove = $accounts[$accountSelection]{'address'};

	# Remove the account file
	system "rm ${PATH}/accounts/${accountToRemove}";

	exit;
}

# Shows emails, starting with those unread
sub showEmailList {
	my @accounts = getAccounts();
	my $accountSelection = pickAccount();

	my $accountAddress = $accounts[$accountSelection]{'address'};
	my $accountPassword = $accounts[$accountSelection]{'password'};

	my $messagesToFetch = 20;
	if( scalar(@_) == 1) {
		$messagesToFetch = $_[0];
	}

	# Open connection to IMAP server
	print "Contacting server...";
	my $imapServer = Net::IMAP::Simple->new('imap.gmail.com', port=>993, use_ssl=>1) || die "Unable to connect to Gmail\n";
	$imapServer->login($accountAddress, $accountPassword) || die "Unable to login\n";
	print "\n";

	my $messageCount = $imapServer->select('INBOX');

	# Select the folder (use inbox for now)
	my ($unreadMessages, $recentMessages, $totalMessages) = $imapServer->status();

	print "There are ${unreadMessages} unread messages of ${recentMessages} recent messages. There are ${totalMessages} in the inbox\n\n";

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
			print color("bold red"), "* ", color("reset");
		} else {
			print "  ";
		}

		print color("bold white"), $email->header('Subject');
		print color("bold white"), "\n  | " . $email->header('From');
		print color("bold white"), "\n  | " . $email->header('Date'), color("reset");

		foreach( split('\n|\r', $emailBody) ) {
			
			print color("bold white"), "  |   ", color("reset");
		       	print $_ . "\n";
		}

		print color("bold white"), "  |------------------------", color("reset");

		print "\n\n";
	}

}

# Have the user select an account and compose an email
sub composeEmail( ) {
	my @accounts = getAccounts();
	my $accountSelection = pickAccount();

	my $senderAddress = $accounts[$accountSelection]{'address'};
	my $senderPassword = $accounts[$accountSelection]{'password'};

	print "Send to: ";
	my $recipient = inputEmailAddress();

	print "Subject: ";
	my $subject = <STDIN>;
	chomp($subject);

	#### Compose the email
	system "vim ${recipient}.txt";
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

# Find out which command is wanted, allow two arguments for 'read'
if( scalar @ARGV != 1 && !(scalar @ARGV == 2 && $ARGV[0] eq 'read')) {
	# Wrong number of arguments
	print "Usage:\nkaiser <read (number of messages to fetch) | compose | list-accounts | add-account | remove-account>\n";
	exit;
}

if($ARGV[0] eq 'compose') {
	composeEmail( );
} elsif ($ARGV[0] eq 'add-account') {
	addAccount( );
} elsif ($ARGV[0] eq 'remove-account') {
	removeAccount( );
} elsif ($ARGV[0] eq 'list-accounts') {
	listAccounts();
} elsif ($ARGV[0] eq 'read') {
	if(scalar(@ARGV) == 2) {
		showEmailList($ARGV[1]);
	} else {
		showEmailList( );
	}
} else {
	print "Usage:\nkaiser <compose | list-accounts | add-account | remove-account>\n";
}

