-- ICT Infrastructure Automation Database Schema (SQLite)
-- Converted from the MySQL schema for Render / sqlite3 deployment.

-- Branches
CREATE TABLE IF NOT EXISTS branches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_name TEXT UNIQUE NOT NULL,
    branch_code TEXT UNIQUE NOT NULL,
    location_address TEXT,
    contact_person TEXT,
    contact_phone TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_branch_code ON branches(branch_code);
CREATE INDEX IF NOT EXISTS idx_branches_active ON branches(is_active);

-- Device Types
CREATE TABLE IF NOT EXISTS device_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_type_name TEXT UNIQUE NOT NULL,
    description TEXT,
    category TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_device_type_name ON device_types(device_type_name);
CREATE INDEX IF NOT EXISTS idx_dt_category ON device_types(category);
CREATE INDEX IF NOT EXISTS idx_dt_active ON device_types(is_active);

-- Hardware Makes
CREATE TABLE IF NOT EXISTS hardware_makes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    make_name TEXT UNIQUE NOT NULL,
    description TEXT,
    website TEXT,
    support_contact TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_make_name ON hardware_makes(make_name);
CREATE INDEX IF NOT EXISTS idx_makes_active ON hardware_makes(is_active);

-- Hardware Models
CREATE TABLE IF NOT EXISTS hardware_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_name TEXT NOT NULL,
    make_id INTEGER NOT NULL,
    device_type_id INTEGER NOT NULL,
    specifications TEXT,
    release_year INTEGER,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (make_id) REFERENCES hardware_makes(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_type_id) REFERENCES device_types(id) ON DELETE RESTRICT,
    UNIQUE (model_name, make_id, device_type_id)
);
CREATE INDEX IF NOT EXISTS idx_model_name ON hardware_models(model_name);
CREATE INDEX IF NOT EXISTS idx_models_make ON hardware_models(make_id);
CREATE INDEX IF NOT EXISTS idx_models_dtype ON hardware_models(device_type_id);
CREATE INDEX IF NOT EXISTS idx_models_active ON hardware_models(is_active);

-- Hardware Status
CREATE TABLE IF NOT EXISTS hardware_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    status_name TEXT UNIQUE NOT NULL,
    description TEXT,
    color_code TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_status_name ON hardware_status(status_name);
CREATE INDEX IF NOT EXISTS idx_status_active ON hardware_status(is_active);

