$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
function Run-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) { throw "Docker failed: $args" }
}
New-Item -ItemType Directory -Force artifacts | Out-Null
Run-Docker compose up -d --build --wait
try {
    Run-Docker compose exec -T resolver rndc flush
    Run-Docker compose run --rm --no-deps test baseline
    Run-Docker compose exec -T -d authority tcpdump -Z root -U -i eth0 -w /evidence/unsigned.pcap 'port 53'
    Run-Docker compose exec -T authority touch /run/unsigned
    Start-Sleep -Seconds 2
    # Keep the DNSKEY cached from baseline; evict the target RRset.
    Run-Docker compose exec -T resolver rndc flushname bank.lab.test
    Run-Docker compose run --rm --no-deps test unsigned-wire
    Run-Docker compose run --rm --no-deps test blocked
    Run-Docker compose run --rm --no-deps test blocked
} finally {
    & docker compose exec -T authority rm -f /run/unsigned
    Start-Sleep -Seconds 2
    & docker compose exec -T authority pkill -INT tcpdump
    & docker compose logs --no-color | Set-Content -Encoding utf8 artifacts/lab.log
    & docker compose cp authority:/evidence/unsigned.pcap artifacts/unsigned.pcap
}
Run-Docker compose exec -T resolver rndc flush
Run-Docker compose run --rm --no-deps test recovery
Write-Host 'PASS: baseline, unsigned wire, blocked twice, recovery. Evidence: artifacts/'
