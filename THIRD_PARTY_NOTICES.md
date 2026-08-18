# Third-Party Notices

The root repository license covers code authored for this repository under the terms stated in `LICENSE`. Individual companion packages may depend on third-party libraries, database engines, drivers, frameworks, build tools, or runtimes that have their **own licenses and terms**.

## Important rule

The root MIT License does not replace or override a third-party dependency's license.

## Examples of dependency sources

Depending on the Part/project, dependencies may include:

- SQLite libraries/drivers
- PostgreSQL drivers/tooling
- Rust crates
- Go modules
- C/C++ build dependencies
- framework/ORM packages

Check the owning package's manifest and README for exact dependencies.

## Contributor requirements

When adding a new dependency:

1. record it in the package's normal manifest/setup file
2. review and comply with its license
3. add attribution/notice text when required
4. avoid copying third-party source into the repository unless redistribution is permitted and necessary
5. never remove copyright/license notices from redistributed third-party material

## Commercial book boundary

The commercial SQL Full Mastery manuscript and publishing assets are governed separately by `BOOK_LICENSE.md` and are not relicensed under the repository MIT License.

For questions about repository licensing, use the business/support contacts documented in `SUPPORT.md`.