-- Hardware Register
CREATE TABLE IF NOT EXISTS hardware_register (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_tag TEXT UNIQUE NOT NULL,
    branch_id INTEGER,
    device_type_id INTEGER,
    model_id INTEGER,
    serial_number TEXT UNIQUE,
    purchase_date TEXT,
    warranty_expiry TEXT,
    status_id INTEGER,
    location TEXT,
    assigned_to TEXT,
    notes TEXT,
    device_type TEXT,
    make TEXT,
    model TEXT,
    status TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_type_id) REFERENCES device_types(id) ON DELETE RESTRICT,
    FOREIGN KEY (model_id) REFERENCES hardware_models(id) ON DELETE RESTRICT,
    FOREIGN KEY (status_id) REFERENCES hardware_status(id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_hr_asset_tag ON hardware_register(asset_tag);
CREATE INDEX IF NOT EXISTS idx_hr_serial ON hardware_register(serial_number);
CREATE INDEX IF NOT EXISTS idx_hr_branch ON hardware_register(branch_id);
CREATE INDEX IF NOT EXISTS idx_hr_dtype ON hardware_register(device_type_id);
CREATE INDEX IF NOT EXISTS idx_hr_model ON hardware_register(model_id);
CREATE INDEX IF NOT EXISTS idx_hr_status ON hardware_register(status_id);
CREATE INDEX IF NOT EXISTS idx_hr_location ON hardware_register(location);
CREATE INDEX IF NOT EXISTS idx_hr_assigned ON hardware_register(assigned_to);
CREATE INDEX IF NOT EXISTS idx_hr_active ON hardware_register(is_active);

-- Repair Register
CREATE TABLE IF NOT EXISTS repair_register (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hardware_id INTEGER NOT NULL,
    issue_description TEXT NOT NULL,
    reported_by TEXT NOT NULL,
    reported_date TEXT NOT NULL,
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'Pending',
    assigned_to TEXT,
    resolution_details TEXT,
    resolved_date TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_rr_hardware ON repair_register(hardware_id);
CREATE INDEX IF NOT EXISTS idx_rr_status ON repair_register(status);
CREATE INDEX IF NOT EXISTS idx_rr_priority ON repair_register(priority);
CREATE INDEX IF NOT EXISTS idx_rr_reported ON repair_register(reported_date);

-- Asset Movements
CREATE TABLE IF NOT EXISTS asset_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hardware_id INTEGER NOT NULL,
    from_location TEXT NOT NULL,
    to_location TEXT NOT NULL,
    moved_by TEXT NOT NULL,
    move_date TEXT NOT NULL,
    reason TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_am_hardware ON asset_movements(hardware_id);
CREATE INDEX IF NOT EXISTS idx_am_move_date ON asset_movements(move_date);

-- Weekly Tasks
CREATE TABLE IF NOT EXISTS weekly_tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_name TEXT NOT NULL,
    description TEXT,
    assigned_to TEXT NOT NULL,
    due_date TEXT NOT NULL,
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'Pending',
    completion_notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Task Queue
CREATE TABLE IF NOT EXISTS task_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'Queued',
    assigned_to TEXT,
    hardware_id INTEGER,
    estimated_hours REAL,
    actual_hours REAL,
    created_by TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    assigned_at TEXT,
    started_at TEXT,
    completed_at TEXT,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE SET NULL
);

-- Users
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT DEFAULT 'User',
    department TEXT,
    password_hash TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    must_change_password INTEGER DEFAULT 0,
    last_login TEXT,
    phone TEXT,
    specialization TEXT,
    skills TEXT,
    certifications TEXT,
    experience_level TEXT,
    on_call INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Assets (main asset register used by the app)
CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_tag TEXT UNIQUE NOT NULL,
    serial_number TEXT,
    branch_id INTEGER,
    device_type_id INTEGER,
    model_id INTEGER,
    purchase_date TEXT,
    warranty_expiry TEXT,
    status_id INTEGER,
    location TEXT,
    assigned_to TEXT,
    notes TEXT,
    acknowledged_at TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (device_type_id) REFERENCES device_types(id),
    FOREIGN KEY (model_id) REFERENCES hardware_models(id),
    FOREIGN KEY (status_id) REFERENCES hardware_status(id)
);
CREATE INDEX IF NOT EXISTS idx_assets_tag ON assets(asset_tag);
CREATE INDEX IF NOT EXISTS idx_assets_branch ON assets(branch_id);
CREATE INDEX IF NOT EXISTS idx_assets_dtype ON assets(device_type_id);
CREATE INDEX IF NOT EXISTS idx_assets_model ON assets(model_id);
CREATE INDEX IF NOT EXISTS idx_assets_status ON assets(status_id);
CREATE INDEX IF NOT EXISTS idx_assets_location ON assets(location);
CREATE INDEX IF NOT EXISTS idx_assets_active ON assets(is_active);
CREATE INDEX IF NOT EXISTS idx_assets_serial ON assets(serial_number);

-- Fault Reports / Support Tickets
CREATE TABLE IF NOT EXISTS fault_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_number TEXT UNIQUE,
    subject TEXT,
    description TEXT,
    category TEXT DEFAULT 'other',
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'Submitted',
    reported_by TEXT,
    assigned_to TEXT,
    department TEXT,
    asset_tag TEXT,
    resolution_notes TEXT,
    resolved_at TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_fr_ticket ON fault_reports(ticket_number);
CREATE INDEX IF NOT EXISTS idx_fr_status ON fault_reports(status);
CREATE INDEX IF NOT EXISTS idx_fr_reported_by ON fault_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_fr_assigned ON fault_reports(assigned_to);
CREATE INDEX IF NOT EXISTS idx_fr_active ON fault_reports(is_active);
CREATE INDEX IF NOT EXISTS idx_fr_created ON fault_reports(created_at);

-- Repair Forms
CREATE TABLE IF NOT EXISTS repair_forms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch TEXT,
    date_in TEXT,
    received_by TEXT,
    devices TEXT,
    prepared_by_name TEXT,
    prepared_by_signature TEXT,
    prepared_by_date TEXT,
    confirmed_by_name TEXT,
    confirmed_by_signature TEXT,
    confirmed_by_date TEXT,
    comment_by_hod TEXT,
    received_by_hod_name TEXT,
    received_by_hod_signature TEXT,
    received_by_hod_date TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_rf_active ON repair_forms(is_active);
CREATE INDEX IF NOT EXISTS idx_rf_created ON repair_forms(created_at);

