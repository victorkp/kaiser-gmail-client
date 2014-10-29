package Kaiser::Config;
use strict;
use warnings;

# Config File Options
# editor: <editor>
# read-messages <number of messages to read, < 1 for unread messages>
#

use Exporter qw(import);
{
	no warnings 'qw';
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = ();
	@EXPORT_OK = qw(load_config, set_editor, get_editor, get_read_messages, set_read_messages);
}

my $DEFAULT_EDITOR = "vim";
my $DEFAULT_READ_MESSAGES = -1;

my $config_file_path; # Config path
my $editor = $DEFAULT_EDITOR; # Config editor
my $read_messages = $DEFAULT_READ_MESSAGES;


# Parses a line in the config file
sub parse_config_line($) {
	my $line = $_[0];

	if($line =~ m/editor\s*:\s*(.+)\s*/) {
		# Set the editor
		$editor = $1;
	} elsif ($line =~ m/read-messages\s*:\s*(.+)\s*/) {
		# Set the default messages to read
		$read_messages = $1;
	}
}

# Setup the config. Expect the 
# Kaiser data direcotry as an argument
sub load_config($) {
	$config_file_path = $_[0];
	$config_file_path .= "/config";

	system "touch ${config_file_path}";
	open(CONFIG_FILE, "<${config_file_path}") or die "Could not open config";
	
	while(my $line = <CONFIG_FILE>) {
		chomp($line);
		parse_config_line($line);
	}

	close(CONFIG_FILE);
}

# Write the configuration
# to the config file - for use
# when updating or saving configs
sub write_config() {
	# Create the config text to write
	my $config_text = "";
	$config_text .= "editor : ${editor}\n";
	$config_text .= "read-messages : ${read_messages}\n";
	
	open(my $config_file, ">", $config_file_path) or die "Could not open config";
	print($config_file $config_text);
	close($config_file);
}

# Set the default editor
sub set_editor($) {
	my $input = $_[0];
	$editor = $input;
	write_config();
}

# Get the default editor
sub get_editor() {
	return $editor;
}

# Set the default number of messages to read
sub set_read_messages($) {
	my $input = $_[0];
	$read_messages = $input;
	write_config();
}

# Return the default number of messages to read
# <= 0 for read all unread messages
sub get_read_messages() {
	return $read_messages;
}

1;
