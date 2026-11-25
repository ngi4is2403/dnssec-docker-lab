import sys
import dns.rdata
import dns.rdataclass
import dns.rdatatype
with open(sys.argv[1]) as source:
    record = " ".join(line for line in source if not line.lstrip().startswith(";"))
ksk = dns.rdata.from_text(dns.rdataclass.IN, dns.rdatatype.DNSKEY, record.split("DNSKEY", 1)[1])
assert ksk.flags == 257
with open(sys.argv[2] + ".tmp", "w") as f:
    f.write('trust-anchors { "lab.test." static-key 257 3 13 "' + "".join(ksk.to_text().split()[3:]) + '"; };\n')
import os
os.replace(sys.argv[2] + ".tmp", sys.argv[2])
