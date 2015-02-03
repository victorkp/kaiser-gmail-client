package Kaiser::Accounts;

use strict;
use warnings;
use Term::ReadKey;
use Crypt::Lite;
use File::Slurp;
use IO::Prompt;


use Exporter qw(import);
{
	no warnings 'qw';
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = ();
	@EXPORT_OK = qw(load_accounts, get_accounts, pick_account, add_account, remove_account);
}

my $accounts_folder_path; # Config path


# Setup the config. Expect the 
# Kaiser data direcotry as an argument
sub load_accounts($) {
	$accounts_folder_path = $_[0];
	$accounts_folder_path .= "/accounts";
}

sub add_account( ) {
	print "Enter email address: ";
	my $address = <STDIN>;
	chomp($address);

	if($address !~ /.+@.+\..+/) {
		print "Email address doesn't look right\n";
		die "\n";
	}

	print "Enter password: ";
	ReadMode('noecho'); # hide password
	my $password = <STDIN>;
	chomp($password);
	ReadMode(0); # back to normal text entry

	print "\n";

	if(length($password) < 1) {
		print "Password cannot be blank";
		die "\n";
	}

	system "mkdir -p $accounts_folder_path";

	# Encrypt password
	my $crypt = Crypt::Lite->new(debug=>0);
	$password = $crypt->encrypt($password, $address);

	# Write account file
	open(ACCOUNT, ">$accounts_folder_path/$address") or die "Could not write account file\n";
	print ACCOUNT "$password";
	close(ACCOUNT);

	print "Added accoung $address\n";
}

# Return array of hashes with 'address' and 'password'
sub get_accounts( ) {
	opendir(my $accountDir, $accounts_folder_path) or die "No accounts. Add one with 'add-account'\n";
	my @accountFiles = readdir($accountDir);

	my @accounts = ();

	foreach(@accountFiles) {
		if($_ eq '.' || $_ eq '..') {
			next;
		}

		my $address = $_;

		open(my $file, '<', "${accounts_folder_path}/${address}") or die "Could not open account file\n";

		my $password = read_file($file);

		# Decrypt the password
		my $crypt = Crypt::Lite->new(debug=>0);
		$password = $crypt->decrypt($password, $address);

		push @accounts, { address=>$address, password=>$password };

		close($file);
	}

	closedir($accountDir);

	if(scalar(@accounts) == 0) {
		die "No accounts. Add one with 'add-account'\n";
	}

	return @accounts;
}

# Argument is whether or not to also print numbers with accounts
sub list_accounts {
	my $showNumbers = 1;

	if(scalar(@_) > 0) {
		$showNumbers = $_[0];
	}

	my @accounts = get_accounts();

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
sub pick_account( ) {
	my @accounts = get_accounts();

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
	list_accounts();

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
sub remove_account( ) {
	my @accounts = get_accounts();
	my $accountSelection = pick_account();

	my $accountToRemove = $accounts[$accountSelection]{'address'};

	# Remove the account file
	system "rm ${accounts_folder_path}/${accountToRemove}";

	exit;
}



1;
