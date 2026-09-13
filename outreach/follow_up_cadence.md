Follow-up cadence & prospect lifecycle — Market Hub Outreach V1

Cadence
- Day 0: Message 1 (intro)
- Day 3: Message 2 (if replied)
- Day 5: Message 3 (qualification form link)
- Day 7–14: Message 4 (conversion/quote) — only after qualification
- Weekly reminders: only for engaged/qualified prospects

Prospect status transitions
new -> engaged -> qualified -> quoted -> quote_accepted -> order_created -> payment_pending -> paid -> shipped -> completed -> closed_won
Failure/alternate states: closed_lost, unresponsive, disqualified, manual_review

Attribution tracking
- Record: source, via_code (popoola-habeeb-iqno), correlation_id, idempotency_key.
- Attribution is metadata only — do not use as legal proof of ownership or payment.

Logging
- All state transitions write an audit_log entry with correlation_id and idempotency_key.
