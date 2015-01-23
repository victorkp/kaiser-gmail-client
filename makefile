install:
	cpan install Module::Build::Compat Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator List::MoreUtils Term::Bash::Completion::Generator Term::ANSIColor Net::IMAP::Simple Email::Simple HTML::Strip WWW::Google::Contacts Proc::ProcessTable IO::Prompt
	cd Proc-Daemon-0.03 && perl Makefile.PL && make && make test && make install
	mkdir /usr/local/etc/kaiser-gmail
	cp kaiser.perl /usr/local/etc/kaiser-gmail
	cp kaiser-fetch-daemon.perl /usr/local/etc/kaiser-gmail
	cp kaiser.service /etc/systemd/system/kaiser.service
	systemctl daemon-reload
	systemctl enable kaiser.service
	cp icon.png /usr/local/etc/kaiser-gmail/
	cp -r lib /usr/local/etc/kaiser-gmail/lib
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser
	cp kaiser-init.sh /etc/init.d/kaiser.sh
	chmod +x /etc/init.d/kaiser.sh

uninstall:
	rm -f /usr/local/bin/kaiser
	rm -rf /usr/local/etc/kaiser-gmail
	rm -f /etc/init.d/kaiser.sh
	rm -f /etc/systemd/system/kaiser.service
	systemctl disable kaiser.service

reinstall:
	cpan install Module::Build::Compat Crypt::Lite File::Slurp Email::Send Email::Send::Gmail Email::Simple::Creator List::MoreUtils Term::Bash::Completion::Generator Term::ANSIColor Net::IMAP::Simple Email::Simple HTML::Strip WWW::Google::Contacts IO::Prompt
	cd Proc-Daemon-0.03 && perl Makefile.PL && make && make test && make install
	rm -f /usr/local/etc/kaiser-gmail/kaiser.perl
	rm -rf /usr/local/etc/kaiser-gmail/lib
	cp kaiser.perl /usr/local/etc/kaiser-gmail/kaiser.perl
	cp kaiser-fetch-daemon.perl /usr/local/etc/kaiser-gmail
	cp kaiser.service /etc/systemd/system/kaiser.service
	systemctl daemon-reload
	systemctl enable kaiser.service
	cp icon.png /usr/local/etc/kaiser-gmail/
	cp -r lib /usr/local/etc/kaiser-gmail/lib
	chmod +x /usr/local/etc/kaiser-gmail/kaiser.perl 
	rm /usr/local/bin/kaiser
	ln -s /usr/local/etc/kaiser-gmail/kaiser.perl /usr/local/bin/kaiser
	cp kaiser-init.sh /etc/init.d/kaiser.sh
	chmod +x /etc/init.d/kaiser.sh
