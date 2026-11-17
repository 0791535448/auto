-- ICT Infrastructure Automation Database Schema (MySQL/TiDB)
-- Mirrors schema_sqlite.sql for the TiDB Serverless deployment.

CREATE TABLE IF NOT EXISTS branches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100) UNIQUE NOT NULL,
    branch_code VARCHAR(20) UNIQUE NOT NULL,
    location_address TEXT,
    contact_person VARCHAR(255),
    contact_phone VARCHAR(20),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hardware_makes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    make_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    website VARCHAR(255),
    support_contact VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hardware_models (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    make_id INT NOT NULL,
    device_type_id INT NOT NULL,
    specifications TEXT,
    release_year INT,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (make_id) REFERENCES hardware_makes(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_type_id) REFERENCES device_types(id) ON DELETE RESTRICT,
    UNIQUE KEY unique_model (model_name, make_id, device_type_id)
);

CREATE TABLE IF NOT EXISTS hardware_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    color_code VARCHAR(7),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hardware_register (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(50) UNIQUE NOT NULL,
    branch_id INT,
    device_type_id INT,
    model_id INT,
    serial_number VARCHAR(100) UNIQUE,
    purchase_date DATE,
    warranty_expiry DATE,
    status_id INT,
    location VARCHAR(255),
    assigned_to VARCHAR(255),
    notes TEXT,
    device_type VARCHAR(100),
    make VARCHAR(100),
    model VARCHAR(100),
    status VARCHAR(50),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_type_id) REFERENCES device_types(id) ON DELETE RESTRICT,
    FOREIGN KEY (model_id) REFERENCES hardware_models(id) ON DELETE RESTRICT,
    FOREIGN KEY (status_id) REFERENCES hardware_status(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS repair_register (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hardware_id INT NOT NULL,
    issue_description TEXT NOT NULL,
    reported_by VARCHAR(255) NOT NULL,
    reported_date DATE NOT NULL,
    priority VARCHAR(20) DEFAULT 'Medium',
    status VARCHAR(20) DEFAULT 'Pending',
    assigned_to VARCHAR(255),
    resolution_details TEXT,
    resolved_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS asset_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hardware_id INT NOT NULL,
    from_location VARCHAR(255) NOT NULL,
    to_location VARCHAR(255) NOT NULL,
    moved_by VARCHAR(255) NOT NULL,
    move_date DATE NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS weekly_tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to VARCHAR(255) NOT NULL,
    due_date DATE NOT NULL,
    priority VARCHAR(20) DEFAULT 'Medium',
    status VARCHAR(20) DEFAULT 'Pending',
    completion_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_type VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'Medium',
    status VARCHAR(20) DEFAULT 'Queued',
    assigned_to VARCHAR(255),
    hardware_id INT,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (hardware_id) REFERENCES hardware_register(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'User',
    department VARCHAR(100),
    password_hash VARCHAR(255) NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    must_change_password TINYINT(1) DEFAULT 0,
    last_login DATETIME NULL,
    phone VARCHAR(50),
    specialization VARCHAR(255),
    skills TEXT,
    certifications TEXT,
    experience_level VARCHAR(50),
    on_call TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(50) UNIQUE NOT NULL,
    serial_number VARCHAR(100),
    branch_id INT,
    device_type_id INT,
    model_id INT,
    purchase_date DATE,
    warranty_expiry DATE,
    status_id INT,
    location VARCHAR(255),
    assigned_to VARCHAR(255),
    notes TEXT,
    acknowledged_at DATETIME NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (device_type_id) REFERENCES device_types(id),
    FOREIGN KEY (model_id) REFERENCES hardware_models(id),
    FOREIGN KEY (status_id) REFERENCES hardware_status(id)
);

CREATE TABLE IF NOT EXISTS fault_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_number VARCHAR(50) UNIQUE,
    subject VARCHAR(255),
    description TEXT,
    category VARCHAR(50) DEFAULT 'other',
    priority VARCHAR(20) DEFAULT 'Medium',
    status VARCHAR(50) DEFAULT 'Submitted',
    reported_by VARCHAR(255),
    assigned_to VARCHAR(255),
    department VARCHAR(100),
    asset_tag VARCHAR(50),
    resolution_notes TEXT,
    resolved_at DATETIME NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS repair_forms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    branch VARCHAR(255),
    date_in DATE NULL,
    received_by VARCHAR(255),
    devices TEXT,
    prepared_by_name VARCHAR(255),
    prepared_by_signature TEXT,
    prepared_by_date DATE NULL,
    confirmed_by_name VARCHAR(255),
    confirmed_by_signature TEXT,
    confirmed_by_date DATE NULL,
    comment_by_hod TEXT,
    received_by_hod_name VARCHAR(255),
    received_by_hod_signature TEXT,
    received_by_hod_date DATE NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issue_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    to_department VARCHAR(255),
    from_location VARCHAR(255),
    date_in DATE NULL,
    ref VARCHAR(100),
    subject VARCHAR(255),
    items TEXT,
    asset_tag VARCHAR(50),
    serial_number VARCHAR(100),
    issuing_officer VARCHAR(255),
    issuing_officer_role VARCHAR(255),
    message TEXT,
    received_by_name VARCHAR(255),
    received_by_designation VARCHAR(255),
    received_by_signature TEXT,
    date_out DATE NULL,
    status VARCHAR(50),
    related_table VARCHAR(50),
    related_id INT,
    note_text TEXT,
    created_by VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ticket_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_id INT NOT NULL,
    author VARCHAR(255) NOT NULL,
    author_name VARCHAR(255),
    message TEXT NOT NULL,
    archived TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tc_report (report_id)
);

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_username (username)
);

CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    token VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    used TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pr_token (token)
);

CREATE TABLE IF NOT EXISTS software (
    id INT AUTO_INCREMENT PRIMARY KEY,
    software_name VARCHAR(255) NOT NULL,
    software_provider VARCHAR(255) NOT NULL,
    license_update_date DATE,
    license_expiry_date DATE,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

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