-- Issue Notes
CREATE TABLE IF NOT EXISTS issue_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    to_department TEXT,
    from_location TEXT,
    date_in TEXT,
    ref TEXT,
    subject TEXT,
    items TEXT,
    asset_tag TEXT,
    serial_number TEXT,
    issuing_officer TEXT,
    issuing_officer_role TEXT,
    message TEXT,
    received_by_name TEXT,
    received_by_designation TEXT,
    received_by_signature TEXT,
    date_out TEXT,
    status TEXT,
    related_table TEXT,
    related_id INTEGER,
    note_text TEXT,
    created_by TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_in_active ON issue_notes(is_active);
CREATE INDEX IF NOT EXISTS idx_in_created ON issue_notes(created_at);
CREATE INDEX IF NOT EXISTS idx_in_related ON issue_notes(related_table, related_id);

-- Ticket Comments
CREATE TABLE IF NOT EXISTS ticket_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    report_id INTEGER NOT NULL,
    author TEXT NOT NULL,
    author_name TEXT,
    message TEXT NOT NULL,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_tc_report ON ticket_comments(report_id);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT,
    type TEXT DEFAULT 'info',
    is_read INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notif_username ON notifications(username);

-- Password Resets
CREATE TABLE IF NOT EXISTS password_resets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    used INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_pr_token ON password_resets(token);

