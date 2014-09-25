install:
	cpan install Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator
	mkdir /usr/local/etc/kaiser-gmail
	cp kaiser.perl /usr/local/etc/kaiser-gmail
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser

uninstall:
	rm /usr/local/bin/kaiser
	rm -r /usr/local/etc/kaiser-gmail
