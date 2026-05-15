
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 0) ENUMS (kept as TEXT+CHECK for portability)
-- ============================================================

-- ============================================================
-- 1) RBAC
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
  role_id SMALLSERIAL PRIMARY KEY,
  role_code TEXT UNIQUE NOT NULL CHECK (role_code IN ('ADMIN','SUB_ADMIN','OPS_HEAD','ORG','HR','EMPLOYEE')),
  role_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS permissions (
  perm_id SMALLSERIAL PRIMARY KEY,
  perm_code TEXT UNIQUE NOT NULL,
  perm_name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id SMALLINT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  perm_id SMALLINT NOT NULL REFERENCES permissions(perm_id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, perm_id)
);

-- ============================================================
-- 2) USERS + AUTH + MFA
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_country_code VARCHAR(8),
  phone_number VARCHAR(20),

  password_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','DELETED')),
  is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,

  mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  mfa_method TEXT CHECK (mfa_method IN ('TOTP','SMS','EMAIL')),

  last_login_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id SMALLINT NOT NULL REFERENCES roles(role_id),
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  user_agent TEXT,
  ip_address TEXT,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS login_attempts (
  attempt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  email VARCHAR(255),
  ip_address TEXT,
  user_agent TEXT,
  outcome TEXT NOT NULL CHECK (outcome IN ('SUCCESS','FAIL')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 3) ORGANIZATIONS (Tenant Root) + MEMBERSHIP (user can belong to multiple orgs)
-- ============================================================

CREATE TABLE IF NOT EXISTS organizations (
  organization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_code TEXT UNIQUE,

  legal_name TEXT NOT NULL,
  trade_name TEXT,
  company_email VARCHAR(255),
  phone_country_code VARCHAR(8),
  company_phone VARCHAR(20),

  industry_type TEXT,
  company_size TEXT,

  registration_number TEXT,
  gst_number TEXT,
  cin_number TEXT,

  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  pincode TEXT,

  contact_person_name TEXT,
  contact_person_designation TEXT,
  contact_person_email TEXT,
  contact_person_mobile TEXT,

  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACTIVE','BLOCKED')),

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),
  deleted_at TIMESTAMP
);

-- Org membership + role-in-org (ORG owner / HR)
CREATE TABLE IF NOT EXISTS organization_users (
  org_user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

  org_role TEXT NOT NULL CHECK (org_role IN ('ORG','HR')),
  designation TEXT,
  department TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),

  UNIQUE (organization_id, user_id, org_role)
);

CREATE TABLE IF NOT EXISTS company_registry_lookups (
  lookup_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE CASCADE,
  registration_number TEXT NOT NULL,
  provider TEXT,
  request_payload JSONB,
  response_payload JSONB,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 4) GLOBAL EMPLOYEE IDENTITY (cross-organization)
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_global_identity (
  employee_global_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE REFERENCES users(user_id) ON DELETE SET NULL, -- if employee logs in
  prora_global_code TEXT UNIQUE, -- optional public-safe code (not PII)
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Link global identity to org-specific employee record
CREATE TABLE IF NOT EXISTS employees (
  employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  user_id UUID UNIQUE REFERENCES users(user_id) ON DELETE SET NULL, -- employee login (optional in some orgs)
  employee_code TEXT,

  designation TEXT,
  department TEXT,
  joining_date DATE,
  employment_type TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),
  deleted_at TIMESTAMP,

  UNIQUE (organization_id, employee_global_id)
);

