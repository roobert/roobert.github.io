---
layout:     post
title:      Mutt Stuff
date:       2014-11-25 21:15
type:       post
---

## Packages

{% highlight bash %}
apt-get install mutt-patched msmtp offlineimap
apt-get purge postfix
{% endhighlight bash %}

## `.offlineimaprc`

{% highlight bash %}
[general]
ui              = ttyui
accounts        = GMail
maxsyncaccounts = 5
maxconnections  = 10

[mbnames]
enabled  = yes
filename = ~/.mutt/mailboxes
header   = "mailboxes "
peritem  = ="%(foldername)s"
sep      = " "
footer   = "\n"

[Account GMail]
localrepository  = GMailLocal
remoterepository = GMailRemote
autorefresh      = 2

[Repository GMailLocal]
type = Maildir
localfolders = ~/Mail/Gmail
nametrans = lambda folder: {'sent':    '[Gmail]/Sent Mail',
                            'flagged': '[Gmail]/Starred',
                            'drafts':  '[Gmail]/Drafts',
                            'bin':     '[Gmail]/Bin',
                            'archive': '[Gmail]/All Mail',
                           }.get(folder, folder)

[Repository GMailRemote]
type               = Gmail
realdelete         = no
remoteuser         = x@gmail.com
remotepass         = x
holdconnectionopen = true
keepalive          = 60
timeout            = 120
sslcacertfile      = /etc/ssl/certs/ca-certificates.crt

nametrans = lambda folder: {'[Gmail]/Sent Mail': 'sent',
                            '[Gmail]/Drafts':    'drafts',
                            '[Gmail]/Starred':   'flagged',
                            '[Gmail]/Bin':       'bin',
                            '[Gmail]/All Mail':  'archive',
                           }.get(folder, folder)

folderfilter = lambda foldername: foldername not in ['[Gmail]/Spam',
                                                     '[Gmail]/All Mail',
                                                     '[Gmail]/Chats',
                                                     '[Gmail]/Starred',
                                                     '[Gmail]/Important',
                                                     'Notes'
                                                    ]
{% endhighlight bash %}

## `.msmtprc`

{% highlight bash %}
account default
host smtp.gmail.com
user x@gmail.com
password x
auth
auto_from off
from x@gmail.com
logfile ~/.msmtp.log
tls on
tls_starttls on
tls_fingerprint E7:48:1D:0B:99:4A:C3:A8:31:86:E5:8F:E5:EE:4F:2A
{% endhighlight bash %}

To clarify tls fingerprint:
{% highlight bash %}
echo -n | openssl s_client -connect smtp.gmail.com:587 -starttls smtp -showcerts |
  | openssl x509 -noout -fingerprint -md5
{% endhighlight bash %}

## Mutt

## `.mailcap`

{% highlight bash %}
text/html; w3m -I %{charset} -T text/html; copiousoutput;
{% endhighlight bash %}

### muttrc / muttrc-work / sidebar

...

## `.netrc`

For goobook
{% highlight bash %}
machine google.com
      login x@gmail.com
      password x
{% endhighlight bash %}

## LDap Address book

## GPG

### `.gnupg/gpg.conf`

{% highlight bash %}
personal-digest-preferences SHA512
cert-digest-algo SHA512
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
personal-cipher-preferences TWOFISH CAMELLIA256 AES 3DES
{% endhighlight bash %}

{% highlight bash %}
gpg --gen-key
gpg  --keyserver pgp.mit.edu --send-keys <id>
gpg --armor --output public.key --export <email>
gpg --keyserver pgp.mit.edu --search <search>
{% endhighlight bash %}
