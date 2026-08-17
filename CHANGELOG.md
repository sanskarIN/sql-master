# Changelog

All notable public companion-repository changes are recorded here.

Official store: **https://ramsandesh.gumroad.com**

## 2026-08-17

### Added
- Public companion repository structure for Parts 1–120.
- Browseable advanced companion content through Parts 103–120.
- Full source publication for Parts 110–120 with package-specific validation.
- Gumroad store promotion and custom highlight asset.
- Repository licensing boundary: MIT companion code and All Rights Reserved commercial manuscript/assets.
- Security, support, contribution, publication-status, and CI documentation.
- Dedicated Python validation workflow for Parts 110–120.

### Fixed
- Corrected the Part 111 purchase-order-line identifier introduced during relay/transcription.

### Known limitations
- Parts 1–102 currently retain repository placeholders until their companion packages are staged for publication.
- Part 116's exact imported test/self-check files pass but emit two non-failing `ResourceWarning`s from unclosed CSV handles; a warning-clean local version has been validated for a future maintenance update.
- Part 119 and Part 120 long CSV banks use relay-safe representations because the connector truncated the original long CSV text during transfer. Required row-count/category contracts are preserved.
