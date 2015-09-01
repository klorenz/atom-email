Email package
=============

This package is intended to become a full featured fuzzy-search based email client,
using the texteditor you love.

What it supports for now
------------------------

- Email configuration file
- Open mailbox specified in [mailtool configuration](https://www.npmjs.com/package/mailtool)
- browse mails (no changes of flags or else possible yet)
- only INBOX browseable

Configuration
-------------

(Email: Open Your Email Configuration).  There is opened a sample, if you open it
the first time.  Email Configuration is a CSON file, which contains an object
of accounts, with a descriptive name as key.

Each account can have following fields:

- **transport**, See https://www.npmjs.com/package:/nodemailer-smtp-transport
- **default**, Prefill this with options from
  https://www.npmjs.com/package/nodemailer#e-mail-message-fields.  Additionally
  you can use **signature** for passing a signature.


How to Use
----------

Create a file and write something like:

```
to: kiwi@franka.dyndns.org
subject: Great Package :)

Hey Kiwi,

this is sent from the brand new mailer for atom.

Regards
```

Select it and then run "Email: Send Mail" command.

Or select some text and run "Email: Send Mail" command.  There will be opened input dialogs for
entering Subject, to address and other.  Confirm with `Enter`, cancel with `ESC`.


Motivation
----------

I work with some pretty big IMAP mail folders and our company's mail repository is just huge, at least for Thunderbird.
It becomes slow.  I tried some other mailers, but everyone is merely the same.  At some point it becomes slow.



Ideas
-----

- Send selection as email.
- Write a file and instead of save send it as mail.
- Create new email as .eml file

For all of this there is needed a configuration of mail account.

You can configure a mail account in a single URL:

imap://user:passwd@imap.host.com:123/

- this implies use of STARTTLS if STARTTLS is part of CAPABILITY
  features.  See https://tools.ietf.org/html/rfc5092

imaps://user:passwd@imap.host.com:993/

- install opener for imap URI like above
  - imaps://user:passwd@imap.host.com:993/ (no sendmail connected, or system default taken)
  - apart from this you can also open mailtool://<configname>, which opens
    imap corresponding to that config.

  - imaps://user:password@imap.host.com:993/ is an alias for opening inbox

  - mailtool://<configname>/path/to/imap/folder opens a folder Editor (view).
  - mailtool://<configname>/path/to/imap/folder/<uid> opens a mail in emailView

  - /path/to/file.eml opens a file from disk

- command for selecting a folder attached to a imap-mailbox-controller


- Have a bottom panel, which is a "docked" listview, containing mails in current folder.
  - there is a subcommand opening a folderSelectView, which does select a folder to be opened in such a docked
    listview.
