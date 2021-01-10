# FlareDNS

*A macOS and Linux command line tool for dynamic updates of DNS using CloudFlare's API.* 

Written as a Swift learning exercise. A work in progress.

## Getting Started

### Configure FlareDNS

Set API token
```bash
$ FlareDNS configure auth add YQSn-xWAQiiEh9qM58wZNnyQS7FUdoqGIUAbrh7T
```

Add DNS records to be updated with an IPv4 address
```bash
$ FlareDNS configure records add test.com @ -r A --ttl 1 --proxied

Type      Name                     Zone                TTL       Priority       Proxied
A         test.com                 test.com            auto      0              true
```

```bash
$ FlareDNS configure records add test.com subdomain -r A --ttl 120 --proxied

Type      Name                     Zone                TTL       Priority       Proxied
A         subdomain.test.com       test.com            120       0              true
```

List added records
```bash
$ FlareDNS configure records list-all

Type      Name                     Zone                TTL       Priority       Proxied
A         subdomain.test.com       test.com            120       0              true
A         test.com                 test.com            auto      0              true
```

Check setup
```bash
$ FlareDNS configure check config

Starting checks
Done!
```

Start app
```bash
$ FlareDNS run

Starting FlareDNS
---
Record "test.com" was updated with IP 123.45.67.89
Record "subdomain.test.com" was updated with IP 123.45.67.89
---
```
