# AGENTS.md — hướng dẫn cho AI-CLI dựng hệ thống này

Người dùng đưa repo này cho bạn và nói "làm theo". Thực hiện đúng thứ tự dưới đây,
**không bỏ bước kiểm tra**, và **dừng lại hỏi** khi gặp chỗ ghi "HỎI".

## Việc bạn phải làm

1. Đọc `README.md` hết một lượt trước khi chạy bất kỳ lệnh nào.
2. Kiểm tra điều kiện: `opencode --version` (>= 2.0), `tailscale status` (đã đăng nhập),
   ghi lại `tailscale ip -4` của máy này.
3. Sinh mật khẩu: `openssl rand -base64 18 | tr -d '/+='`. **Đưa cho người dùng lưu**
   (password manager), không ghi vào file nào trong repo, không dán vào tài liệu.
4. Chạy script đúng hệ điều hành:
   - macOS: `WORKDIR="<thư mục project người dùng chỉ>" ./scripts/macos/install-serve.sh`
   - Windows: `./scripts/windows/install-serve.ps1 -Password "<mật khẩu>" -WorkDir "<thư mục>"`
5. Chạy `tailscale serve --bg http://127.0.0.1:4096` và kiểm tra `tailscale serve status`.
6. Kiểm tra từ chính máy: `curl` tới `http://127.0.0.1:4096/` phải ra HTTP 200.
7. **HỎI người dùng** trước khi đụng ACL: liệt kê thiết bị nào cần vào (điện thoại, laptop),
   xin IP Tailscale của từng thiết bị. ACL là chính sách chung của cả tailnet —
   sửa sai ảnh hưởng mọi người.
8. Sửa ACL bằng Admin API đúng quy trình trong README (GET → sửa → POST kèm `If-Match`).
   Giữ nguyên mọi comment và test sẵn có. Thêm test cho rule mới.
   Token API lấy từ biến môi trường người dùng cung cấp, không lưu vào repo.
9. Kiểm tra cuối: từ một máy được cấp quyền, `curl` tới
   `https://<tên-máy>.<tailnet>.ts.net/api/project` phải ra **401** (sống, đòi mật khẩu).
   Kèm mật khẩu phải ra **200**.

## Việc bạn không được làm

- Không commit mật khẩu, token, file `auth.json`, `opencode.json` thật, hay IP nội bộ
  của tổ chức vào bất kỳ repo nào.
- Không mở ACL theo dải rộng hay theo tag — chỉ đúng từng IP thiết bị → cổng 443.
- Không bind serve ra `0.0.0.0`. Chỉ `127.0.0.1`.
- Không tắt Tailscale Serve để "cho nhanh" rồi mở cổng thô.
- Không kết luận một máy đã rời tailnet chỉ vì nó vắng trong `tailscale status`
  (lệnh này bị lọc theo ACL). Danh sách thật nằm ở Admin Console.

## Khi gặp lỗi

Tra bảng "Bẫy đã trả giá" trong `README.md` trước khi đoán. Hai ca hay gặp nhất:
serve treo không thoát (502 — để watchdog xử lý, hoặc restart tay), và thiết bị bị
ACL chặn dù đã bật Tailscale (401/000 từ ngoài — thêm rule).
