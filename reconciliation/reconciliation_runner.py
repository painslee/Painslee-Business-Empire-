"""
reconciliation_runner.py

Outline script: loads reconciliation CSV (or exports), loads orders/payments/ledger from local CSVs or DB exports,
matches payments to orders only when provider_transaction_id AND evidence_link exist,
produces an exceptions report. Does NOT create or modify transactions.

Run: python reconciliation_runner.py --orders orders.csv --payments payments.csv --ledger ledger.csv --out report.csv
"""

import csv
import argparse
from collections import defaultdict


def load_csv(path, key_field=None):
    items = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            items.append(row)
    return items


def match_payments_orders(orders, payments):
    # Build lookup by provider_transaction_id
    payments_by_tx = {p.get('provider_transaction_id'): p for p in payments if p.get('provider_transaction_id')}
    matches = []
    exceptions = []
    for o in orders:
        tx = o.get('provider_transaction_id') or o.get('payment_provider_transaction_id')
        if tx and tx in payments_by_tx:
            p = payments_by_tx[tx]
            # Only accept match if evidence_link exists
            if p.get('evidence_link'):
                matches.append((o, p))
            else:
                exceptions.append({'order': o, 'issue': 'missing_payment_evidence'})
        else:
            exceptions.append({'order': o, 'issue': 'no_matching_payment'})
    return matches, exceptions


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--orders', required=True)
    parser.add_argument('--payments', required=True)
    parser.add_argument('--ledger', required=False)
    parser.add_argument('--out', required=False, default='reconciliation_report.csv')
    args = parser.parse_args()

    orders = load_csv(args.orders)
    payments = load_csv(args.payments)
    ledger = load_csv(args.ledger) if args.ledger else []

    matches, exceptions = match_payments_orders(orders, payments)

    # Write a simple report
    with open(args.out, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['order_id','order_total','payment_id','payment_amount','match_status','issue']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for o, p in matches:
            writer.writerow({'order_id': o.get('order_id'), 'order_total': o.get('total_amount'), 'payment_id': p.get('payment_id'), 'payment_amount': p.get('amount'), 'match_status': 'matched', 'issue': ''})
        for e in exceptions:
            o = e.get('order')
            writer.writerow({'order_id': o.get('order_id'), 'order_total': o.get('total_amount'), 'payment_id': '', 'payment_amount': '', 'match_status': 'exception', 'issue': e.get('issue')})

    print(f"Reconciliation complete. Matches: {len(matches)}. Exceptions: {len(exceptions)}. Report: {args.out}")

if __name__ == '__main__':
    main()
