# Log: provider Linux stability 2026-05-27

- Started: 2026-05-27
- Finished: 2026-05-27
- Status: completed
- Plan: plans/running/plan-aihub-provider-linux-stability-20260527-v1.md
- Doc: docs/operations/linux-runtime-notes-20260527-v1.md

## Mục Tiêu
Theo dõi ổn định Linux cho AI Virtual Assistant Provider sau khi bỏ fixed Docker container names.

## Command Chính
- Rà Docker Compose và source setup.
- Push fix source provider.
- Ghi chú lại lỗi Linux thường gặp và chuẩn hóa allocator port.

## Kết Quả
- Source đã push: `69dc69f` trên `origin/main`.
- Fixed container names đã được xử lý để tránh xung đột khi AI Hub clone/install lại.
- `.env.example` và `start.sh` dùng host ports trong `6000-6050`, ghi map vào `.runtime/ports.env`.

## Lỗi Linux Hay Gặp
- Nhiều service compose dùng port mặc định ngoài `6000-6050`, dễ đụng Hub hoặc stack khác.
- File CSV/runtime được sinh trong `deploy/compose/init-scripts/` không nên tự động commit nếu là dữ liệu test.
- Docker Desktop/WSL có thể giữ network/volume sau khi stop.
- Hosted API mode nên được ưu tiên trên AMD/Windows/Linux không có NVIDIA runtime.

## Rủi Ro Còn Lại
- Provider đã deprecated upstream; full hosted output có thể rerun riêng nếu cần chứng minh lại sau port pass.
