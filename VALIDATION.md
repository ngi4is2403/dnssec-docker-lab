# Kết quả kiểm thử Docker

Ngày chạy: 25/11/2026. Docker Engine 29.7.2 (Docker Desktop, Linux containers/WSL2), Ubuntu 24.04, BIND 9.18.39. Chạy `./test.ps1` từ thư mục dự án.

| Bước | Kết quả thực tế | Kiểm tra |
|---|---|---|
| Baseline | NOERROR; A 192.0.2.10; RRSIG A; flags QR RD RA AD | PASS |
| Truy vấn trực tiếp unsigned upstream | NOERROR; A 203.0.113.66; không RRSIG | PASS |
| Truy vấn qua validating resolver | SERVFAIL; ANSWER rỗng; không AD | PASS |
| Lặp lại truy vấn qua resolver | SERVFAIL; ANSWER rỗng; không AD | PASS |
| Khôi phục BIND, flush cache | NOERROR; A 192.0.2.10; RRSIG A; flags QR RD RA AD | PASS |

Log resolver đã ghi nhận:

```text
no valid RRSIG resolving 'bank.lab.test/DS/IN': 172.30.53.10#53
broken trust chain resolving 'bank.lab.test/A/IN': 172.30.53.10#53
```

PCAP `artifacts/unsigned.pcap` được xuất thành công (1040 byte trong phiên kiểm thử). Log đầy đủ ở `artifacts/lab.log`. Chạy lại script để tự tạo bằng chứng trên máy của bạn; thư mục artifacts không được commit.

Kết quả xác nhận validator từ chối dữ liệu thiếu chữ ký trong zone có trust anchor. Thử nghiệm dùng unsigned upstream có kiểm soát, không mô phỏng cuộc đua gói Scapy hay chứng minh khả năng đầu độc cache trên hệ thống bên ngoài.
