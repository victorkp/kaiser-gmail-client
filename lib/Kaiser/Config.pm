package Kaiser::Config;
use strict;
use warnings;

use Exporter qw(import);
{
	no warnings 'qw';
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = ();
	@EXPORT_OK = qw(load_config, set_editor, get_editor);
}

my $DEFAULT_EDITOR = "vim";

my $config_file_path; # Config path
my $editor = $DEFAULT_EDITOR; # Config editor


# Parses a line in the config file
sub parse_config_line($) {
	my $line = $_[0];

	if($line =~ m/editor\s*:\s*(.+)\s*/) {
		# Set the editor
		$editor = $1;
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
	
	open(my $config_file, ">", $config_file_path) or die "Could not open config";
	print($config_file $config_text);
	close($config_file);
}


sub set_editor($) {
	my $input = $_[0];
	$editor = $input;
	write_config();
}

sub get_editor() {
	return $editor;
}

1;
