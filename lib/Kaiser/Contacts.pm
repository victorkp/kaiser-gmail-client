package Kaiser::Contacts;

use strict;
use warnings;

use WWW::Google::Contacts;

use Exporter qw(import);
{
	no warnings 'qw';
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = ();
	@EXPORT_OK = qw(load_contacts, get_contact, search_for_contact);
}

my $contacts_loaded
my $contacts_google;
my @contacts;

# Load the contacts from Gmail
sub load_contacts($$) {
	if( ! $contacts_loaded ) {
		# Contacts have not been loaded yet
		my $username = $_[0];
		my $password = $_[1];

		$contacts_google = WWW::Google::Contacts->new(
							username->$username,
							password->$password,
							protocol->"https"
						) or die "Could not get contacts\n";

		my $contact_list = $contacts_google->contacts;

		while( my $contact = $contact_list->next ) {
			my $contact_hash = ();
			$contact_hash->{"name"} = contact->full_name;

			if($contact->email->exists) {
				$contact_hash->{"email"} = contact->email;
			} else {
				$contact_hash->{"email"} = "";
			}

			push(@contacts, $contact_hash);
		}
	}

	print_contacts();
}

sub print_contacts() {
	$contacts_loaded or die "Contacts not loaded\n";

	foreach (@contacts) {
		my $name = $_->{"name"};
		my $email = $_->{"email"};
		print "Name: ${name}, email: ${email}\n";
	}
}

# Search for, and return the best match contact
sub search_for_contact($) {
	my $search = $_[0];

	my @matches;

	foreach(@contacts) {
		if($_->{"name"} =~ m/$search/ || $_->{"email"} =~ m/$search/) {
			push(@matches, $_);
		}
	}

	return @matches;
}



1;
