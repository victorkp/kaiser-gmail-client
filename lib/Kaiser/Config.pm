package Kaiser::Config;
use File::Spec;
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

my $DEFAULT_EDITOR = "vi";
my $DEFAULT_READ_MESSAGES = -1;
my $DEFAULT_SYNC_TIME = 60 * 5; # Five minute sync time

my $config_file_path; # Config path
my $editor = $DEFAULT_EDITOR; # Config editor
my $read_messages = $DEFAULT_READ_MESSAGES;
my $sync_time = $DEFAULT_SYNC_TIME;


# Parses a line in the config file
sub parse_config_line($) {
	my $line = $_[0];

	if($line =~ m/editor\s*:\s*(.+)\s*/) {
		# Set the editor
		$editor = $1;
	} elsif ($line =~ m/read-messages\s*:\s*(.+)\s*/) {
		# Set the default messages to read
		$read_messages = $1;
	} elsif ($line =~ m/sync-time\s*:\s*(\d+)\s*/) {
		# Set the sync time
		$sync_time = $1;
	}
}

# Setup the config. Expect the 
# Kaiser data direcotry as an argument
sub load_config($) {
	$config_file_path = $_[0];
	$config_file_path .= "/config";


    if (! -e $config_file_path) {
        write_config();
    }
    
	open(CONFIG_FILE, "<${config_file_path}") or die "Could not open config\n";
	
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
	$config_text .= "sync-time : ${sync_time}\n";

    system "mkdir -p ${config_file_path}";
	open(my $config_file, ">", $config_file_path) or die "Could not open config\n";
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

# Set the time to sync (in milliseconds)
sub set_synctime($) {
	my $input = $_[0];
	$sync_time = $input;
	write_config();
}

# Return the number of milliseconds between syncs
sub get_synctime() {
	return $sync_time;
}

1;
