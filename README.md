# Gemini Video Understanding MCP

MCP local cho Codex: phân tích video bằng Gemini, tóm tắt, chia cảnh theo mốc thời gian, mô tả hình ảnh, giọng nói, âm nhạc và hiệu ứng âm thanh bằng tiếng Việt.

## Cài nhanh trên máy Windows mới

1. Cài và mở Codex desktop, đăng nhập tài khoản của bạn.
2. Trên GitHub chọn **Code → Download ZIP**, giải nén vào thư mục cố định, ví dụ `D:\Tools\gemini-video-mcp`. Không chạy trực tiếp bên trong ZIP.
3. Nhấp đúp **Cai-dat.cmd**. Bộ cài tìm Python và Codex, tạo môi trường riêng, cài thư viện, kiểm tra MCP rồi đăng ký tên `gemini-video`.
4. Nhấp đúp **Nhap-API.cmd**, nhập Gemini API key. Ký tự nhập được ẩn; không gửi key vào chat.
5. Đóng và mở lại Codex, gửi đường dẫn video hoặc link YouTube kèm yêu cầu phân tích.

Nếu thiếu Python, cài [Python 3.10 trở lên từ trang chính thức](https://www.python.org/downloads/windows/), chọn **Add Python to PATH**, rồi chạy lại bộ cài. Python đi kèm runtime của Codex cũng được sử dụng nếu có. Cần Internet để cài thư viện và gọi Gemini. Bộ cài không yêu cầu quyền quản trị.

**Giữ nguyên thư mục sau khi cài.** Nếu chuyển thư mục, chạy lại `Cai-dat.cmd`. Đăng ký cùng tên sẽ cập nhật đường dẫn của MCP `gemini-video` hiện có. Key mã hóa gắn với tài khoản Windows và máy: nhập lại trên máy mới, không chép thư mục `.secrets`.

## Ví dụ yêu cầu trong Codex

> Dùng Gemini Video Understanding phân tích toàn bộ video tại `D:\Videos\clip.mp4` bằng tiếng Việt. Chia từng cảnh, ghi mốc thời gian, hành động nhân vật, góc máy, chữ trên màn hình; phân tích giọng nói, nhạc nền và sound effect tương ứng. Nêu rõ những điểm không chắc chắn.

Hoặc gửi link YouTube công khai và yêu cầu tương tự. Đường dẫn phải có thật trên máy đang chạy MCP.

## Công cụ

| Tool | Chức năng |
| --- | --- |
| `connection_status` | Kiểm tra có key cục bộ; không xác minh kết nối Google và không phát sinh yêu cầu Gemini. |
| `start_video_analysis` | Tải video lên Google nếu dùng file, bắt đầu phân tích và trả `job_id`. |
| `analysis_result` | Xem tiến độ/kết quả; đợi khoảng 10 giây giữa các lần hỏi khi đang chạy. |

`processing` nhận `agentic` (mặc định) hoặc `static`; `model` mặc định `gemini-3.8-flash`, có thể chọn model khác mà dự án API của bạn hỗ trợ. Không phải mọi model đều hỗ trợ agentic. Kết quả có `agentic_verified` dựa trên các bước xử lý được API trả về. Model, hạn mức và giá có thể thay đổi: xem [tài liệu video của Google](https://ai.google.dev/gemini-api/docs/video-understanding) và [bảng giá](https://ai.google.dev/gemini-api/docs/pricing).

## Dữ liệu và giới hạn

- Local nghĩa là MCP chạy trên máy bạn; video vẫn gửi đến Google để phân tích. Yêu cầu API có thể phát sinh phí tùy tài khoản và model.
- Video đã tải lên được yêu cầu xóa khỏi Files API khi tác vụ kết thúc, kể cả khi lỗi; nếu kết nối bị ngắt hoặc tiến trình bị đóng, thao tác xóa có thể không hoàn tất.
- Bản phân tích lưu tại `results/`. Một tác vụ chạy tại một thời điểm. Tác vụ đang chạy không tiếp tục qua lần khởi động lại MCP.
- Không cam kết mốc thời gian hoặc lời nói chính xác tuyệt đối; kiểm tra lại các chi tiết quan trọng.
- `.secrets`, `.venv`, `results`, file video và `.env` không thuộc mã nguồn. Không đăng API key lên GitHub.
- Key được mã hóa bằng Windows DPAPI. Có thể dùng biến môi trường `GEMINI_API_KEY` thay thế (hữu ích trên macOS/Linux; bộ cài nhấp đúp chỉ dành cho Windows).

## Cập nhật

Tải ZIP mới, giải nén và chép các file mã nguồn vào thư mục đang dùng, giữ `.secrets` và `results` trên máy. Chạy lại `Cai-dat.cmd`, rồi mở lại Codex. Nếu dùng Git, chạy `git pull` trong thư mục kho rồi chạy bộ cài.

## Kiểm tra dành cho người phát triển

```powershell
.\.venv\Scripts\python.exe -X utf8 Kiem-tra.py
.\.venv\Scripts\python.exe -X utf8 -m unittest discover -s tests -v
```

Các kiểm tra dùng dữ liệu giả lập, không gửi video và không gọi Gemini thật. Đây là công cụ cộng đồng, không phải sản phẩm chính thức của Google hoặc OpenAI.
