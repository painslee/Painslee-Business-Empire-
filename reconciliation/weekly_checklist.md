Weekly reconciliation checklist — Market Hub Outreach V1

1) Export orders created in the week (include correlation_id, prospect_id, order_id, total_amount)
2) Export payments from payment providers for the same period (provider_transaction_id, amount, evidence_link)
3) Match payments to orders using provider_transaction_id and correlation_id
4) Flag exceptions: missing evidence, amount mismatch, unmapped ledger entries
5) For each exception create an issue using .github/ISSUE_TEMPLATE/reconciliation-exception.md
6) Create ledger entries or mark ledger_mapped=true only after evidence review
7) Save reconciliation CSV and attach to project_assets with an audit_log entry
8) Archive and retain per retention policy
