---
layout:     post
title:      LetsEncrypt NGiNX Quick Start
date:       2015-12-06 14:52
type:       post
draft: true
---

[NGiNX support](http://letsencrypt.readthedocs.org/en/latest/using.html#nginx) for the [Lets Encrypt](https://letsencrypt.org/) `letsencrypt-auto` tool is not yet stable, here are some instrucions on how to get up and running with LetsEncrypt when using NGiNX.

### NGiNX Static Content Server Config

Start a web server with a config like:

```
server {
    listen      80;
    server_name www.dust.cx dust.cx;
    location / { root /var/www/dust.cx; autoindex on;  }
}
```

### Certificate Request

Request certificate:

```bash
git clone https://github.com/letsencrypt/letsencrypt ~/git/letsencrypt 
~/git/letsencrypt/letsencrypt-auto certonly --webroot -w /var/www/dust.cx -d dust.cx -d www.dust.cx
```


### NGiNX Config

Update NGiNX config to redirect all HTTP traffic to HTTPS, and specify cert file paths:

```bash
server {
    listen      80;
    server_name www.dust.cx dust.cx;
    rewrite     ^https://$server_name$request_uri? permanent;
}

server {
    listen 443;
    server_name www.dust.cx dust.cx;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/dust.cx/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dust.cx/privkey.pem;

    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";

    location / { root /var/www/dust.cx; autoindex on; }
}
```

Reload NGiNX:

```
service nginx reload
```

### Test

```
$ echo -n | openssl s_client -connect dust.cx:443
CONNECTED(00000003)
depth=2 O = Digital Signature Trust Co., CN = DST Root CA X3
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X1
verify return:1
depth=0 CN = dust.cx
verify return:1
---
Certificate chain
 0 s:/CN=dust.cx
   i:/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X1
 1 s:/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X1
   i:/O=Digital Signature Trust Co./CN=DST Root CA X3
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIE/zCCA+egAwIBAgISAdtFUuyTk5UZoVzFVVnVT25zMA0GCSqGSIb3DQEBCwUA
MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMTAeFw0xNTEyMDYxMTQ0MDBaFw0x
NjAzMDUxMTQ0MDBaMBIxEDAOBgNVBAMTB2R1c3QuY3gwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDG+5xpMLdKinooEM4+ocZgtYAa+GaKc/RhbhuZLAh6
xYHy1/vLutqBlifuv6qXAtAYrM/xk3+zW7KrCXv3iz7ZYKh5mMKPV5hn+M8fIfqo
NHg9t75BlgeP6M/EG4td+hXWS9jYFJ7o82SIDX8zhDlEs/g3bQIE/+DuYWSC5WYu
PbJ1kUkOfGs7HQPwTPt7d2QafiEoy0sszgfPPPsYiEuOddgtsrKE+F9LuDdbT+Ze
V3TVK6nzdw7Km+i68xBTFk7m9+3guYBAf1yB4yROxNNOReBahqh3aFMjo4zZ3cYj
/U+MpOExTbT7ECO/mXkhCBzjK2I/k2bGqOhWcBOATvNlAgMBAAGjggIVMIICETAO
BgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwG
A1UdEwEB/wQCMAAwHQYDVR0OBBYEFG7T/aH/BX76cSQou6icQD/fs5ZxMB8GA1Ud
IwQYMBaAFKhKamMEfd265tE5t6ZFZe/zqOyhMHAGCCsGAQUFBwEBBGQwYjAvBggr
BgEFBQcwAYYjaHR0cDovL29jc3AuaW50LXgxLmxldHNlbmNyeXB0Lm9yZy8wLwYI
KwYBBQUHMAKGI2h0dHA6Ly9jZXJ0LmludC14MS5sZXRzZW5jcnlwdC5vcmcvMB8G
A1UdEQQYMBaCB2R1c3QuY3iCC3d3dy5kdXN0LmN4MIH+BgNVHSAEgfYwgfMwCAYG
Z4EMAQIBMIHmBgsrBgEEAYLfEwEBATCB1jAmBggrBgEFBQcCARYaaHR0cDovL2Nw
cy5sZXRzZW5jcnlwdC5vcmcwgasGCCsGAQUFBwICMIGeDIGbVGhpcyBDZXJ0aWZp
Y2F0ZSBtYXkgb25seSBiZSByZWxpZWQgdXBvbiBieSBSZWx5aW5nIFBhcnRpZXMg
YW5kIG9ubHkgaW4gYWNjb3JkYW5jZSB3aXRoIHRoZSBDZXJ0aWZpY2F0ZSBQb2xp
Y3kgZm91bmQgYXQgaHR0cHM6Ly9sZXRzZW5jcnlwdC5vcmcvcmVwb3NpdG9yeS8w
DQYJKoZIhvcNAQELBQADggEBADRzDUqJGXwVCAZTch9C3pLVbahmJ3vu3Iz1niXo
eMWceM3hEMUXtDAWIJbnmbDG9X37MI58+L9mHmD593cE7b7y1u0PtRta0X3QMYzd
CemUZD5RkII3KZuz1CYbccbdE/oL8xkAXwNxlNS6qHkdoS0xPRm3COX5DDJgIR0t
OjOthLu/XXPkdm7sA3mtxdhGGvAbNKvBNZiHOBdYR2IkxaIl6ONl5vpa/0pPAJ0p
u0I86Fpu3EwVH5dsK+jk3EXn/Zhv15EDc6mwJ0GSRGYtn83+SM3kAILmkcLxhflx
XZYHrONeYLkPhDUJGnCxObPHbSVauVvdUgW1HnfAdph1+dE=
-----END CERTIFICATE-----
subject=/CN=dust.cx
issuer=/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X1
---
No client certificate CA names sent
Peer signing digest: SHA512
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3157 bytes and written 441 bytes
---
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES256-GCM-SHA384
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES256-GCM-SHA384
    Session-ID: CAB0B56296FF95BA74ADC40876E78EBAA4B3949FDFC145B0DFCDAB3A5C69B588
    Session-ID-ctx: 
    Master-Key: D04421C7E3BDE901845C4F418601B8118A7F7CAACA1C18B1CC8E0F02687DDFB5AF39A7ED213294C833BBC9BFE850C1A8
    Key-Arg   : None
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - 9e d2 78 c0 fd e2 03 e9-c6 ec 39 ad 55 3a 14 df   ..x.......9.U:..
    0010 - 2c 93 0a c4 13 30 af 73-9c 64 04 9d 18 e8 c1 21   ,....0.s.d.....!
    0020 - de 48 31 c9 02 53 17 38-2a a5 b4 04 4f 68 38 e9   .H1..S.8*...Oh8.
    0030 - 08 45 ec b4 ec 45 38 a5-7b 5d d9 d8 e8 40 02 f2   .E...E8.{]...@..
    0040 - 1b 39 92 b5 08 bc e0 f0-2a 81 a6 85 66 76 20 86   .9......*...fv .
    0050 - 80 52 5c 58 90 21 da 3f-e9 9c d0 81 d1 f6 ba dc   .R\X.!.?........
    0060 - 8e 4f 11 b3 d2 51 ed 0f-ff 6d f6 06 00 d6 ec 6e   .O...Q...m.....n
    0070 - 00 b5 9d ec b9 7d b0 5f-1c 3c b2 fa 6c 1d 89 c5   .....}._.<..l...
    0080 - 84 3d 69 98 28 de df c1-24 23 cf c3 fd c4 81 90   .=i.(...$#......
    0090 - c7 16 b2 ed 8d f7 49 32-37 32 04 9b 42 e1 08 3f   ......I272..B..?
    00a0 - e5 43 f8 4d 55 23 e2 19-b4 ad f2 80 c4 9d 12 b9   .C.MU#..........

    Start Time: 1449413126
    Timeout   : 300 (sec)
    Verify return code: 0 (ok)
---
DONE
```