-- Software
CREATE TABLE IF NOT EXISTS software (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    software_name TEXT NOT NULL,
    software_provider TEXT NOT NULL,
    license_update_date TEXT,
    license_expiry_date TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_software_name ON software(software_name);
CREATE INDEX IF NOT EXISTS idx_software_active ON software(is_active);

-- ===================== Seed Data =====================

INSERT INTO branches (branch_name, branch_code, location_address, contact_person, contact_phone) VALUES
('Head Office', 'HO', '123 Main Street, Nairobi, Kenya', 'John Manager', '+254-712-345-678'),
('IT Department', 'IT', '456 Tech Avenue, Nairobi, Kenya', 'Jane IT', '+254-723-456-789'),
('Finance Department', 'FIN', '789 Finance Road, Nairobi, Kenya', 'Mike Finance', '+254-734-567-890'),
('Reception', 'REC', '321 Reception Lane, Nairobi, Kenya', 'Sarah Reception', '+254-745-678-901');

INSERT INTO device_types (device_type_name, description, category) VALUES
('Laptop', 'Portable computer for mobile work', 'Computer'),
('Desktop', 'Desktop computer for office work', 'Computer'),
('Printer', 'Document printing device', 'Peripheral'),
('Monitor', 'Display screen for computers', 'Peripheral'),
('Server', 'Enterprise server equipment', 'Infrastructure'),
('Router', 'Network routing device', 'Network'),
('Switch', 'Network switching device', 'Network'),
('Scanner', 'Document scanning device', 'Peripheral');

INSERT INTO hardware_makes (make_name, description, website, support_contact) VALUES
('Dell', 'Dell Inc. computer hardware', 'https://www.dell.com', 'support@dell.com'),
('HP', 'Hewlett-Packard computer hardware', 'https://www.hp.com', 'support@hp.com'),
('Canon', 'Canon printing and imaging equipment', 'https://www.canon.com', 'support@canon.com'),
('LG', 'LG Electronics displays and electronics', 'https://www.lg.com', 'support@lg.com'),
('Cisco', 'Cisco networking equipment', 'https://www.cisco.com', 'support@cisco.com'),
('Lenovo', 'Lenovo computer hardware', 'https://www.lenovo.com', 'support@lenovo.com'),
('Epson', 'Epson printing equipment', 'https://www.epson.com', 'support@epson.com'),
('Samsung', 'Samsung electronics and displays', 'https://www.samsung.com', 'support@samsung.com');

INSERT INTO hardware_models (model_name, make_id, device_type_id, specifications, release_year) VALUES
('Latitude 7420', 1, 1, 'Intel Core i7, 16GB RAM, 512GB SSD', 2023),
('EliteDesk 800', 2, 2, 'Intel Core i5, 8GB RAM, 256GB SSD', 2022),
('IR-ADV 4535', 3, 3, 'Multi-function printer, 45ppm, Color', 2021),
('27UL850', 4, 4, '27-inch 4K UHD Monitor, USB-C', 2022),
('ThinkPad X1 Carbon', 6, 1, 'Intel Core i7, 16GB RAM, 1TB SSD', 2023),
('Epson EcoTank L3150', 7, 3, 'Ink Tank Printer, Wireless', 2022),
('Cisco Catalyst 2960', 5, 6, '24-port Gigabit Switch', 2021);

INSERT INTO hardware_status (status_name, description, color_code) VALUES
('Active', 'Device is in use and operational', '#22c55e'),
('Under Repair', 'Device is being repaired', '#f59e0b'),
('Retired', 'Device is no longer in service', '#64748b'),
('Lost', 'Device has been lost', '#ef4444'),
('Disposed', 'Device has been disposed', '#991b1b'),
('In Storage', 'Device is in storage', '#8b5cf6'),
('Pending Assignment', 'Device awaiting assignment', '#06b6d4');

-- password for all seed users: password123 (bcrypt)
INSERT INTO users (username, email, full_name, role, department, password_hash) VALUES
('superadmin', 'superadmin@company.com', 'Super Administrator', 'Super Admin', 'IT', '$2b$12$hTL6544kmDmqFXlKuWWrp.WjQZZhrTsOlDU1kJOKWRCzqNs7wdbUi'),
('admin', 'admin@company.com', 'System Administrator', 'Admin', 'IT', '$2b$12$hTL6544kmDmqFXlKuWWrp.WjQZZhrTsOlDU1kJOKWRCzqNs7wdbUi'),
('jdoe', 'john.doe@company.com', 'John Doe', 'Technician', 'IT', '$2b$12$hTL6544kmDmqFXlKuWWrp.WjQZZhrTsOlDU1kJOKWRCzqNs7wdbUi'),
('jsmith', 'jane.smith@company.com', 'Jane Smith', 'Manager', 'Finance', '$2b$12$hTL6544kmDmqFXlKuWWrp.WjQZZhrTsOlDU1kJOKWRCzqNs7wdbUi');

INSERT INTO hardware_register (asset_tag, branch_id, device_type_id, model_id, serial_number, purchase_date, warranty_expiry, status_id, location, assigned_to, notes) VALUES
('ICT001', 2, 1, 1, 'DL74202023001', '2023-01-15', '2026-01-15', 1, 'IT Office', 'John Doe', 'Primary laptop for IT support'),
('ICT002', 3, 2, 2, 'HPED8002022001', '2022-06-20', '2025-06-20', 1, 'Finance Office', 'Jane Smith', 'Finance department desktop'),
('ICT003', 4, 3, 3, 'CN45352021001', '2021-03-10', '2024-03-10', 2, 'Reception', NULL, 'Main reception printer - under repair'),
('ICT004', 1, 4, 4, 'LG27UL8502022001', '2022-11-05', '2025-11-05', 1, 'Conference Room', NULL, 'Conference room monitor'),
('ICT005', 2, 1, 5, 'TPX1C2023002', '2023-03-01', '2026-03-01', 1, 'IT Office', 'Jane IT', 'IT manager laptop'),
('ICT006', 3, 3, 6, 'EPL3150202201', '2022-08-15', '2025-08-15', 1, 'Finance Office', 'Mike Finance', 'Finance department backup printer');

INSERT INTO assets (asset_tag, serial_number, branch_id, device_type_id, model_id, status_id, location, assigned_to, notes, is_active) VALUES
('ICT001', 'DL74202023001', 2, 1, 1, 1, 'IT Office', 'John Doe', 'Primary laptop for IT support', 1),
('ICT002', 'HPED8002022001', 3, 2, 2, 1, 'Finance Office', 'Jane Smith', 'Finance department desktop', 1),
('ICT003', 'CN45352021001', 4, 3, 3, 2, 'Reception', NULL, 'Main reception printer - under repair', 1),
('ICT004', 'LG27UL8502022001', 1, 4, 4, 1, 'Conference Room', NULL, 'Conference room monitor', 1),
('ICT005', 'TPX1C2023002', 2, 1, 5, 1, 'IT Office', 'Jane IT', 'IT manager laptop', 1),
('ICT006', 'EPL3150202201', 3, 3, 6, 1, 'Finance Office', 'Mike Finance', 'Finance department backup printer', 1);

INSERT INTO software (software_name, software_provider, license_update_date, license_expiry_date, is_active) VALUES
('BR Net', 'Craft Silicon', '2024-01-15', '2025-01-15', 1),
('FITNES', 'FITNES Corp', '2024-02-20', '2025-02-20', 1),
('Perpay', 'Perpay Solutions', '2024-03-10', '2025-03-10', 1),
('SOPHOS', 'Sophos Ltd', '2024-04-05', '2025-04-05', 1),
('Zimbra', 'Zimbra Inc', '2024-05-12', '2025-05-12', 1),
('GP', 'Microsoft Dynamics', '2024-06-18', '2025-06-18', 1),
('Kaspersky', 'Kaspersky Lab', '2024-07-22', '2025-07-22', 1);
