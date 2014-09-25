install:
	cpan install Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator
	mkdir /usr/local/etc/perl-gmail 
	cp email.perl /usr/local/etc/perl-gmail
	chmod +x /usr/local/etc/perl-gmail/email.perl 
	ln -s /usr/local/etc/perl-gmail/email.perl /usr/local/bin/email

uninstall:
	rm /usr/local/bin/email
	rm -r /usr/local/etc/perl-gmail
