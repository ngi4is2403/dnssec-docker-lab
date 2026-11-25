"""Controlled unsigned upstream; no sniffing or traffic targeting outside this lab."""
import socket
import dns.edns
import dns.flags
import dns.message
import dns.rdatatype
import dns.rrset

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 53))
while True:
    wire, peer = sock.recvfrom(65535)
    if peer[0] != "172.30.53.20":
        continue
    try:
        query = dns.message.from_wire(wire)
        response = dns.message.make_response(query)
        response.flags |= dns.flags.AA
        # Echo the EDNS client/server cookie used by this transaction.
        cookies = [o for o in query.options if o.otype == dns.edns.OptionType.COOKIE]
        response.use_edns(edns=query.edns, payload=1232, options=cookies)
        question = query.question[0]
        if question.name.to_text() == "bank.lab.test." and question.rdtype == dns.rdatatype.A:
            response.answer.append(dns.rrset.from_text("bank.lab.test.", 60, "IN", "A", "203.0.113.66"))
            print(f"UNSIGNED bank.lab.test -> 203.0.113.66 TXID={query.id} resolver-port={peer[1]}", flush=True)
        sock.sendto(response.to_wire(), peer)
    except (ValueError, dns.exception.DNSException) as error:
        print(f"Malformed lab query: {error}", flush=True)
