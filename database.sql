-- ================================
-- EXTENSIONS
-- ================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================
-- USERS (ALL LOGIN ACCOUNTS)
-- ================================
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (
        role IN ('ADMIN','OPS_HEAD','ORG','HR','EMPLOYEE')
    ),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (
        status IN ('ACTIVE','SUSPENDED','DELETED')
    ),
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- ORGANIZATIONS
-- ================================
CREATE TABLE organizations (
    organization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255),
    company_email VARCHAR(255) UNIQUE NOT NULL,
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
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING','ACTIVE','BLOCKED')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- ORGANIZATION USERS (ORG + HR)
-- ================================
CREATE TABLE organization_users (
    org_user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(organization_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    role VARCHAR(20) NOT NULL CHECK (role IN ('ORG','HR')),
    designation VARCHAR(100),
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, user_id)
);

-- ================================
-- EMPLOYEES
-- ================================
CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(organization_id),
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id),
    employee_code VARCHAR(50),
    designation VARCHAR(100),
    department VARCHAR(100),
    joining_date DATE,
    employment_type VARCHAR(50),
    verification_status VARCHAR(30) DEFAULT 'NOT_SUBMITTED' CHECK (
        verification_status IN (
            'NOT_SUBMITTED','SUBMITTED','IN_VERIFICATION','COMPLETED'
        )
    ),
    final_decision VARCHAR(20) DEFAULT 'PENDING' CHECK (
        final_decision IN ('PASS','FAIL','PENDING')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- EMPLOYEE PERSONAL DETAILS
-- ================================
CREATE TABLE employee_personal_details (
    employee_id UUID PRIMARY KEY REFERENCES employees(employee_id),
    first_name VARCHAR(100),
    middle_name VARCHAR(100),
    last_name VARCHAR(100),
    dob DATE,
    gender VARCHAR(20),
    mobile VARCHAR(20),
    personal_email VARCHAR(255)
);

-- ================================
-- EMPLOYEE ADDRESS DETAILS
-- ================================
CREATE TABLE employee_address_details (
    employee_id UUID PRIMARY KEY REFERENCES employees(employee_id),
    current_address TEXT,
    permanent_address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20)
);

-- ================================
-- EMPLOYEE IDENTITY DETAILS (ENCRYPTED DATA)
-- ================================
CREATE TABLE employee_identity_details (
    employee_id UUID PRIMARY KEY REFERENCES employees(employee_id),
    aadhaar_encrypted TEXT,
    pan_encrypted TEXT,
    passport_encrypted TEXT,
    driving_license_encrypted TEXT
);

-- ================================
-- DOCUMENTS
-- ================================
CREATE TABLE documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES employees(employee_id),
    document_type VARCHAR(100),
    encrypted_file_path TEXT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- VERIFICATION REQUESTS
-- ================================
CREATE TABLE verification_requests (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(employee_id),
    submitted_by UUID REFERENCES users(user_id),
    assigned_ops_head_id UUID REFERENCES users(user_id),
    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING','IN_PROGRESS','VERIFIED')
    ),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- VERIFICATION REPORTS
-- ================================
CREATE TABLE verification_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID NOT NULL REFERENCES verification_requests(verification_id),
    ops_head_id UUID NOT NULL REFERENCES users(user_id),
    report_file_path TEXT NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- ORGANIZATION FINAL DECISION
-- ================================
CREATE TABLE organization_decisions (
    decision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID NOT NULL REFERENCES verification_requests(verification_id),
    organization_id UUID NOT NULL REFERENCES organizations(organization_id),
    decision VARCHAR(20) CHECK (decision IN ('PASS','FAIL')),
    decision_by UUID REFERENCES users(user_id),
    decision_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- AUDIT LOGS (LEGAL & SECURITY)
-- ================================
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    role VARCHAR(30),
    action VARCHAR(255),
    entity_type VARCHAR(100),
    entity_id UUID,
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
