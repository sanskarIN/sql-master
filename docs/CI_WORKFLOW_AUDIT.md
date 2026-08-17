# CI Workflow Audit

Official store: **https://ramsandesh.gumroad.com**

`sql-master` is a **multi-part, multi-language companion repository**, not one root-level CMake/MSBuild/Make application. CI must therefore be scoped to the paths and toolchains it actually validates.

## Authoritative companion test workflow

`.github/workflows/companion-python-tests.yml` runs the dependency-free validation suites for Parts 110–120 with the runner each package actually uses.

## Generic workflow caution

GitHub-generated templates such as root-level CMake, MSBuild, Makefile, or C/C++ workflows can fail when they assume a root project file that does not exist. Keep them only when they are path-scoped to a real companion project.

Recommended mapping:

- C/C++: Part 103
- Rust: Part 104
- Go: Part 105
- API/Python and later model packages: use the package-specific test runner
- CodeQL: scope languages and paths deliberately
- SLSA/provenance: use for release artifacts after a defined release build exists

## CI design rules

1. Do not make unrelated Parts fail because one language toolchain is unavailable.
2. Use path filters where practical.
3. Keep `permissions` minimal.
4. Pin trusted GitHub Actions to supported major versions or immutable revisions based on the repository's security policy.
5. Make every workflow prove a real package contract rather than merely executing a template command.
6. Do not publish the paid Master PDF/DOCX/EPUB from public CI.
