## Project Overview
- Business Central AL app **BC2ADLS** exporting selected tables to Azure Data Lake / Fabric with incremental sync.
- AL runtime 16.0, platform/application 27.x; id range 11344437-11344456; target Cloud; translations enabled.
- Structure: `src/` AL objects (tables, pages, codeunits, enums, reports, xmlports); `permissions/`; `Translations/`; `app.json` metadata in root.
- Core modules: setup/config (`Setup.*`, `Table.*`, `Field.*`), export pipeline (`Execute`, `Execution`, `Communication`, `Util`, `Http`, `Gen2Util`), API pages (`*APIv12`), scheduling/reports, upgrade/install codeunits, translation helpers.