-- ============================================================
-- 5) PII VAULT TABLES (encrypt at app layer, store ciphertext)
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_profile_pii (
  employee_global_id UUID PRIMARY KEY REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  first_name_enc TEXT,
  middle_name_enc TEXT,
  last_name_enc TEXT,
  dob_enc TEXT,
  gender_enc TEXT,
  personal_email_enc TEXT,
  personal_phone_enc TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_identities_pii (
  employee_global_id UUID PRIMARY KEY REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  aadhaar_enc TEXT,
  pan_enc TEXT,
  passport_enc TEXT,
  driving_license_enc TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_addresses_pii (
  address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  address_type TEXT NOT NULL CHECK (address_type IN ('CURRENT','PERMANENT','OFFICE','OTHER')),
  address_enc TEXT,
  city_enc TEXT,
  state_enc TEXT,
  country_enc TEXT,
  pincode_enc TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 6) DOCUMENTS (versioning + access logs) - store in S3 private
-- ============================================================

CREATE TABLE IF NOT EXISTS document_types (
  document_type_code TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS employee_documents (
  document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  document_type_code TEXT NOT NULL REFERENCES document_types(document_type_code),

  current_version INT NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'UPLOADED' CHECK (status IN ('UPLOADED','APPROVED','REJECTED','ARCHIVED')),

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_document_versions (
  doc_version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES employee_documents(document_id) ON DELETE CASCADE,
  version_no INT NOT NULL,

  storage_key_enc TEXT NOT NULL,
  file_hash TEXT,
  mime_type TEXT,
  size_bytes BIGINT,

  uploaded_by UUID REFERENCES users(user_id),
  uploaded_at TIMESTAMP NOT NULL DEFAULT now(),

  UNIQUE (document_id, version_no)
);

CREATE TABLE IF NOT EXISTS document_access_logs (
  access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID REFERENCES employee_documents(document_id) ON DELETE SET NULL,
  doc_version_id UUID REFERENCES employee_document_versions(doc_version_id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('VIEW','DOWNLOAD','SHARE_LINK','REVOKE_LINK')),
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 7) CONSENT + POLICY + RETENTION + LEGAL HOLD + DSAR
-- ============================================================

CREATE TABLE IF NOT EXISTS consents (
  consent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  consent_type TEXT NOT NULL,     -- e.g., PF_GAP_CHECK, CREDIT_CHECK, GLOBAL_SCORE_SHARE
  consent_version TEXT,
  consented_at TIMESTAMP NOT NULL DEFAULT now(),
  consented_by UUID REFERENCES users(user_id),
  revoked_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS data_retention_policies (
  policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE CASCADE, -- null => platform default
  entity_type TEXT NOT NULL,
  retention_days INT NOT NULL CHECK (retention_days > 0),
  delete_mode TEXT NOT NULL CHECK (delete_mode IN ('SOFT','HARD')),
  legal_hold_allowed BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_holds (
  hold_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE CASCADE,

  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,

  reason TEXT NOT NULL,
  start_at TIMESTAMP NOT NULL DEFAULT now(),
  end_at TIMESTAMP,

  created_by UUID REFERENCES users(user_id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- DSAR: Data Subject Access Request (GDPR/DPDP)
CREATE TABLE IF NOT EXISTS dsar_requests (
  dsar_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,

  request_type TEXT NOT NULL CHECK (request_type IN ('EXPORT','DELETE','RECTIFY')),
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','COMPLETED','REJECTED')),
  reason TEXT,
  requested_by UUID REFERENCES users(user_id),
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  completed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dsar_artifacts (
  artifact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dsar_id UUID NOT NULL REFERENCES dsar_requests(dsar_id) ON DELETE CASCADE,
  storage_key_enc TEXT NOT NULL,
  file_hash TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 8) BACKGROUND VERIFICATION (dynamic checks + SLA + rechecks)
-- ============================================================

CREATE TABLE IF NOT EXISTS bv_case_types (
  case_type_code TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS bv_cases (
  case_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  case_type_code TEXT REFERENCES bv_case_types(case_type_code),
  case_reference_no TEXT UNIQUE, -- friendly unique id (optional)

  created_by_hr UUID REFERENCES users(user_id),
  assigned_ops_head UUID REFERENCES users(user_id),

  status TEXT NOT NULL DEFAULT 'SUBMITTED' CHECK (status IN (
    'DRAFT','SUBMITTED','HR_REVIEW','OPS_REVIEW','COMPLETED','CANCELLED'
  )),

  priority TEXT DEFAULT 'MEDIUM' CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),

  sla_due_at TIMESTAMP,           -- case-level SLA
  closed_at TIMESTAMP,

  risk_score NUMERIC(6,2) DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Dynamic checks (admin can add/remove)
CREATE TABLE IF NOT EXISTS bv_check_catalog (
  check_code TEXT PRIMARY KEY,         -- stable unique code
  check_name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  requires_consent BOOLEAN NOT NULL DEFAULT FALSE,
  default_sla_hours INT,
  created_by UUID REFERENCES users(user_id),
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Templates for check input fields (dynamic forms / payload schema)
CREATE TABLE IF NOT EXISTS bv_check_input_templates (
  template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  check_code TEXT NOT NULL REFERENCES bv_check_catalog(check_code) ON DELETE CASCADE,
  schema_json JSONB NOT NULL,           -- json-schema like structure
  version INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (check_code, version)
);

-- Required docs mapping (if needed per check)
CREATE TABLE IF NOT EXISTS bv_check_required_docs (
  req_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  check_code TEXT NOT NULL REFERENCES bv_check_catalog(check_code) ON DELETE CASCADE,
  document_type_code TEXT NOT NULL REFERENCES document_types(document_type_code),
  is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (check_code, document_type_code)
);

CREATE TABLE IF NOT EXISTS bv_case_checks (
  case_check_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,
  check_code TEXT NOT NULL REFERENCES bv_check_catalog(check_code),

  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN (
    'PENDING','RUNNING','SUCCESS','FAILED','NEEDS_REVIEW','SKIPPED'
  )),

  -- SLA per check
  sla_due_at TIMESTAMP,
  escalated_level INT NOT NULL DEFAULT 0,

  started_at TIMESTAMP,
  completed_at TIMESTAMP,

  UNIQUE (case_id, check_code)
);

-- Store input payload actually used (masked/encrypted if includes PII)
CREATE TABLE IF NOT EXISTS bv_case_check_inputs (
  input_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_check_id UUID NOT NULL REFERENCES bv_case_checks(case_check_id) ON DELETE CASCADE,
  template_version INT,
  input_json JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bv_check_results (
  result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_check_id UUID NOT NULL REFERENCES bv_case_checks(case_check_id) ON DELETE CASCADE,

  provider TEXT,
  request_id TEXT,
  result_status TEXT,            -- MATCH/MISMATCH/INCONCLUSIVE
  score NUMERIC(6,2),
  flags JSONB,
  evidence_refs JSONB,

  raw_response_masked JSONB,     -- minimal / masked

  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Reports + versioning
CREATE TABLE IF NOT EXISTS bv_reports (
  report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,
  version_no INT NOT NULL DEFAULT 1,

  generated_by_ops_head UUID REFERENCES users(user_id),
  report_storage_key_enc TEXT NOT NULL,
  file_hash TEXT,
  summary TEXT,

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (case_id, version_no)
);

CREATE TABLE IF NOT EXISTS bv_org_decisions (
  decision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID UNIQUE NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,

  decision TEXT NOT NULL CHECK (decision IN ('PASS','FAIL')),
  decided_by UUID REFERENCES users(user_id),
  decided_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Optional specialized results
CREATE TABLE IF NOT EXISTS pf_gap_analysis (
  pf_gap_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,

  provider TEXT,
  pf_identifier_hash TEXT,
  gap_months INT,
  gap_periods JSONB,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS address_validation_results (
  address_val_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,

  method TEXT NOT NULL,
  provider TEXT,
  status TEXT,
  details JSONB,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS screening_results (
  screening_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,

  watchlists_checked JSONB,
  matches_found BOOLEAN,
  details JSONB,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 9) DISPUTES (BV) + SCORE DISPUTES (new requirement)
-- ============================================================

CREATE TABLE IF NOT EXISTS bv_disputes (
  dispute_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES bv_cases(case_id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  raised_by UUID NOT NULL REFERENCES users(user_id),
  dispute_type TEXT,
  description TEXT NOT NULL,

  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_REVIEW','RESOLVED','REJECTED')),
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dispute_messages (
  message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dispute_id UUID NOT NULL REFERENCES bv_disputes(dispute_id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(user_id),
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dispute_attachments (
  attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dispute_id UUID NOT NULL REFERENCES bv_disputes(dispute_id) ON DELETE CASCADE,
  storage_key_enc TEXT NOT NULL,
  file_hash TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Score dispute (employee can raise dispute about score)
CREATE TABLE IF NOT EXISTS prora_score_disputes (
  score_dispute_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL, -- optional: dispute in context of org
  raised_by UUID NOT NULL REFERENCES users(user_id),

  current_score INT,
  complaint TEXT NOT NULL,
  requested_action TEXT, -- recalculation / correction / explanation

  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_REVIEW','RESOLVED','REJECTED')),
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS prora_score_dispute_messages (
  message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  score_dispute_id UUID NOT NULL REFERENCES prora_score_disputes(score_dispute_id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(user_id),
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS prora_score_dispute_attachments (
  attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  score_dispute_id UUID NOT NULL REFERENCES prora_score_disputes(score_dispute_id) ON DELETE CASCADE,
  storage_key_enc TEXT NOT NULL,
  file_hash TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 10) PRORA SCORE (global + continuous events + explainability + admin override only)
-- ============================================================

CREATE TABLE IF NOT EXISTS model_versions (
  model_version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  model_name TEXT NOT NULL,
  algorithm_type TEXT NOT NULL,       -- xgboost/lightgbm/catboost/logreg
  training_data_ref TEXT,             -- S3 path / dataset id
  metrics JSONB,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DEPRECATED','DISABLED')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Global score per employee (primary truth)
CREATE TABLE IF NOT EXISTS prora_scores_global (
  score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID UNIQUE NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  score_value INT NOT NULL CHECK (score_value >= 0),
  score_band TEXT,
  confidence NUMERIC(5,2),

  reason_codes JSONB,          -- top factors safe for UI
  explanation JSONB,           -- safe explanation (e.g., SHAP summaries)

  model_version_id UUID REFERENCES model_versions(model_version_id),
  calculated_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Org-view score snapshot (optional, can keep same as global or apply org policy)
CREATE TABLE IF NOT EXISTS prora_scores_org (
  score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  score_value INT NOT NULL CHECK (score_value >= 0),
  score_band TEXT,
  confidence NUMERIC(5,2),

  reason_codes JSONB,
  explanation JSONB,

  model_version_id UUID REFERENCES model_versions(model_version_id),
  calculated_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),

  UNIQUE (organization_id, employee_global_id)
);

-- Feature snapshots (event-driven)
CREATE TABLE IF NOT EXISTS feature_snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,

  subject_type TEXT NOT NULL CHECK (subject_type IN ('EMPLOYEE','BV_CASE')),
  subject_id UUID NOT NULL,

  features JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Score events (continuous updates)
CREATE TABLE IF NOT EXISTS prora_score_events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,
  case_id UUID REFERENCES bv_cases(case_id) ON DELETE SET NULL,

  event_type TEXT NOT NULL, -- bv_completed, dispute_resolved, new_employment, etc.
  payload JSONB,

  old_score INT,
  new_score INT,

  model_version_id UUID REFERENCES model_versions(model_version_id),
  triggered_by UUID REFERENCES users(user_id),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Admin override only
CREATE TABLE IF NOT EXISTS prora_score_overrides (
  override_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_global_id UUID NOT NULL REFERENCES employee_global_identity(employee_global_id) ON DELETE CASCADE,

  old_score INT,
  new_score INT NOT NULL CHECK (new_score >= 0),

  reason TEXT NOT NULL,
  overridden_by UUID NOT NULL REFERENCES users(user_id), -- ensure this is ADMIN in app logic
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Inference logs (monitoring + SOC2 evidence)
CREATE TABLE IF NOT EXISTS ml_inference_logs (
  inference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  model_version_id UUID REFERENCES model_versions(model_version_id),
  employee_global_id UUID REFERENCES employee_global_identity(employee_global_id) ON DELETE SET NULL,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,

  request_hash TEXT,
  latency_ms INT,
  status TEXT NOT NULL CHECK (status IN ('SUCCESS','FAIL')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 11) AUDIT + FIELD LEVEL AUDIT + SECURITY EVENTS
-- ============================================================

-- High-level audit log (append-only)
CREATE TABLE IF NOT EXISTS audit_logs (
  audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,

  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,

  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Field-level audit (old/new) for sensitive tables
CREATE TABLE IF NOT EXISTS audit_log_details (
  detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  audit_id UUID NOT NULL REFERENCES audit_logs(audit_id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT
);

CREATE TABLE IF NOT EXISTS security_events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,
  severity TEXT NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  category TEXT NOT NULL, -- auth, anomaly, data_access, policy, malware
  details JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 12) SAAS BILLING (Plans TBD - skeleton)
-- ============================================================

CREATE TABLE IF NOT EXISTS billing_plans (
  plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_code TEXT UNIQUE NOT NULL,
  plan_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','ACTIVE','INACTIVE')),
  config JSONB, -- pricing rules, limits, features (decide later)
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  plan_id UUID REFERENCES billing_plans(plan_id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','PAUSED','CANCELLED')),
  start_at TIMESTAMP NOT NULL DEFAULT now(),
  end_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoices (
  invoice_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(subscription_id) ON DELETE SET NULL,
  invoice_no TEXT UNIQUE,
  currency TEXT DEFAULT 'INR',
  amount_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'DUE' CHECK (status IN ('DUE','PAID','VOID')),
  issued_at TIMESTAMP NOT NULL DEFAULT now(),
  due_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payments (
  payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id UUID REFERENCES invoices(invoice_id) ON DELETE SET NULL,
  organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
  provider TEXT, -- razorpay/stripe/etc
  provider_ref TEXT,
  amount NUMERIC(12,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('INITIATED','SUCCESS','FAILED','REFUNDED')),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- 13) INDEXES (scale)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

CREATE INDEX IF NOT EXISTS idx_org_status ON organizations(status);
CREATE INDEX IF NOT EXISTS idx_org_users_org ON organization_users(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_users_user ON organization_users(user_id);

CREATE INDEX IF NOT EXISTS idx_emp_org ON employees(organization_id);
CREATE INDEX IF NOT EXISTS idx_emp_global ON employees(employee_global_id);

CREATE INDEX IF NOT EXISTS idx_docs_emp ON employee_documents(employee_id);
CREATE INDEX IF NOT EXISTS idx_doc_versions_doc ON employee_document_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_doc_access_time ON document_access_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_bv_cases_org ON bv_cases(organization_id);
CREATE INDEX IF NOT EXISTS idx_bv_cases_emp ON bv_cases(employee_id);
CREATE INDEX IF NOT EXISTS idx_bv_cases_global ON bv_cases(employee_global_id);
CREATE INDEX IF NOT EXISTS idx_bv_cases_status ON bv_cases(status);

CREATE INDEX IF NOT EXISTS idx_case_checks_case ON bv_case_checks(case_id);
CREATE INDEX IF NOT EXISTS idx_case_results_casecheck ON bv_check_results(case_check_id);
CREATE INDEX IF NOT EXISTS idx_bv_reports_case ON bv_reports(case_id);

CREATE INDEX IF NOT EXISTS idx_score_global_emp ON prora_scores_global(employee_global_id);
CREATE INDEX IF NOT EXISTS idx_score_org_emp ON prora_scores_org(organization_id, employee_global_id);
CREATE INDEX IF NOT EXISTS idx_score_events_emp ON prora_score_events(employee_global_id, created_at);

CREATE INDEX IF NOT EXISTS idx_audit_time ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_security_time ON security_events(created_at);

-- ============================================================
-- 14) updated_at trigger (common)
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_updated_at') THEN
    CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_orgs_updated_at') THEN
    CREATE TRIGGER trg_orgs_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_org_users_updated_at') THEN
    CREATE TRIGGER trg_org_users_updated_at BEFORE UPDATE ON organization_users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_emp_global_updated_at') THEN
    CREATE TRIGGER trg_emp_global_updated_at BEFORE UPDATE ON employee_global_identity
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_employees_updated_at') THEN
    CREATE TRIGGER trg_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_bv_cases_updated_at') THEN
    CREATE TRIGGER trg_bv_cases_updated_at BEFORE UPDATE ON bv_cases
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_bv_check_catalog_updated_at') THEN
    CREATE TRIGGER trg_bv_check_catalog_updated_at BEFORE UPDATE ON bv_check_catalog
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_bv_reports_updated_at') THEN
    CREATE TRIGGER trg_bv_reports_updated_at BEFORE UPDATE ON bv_reports
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_score_global_updated_at') THEN
    CREATE TRIGGER trg_score_global_updated_at BEFORE UPDATE ON prora_scores_global
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_score_org_updated_at') THEN
    CREATE TRIGGER trg_score_org_updated_at BEFORE UPDATE ON prora_scores_org
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_bv_disputes_updated_at') THEN
    CREATE TRIGGER trg_bv_disputes_updated_at BEFORE UPDATE ON bv_disputes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_score_disputes_updated_at') THEN
    CREATE TRIGGER trg_score_disputes_updated_at BEFORE UPDATE ON prora_score_disputes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_subscriptions_updated_at') THEN
    CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_billing_plans_updated_at') THEN
    CREATE TRIGGER trg_billing_plans_updated_at BEFORE UPDATE ON billing_plans
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END$$;

-- ============================================================
-- 15) RLS ENABLEMENT (recommended)
-- IMPORTANT:
--   Use app to set `SET LOCAL app.current_org = '<uuid>';`
--   Use separate DB roles for app (no superuser)
-- ============================================================

-- Enable RLS on tenant tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_case_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_case_check_inputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_check_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_org_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pf_gap_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE address_validation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE screening_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE bv_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE prora_scores_org ENABLE ROW LEVEL SECURITY;
ALTER TABLE prora_score_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE prora_score_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE prora_score_dispute_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE prora_score_dispute_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Example RLS policy pattern (org-based)
-- NOTE: You must SET LOCAL app.current_org = '<uuid>' per request.
-- Create policies (repeat similarly for all org-owned tables)
DO $$
BEGIN
  -- organizations: allow read only for current org (and platform admins in app logic)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='organizations' AND policyname='org_isolation_select') THEN
    EXECUTE $p$
      CREATE POLICY org_isolation_select ON organizations
      FOR SELECT
      USING (organization_id::text = current_setting('app.current_org', true))
    $p$;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='employees' AND policyname='employees_org_isolation') THEN
    EXECUTE $p$
      CREATE POLICY employees_org_isolation ON employees
      FOR ALL
      USING (organization_id::text = current_setting('app.current_org', true))
      WITH CHECK (organization_id::text = current_setting('app.current_org', true))
    $p$;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bv_cases' AND policyname='bv_cases_org_isolation') THEN
    EXECUTE $p$
      CREATE POLICY bv_cases_org_isolation ON bv_cases
      FOR ALL
      USING (organization_id::text = current_setting('app.current_org', true))
      WITH CHECK (organization_id::text = current_setting('app.current_org', true))
    $p$;
  END IF;
END$$;

-- ============================================================
-- 16) SEED ROLES (run once)
-- ============================================================

INSERT INTO roles (role_code, role_name)
VALUES
  ('ADMIN','Admin'),
  ('SUB_ADMIN','Sub Admin'),
  ('OPS_HEAD','Operational Head'),
  ('ORG','Organization'),
  ('HR','HR'),
  ('EMPLOYEE','Employee')
ON CONFLICT (role_code) DO NOTHING;
