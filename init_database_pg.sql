-- =============================================
-- 智慧停車場車輛管理系統 (HSPMS) - PostgreSQL 版本
-- 專用於 Railway PostgreSQL 資料庫初始化腳本 (DDL & Initial Seed Data)
-- =============================================

-- 依序清除舊表 (避免外鍵約束衝突)
DROP TABLE IF EXISTS ParkingInspectionLogs CASCADE;
DROP TABLE IF EXISTS InspectionLogs CASCADE;
DROP TABLE IF EXISTS ParkingEmployeeApplications CASCADE;
DROP TABLE IF EXISTS EmployeeApplications CASCADE;
DROP TABLE IF EXISTS ParkingPermits CASCADE;
DROP TABLE IF EXISTS Permits CASCADE;
DROP TABLE IF EXISTS ParkingZones CASCADE;
DROP TABLE IF EXISTS ParkingDepartments CASCADE;
DROP TABLE IF EXISTS Departments CASCADE;
DROP TABLE IF EXISTS ParkingSystemAdmins CASCADE;
DROP TABLE IF EXISTS SystemAdmins CASCADE;

-- 1. 部門類別字典檔
CREATE TABLE ParkingDepartments (
    DeptID SERIAL PRIMARY KEY,
    DeptCode VARCHAR(20) NOT NULL UNIQUE,
    DeptName VARCHAR(50) NOT NULL,
    QuotaLimit INT NOT NULL DEFAULT 0,
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. 停車區域類別字典檔
CREATE TABLE ParkingZones (
    ZoneID SERIAL PRIMARY KEY,
    ZoneCode VARCHAR(10) NOT NULL UNIQUE,
    ZoneName VARCHAR(50) NOT NULL,
    TotalCapacity INT NOT NULL DEFAULT 0,
    WarningThresholdPct INT NOT NULL DEFAULT 85,
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. 車輛通行證主檔
CREATE TABLE ParkingPermits (
    PermitID SERIAL PRIMARY KEY,
    PermitNumber VARCHAR(30) NOT NULL UNIQUE,
    DeptID INT NOT NULL REFERENCES ParkingDepartments(DeptID),
    CardNumber VARCHAR(50) NULL,
    OwnerName VARCHAR(50) NOT NULL,
    SensorTagNumber VARCHAR(50) NULL,
    RemoteControllerNo VARCHAR(50) NULL,
    VehicleColor VARCHAR(20) NOT NULL,
    LicensePlate VARCHAR(15) NOT NULL,
    CleanPlate VARCHAR(15) GENERATED ALWAYS AS (REPLACE(REPLACE(UPPER(LicensePlate), '-', ''), ' ', '')) STORED,
    VehicleBrand VARCHAR(30) NOT NULL,
    ZoneID INT NOT NULL REFERENCES ParkingZones(ZoneID),
    RegisterDate DATE NOT NULL DEFAULT CURRENT_DATE,
    StartDate DATE NOT NULL,
    ExpireDate DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    Remarks VARCHAR(255) NULL,
    UpdatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CK_ParkingPermit_DateRange CHECK (ExpireDate >= StartDate)
);

-- 索引優化
CREATE INDEX IX_ParkingPermits_LicensePlate ON ParkingPermits(LicensePlate);
CREATE INDEX IX_ParkingPermits_CleanPlate ON ParkingPermits(CleanPlate);
CREATE INDEX IX_ParkingPermits_CardNumber ON ParkingPermits(CardNumber);
CREATE INDEX IX_ParkingPermits_Zone_Status ON ParkingPermits(ZoneID, Status);
CREATE INDEX IX_ParkingPermits_Dept ON ParkingPermits(DeptID);

-- 4. 員工線上申請主檔
CREATE TABLE ParkingEmployeeApplications (
    ApplicationID SERIAL PRIMARY KEY,
    ApplicationNo VARCHAR(30) NOT NULL UNIQUE,
    EmpNo VARCHAR(20) NOT NULL,
    ApplicantName VARCHAR(50) NOT NULL,
    DeptID INT NOT NULL REFERENCES ParkingDepartments(DeptID),
    ContactPhone VARCHAR(20) NULL,
    LicensePlate VARCHAR(15) NOT NULL,
    VehicleBrand VARCHAR(30) NOT NULL,
    VehicleColor VARCHAR(20) NOT NULL,
    PreferredZoneID INT NOT NULL REFERENCES ParkingZones(ZoneID),
    AssignedZoneID INT NULL REFERENCES ParkingZones(ZoneID),
    ApplyDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ReviewStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    ReviewerName VARCHAR(50) NULL,
    ReviewDate TIMESTAMP NULL,
    RejectReason VARCHAR(200) NULL,
    ReviewRemarks VARCHAR(200) NULL
);

-- 5. 現場巡檢查核紀錄檔
CREATE TABLE ParkingInspectionLogs (
    LogID BIGSERIAL PRIMARY KEY,
    InspectTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    InspectorAccount VARCHAR(50) NOT NULL,
    ZoneID INT NOT NULL REFERENCES ParkingZones(ZoneID),
    PlateScanned VARCHAR(15) NOT NULL,
    PermitID INT NULL REFERENCES ParkingPermits(PermitID),
    ResultStatus VARCHAR(20) NOT NULL,
    PhotoPath VARCHAR(255) NULL,
    Remark VARCHAR(200) NULL
);

-- 6. 系統管理員與巡檢人員資料表
CREATE TABLE ParkingSystemAdmins (
    AdminID SERIAL PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(100) NOT NULL,
    DisplayName VARCHAR(50) NOT NULL,
    Role VARCHAR(30) NOT NULL,
    RoleName VARCHAR(50) NOT NULL,
    DeptName VARCHAR(50) NOT NULL,
    ContactPhone VARCHAR(30) NULL,
    Email VARCHAR(100) NULL,
    LastLoginTime TIMESTAMP NULL,
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Remarks VARCHAR(200) NULL
);

-- =============================================
-- 初始基礎字典檔資料 (Seed Data)
-- =============================================

INSERT INTO ParkingDepartments (DeptCode, DeptName, QuotaLimit, IsActive) VALUES
('CARDIO', '心臟超音波室', 45, TRUE),
('PED',    '婦兒科部',     50, TRUE),
('DENT',   '牙科醫療部',   30, TRUE),
('ER',     '急診醫學科',   60, TRUE),
('RAD',    '影像醫學部',   35, TRUE),
('SURG',   '一般外科部',   40, TRUE),
('NURSE',  '護理部',       80, TRUE),
('GA',     '總務行政處',   25, TRUE);

INSERT INTO ParkingZones (ZoneCode, ZoneName, TotalCapacity, WarningThresholdPct, IsActive) VALUES
('A', '地下A區 (醫療大樓地下室/主管醫師)', 100, 85, TRUE),
('B', '露天B區 (急診室旁/全日醫護)',       150, 85, TRUE),
('C', '第三立體C區 (全院同仁/綜合車位)',   250, 85, TRUE);

-- 通行證測試假資料
INSERT INTO ParkingPermits (PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber, RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand, ZoneID, RegisterDate, StartDate, ExpireDate, Status, Remarks) VALUES
('PRK-202610-001', 1, 'EMP1001', '李建榮 醫師', 'TAG-8801', 'RC-101', '珍珠白', 'ABC-1234', 'Toyota Camry', 1, '2026-01-01', '2026-01-01', '2027-12-31', 'ACTIVE', '心臟內科主治醫師專用'),
('PRK-202610-002', 2, 'EMP1002', '林淑敏 護理長', 'TAG-8802', 'RC-102', '星燦灰', '5678-EF', 'Honda CR-V',   2, '2026-02-15', '2026-02-15', '2026-11-05', 'ACTIVE', '兒科加護病房輪值 (即將到期)'),
('PRK-202610-003', 3, 'EMP1003', '張志偉 技師', 'TAG-8803', NULL,      '曜石黑', '9876-AA', 'Nissan Kicks',  3, '2025-09-01', '2025-09-01', '2026-09-30', 'EXPIRED', '證件已過期，待展期手續'),
('PRK-202610-004', 4, 'EMP1004', '陳明德 醫師', 'TAG-8804', 'RC-104', '極光銀', 'BAG-9988', 'Lexus RX300',   1, '2026-03-01', '2026-03-01', '2027-02-28', 'ACTIVE', '急診重症專任醫師'),
('PRK-202610-005', 7, 'EMP1005', '黃雅婷 護理師', 'TAG-8805', NULL,      '冰鑽藍', '8888-QQ', 'Mazda 3',       2, '2026-04-10', '2026-04-10', '2027-04-09', 'ACTIVE', '急診夜班輪值護理'),
('PRK-202610-006', 5, 'EMP1006', '吳孟勳 放射師', 'TAG-8806', 'RC-106', '雲河灰', 'KEA-2468', 'Ford Focus',    3, '2026-05-01', '2026-05-01', '2027-04-30', 'ACTIVE', 'CT/MRI 放射檢查室'),
('PRK-202610-007', 8, 'EMP1007', '鄭富元 專員', 'TAG-8807', 'RC-107', '雪貂白', '7777-TX', 'Tesla Model Y', 1, '2026-01-10', '2026-01-10', '2027-01-09', 'ACTIVE', '總務行政車輛 (充電樁優先)'),
('PRK-202610-008', 6, 'EMP1008', '蘇文彬 醫師', 'TAG-8808', 'RC-108', '琥珀金', 'RAC-3579', 'BMW 520i',      1, '2026-06-15', '2026-06-15', '2027-06-14', 'ACTIVE', '神經外科主治醫師'),
('PRK-202610-009', 2, 'EMP1009', '劉美惠 醫師', 'TAG-8809', 'RC-109', '寶石紅', '5566-HN', 'Volvo XC60',    2, '2026-02-01', '2026-02-01', '2026-10-31', 'ACTIVE', '婦產科門診 (即將到期)'),
('PRK-202610-010', 1, 'EMP1010', '柯子揚 技術員', 'TAG-8810', NULL,     '石墨黑', '9911-ZZ', 'Toyota Altis',  3, '2025-08-01', '2025-08-01', '2026-08-01', 'EXPIRED', '逾期未繳管理費已註銷停權');

-- 員工申請主檔測試資料
INSERT INTO ParkingEmployeeApplications (ApplicationNo, EmpNo, ApplicantName, DeptID, ContactPhone, LicensePlate, VehicleBrand, VehicleColor, PreferredZoneID, ApplyDate, ReviewStatus, ReviewerName, ReviewDate, RejectReason) VALUES
('APP-20261017-001', 'EMP2001', '王大明', 1, '分機 3211', 'BPK-8899', 'Toyota RAV4',  '極光銀', 1, '2026-10-17 08:30:00', 'PENDING', NULL, NULL, NULL),
('APP-20261017-002', 'EMP2002', '蔡佳玲', 2, '分機 3105', 'ABC-5678',  'Honda Fit',    '珍珠白', 2, '2026-10-17 09:15:00', 'PENDING', NULL, NULL, NULL),
('APP-20261016-003', 'EMP2003', '趙重光', 4, '0912-345678', 'EAA-1234', 'Nissan Sentra', '曜石黑', 2, '2026-10-16 14:20:00', 'APPROVED', '總務行政處 陳專員', '2026-10-16 16:30:00', NULL),
('APP-20261015-004', 'EMP2004', '周曉菁', 7, '分機 5520', '3344-ZZ',  'Mazda CX-5',   '鋼鐵灰', 3, '2026-10-15 10:00:00', 'REJECTED', '總務行政處 陳專員', '2026-10-15 11:30:00', '車籍資料照片模糊，且該部門本季車位配額已達飽和上限。'),
('APP-20261014-005', 'EMP2005', '許銘倫', 6, '分機 6108', 'BAM-7722', 'Ford Kuga',    '烈焰紅', 1, '2026-10-14 16:45:00', 'COMPLETED', '總務行政處 陳專員', '2026-10-15 09:00:00', NULL);

-- 現場巡檢稽核紀錄測試資料
INSERT INTO ParkingInspectionLogs (InspectTime, InspectorAccount, ZoneID, PlateScanned, PermitID, ResultStatus, PhotoPath, Remark) VALUES
(CURRENT_TIMESTAMP - INTERVAL '120 minutes', 'SEC_DUTY01', 1, 'ABC1234',  1,    'VALID',      NULL, '例行地下A區巡檢，授權資格正常'),
(CURRENT_TIMESTAMP - INTERVAL '95 minutes',  'SEC_DUTY01', 1, '5678EF',   2,    'WRONG_ZONE', '/Uploads/wrong_zone_5678EF.jpg', '該車授權區域為B區，違規跨區停放於地下A區VIP格位'),
(CURRENT_TIMESTAMP - INTERVAL '60 minutes',  'SEC_DUTY02', 3, '9876AA',   3,    'EXPIRED',    '/Uploads/expired_9876AA.jpg',    '車輛通行證已於9月底過期未展期'),
(CURRENT_TIMESTAMP - INTERVAL '30 minutes',  'SEC_DUTY02', 2, 'XYZ9999',  NULL, 'NOT_FOUND',  '/Uploads/unknown_XYZ9999.jpg',  '全院查無此車登記紀錄，已於前擋夾置臨停警告通知單'),
(CURRENT_TIMESTAMP - INTERVAL '10 minutes',  'SEC_DUTY01', 2, '8888QQ',   5,    'VALID',      NULL, '夜班醫護車輛停放正常');

-- 系統管理員與巡檢人員資料表
INSERT INTO ParkingSystemAdmins (Username, Password, DisplayName, Role, RoleName, DeptName, ContactPhone, LastLoginTime, Remarks) VALUES
('admin', 'admin123', '陳專員 (總務管理員)', 'SUPER_ADMIN', '總務行政主管', '總務行政處', '分機 3100', CURRENT_TIMESTAMP, '系統最高管理權限'),
('security01', 'sec123', '李警衛 (現場查核隊)', 'SECURITY', '現場巡檢警衛', '安全警衛課', '分機 1199', CURRENT_TIMESTAMP, '行動巡查專用帳號');

