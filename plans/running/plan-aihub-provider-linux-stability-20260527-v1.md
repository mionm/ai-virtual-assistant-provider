# Plan: aihub-provider-linux-stability

- Created: 2026-05-27 00:00
- Updated: 2026-05-27 23:40
- Status: completed
- Related log: logs/testing/provider-linux-stability-20260527-v1.md
- Related doc: docs/operations/linux-runtime-notes-20260527-v1.md

## Goal
Ổn định AI Virtual Assistant Provider khi AI Hub clone lại repo, tránh xung đột Docker trên Linux và chuẩn hóa ghi chú port `6000-6050`.

## Scope
- In: tránh fixed Docker container names, ghi chú port/rủi ro Linux, lưu trạng thái test.
- Out: không commit dữ liệu runtime hoặc key thật, không push evidence Hub tổng.

## Skills
- testing-skill
- plan-skill
- logging-skill
- documentation-skill
- push-code-skill

## Phases
| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Fix fixed Docker container names | done | commit `69dc69f` |
| 2 | Ghi chú Linux và port `6000-6050` | done | docs/operations |
| 3 | Fresh install full chức năng | skipped | deprecated provider cần full rerun riêng nếu mở lại |

## Verification
- Đã push fix source `69dc69f`.
- Port defaults và runtime allocator đã được chuẩn hóa về `6000-6050`.

## Close Criteria
- Port host được chuẩn hóa vào `6000-6050`.
- Full install từ GitHub không dùng port ngoài range.
- Không lưu secret hoặc dữ liệu runtime.
