#!/usr/bin/perl
use strict;
use warnings;
use Crypt::Lite;
use File::Slurp;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;

my $PATH = '/usr/local/share/etc/kaiser-gmail';

sub addAccount( ) {
	print("Adding a Gmail Account\n");

	print("Email address: ");
	my $address = <STDIN>;
	chomp($address);

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
sub getAccounts() {
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
sub listAccounts() {
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

sub removeAccount( ) {

}

# Have the user select an account and send an email
sub sendEmail( ) {
	my @accounts = getAccounts();
	my $accountSelection = pickAccount();

	my $senderAddress = $accounts[$accountSelection]{'address'};
	my $senderPassword = $accounts[$accountSelection]{'password'};

	print "Send to: ";
	my $recipient = <STDIN>;
	chomp($recipient);

	print "Subject: ";
	my $subject = <STDIN>;
	chomp($subject);

	#### Compose the email
	system "rm -f email.txt";
	system "vim email.txt";
	open(my $data, '<', 'email.txt') or die "Cancelling...\n";
	
	# Read email text into a string
	my $emailBody = "";
	while (my $line = <$data>) {
	       $emailBody = "${emailBody}\n${line}";
	}

	# Delete the email file
	system "rm -f email.txt";

	#### Send the email
	print("Sending email to ${recipient}... ");

	my $email = Email::Simple->create(
		header => [
			From => "${senderAddress}",
			To => "${recipient}",
			Subject => "${subject}",
		],
		body => "${emailBody}",);

	my $sender = Email::Send->new(
		{ mailer => 'Gmail',
		  mailer_args => [ username => "${senderAddress}",
				   password => "${senderPassword}", ]
		});

	$sender->send($email) or die "\nError sending email to ${recipient}\n";

	# Delete the email file after successful send
	system "rm -f email.txt";

	print("Sent\n");
	exit;
}

# Find out which command is wanted
if( scalar @ARGV != 1 ) {
	# Wrong number of arguments
	print "Usage:\nkaiser <send | list-accounts | add-account | remove-account>\n";
	exit;
}

if($ARGV[0] eq 'send') {
	sendEmail( );
} elsif ($ARGV[0] eq 'add-account') {
	addAccount( );
} elsif ($ARGV[0] eq 'remove-account') {
	removeAccount( );
} elsif ($ARGV[0] eq 'list-accounts') {
	listAccounts();
}

