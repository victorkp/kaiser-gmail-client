## Kaiser Gmail Client ##
An extremely simple, command-line client for Gmail written in Perl.

## Installation and Uninstallation ##
Run `make install` or `make uninstall` with elevated privileges in order to install.

## Usage ##
kaiser \<compose \| read \<optional number of emails to show\> \| add-account \| remove-account \| list-accounts \| config\>

## Reading, Replying, and Deleting Mail ##
Use `kaiser read`  to display all unread emails you have, or use `kaiser read XXX` where `XXX` is the number of messages to show.

When reading email, everything is displayed as plain text and opened in the text editor of your choice (default editor is vi; use `kaiser config` to change editors). Replying and deleting mail involves editing this text file. Once you've made your edits, make sure to save and close the file in order to have your replies and deletes propagated.

![kaiser read Screenshot](screenshots/read.png)
The above screenshot is a sample output of `kaiser read`.

### Replying ###
Simply type your reply between the `Reply-below-this-line` and the `-----` separator lines. When the file is saved and closed, the reply will be sent.

### Deleting ###
Delete the `Delete-this-line` immediately below the email you wish to delete. When the file is saved and closed, the email will be deleted.

## Config ##
Kaiser is quite customizeable. By default, the vi editor is used to read and write emails, however you can tell Kaiser to use whatever editor you prefer.

Use `kaiser config` and then one of the following commands to change functionality of Kaiser.
### set-editor ###
Use `kaiser config set-editor \<EDITOR\>` to change the text editor that Kaiser will invoke when reading and writing emails. You can use a terminal-based or a GUI editor - as long as it can write text files, it'll work.
Example: `kaiser config set-editor vim` or `kaiser config set-editor gedit`.
