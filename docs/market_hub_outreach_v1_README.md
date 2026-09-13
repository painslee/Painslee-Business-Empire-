# Market Hub Outreach V1 — README

This PR adds the Market Hub Outreach V1 implementation artifacts: SQL schema templates, outreach templates for multiple channels, qualification form schema and example, reconciliation CSV spec and runner outline, and documentation.

Important safety rules
- No secrets, no service_role credentials, no Founder Code in public files.
- via=popoola-habeeb-iqno is stored as attribution only.
- Founder Code is internal-only and never included in outreach or form assets.
- This PR is for review. Do not merge until Schema, Security, Outreach, Form Validation, Reconciliation, and CI reviews pass.

Files included
- sql/market_hub_schema.sql
- outreach/*.md
- forms/*.json and example HTML
- reconciliation/*
- docs/market_hub_outreach_v1_README.md
- .github/ISSUE_TEMPLATE/reconciliation-exception.md

Pre-PR verification performed (static checks)
- Confirmed no obvious secrets (strings like 'SECRET', 'TOKEN', 'SERVICE_ROLE') present.
- Confirmed via_code appears only as attribution metadata.
- Confirmed Founder Code is referenced only as internal policy in comments; not present in templates.

What this PR DOES NOT do
- It does NOT execute RLS or DB policies in a live DB. RLS and SECURITY DEFINER functions are templates and must be reviewed by DB admins and tested in a staging environment.
- It does NOT connect to payment providers or create financial transactions.
- It does NOT run CI tests; CI will run after PR is opened and configured in your repo.

Next steps for reviewers
1) Run SQL DDL in a staging DB and verify RLS & SECURITY DEFINER function behavior.
2) Review outreach content for brand voice and legal compliance.
3) Validate the qualification form schema and sample payload with front-end.
4) Run reconciliation_runner.py in a local environment with exported CSVs and verify exceptions handling.

