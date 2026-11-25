#!/bin/sh
set -eu
mkdir -p /run/named /var/cache/bind
if [ "$1" = authority ]; then
  mkdir -p /var/lib/lab/keys
  cd /var/lib/lab
  cat >db.lab.test <<'ZONE'
$TTL 300
@ IN SOA ns1.lab.test. admin.lab.test. ( 2026112501 300 120 604800 60 )
@ IN NS ns1.lab.test.
ns1 IN A 172.30.53.10
bank IN A 192.0.2.10
ZONE
  ksk=$(dnssec-keygen -q -K keys -a ECDSAP256SHA256 -n ZONE -f KSK lab.test)
  dnssec-keygen -q -K keys -a ECDSAP256SHA256 -n ZONE lab.test
  dnssec-signzone -n 1 -S -K keys -o lab.test -e +2592000 -f db.lab.test.signed db.lab.test
  python3 /lab/trust_anchor.py "keys/$ksk.key" /trust/anchor.conf
  cat >/etc/bind/named.conf <<'CONF'
options {
  directory "/var/lib/lab";
  listen-on { any; }; listen-on-v6 { none; };
  recursion no; allow-query { 127.0.0.1; 172.30.53.0/24; };
  dnssec-validation no; pid-file "/run/named/named.pid";
};
zone "lab.test" { type primary; file "db.lab.test.signed"; };
CONF
  named-checkconf
  named-checkzone lab.test db.lab.test.signed
  exec python3 /lab/authority.py
elif [ "$1" = resolver ]; then
  test -s /trust/anchor.conf
  rndc-confgen -a -c /etc/bind/rndc.key
  chown root:root /etc/bind/rndc.key
  chmod 600 /etc/bind/rndc.key
  cat >/etc/bind/named.conf <<'CONF'
include "/etc/bind/rndc.key";
options {
  directory "/var/cache/bind";
  listen-on { any; }; listen-on-v6 { none; };
  recursion yes; dnssec-validation yes;
  allow-query { 127.0.0.1; 172.30.53.0/24; };
  allow-recursion { 127.0.0.1; 172.30.53.0/24; };
  empty-zones-enable no;
  pid-file "/run/named/named.pid";
};
controls { inet 127.0.0.1 allow { 127.0.0.1; } keys { "rndc-key"; }; };
include "/trust/anchor.conf";
zone "lab.test" {
  type forward; forward only;
  forwarders { 172.30.53.10; };
};
logging {
  channel stderr_log { stderr; severity info; print-time yes; };
  category dnssec { stderr_log; };
};
CONF
  named-checkconf
  exec named -g -u root -n 1 -c /etc/bind/named.conf
else
  exec "$@"
fi
