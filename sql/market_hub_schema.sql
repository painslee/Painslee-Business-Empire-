-- Market Hub schema and RLS templates for Painslee Business Empire
-- WARNING: This file contains schema templates and SECURITY DEFINER function examples.
-- Do NOT embed secrets or service_role credentials in application code.

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()

-- market_prospects
CREATE TABLE IF NOT EXISTS market_prospects (
  prospect_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text,
  contact_method text,
  phone text,
  email text,
  source text,
  via_code text, -- e.g., popoola-habeeb-iqno
  interest text,
  product_category text,
  budget_range text,
  custom_fit_required boolean,
  preferred_location text,
  conversation_status text DEFAULT 'new',
  next_action text,
  correlation_id uuid DEFAULT gen_random_uuid(),
  idempotency_key text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_market_prospects_idempotency ON market_prospects (idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_prospects_via ON market_prospects (via_code);
CREATE INDEX IF NOT EXISTS ix_prospects_status ON market_prospects (conversation_status);

-- founder_authorizations
CREATE TABLE IF NOT EXISTS founder_authorizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id uuid REFERENCES market_prospects(prospect_id),
  founder_user_id uuid NOT NULL,
  approval boolean NOT NULL,
  reason text,
  correlation_id uuid,
  idempotency_key text,
  created_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_founder_auth_idempotency ON founder_authorizations (idempotency_key) WHERE idempotency_key IS NOT NULL;

-- audit_log
CREATE TABLE IF NOT EXISTS audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid,
  actor_role text,
  action text NOT NULL,
  resource_type text,
  resource_id uuid,
  details jsonb,
  correlation_id uuid,
  idempotency_key text,
  created_at timestamptz DEFAULT now()
);

-- quotes, orders, payments, ledger, project_assets
CREATE TABLE IF NOT EXISTS market_quotes (
  quote_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id uuid REFERENCES market_prospects(prospect_id),
  items jsonb,
  total_amount numeric(12,2),
  currency text DEFAULT 'NGN',
  status text DEFAULT 'created',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS market_orders (
  order_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id uuid REFERENCES market_quotes(quote_id),
  prospect_id uuid REFERENCES market_prospects(prospect_id),
  status text DEFAULT 'order_created',
  payment_id uuid,
  total_amount numeric(12,2),
  ledger_mapped boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payments (
  payment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES market_orders(order_id),
  provider text,
  provider_transaction_id text,
  amount numeric(12,2),
  currency text,
  payment_status text,
  evidence_link text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ledger_entries (
  ledger_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES market_orders(order_id),
  account_code text NOT NULL, -- use Chart of Accounts codes (1001,1005,4003...)
  debit numeric(12,2),
  credit numeric(12,2),
  description text,
  project_id uuid,
  owner_user_id uuid NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_assets (
  asset_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid,
  prospect_id uuid,
  file_path text,
  file_type text,
  uploaded_by uuid,
  correlation_id uuid,
  created_at timestamptz DEFAULT now()
);

-- RLS enable and policy templates (examples)
ALTER TABLE IF EXISTS founder_authorizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ledger_entries ENABLE ROW LEVEL SECURITY;

-- Example POLICY: prevent direct client inserts; require server path or SECURITY DEFINER functions
-- IMPORTANT: adapt current_setting usage to your application pattern if used.

-- Example: small helper to demonstrate server-only insert pattern using SECURITY DEFINER
CREATE OR REPLACE FUNCTION server_insert_founder_authorization(
  _prospect_id uuid,
  _founder_user_id uuid,
  _approval boolean,
  _reason text,
  _correlation_id uuid,
  _idempotency_key text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  _id uuid;
BEGIN
  INSERT INTO founder_authorizations(prospect_id, founder_user_id, approval, reason, correlation_id, idempotency_key)
  VALUES (_prospect_id, _founder_user_id, _approval, _reason, _correlation_id, _idempotency_key)
  RETURNING id INTO _id;

  INSERT INTO audit_log(actor_user_id, actor_role, action, resource_type, resource_id, details, correlation_id, idempotency_key)
  VALUES (_founder_user_id, 'founder', 'founder_authorization.create', 'founder_authorizations', _id, jsonb_build_object('reason', _reason, 'approval', _approval), _correlation_id, _idempotency_key);

  RETURN _id;
END;
$$;

-- Note: SECURITY DEFINER functions should be owned by a trusted role. Ensure proper permissions are set and functions are audited.

-- Indexes to support reconciliation and queries
CREATE INDEX IF NOT EXISTS ix_orders_status ON market_orders (status);
CREATE INDEX IF NOT EXISTS ix_payments_provider_tx ON payments (provider_transaction_id);
CREATE INDEX IF NOT EXISTS ix_ledger_order ON ledger_entries (order_id);

-- End of schema template
