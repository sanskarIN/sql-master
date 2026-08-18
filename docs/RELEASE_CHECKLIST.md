# Release Checklist

Use this checklist before calling a repository state release-ready.

## Source and scope

- [ ] `README.md` matches the live repository tree.
- [ ] `COMPANION_STATUS.json` matches the published Part directories.
- [ ] `PROJECTS_STATUS.json` matches the standalone project directories.
- [ ] No paid Master PDF/DOCX/EPUB is present in the public tree.
- [ ] No mutable X/Twitter profile URL exists in permanent metadata.
- [ ] Official Gumroad link is present in the required public documentation.

## Tests

- [ ] `python scripts/validate_repository.py` passes.
- [ ] `python scripts/run_all_tests.py --standalone` passes.
- [ ] `python scripts/run_all_tests.py --companion` passes for Parts 110–120.
- [ ] Package-specific checksum manifests are updated after intentional source changes.
- [ ] Any warning treated as acceptable is documented with a reason.

## CI and security

- [ ] Repository Quality workflow passes.
- [ ] Standalone SQL Projects workflow passes.
- [ ] Companion Python Tests workflow passes.
- [ ] CodeQL completes without an unresolved repository-breaking configuration error.
- [ ] No obsolete root-level starter workflow has reappeared.
- [ ] `SECURITY.md` and issue templates are current.

## Documentation

- [ ] `docs/README.md` indexes the current docs.
- [ ] `docs/ARCHITECTURE.md` reflects the current layout.
- [ ] `docs/TESTING.md` uses the actual test commands.
- [ ] `docs/DEVELOPMENT.md` reflects the current contribution workflow.
- [ ] `docs/TROUBLESHOOTING.md` covers known setup/CI issues.
- [ ] `CURRENT_STATUS.md` is accurate.
- [ ] `CHANGELOG.md` and `what_changed.md` are updated.

## Git

- [ ] Commits are small and meaningful.
- [ ] Repository-local commit email is `sanskarin@outlook.in` when using local Git.
- [ ] `main` contains all intended commits.
- [ ] No force-push is needed for routine publication work.

## Release communication

- [ ] Public repo description is accurate.
- [ ] Public/private licensing boundary is clear.
- [ ] Buyer-facing store link is **https://ramsandesh.gumroad.com**.
- [ ] Known limitations are stated rather than hidden.

A passed checklist means the repository has passed its defined release gates. It is not a mathematical guarantee that undiscovered software defects are impossible.
