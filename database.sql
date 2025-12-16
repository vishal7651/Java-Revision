CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- USERS (ALL LOGIN USERS)
-- =========================
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (
        role IN (
            'ADMIN',
            'SUB_ADMIN',
            'OPS_HEAD',
            'OPS_GROUND',
            'ORG',
            'HR',
            'EMPLOYEE'
        )
    ),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- ORGANIZATIONS
-- =========================
CREATE TABLE organizations (
    organization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name VARCHAR(255),
    trade_name VARCHAR(255),
    company_email VARCHAR(255),
    company_phone VARCHAR(20),
    industry_type VARCHAR(100),
    company_size VARCHAR(50),
    registration_number VARCHAR(100),
    gst_number VARCHAR(50),
    cin_number VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20),
    contact_person_name VARCHAR(150),
    contact_person_email VARCHAR(255),
    contact_person_mobile VARCHAR(20),
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- ORGANIZATION USERS (ORG + HR)
-- =========================
CREATE TABLE organization_users (
    org_user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(organization_id),
    user_id UUID REFERENCES users(user_id),
    role VARCHAR(20) CHECK (role IN ('ORG','HR')),
    designation VARCHAR(100),
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- EMPLOYEES
-- =========================
CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(organization_id),
    user_id UUID UNIQUE REFERENCES users(user_id),
    employee_code VARCHAR(50),
    designation VARCHAR(100),
    department VARCHAR(100),
    joining_date DATE,
    employment_type VARCHAR(50),
    verification_status VARCHAR(30) DEFAULT 'NOT_SUBMITTED',
    final_decision VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- OPERATIONAL HEADS
-- =========================
CREATE TABLE operational_heads (
    ops_head_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    department VARCHAR(100),
    assigned_region VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- OPERATIONAL GROUND STAFF
-- =========================
CREATE TABLE operational_ground (
    ops_ground_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    assigned_region VARCHAR(100),
    geo_tracking_enabled BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- VERIFICATION REQUESTS
-- =========================
CREATE TABLE verification_requests (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES employees(employee_id),
    assigned_ops_head_id UUID REFERENCES users(user_id),
    assigned_ops_ground_id UUID REFERENCES users(user_id),
    requires_manual_verification BOOLEAN DEFAULT FALSE,
    current_stage VARCHAR(30),
    status VARCHAR(30),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- MANUAL VERIFICATION (GROUND)
-- =========================
CREATE TABLE manual_verifications (
    manual_verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verification_requests(verification_id),
    ops_ground_id UUID REFERENCES users(user_id),
    visit_date DATE,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    geo_fence_status VARCHAR(20),
    address_verified BOOLEAN,
    neighbor_confirmation BOOLEAN,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- VERIFICATION REPORTS
-- =========================
CREATE TABLE verification_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verification_requests(verification_id),
    ops_head_id UUID REFERENCES users(user_id),
    includes_manual_verification BOOLEAN,
    remarks TEXT,
    report_file_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- ORGANIZATION FINAL DECISION
-- =========================
CREATE TABLE organization_decisions (
    decision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verification_requests(verification_id),
    organization_id UUID REFERENCES organizations(organization_id),
    decision VARCHAR(20),
    decision_by UUID REFERENCES users(user_id),
    decision_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- AUDIT LOGS
-- =========================
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    role VARCHAR(30),
    action TEXT,
    entity_type VARCHAR(100),
    entity_id UUID,
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
