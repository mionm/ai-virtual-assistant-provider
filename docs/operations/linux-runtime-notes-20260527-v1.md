# Linux Runtime Notes: AI Virtual Assistant Provider

- Date: 2026-05-27
- Status: completed
- Related plan: ../../plans/running/plan-aihub-provider-linux-stability-20260527-v1.md
- Related log: ../../logs/testing/provider-linux-stability-20260527-v1.md

## Port Rule
AI Hub installs use host ports in `6000-6050`. Fresh clones get range-safe defaults from `.env.example`, and `start.sh` resolves busy ports inside the same range before writing `.runtime/ports.env`.

## Common Linux Issues
- Avoid fixed `container_name` values in compose; they collide after reinstall.
- Stop old compose projects and remove orphan containers before a fresh install.
- Keep generated CSV/runtime data out of commits unless it is intentional fixture data.
- Hosted mode is the safer path on AMD/Windows/Linux without NVIDIA runtime.

## Verified Output
Existing Hub evidence contains lifecycle screenshots and reports for earlier provider runs. The provider is deprecated upstream, so full hosted output can be rerun separately when this blueprint needs another release sign-off.
