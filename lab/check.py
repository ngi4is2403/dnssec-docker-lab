import sys
import dns.flags
import dns.message
import dns.query
import dns.rcode
import dns.rdatatype

mode = sys.argv[1]
server = "172.30.53.10" if mode == "unsigned-wire" else "172.30.53.20"
query = dns.message.make_query("bank.lab.test.", "A", want_dnssec=True)
response = dns.query.udp(query, server, timeout=20)
print(response.to_text())
addresses = [r.address for rr in response.answer if rr.rdtype == dns.rdatatype.A for r in rr]
signed = any(rr.rdtype == dns.rdatatype.RRSIG for rr in response.answer)
if mode in ("baseline", "recovery"):
    assert response.rcode() == dns.rcode.NOERROR, "Expected NOERROR"
    assert addresses == ["192.0.2.10"], addresses
    assert response.flags & dns.flags.AD, "Missing AD"
    assert signed, "Missing RRSIG"
elif mode == "unsigned-wire":
    assert addresses == ["203.0.113.66"], addresses
    assert not signed, "Unsigned upstream unexpectedly signed"
elif mode == "blocked":
    assert response.rcode() == dns.rcode.SERVFAIL, "Expected validation failure"
    assert not response.answer, "Bogus data reached client"
    assert not response.flags & dns.flags.AD, "Unexpected AD"
else:
    raise ValueError(mode)
print("PASS " + mode)
