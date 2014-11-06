install:
	cpan install Module::Build::Compat Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator List::MoreUtils Term::Bash::Completion::Generator Term::ANSIColor Net::IMAP::Simple Email::Simple HTML::Strip WWW::Google::Contacts Proc::Daemon IO::Prompt
	mkdir /usr/local/etc/kaiser-gmail
	cp kaiser.perl /usr/local/etc/kaiser-gmail
	cp -r lib /usr/local/etc/kaiser-gmail/lib
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser

uninstall:
	rm /usr/local/bin/kaiser
	rm -r /usr/local/etc/kaiser-gmail

reinstall:
	cpan install Module::Build::Compat Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator List::MoreUtils Term::Bash::Completion::Generator Term::ANSIColor Net::IMAP::Simple Email::Simple HTML::Strip WWW::Google::Contacts Proc::Daemon IO::Prompt
	rm -f /usr/local/etc/kaiser-gmail/kaiser.perl
	rm -rf /usr/local/etc/kaiser-gmail/lib
	cp kaiser.perl /usr/local/etc/kaiser-gmail/kaiser.perl
	cp -r lib /usr/local/etc/kaiser-gmail/lib
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	rm /usr/local/bin/kaiser
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser
