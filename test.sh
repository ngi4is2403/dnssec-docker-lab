#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p artifacts
docker compose up -d --build --wait
cleanup() {
  docker compose exec -T authority rm -f /run/unsigned || true
  sleep 2
  docker compose exec -T authority pkill -INT tcpdump || true
  docker compose logs --no-color >artifacts/lab.log
  docker compose cp authority:/evidence/unsigned.pcap artifacts/unsigned.pcap || true
}
trap cleanup EXIT
docker compose exec -T resolver rndc flush
docker compose run --rm --no-deps test baseline
docker compose exec -T -d authority tcpdump -Z root -U -i eth0 -w /evidence/unsigned.pcap 'port 53'
docker compose exec -T authority touch /run/unsigned
sleep 2
docker compose exec -T resolver rndc flushname bank.lab.test
docker compose run --rm --no-deps test unsigned-wire
docker compose run --rm --no-deps test blocked
docker compose run --rm --no-deps test blocked
cleanup
trap - EXIT
docker compose exec -T resolver rndc flush
docker compose run --rm --no-deps test recovery
echo 'PASS: baseline, unsigned wire, blocked twice, recovery. Evidence: artifacts/'
