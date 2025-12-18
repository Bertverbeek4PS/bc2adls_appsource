## Style and Conventions
- Object prefix should be **ADL** (requirement to replace old ADLSE prefix). Namespace `bc2adls` across files; object IDs in 11344437-11344456.
- Captions/labels in English; keep ASCII unless required. Telemetry IDs use `ADLSE-###` format (retain unless instructed).
- API pages use `APIPublisher bc2adlsTeamMicrosoft`, `APIGroup bc2adls`, `APIVersion v1.2`; entity names are lowercase identifiers (currently adlse*).
- Use `[InherentPermissions]` and `Permissions` properties consistently on tables/codeunits; Access often `Internal`.
- General AL patterns: card/list pages for setup, processing reports for jobs, codeunits for execution, enums for state/config.