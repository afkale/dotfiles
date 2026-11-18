# Plans

Each change that an agent will implement gets a plan file here before any code is written.

- **Format**: Markdown with YAML frontmatter. Copy `TEMPLATE.md`.
- **Filename**: `YYYY-MM-DD-slug.md`, for example `2026-11-18-flow-view.md`.
- **Review**: every plan goes through `plannotator annotate <file> --gate`. Set `status` to
  `approved` or `denied` from the decision. Agents do not start implementing until it is `approved`.
- **Lifecycle**: `draft` → `approved` (or `denied`) → `done` once the change is merged.
- **Scope**: this folder holds plans only. Specs live in `docs/specs/`, decisions in `docs/adr/`.
