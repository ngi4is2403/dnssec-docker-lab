# DNSSEC Docker Lab

Chuyển mô hình hai VM trong [báo cáo DNSSEC](https://docs.google.com/document/d/11fwnF2LnT1U6xgHZ9Y0sJHIIhrDJZw5DAg0DtRotBRw/edit) sang Docker Compose. BIND9 ký zone `lab.test` bằng ECDSAP256SHA256; resolver xác thực bằng public KSK được tạo tự động.

Đã chạy kiểm thử đầy đủ ngày 25/11/2026 trên Docker Desktop Linux containers, BIND 9.18.39. [Kết quả kiểm chứng](VALIDATION.md).

| Thành phần | Địa chỉ nội bộ | Vai trò |
|---|---|---|
| authority | 172.30.53.10 | BIND9 authoritative; chuyển sang unsigned upstream khi test |
| resolver | 172.30.53.20 | BIND9 validating resolver |
| test | Chung network namespace resolver | Client kiểm tra kết quả |

## Chạy

Cần Docker Engine/Desktop đang chạy Linux containers, Docker Compose v2 và Internet khi build image. Không cần cài BIND trên máy chủ.

```sh
docker compose up -d --build --wait
docker compose run --rm --no-deps test baseline
```

Kiểm thử đầy đủ trên Windows PowerShell:

```powershell
./test.ps1
```

Linux/macOS:

```sh
sh test.sh
```

Quy trình tự động kiểm tra:

1. Baseline: `NOERROR`, A `192.0.2.10`, có `RRSIG` và cờ `AD`.
2. Chuyển authority sang upstream trả A `203.0.113.66`, thiếu `RRSIG`.
3. Xác minh trực tiếp upstream thật sự trả IP sai, sau đó resolver phải trả `SERVFAIL`, ANSWER rỗng, không có `AD`; lặp lại để kiểm tra IP sai không được trả từ cache.
4. Khôi phục BIND9, xóa cache và xác minh lại A hợp lệ, `RRSIG`, `AD`.

Log và PCAP nằm trong `artifacts/` sau khi chạy. Mở `unsigned.pcap` bằng Wireshark, lọc `dns.qry.name == "bank.lab.test"`. Chạy `docker compose logs resolver` để xem log validation. Script luôn cố khôi phục authority nếu kiểm tra thất bại.

Truy vấn thủ công bằng `dig` có sẵn trong container:

```sh
docker compose exec resolver dig '@127.0.0.1' bank.lab.test A +dnssec
docker compose exec resolver rndc flush
docker compose logs --tail 100 resolver
docker compose down
```

## Khác biệt với báo cáo VM

Docker dùng Ubuntu 24.04 cho cả hai vai trò, không cần `systemctl`. Python/dnspython trả phản hồi thiếu chữ ký từ chính endpoint authoritative thay cho Scapy sniff/spoof. Transaction ID, source port và EDNS cookie được lấy từ query hiện tại; mục tiêu kiểm chứng là DNSSEC validation, không phải kỹ thuật thắng cuộc đua gói tin. Unsigned responder chỉ nhận truy vấn từ resolver của lab; dữ liệu thử dùng các IP tài liệu.

Mạng Compose có `internal: true` và không publish cổng ra host. Truy vấn và kiểm thử chạy trong container; Docker Desktop không cần mở cổng 53 trên Windows. Không có recursive resolver mở ra Internet. KSK/ZSK sinh mới khi authority khởi động và không đưa vào Git. Volume `trust` chỉ chứa public trust anchor, resolver mount read-only. Sau khi recreate authority, recreate resolver để nạp khóa mới (`docker compose up -d --force-recreate --wait`). Chữ ký hiệu lực 30 ngày; recreate cả hai service để ký lại. Đây là lab island of security, chưa minh họa chuỗi DS từ root hay key rollover.

Nếu subnet trùng mạng hiện có, cần đổi subnet/IP trong Compose, `entrypoint.sh`, `unsigned.py`, `check.py` đồng bộ. Chạy một phiên kiểm thử tại một thời điểm.

## Tham khảo

- [BIND9: DNSSEC validation và trust anchors](https://bind9.readthedocs.io/en/v9.18.41/reference.html)
- [Báo cáo gốc](https://docs.google.com/document/d/11fwnF2LnT1U6xgHZ9Y0sJHIIhrDJZw5DAg0DtRotBRw/edit)
