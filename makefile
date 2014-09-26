install:
	cpan install Module::Build::Compat Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator List::MoreUtils Term::Bash::Completion::Generator Term::ANSIColor Net::IMAP::Simple Email::Simple
	mkdir /usr/local/etc/kaiser-gmail
	cp kaiser.perl /usr/local/etc/kaiser-gmail
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser

uninstall:
	rm /usr/local/bin/kaiser
	rm -r /usr/local/etc/kaiser-gmail

reinstall:
	rm /usr/local/etc/kaiser-gmail/kaiser.perl
	cp kaiser.perl /usr/local/etc/kaiser-gmail
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	rm /usr/local/bin/kaiser
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser
