-- =============================================
-- 智慧停車場車輛管理系統 (HospitalParkingDB)
-- 資料庫與資料表建置腳本 (DDL & Initial Seed Data)
-- =============================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'HospitalParkingDB')
BEGIN
    ALTER DATABASE HospitalParkingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HospitalParkingDB;
END
GO

CREATE DATABASE HospitalParkingDB;
GO

USE HospitalParkingDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 依序清除舊表與新表 (避免外鍵約束衝突)
IF OBJECT_ID('dbo.ParkingInspectionLogs', 'U') IS NOT NULL DROP TABLE dbo.ParkingInspectionLogs;
IF OBJECT_ID('dbo.InspectionLogs', 'U') IS NOT NULL DROP TABLE dbo.InspectionLogs;
IF OBJECT_ID('dbo.ParkingEmployeeApplications', 'U') IS NOT NULL DROP TABLE dbo.ParkingEmployeeApplications;
IF OBJECT_ID('dbo.EmployeeApplications', 'U') IS NOT NULL DROP TABLE dbo.EmployeeApplications;
IF OBJECT_ID('dbo.ParkingPermits', 'U') IS NOT NULL DROP TABLE dbo.ParkingPermits;
IF OBJECT_ID('dbo.Permits', 'U') IS NOT NULL DROP TABLE dbo.Permits;
IF OBJECT_ID('dbo.ParkingZones', 'U') IS NOT NULL DROP TABLE dbo.ParkingZones;
IF OBJECT_ID('dbo.ParkingDepartments', 'U') IS NOT NULL DROP TABLE dbo.ParkingDepartments;
IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL DROP TABLE dbo.Departments;
IF OBJECT_ID('dbo.ParkingSystemAdmins', 'U') IS NOT NULL DROP TABLE dbo.ParkingSystemAdmins;
IF OBJECT_ID('dbo.SystemAdmins', 'U') IS NOT NULL DROP TABLE dbo.SystemAdmins;
GO

-- 1. 部門類別字典檔
CREATE TABLE ParkingDepartments (
    DeptID INT IDENTITY(1,1) PRIMARY KEY,
    DeptCode NVARCHAR(20) NOT NULL UNIQUE,       -- 如: CARDIO, PED, DENT
    DeptName NVARCHAR(50) NOT NULL,              -- 如: 心臟超音波室、婦兒科、牙科
    QuotaLimit INT NOT NULL DEFAULT 0,           -- 該部門分配總車位上限
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- 2. 停車區域類別字典檔 (保留 ParkingZones，不重複加 Parking)
CREATE TABLE ParkingZones (
    ZoneID INT IDENTITY(1,1) PRIMARY KEY,
    ZoneCode NVARCHAR(10) NOT NULL UNIQUE,       -- 如: A, B, C
    ZoneName NVARCHAR(50) NOT NULL,              -- 如: 地下A區(行政主管/醫師)、露天B區(全日醫護)
    TotalCapacity INT NOT NULL DEFAULT 0,        -- 總格位數
    WarningThresholdPct INT NOT NULL DEFAULT 85, -- 飽和告警百分比 (預設 85%)
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- 3. 車輛通行證主檔 (完整包含 13 個核心欄位與狀態)
CREATE TABLE ParkingPermits (
    PermitID INT IDENTITY(1,1) PRIMARY KEY,
    PermitNumber NVARCHAR(30) NOT NULL UNIQUE,   -- 停車證號 (例: PRK-202610-001)
    DeptID INT NOT NULL FOREIGN KEY REFERENCES ParkingDepartments(DeptID), -- 部門
    CardNumber NVARCHAR(50) NULL,                -- 卡號 (工號或識別卡號)
    OwnerName NVARCHAR(50) NOT NULL,             -- 姓名
    SensorTagNumber NVARCHAR(50) NULL,           -- 感應卡 (RFID/eTag 卡號)
    RemoteControllerNo NVARCHAR(50) NULL,        -- 遙控器編號
    VehicleColor NVARCHAR(20) NOT NULL,          -- 車輛顏色
    LicensePlate NVARCHAR(15) NOT NULL,          -- 車牌號碼 (正規化大寫無特殊符號)
    CleanPlate AS CAST(REPLACE(REPLACE(UPPER(LicensePlate), '-', ''), ' ', '') AS NVARCHAR(15)) PERSISTED, -- 去除符號正規化計算欄位
    VehicleBrand NVARCHAR(30) NOT NULL,          -- 車輛廠牌 (Toyota, Honda...)
    ZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID), -- 停車區域
    RegisterDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),      -- 登記日期
    StartDate DATE NOT NULL,                     -- 開始日期
    ExpireDate DATE NOT NULL,                    -- 停車日期 / 到期日期
    Status NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE(有效), EXPIRED(過期), REVOKED(註銷)
    Remarks NVARCHAR(255) NULL,
    UpdatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_ParkingPermit_DateRange CHECK (ExpireDate >= StartDate)
);

-- 索引優化：巡檢與查詢高頻索引
CREATE NONCLUSTERED INDEX IX_ParkingPermits_LicensePlate ON ParkingPermits(LicensePlate);
CREATE NONCLUSTERED INDEX IX_ParkingPermits_CleanPlate ON ParkingPermits(CleanPlate);
CREATE NONCLUSTERED INDEX IX_ParkingPermits_CardNumber ON ParkingPermits(CardNumber);
CREATE NONCLUSTERED INDEX IX_ParkingPermits_Zone_Status ON ParkingPermits(ZoneID, Status);
CREATE NONCLUSTERED INDEX IX_ParkingPermits_Dept ON ParkingPermits(DeptID);

-- 4. 員工線上申請主檔
CREATE TABLE ParkingEmployeeApplications (
    ApplicationID INT IDENTITY(1,1) PRIMARY KEY,
    ApplicationNo NVARCHAR(30) NOT NULL UNIQUE,  -- 申請單號 (APP-20261017-001)
    EmpNo NVARCHAR(20) NOT NULL,                 -- 員工工號
    ApplicantName NVARCHAR(50) NOT NULL,         -- 申請人姓名
    DeptID INT NOT NULL FOREIGN KEY REFERENCES ParkingDepartments(DeptID),
    ContactPhone NVARCHAR(20) NULL,
    LicensePlate NVARCHAR(15) NOT NULL,
    VehicleBrand NVARCHAR(30) NOT NULL,
    VehicleColor NVARCHAR(20) NOT NULL,
    PreferredZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID),
    AssignedZoneID INT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID),   -- 管理者核定/實際停放區域 (預設為同仁志願，管理者可依現場配置彈性調整)
    ApplyDate DATETIME NOT NULL DEFAULT GETDATE(),
    ReviewStatus NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING(待審核), PROCESSING(已收案), WAITLIST(待排序), APPROVED(待領證), COMPLETED(已發證), REJECTED(已駁回)
    ReviewerName NVARCHAR(50) NULL,
    ReviewDate DATETIME NULL,
    RejectReason NVARCHAR(200) NULL,
    ReviewRemarks NVARCHAR(200) NULL
);

-- 5. 現場巡檢查核紀錄檔
CREATE TABLE ParkingInspectionLogs (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    InspectTime DATETIME NOT NULL DEFAULT GETDATE(),
    InspectorAccount NVARCHAR(50) NOT NULL,      -- 巡檢員/警衛帳號
    ZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID), -- 當前巡檢區域
    PlateScanned NVARCHAR(15) NOT NULL,          -- 拍攝辨識或手動輸入之車牌
    PermitID INT NULL FOREIGN KEY REFERENCES ParkingPermits(PermitID), -- 對應之通行證 (查無則 NULL)
    ResultStatus NVARCHAR(20) NOT NULL,          -- VALID(合格), WRONG_ZONE(跨區停放), EXPIRED(逾期停放), NOT_FOUND(無證車輛)
    PhotoPath NVARCHAR(255) NULL,                -- 違規舉證照片存檔路徑
    Remark NVARCHAR(200) NULL
);
GO

-- =============================================
-- 初始基礎字典檔資料 (Seed Data)
-- =============================================

INSERT INTO ParkingDepartments (DeptCode, DeptName, QuotaLimit, IsActive) VALUES
(N'CARDIO', N'心臟超音波室', 45, 1),
(N'PED',    N'婦兒科部',     50, 1),
(N'DENT',   N'牙科醫療部',   30, 1),
(N'ER',     N'急診醫學科',   60, 1),
(N'RAD',    N'影像醫學部',   35, 1),
(N'SURG',   N'一般外科部',   40, 1),
(N'NURSE',  N'護理部',       80, 1),
(N'GA',     N'總務行政處',   25, 1);

INSERT INTO ParkingZones (ZoneCode, ZoneName, TotalCapacity, WarningThresholdPct, IsActive) VALUES
(N'A', N'地下A區 (醫療大樓地下室/主管醫師)', 100, 85, 1),
(N'B', N'露天B區 (急診室旁/全日醫護)',       150, 85, 1),
(N'C', N'第三立體C區 (全院同仁/綜合車位)',   250, 85, 1);
GO

-- =============================================
-- 通行證測試假資料 (含正常、即期、過期、跨區測試車輛)
-- =============================================

INSERT INTO ParkingPermits (PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber, RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand, ZoneID, RegisterDate, StartDate, ExpireDate, Status, Remarks) VALUES
(N'PRK-202610-001', 1, N'EMP1001', N'李建榮 醫師', N'TAG-8801', N'RC-101', N'珍珠白', N'ABC-1234', N'Toyota Camry', 1, '2026-01-01', '2026-01-01', '2027-12-31', 'ACTIVE', N'心臟內科主治醫師專用'),
(N'PRK-202610-002', 2, N'EMP1002', N'林淑敏 護理長', N'TAG-8802', N'RC-102', N'星燦灰', N'5678-EF', N'Honda CR-V',   2, '2026-02-15', '2026-02-15', '2026-11-05', 'ACTIVE', N'兒科加護病房輪值 (即將到期)'),
(N'PRK-202610-003', 3, N'EMP1003', N'張志偉 技師', N'TAG-8803', NULL,      N'曜石黑', N'9876-AA', N'Nissan Kicks',  3, '2025-09-01', '2025-09-01', '2026-09-30', 'EXPIRED', N'證件已過期，待展期手續'),
(N'PRK-202610-004', 4, N'EMP1004', N'陳明德 醫師', N'TAG-8804', N'RC-104', N'極光銀', N'BAG-9988', N'Lexus RX300',   1, '2026-03-01', '2026-03-01', '2027-02-28', 'ACTIVE', N'急診重症專任醫師'),
(N'PRK-202610-005', 7, N'EMP1005', N'黃雅婷 護理師', N'TAG-8805', NULL,      N'冰鑽藍', N'8888-QQ', N'Mazda 3',       2, '2026-04-10', '2026-04-10', '2027-04-09', 'ACTIVE', N'急診夜班輪值護理'),
(N'PRK-202610-006', 5, N'EMP1006', N'吳孟勳 放射師', N'TAG-8806', N'RC-106', N'雲河灰', N'KEA-2468', N'Ford Focus',    3, '2026-05-01', '2026-05-01', '2027-04-30', 'ACTIVE', N'CT/MRI 放射檢查室'),
(N'PRK-202610-007', 8, N'EMP1007', N'鄭富元 專員', N'TAG-8807', N'RC-107', N'雪貂白', N'7777-TX', N'Tesla Model Y', 1, '2026-01-10', '2026-01-10', '2027-01-09', 'ACTIVE', N'總務行政車輛 (充電樁優先)'),
(N'PRK-202610-008', 6, N'EMP1008', N'蘇文彬 醫師', N'TAG-8808', N'RC-108', N'琥珀金', N'RAC-3579', N'BMW 520i',      1, '2026-06-15', '2026-06-15', '2027-06-14', 'ACTIVE', N'神經外科主治醫師'),
(N'PRK-202610-009', 2, N'EMP1009', N'劉美惠 醫師', N'TAG-8809', N'RC-109', N'寶石紅', N'5566-HN', N'Volvo XC60',    2, '2026-02-01', '2026-02-01', '2026-10-31', 'ACTIVE', N'婦產科門診 (即將到期)'),
(N'PRK-202610-010', 1, N'EMP1010', N'柯子揚 技術員', N'TAG-8810', NULL,     N'石墨黑', N'9911-ZZ', N'Toyota Altis',  3, '2025-08-01', '2025-08-01', '2026-08-01', 'EXPIRED', N'逾期未繳管理費已註銷停權');
GO

-- =============================================
-- 員工申請主檔測試資料 (Seed Data)
-- =============================================

INSERT INTO ParkingEmployeeApplications (ApplicationNo, EmpNo, ApplicantName, DeptID, ContactPhone, LicensePlate, VehicleBrand, VehicleColor, PreferredZoneID, ApplyDate, ReviewStatus, ReviewerName, ReviewDate, RejectReason) VALUES
(N'APP-20261017-001', N'EMP2001', N'王大明', 1, N'分機 3211', N'BPK-8899', N'Toyota RAV4',  N'極光銀', 1, '2026-10-17 08:30:00', N'PENDING', NULL, NULL, NULL),
(N'APP-20261017-002', N'EMP2002', N'蔡佳玲', 2, N'分機 3105', N'ABC-5678',  N'Honda Fit',    N'珍珠白', 2, '2026-10-17 09:15:00', N'PENDING', NULL, NULL, NULL),
(N'APP-20261016-003', N'EMP2003', N'趙重光', 4, N'0912-345678', N'EAA-1234', N'Nissan Sentra', N'曜石黑', 2, '2026-10-16 14:20:00', N'APPROVED', N'總務行政處 陳專員', '2026-10-16 16:30:00', NULL),
(N'APP-20261015-004', N'EMP2004', N'周曉菁', 7, N'分機 5520', N'3344-ZZ',  N'Mazda CX-5',   N'鋼鐵灰', 3, '2026-10-15 10:00:00', N'REJECTED', N'總務行政處 陳專員', '2026-10-15 11:30:00', N'車籍資料照片模糊，且該部門本季車位配額已達飽和上限。'),
(N'APP-20261014-005', N'EMP2005', N'許銘倫', 6, N'分機 6108', N'BAM-7722', N'Ford Kuga',    N'烈焰紅', 1, '2026-10-14 16:45:00', N'COMPLETED', N'總務行政處 陳專員', '2026-10-15 09:00:00', NULL);
GO

-- =============================================
-- 現場巡檢稽核紀錄測試資料 (Seed Data)
-- =============================================

INSERT INTO ParkingInspectionLogs (InspectTime, InspectorAccount, ZoneID, PlateScanned, PermitID, ResultStatus, PhotoPath, Remark) VALUES
(DATEADD(MINUTE, -120, GETDATE()), N'SEC_DUTY01', 1, N'ABC1234',  1,    N'VALID',      NULL, N'例行地下A區巡檢，授權資格正常'),
(DATEADD(MINUTE, -95,  GETDATE()), N'SEC_DUTY01', 1, N'5678EF',   2,    N'WRONG_ZONE', N'/Uploads/wrong_zone_5678EF.jpg', N'該車授權區域為B區，違規跨區停放於地下A區VIP格位'),
(DATEADD(MINUTE, -60,  GETDATE()), N'SEC_DUTY02', 3, N'9876AA',   3,    N'EXPIRED',    N'/Uploads/expired_9876AA.jpg',    N'車輛通行證已於9月底過期未展期'),
(DATEADD(MINUTE, -30,  GETDATE()), N'SEC_DUTY02', 2, N'XYZ9999',  NULL, N'NOT_FOUND',  N'/Uploads/unknown_XYZ9999.jpg',  N'全院查無此車登記紀錄，已於前擋夾置臨停警告通知單'),
(DATEADD(MINUTE, -10,  GETDATE()), N'SEC_DUTY01', 2, N'8888QQ',   5,    N'VALID',      NULL, N'夜班醫護車輛停放正常');
GO

-- =============================================
-- 6. 系統管理員與巡檢人員資料表 (ParkingSystemAdmins)
-- =============================================

CREATE TABLE ParkingSystemAdmins (
    AdminID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,       -- 登入帳號
    Password NVARCHAR(100) NOT NULL,             -- 密碼
    DisplayName NVARCHAR(50) NOT NULL,           -- 姓名 / 稱謂
    Role NVARCHAR(30) NOT NULL,                  -- SUPER_ADMIN, ADMIN, SECURITY
    RoleName NVARCHAR(50) NOT NULL,              -- 總務行政主管、現場巡檢警衛
    DeptName NVARCHAR(50) NOT NULL,              -- 所屬部門 (如: 總務行政處、安全警衛課)
    ContactPhone NVARCHAR(30) NULL,              -- 聯絡電話/分機
    Email NVARCHAR(100) NULL,                    -- 電子信箱
    LastLoginTime DATETIME NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    Remarks NVARCHAR(200) NULL
);
GO

INSERT INTO ParkingSystemAdmins (Username, Password, DisplayName, Role, RoleName, DeptName, ContactPhone, LastLoginTime, Remarks) VALUES
(N'admin', N'admin123', N'陳專員 (總務管理員)', N'SUPER_ADMIN', N'總務行政主管', N'總務行政處', N'分機 3100', GETDATE(), N'系統最高管理權限'),
(N'security01', N'sec123', N'李警衛 (現場查核隊)', N'SECURITY', N'現場巡檢警衛', N'安全警衛課', N'分機 1199', GETDATE(), N'行動巡查專用帳號');
GO

PRINT N'HospitalParkingDB 資料庫與初始測試資料建置成功！';
