# 智慧停車場車輛管理系統 程式開發規格書 (Technical Architecture & Development Spec)

## 1. 系統架構與技術棧規劃 (Architecture & Tech Stack)

本系統採用經典企業級 **ASP.NET C# Web Forms 三層架構 (3-Tier Architecture)**，兼顧穩定性、安全性與維護成本，並針對行動端查核提供高響應性的 AJAX/JSON 服務支援。

### 1.1 技術棧清單 (Technology Stack)
* **執行階段 (Runtime)**：.NET Framework 4.8 / ASP.NET Web Forms
* **後端語言**：C# 8.0+
* **資料庫管理系統**：Microsoft SQL Server 2016+
* **資料存取層 (DAL)**：ADO.NET (搭配 `SqlParameter` 參數化查詢) 或 Dapper 輕量級 ORM
* **前端框架與套件**：
  * UI 框架：Bootstrap 5.3 (透過 MasterPage 封裝)
  * 圖表元件：Chart.js (管理看板)
  * 非同步溝通：jQuery 3.6+ AJAX 串接 ASP.NET `[WebMethod]` PageMethods
  * 提示反饋：SweetAlert2
* **行動端取像技術**：HTML5 `navigator.mediaDevices.getUserMedia` 或 `<input type="file" accept="image/*" capture="environment">`

### 1.2 三層架構說明
```
+-------------------------------------------------------------------+
|                        展示層 (Presentation Layer)                 |
|  - .aspx 頁面 (Admin_Dashboard, Permit_Management, Mobile_Check)  |
|  - 前端 JavaScript / jQuery / AJAX 呼叫靜態 WebMethod             |
+---------------------------------+---------------------------------+
                                  | (DTO / ViewModel)
+---------------------------------v---------------------------------+
|                        商業邏輯層 (Business Logic Layer)           |
|  - PermitService: 車牌檢核、展期邏輯、配額計算                    |
|  - ApplicationWorkflowService: 員工申請審核流程狀態機             |
|  - InspectionService: 現場查核比對、跨區違規判定                  |
+---------------------------------+---------------------------------+
                                  | (Entity Models)
+---------------------------------v---------------------------------+
|                        資料存取層 (Data Access Layer)             |
|  - SqlHelper / Dapper Repository                                  |
|  - 參數化查詢與交易管理 (TransactionScope)                        |
+---------------------------------+---------------------------------+
                                  | (T-SQL)
+---------------------------------v---------------------------------+
|                    資料庫 (Microsoft SQL Server)                  |
+-------------------------------------------------------------------+
```

---

## 2. 資料庫設計與 DDL 腳本 (Database Schema & DDL)

系統規劃 5 張核心資料表：部門字典檔、停車區域字典檔、通行證主檔、員工申請主檔、巡檢稽核紀錄檔。

### 2.1 資料表關聯設計 (ER Diagram Concepts)
* `Departments` (1) <---> (N) `Permits`
* `ParkingZones` (1) <---> (N) `Permits`
* `Permits` (1) <---> (N) `InspectionLogs`
* `EmployeeApplications` (1) ---> 審核核准後轉入 ---> `Permits`

### 2.2 SQL Server 建立資料庫與資料表腳本 (DDL)

```sql
-- 建立資料庫
CREATE DATABASE HospitalParkingDB;
GO

USE HospitalParkingDB;
GO

-- 1. 部門類別字典檔
CREATE TABLE Departments (
    DeptID INT IDENTITY(1,1) PRIMARY KEY,
    DeptCode NVARCHAR(20) NOT NULL UNIQUE,       -- 如: CARDIO, PED, DENT
    DeptName NVARCHAR(50) NOT NULL,              -- 如: 心臟超音波、婦兒科、牙科
    QuotaLimit INT NOT NULL DEFAULT 0,           -- 該部門分配總車位上限
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- 2. 停車區域類別字典檔
CREATE TABLE ParkingZones (
    ZoneID INT IDENTITY(1,1) PRIMARY KEY,
    ZoneCode NVARCHAR(10) NOT NULL UNIQUE,       -- 如: A, B, C
    ZoneName NVARCHAR(50) NOT NULL,              -- 如: 地下A區(行政主管)、露天B區(全日)
    TotalCapacity INT NOT NULL DEFAULT 0,        -- 總格位數
    WarningThresholdPct INT NOT NULL DEFAULT 85, -- 飽和告警百分比 (預設 85%)
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- 3. 車輛通行證主檔 (完整包含 13 個核心欄位與狀態)
CREATE TABLE Permits (
    PermitID INT IDENTITY(1,1) PRIMARY KEY,
    PermitNumber NVARCHAR(30) NOT NULL UNIQUE,   -- 停車證號 (例: PRK-202610-001)
    DeptID INT NOT NULL FOREIGN KEY REFERENCES Departments(DeptID), -- 部門
    CardNumber NVARCHAR(50) NULL,                -- 卡號 (工號或識別卡號)
    OwnerName NVARCHAR(50) NOT NULL,             -- 姓名
    SensorTagNumber NVARCHAR(50) NULL,           -- 感應卡 (RFID/eTag 卡號)
    RemoteControllerNo NVARCHAR(50) NULL,        -- 遙控器編號
    VehicleColor NVARCHAR(20) NOT NULL,          -- 車輛顏色
    LicensePlate NVARCHAR(15) NOT NULL,          -- 車牌號碼 (正規化大寫無特殊符號)
    VehicleBrand NVARCHAR(30) NOT NULL,          -- 車輛廠牌 (Toyota, Honda...)
    ZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID), -- 停車區域
    RegisterDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),      -- 登記日期
    StartDate DATE NOT NULL,                     -- 開始日期
    ExpireDate DATE NOT NULL,                    -- 停車日期 / 到期日期
    Status NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE(有效), EXPIRED(過期), REVOKED(註銷)
    Remarks NVARCHAR(255) NULL,
    UpdatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_Permit_DateRange CHECK (ExpireDate >= StartDate)
);

-- 索引優化：巡檢與查詢高頻索引
CREATE NONCLUSTERED INDEX IX_Permits_LicensePlate ON Permits(LicensePlate);
CREATE NONCLUSTERED INDEX IX_Permits_CardNumber ON Permits(CardNumber);
CREATE NONCLUSTERED INDEX IX_Permits_Zone_Status ON Permits(ZoneID, Status);

-- 4. 員工線上申請主檔
CREATE TABLE EmployeeApplications (
    ApplicationID INT IDENTITY(1,1) PRIMARY KEY,
    ApplicationNo NVARCHAR(30) NOT NULL UNIQUE,  -- 申請單號 (APP-20261017-001)
    EmpNo NVARCHAR(20) NOT NULL,                 -- 員工工號
    ApplicantName NVARCHAR(50) NOT NULL,         -- 申請人姓名
    DeptID INT NOT NULL FOREIGN KEY REFERENCES Departments(DeptID),
    ContactPhone NVARCHAR(20) NULL,
    LicensePlate NVARCHAR(15) NOT NULL,
    VehicleBrand NVARCHAR(30) NOT NULL,
    VehicleColor NVARCHAR(20) NOT NULL,
    PreferredZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID),
    ApplyDate DATETIME NOT NULL DEFAULT GETDATE(),
    ReviewStatus NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING(待審核), APPROVED(已核准待發證), REJECTED(已駁回), COMPLETED(已結案領證)
    ReviewerName NVARCHAR(50) NULL,
    ReviewDate DATETIME NULL,
    RejectReason NVARCHAR(200) NULL
);

-- 5. 現場巡檢查核紀錄檔
CREATE TABLE InspectionLogs (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    InspectTime DATETIME NOT NULL DEFAULT GETDATE(),
    InspectorAccount NVARCHAR(50) NOT NULL,      -- 巡檢員/警衛帳號
    ZoneID INT NOT NULL FOREIGN KEY REFERENCES ParkingZones(ZoneID), -- 當前巡檢區域
    PlateScanned NVARCHAR(15) NOT NULL,          -- 拍攝辨識或手動輸入之車牌
    PermitID INT NULL FOREIGN KEY REFERENCES Permits(PermitID), -- 對應之通行證 (查無則 NULL)
    ResultStatus NVARCHAR(20) NOT NULL,          -- VALID(合格), WRONG_ZONE(跨區停放), EXPIRED(逾期停放), NOT_FOUND(無證車輛)
    PhotoPath NVARCHAR(255) NULL,                -- 違規舉證照片存檔路徑
    Remark NVARCHAR(200) NULL
);
GO
```

---

## 3. 核心功能實作規格與程式範例 (Implementation Specs)

### 3.1 車輛通行證維護與 AJAX CRUD (`Permit_Management.aspx`)

前端整合 Bootstrap 5 表格與 Modal，所有操作透過 PageMethods 非同步處理，杜絕 PostBack 刷新。

#### 前端 ASPX 設計 (`Permit_Management.aspx`)
```html
<%@ Page Title="車輛通行證維護" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Permit_Management.aspx.cs" Inherits="HospitalParking.Permit_Management" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-4">
        <h3 class="mt-4"><i class="bi bi-card-checklist me-2"></i>車輛通行證主檔維護</h3>
        <p class="text-muted">管理全院 13 項通行證資訊、門禁感應卡與遙控器配發狀況。</p>

        <!-- 查詢篩選條件卡片 -->
        <div class="card shadow-sm mb-4">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">所屬部門</label>
                        <select id="ddlSearchDept" class="form-select">
                            <option value="">-- 全部部門 --</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">停車區域</label>
                        <select id="ddlSearchZone" class="form-select">
                            <option value="">-- 全部區域 --</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">關鍵字查詢 (車牌 / 姓名 / 卡號)</label>
                        <input type="text" id="txtKeyword" class="form-control" placeholder="請輸入欲查詢的資訊..." />
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="button" class="btn btn-primary w-100" onclick="loadPermitsData();">
                            <i class="bi bi-search me-1"></i>查詢
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 資料清單區塊 -->
        <div class="card shadow-sm">
            <div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
                <span class="h6 mb-0 font-weight-bold">通行證清單</span>
                <button type="button" class="btn btn-success btn-sm" onclick="openCreateModal();">
                    <i class="bi bi-plus-circle me-1"></i>新增通行證
                </button>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0" id="tblPermits">
                        <thead class="table-light">
                            <tr>
                                <th>停車證號</th>
                                <th>部門</th>
                                <th>姓名(卡號)</th>
                                <th>車牌號碼</th>
                                <th>廠牌/顏色</th>
                                <th>停車區域</th>
                                <th>感應卡/遙控器</th>
                                <th>起迄有效日期</th>
                                <th>狀態</th>
                                <th class="text-center">操作</th>
                            </tr>
                        </thead>
                        <tbody id="permitTableBody">
                            <!-- 動態載入 -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- 編輯/新增 Modal -->
    <div class="modal fade" id="permitModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title" id="modalTitle">新增通行證</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="frmPermit">
                        <input type="hidden" id="hidPermitID" value="0" />
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label required">停車證號</label>
                                <input type="text" id="txtPermitNumber" class="form-control" required placeholder="例: PRK-202610-001" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label required">部門科室</label>
                                <select id="modalDept" class="form-select" required></select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label required">姓名</label>
                                <input type="text" id="txtOwnerName" class="form-control" required />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">卡號 (員工識別碼)</label>
                                <input type="text" id="txtCardNumber" class="form-control" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">車牌號碼</label>
                                <input type="text" id="txtLicensePlate" class="form-control text-uppercase" required />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">車輛廠牌</label>
                                <input type="text" id="txtVehicleBrand" class="form-control" required placeholder="例: Toyota" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">車輛顏色</label>
                                <input type="text" id="txtVehicleColor" class="form-control" required placeholder="例: 白色" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">停車區域</label>
                                <select id="modalZone" class="form-select" required></select>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">感應卡號 (eTag/RFID)</label>
                                <input type="text" id="txtSensorTagNumber" class="form-control" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">遙控器編號</label>
                                <input type="text" id="txtRemoteControllerNo" class="form-control" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">登記日期</label>
                                <input type="date" id="txtRegisterDate" class="form-control" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">開始日期</label>
                                <input type="date" id="txtStartDate" class="form-control" required />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label required">停車日期 (到期日)</label>
                                <input type="date" id="txtExpireDate" class="form-control" required />
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-primary" onclick="savePermitData();">確認儲存</button>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        $(document).ready(function () {
            loadInitialLookups();
            loadPermitsData();
        });

        // 載入字典檔 (部門/區域)
        function loadInitialLookups() {
            $.ajax({
                type: "POST",
                url: "Permit_Management.aspx/GetLookupOptions",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var data = res.d;
                    var deptOpts = '<option value="">-- 全部部門 --</option>';
                    data.Departments.forEach(d => {
                        deptOpts += `<option value="${d.DeptID}">${d.DeptName}</option>`;
                    });
                    $('#ddlSearchDept').html(deptOpts);
                    $('#modalDept').html(deptOpts);

                    var zoneOpts = '<option value="">-- 全部區域 --</option>';
                    data.Zones.forEach(z => {
                        zoneOpts += `<option value="${z.ZoneID}">${z.ZoneName}</option>`;
                    });
                    $('#ddlSearchZone').html(zoneOpts);
                    $('#modalZone').html(zoneOpts);
                }
            });
        }

        // 查詢通行證清單
        function loadPermitsData() {
            var searchDto = {
                DeptID: $('#ddlSearchDept').val() ? parseInt($('#ddlSearchDept').val()) : null,
                ZoneID: $('#ddlSearchZone').val() ? parseInt($('#ddlSearchZone').val()) : null,
                Keyword: $('#txtKeyword').val().trim()
            };

            $.ajax({
                type: "POST",
                url: "Permit_Management.aspx/SearchPermits",
                data: JSON.stringify({ criteria: searchDto }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var list = res.d;
                    var html = '';
                    if (list.length === 0) {
                        html = '<tr><td colspan="10" class="text-center py-4 text-muted">查無相符資料</td></tr>';
                    } else {
                        list.forEach(p => {
                            var statusBadge = p.Status === 'ACTIVE' 
                                ? '<span class="badge bg-success">正常</span>' 
                                : '<span class="badge bg-danger">逾期/失效</span>';

                            html += `<tr>
                                <td><strong>${p.PermitNumber}</strong></td>
                                <td>${p.DeptName}</td>
                                <td>${p.OwnerName} <br><small class="text-muted">${p.CardNumber || '--'}</small></td>
                                <td><span class="badge bg-secondary font-monospace fs-6">${p.LicensePlate}</span></td>
                                <td>${p.VehicleBrand} / ${p.VehicleColor}</td>
                                <td><span class="badge bg-info text-dark">${p.ZoneName}</span></td>
                                <td><small>感應:${p.SensorTagNumber || '--'}<br>遙控:${p.RemoteControllerNo || '--'}</small></td>
                                <td><small>${p.StartDate} ~<br>${p.ExpireDate}</small></td>
                                <td>${statusBadge}</td>
                                <td class="text-center">
                                    <button class="btn btn-outline-primary btn-sm me-1" onclick="editPermit(${p.PermitID});"><i class="bi bi-pencil"></i></button>
                                    <button class="btn btn-outline-danger btn-sm" onclick="deletePermit(${p.PermitID});"><i class="bi bi-trash"></i></button>
                                </td>
                            </tr>`;
                        });
                    }
                    $('#permitTableBody').html(html);
                }
            });
        }

        function openCreateModal() {
            $('#frmPermit')[0].reset();
            $('#hidPermitID').val('0');
            $('#modalTitle').text('新增通行證');
            var today = new Date().toISOString().split('T')[0];
            $('#txtRegisterDate').val(today);
            $('#txtStartDate').val(today);
            $('#permitModal').modal('show');
        }

        function savePermitData() {
            var dto = {
                PermitID: parseInt($('#hidPermitID').val()),
                PermitNumber: $('#txtPermitNumber').val().trim(),
                DeptID: parseInt($('#modalDept').val()),
                CardNumber: $('#txtCardNumber').val().trim(),
                OwnerName: $('#txtOwnerName').val().trim(),
                SensorTagNumber: $('#txtSensorTagNumber').val().trim(),
                RemoteControllerNo: $('#txtRemoteControllerNo').val().trim(),
                VehicleColor: $('#txtVehicleColor').val().trim(),
                LicensePlate: $('#txtLicensePlate').val().trim().toUpperCase(),
                VehicleBrand: $('#txtVehicleBrand').val().trim(),
                ZoneID: parseInt($('#modalZone').val()),
                RegisterDate: $('#txtRegisterDate').val(),
                StartDate: $('#txtStartDate').val(),
                ExpireDate: $('#txtExpireDate').val()
            };

            if (!dto.PermitNumber || !dto.DeptID || !dto.OwnerName || !dto.LicensePlate || !dto.ZoneID || !dto.StartDate || !dto.ExpireDate) {
                Swal.fire('提醒', '請填寫所有標記必填的欄位！', 'warning');
                return;
            }

            $.ajax({
                type: "POST",
                url: "Permit_Management.aspx/SavePermit",
                data: JSON.stringify({ dto: dto }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res.d.Success) {
                        Swal.fire('成功', res.d.Message, 'success');
                        $('#permitModal').modal('hide');
                        loadPermitsData();
                    } else {
                        Swal.fire('儲存失敗', res.d.Message, 'error');
                    }
                }
            });
        }
    </script>
</asp:Content>
```

#### 後端 C# Code-Behind (`Permit_Management.aspx.cs`)
```csharp
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;

namespace HospitalParking
{
    public partial class Permit_Management : System.Web.UI.Page
    {
        private static readonly string connStr = ConfigurationManager.ConnectionStrings["HospitalParkingDB"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            // 驗證管理權限 (可結合 Session 或 FormsAuthentication)
            if (!IsPostBack)
            {
                // 初始化必要權限檢核
            }
        }

        #region DTO Models
        public class LookupDataDto
        {
            public List<DeptItem> Departments { get; set; } = new List<DeptItem>();
            public List<ZoneItem> Zones { get; set; } = new List<ZoneItem>();
        }
        public class DeptItem { public int DeptID { get; set; } public string DeptName { get; set; } }
        public class ZoneItem { public int ZoneID { get; set; } public string ZoneName { get; set; } }

        public class SearchCriteriaDto
        {
            public int? DeptID { get; set; }
            public int? ZoneID { get; set; }
            public string Keyword { get; set; }
        }

        public class PermitItemDto
        {
            public int PermitID { get; set; }
            public string PermitNumber { get; set; }
            public int DeptID { get; set; }
            public string DeptName { get; set; }
            public string CardNumber { get; set; }
            public string OwnerName { get; set; }
            public string SensorTagNumber { get; set; }
            public string RemoteControllerNo { get; set; }
            public string VehicleColor { get; set; }
            public string LicensePlate { get; set; }
            public string VehicleBrand { get; set; }
            public int ZoneID { get; set; }
            public string ZoneName { get; set; }
            public string RegisterDate { get; set; }
            public string StartDate { get; set; }
            public string ExpireDate { get; set; }
            public string Status { get; set; }
        }

        public class OperationResult
        {
            public bool Success { get; set; }
            public string Message { get; set; }
        }
        #endregion

        [WebMethod]
        public static LookupDataDto GetLookupOptions()
        {
            var result = new LookupDataDto();
            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand("SELECT DeptID, DeptName FROM Departments WHERE IsActive=1 ORDER BY DeptName", conn))
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        result.Departments.Add(new DeptItem { DeptID = dr.GetInt32(0), DeptName = dr.GetString(1) });
                    }
                }

                using (var cmd = new SqlCommand("SELECT ZoneID, ZoneName FROM ParkingZones WHERE IsActive=1 ORDER BY ZoneCode", conn))
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        result.Zones.Add(new ZoneItem { ZoneID = dr.GetInt32(0), ZoneName = dr.GetString(1) });
                    }
                }
            }
            return result;
        }

        [WebMethod]
        public static List<PermitItemDto> SearchPermits(SearchCriteriaDto criteria)
        {
            var list = new List<PermitItemDto>();
            string sql = @"
                SELECT p.PermitID, p.PermitNumber, p.DeptID, d.DeptName, p.CardNumber, p.OwnerName,
                       p.SensorTagNumber, p.RemoteControllerNo, p.VehicleColor, p.LicensePlate,
                       p.VehicleBrand, p.ZoneID, z.ZoneName,
                       CONVERT(VARCHAR(10), p.RegisterDate, 120) AS RegisterDate,
                       CONVERT(VARCHAR(10), p.StartDate, 120) AS StartDate,
                       CONVERT(VARCHAR(10), p.ExpireDate, 120) AS ExpireDate,
                       p.Status
                FROM Permits p
                INNER JOIN Departments d ON p.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                WHERE 1=1 ";

            if (criteria.DeptID.HasValue) sql += " AND p.DeptID = @DeptID ";
            if (criteria.ZoneID.HasValue) sql += " AND p.ZoneID = @ZoneID ";
            if (!string.IsNullOrWhiteSpace(criteria.Keyword))
            {
                sql += " AND (p.LicensePlate LIKE @Kw OR p.OwnerName LIKE @Kw OR p.CardNumber LIKE @Kw OR p.PermitNumber LIKE @Kw) ";
            }
            sql += " ORDER BY p.PermitID DESC";

            using (var conn = new SqlConnection(connStr))
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (criteria.DeptID.HasValue) cmd.Parameters.AddWithValue("@DeptID", criteria.DeptID.Value);
                if (criteria.ZoneID.HasValue) cmd.Parameters.AddWithValue("@ZoneID", criteria.ZoneID.Value);
                if (!string.IsNullOrWhiteSpace(criteria.Keyword)) cmd.Parameters.AddWithValue("@Kw", "%" + criteria.Keyword + "%");

                conn.Open();
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        list.Add(new PermitItemDto
                        {
                            PermitID = Convert.ToInt32(dr["PermitID"]),
                            PermitNumber = dr["PermitNumber"].ToString(),
                            DeptID = Convert.ToInt32(dr["DeptID"]),
                            DeptName = dr["DeptName"].ToString(),
                            CardNumber = dr["CardNumber"]?.ToString(),
                            OwnerName = dr["OwnerName"].ToString(),
                            SensorTagNumber = dr["SensorTagNumber"]?.ToString(),
                            RemoteControllerNo = dr["RemoteControllerNo"]?.ToString(),
                            VehicleColor = dr["VehicleColor"].ToString(),
                            LicensePlate = dr["LicensePlate"].ToString(),
                            VehicleBrand = dr["VehicleBrand"].ToString(),
                            ZoneID = Convert.ToInt32(dr["ZoneID"]),
                            ZoneName = dr["ZoneName"].ToString(),
                            RegisterDate = dr["RegisterDate"].ToString(),
                            StartDate = dr["StartDate"].ToString(),
                            ExpireDate = dr["ExpireDate"].ToString(),
                            Status = dr["Status"].ToString()
                        });
                    }
                }
            }
            return list;
        }

        [WebMethod]
        public static OperationResult SavePermit(PermitItemDto dto)
        {
            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // 檢查車牌與停車證號重複性 (排除自身)
                    string chkSql = "SELECT COUNT(1) FROM Permits WHERE (LicensePlate = @Plate OR PermitNumber = @PermitNum) AND PermitID <> @PermitID";
                    using (var chkCmd = new SqlCommand(chkSql, conn))
                    {
                        chkCmd.Parameters.AddWithValue("@Plate", dto.LicensePlate);
                        chkCmd.Parameters.AddWithValue("@PermitNum", dto.PermitNumber);
                        chkCmd.Parameters.AddWithValue("@PermitID", dto.PermitID);
                        int count = (int)chkCmd.ExecuteScalar();
                        if (count > 0)
                        {
                            return new OperationResult { Success = false, Message = "該車牌號碼或通行證號已存在，不得重複新增！" };
                        }
                    }

                    string query;
                    if (dto.PermitID == 0) // 新增
                    {
                        query = @"
                            INSERT INTO Permits (
                                PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber,
                                RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand,
                                ZoneID, RegisterDate, StartDate, ExpireDate, Status
                            ) VALUES (
                                @PermitNumber, @DeptID, @CardNumber, @OwnerName, @SensorTagNumber,
                                @RemoteControllerNo, @VehicleColor, @LicensePlate, @VehicleBrand,
                                @ZoneID, @RegisterDate, @StartDate, @ExpireDate, 'ACTIVE'
                            )";
                    }
                    else // 修改
                    {
                        query = @"
                            UPDATE Permits SET
                                PermitNumber = @PermitNumber,
                                DeptID = @DeptID,
                                CardNumber = @CardNumber,
                                OwnerName = @OwnerName,
                                SensorTagNumber = @SensorTagNumber,
                                RemoteControllerNo = @RemoteControllerNo,
                                VehicleColor = @VehicleColor,
                                LicensePlate = @LicensePlate,
                                VehicleBrand = @VehicleBrand,
                                ZoneID = @ZoneID,
                                StartDate = @StartDate,
                                ExpireDate = @ExpireDate,
                                UpdatedDate = GETDATE()
                            WHERE PermitID = @PermitID";
                    }

                    using (var cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@PermitID", dto.PermitID);
                        cmd.Parameters.AddWithValue("@PermitNumber", dto.PermitNumber);
                        cmd.Parameters.AddWithValue("@DeptID", dto.DeptID);
                        cmd.Parameters.AddWithValue("@CardNumber", (object)dto.CardNumber ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@OwnerName", dto.OwnerName);
                        cmd.Parameters.AddWithValue("@SensorTagNumber", (object)dto.SensorTagNumber ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@RemoteControllerNo", (object)dto.RemoteControllerNo ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@VehicleColor", dto.VehicleColor);
                        cmd.Parameters.AddWithValue("@LicensePlate", dto.LicensePlate);
                        cmd.Parameters.AddWithValue("@VehicleBrand", dto.VehicleBrand);
                        cmd.Parameters.AddWithValue("@ZoneID", dto.ZoneID);
                        cmd.Parameters.AddWithValue("@RegisterDate", DateTime.Parse(dto.RegisterDate));
                        cmd.Parameters.AddWithValue("@StartDate", DateTime.Parse(dto.StartDate));
                        cmd.Parameters.AddWithValue("@ExpireDate", DateTime.Parse(dto.ExpireDate));

                        cmd.ExecuteNonQuery();
                    }
                }
                return new OperationResult { Success = true, Message = "通行證資料已順利儲存完畢。" };
            }
            catch (Exception ex)
            {
                return new OperationResult { Success = false, Message = "儲存異常：" + ex.Message };
            }
        }
    }
}
```

---

### 3.2 行動端現場巡檢比對邏輯 (`Mobile_Check.aspx`)

巡檢端需考量警衛現場操作：支援行動端調用相機（利用 HTML5 file capture 或 WebRTC 取格），並提供輸入/拍攝查驗的核心檢核演算法。

#### 行動端畫面與相機調用前端核心碼
```html
<%@ Page Title="現場行動巡檢" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Mobile_Check.aspx.cs" Inherits="HospitalParking.Mobile_Check" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
<div class="container py-3" style="max-width: 600px;">
    <!-- 巡檢所在區域選擇 -->
    <div class="card mb-3 shadow-sm border-0">
        <div class="card-body">
            <label class="form-label font-weight-bold"><i class="bi bi-geo-alt-fill text-danger me-1"></i>當前巡檢停車區域</label>
            <select id="ddlCurrentZone" class="form-select form-select-lg">
                <option value="1">A區 (醫療大樓地下室)</option>
                <option value="2">B區 (急診室旁露天區)</option>
                <option value="3">C區 (第三立體停車場)</option>
            </select>
        </div>
    </div>

    <!-- 拍攝與輸入查核面板 -->
    <div class="card mb-3 shadow-sm border-0 text-center">
        <div class="card-body p-4">
            <!-- 隱藏原生 File Input，利用 capture 調用後鏡頭 -->
            <input type="file" id="cameraInput" accept="image/*" capture="environment" style="display:none;" onchange="handleImageCaptured(this);" />
            
            <button type="button" class="btn btn-primary btn-lg w-100 py-3 mb-3 shadow" onclick="$('#cameraInput').click();">
                <i class="bi bi-camera-fill fs-2 d-block mb-1"></i>
                點擊拍攝車牌辨識
            </button>

            <div class="d-flex align-items-center my-3">
                <hr class="flex-grow-1"><span class="px-2 text-muted small">或 手動輸入車牌</span><hr class="flex-grow-1">
            </div>

            <div class="input-group input-group-lg">
                <input type="text" id="txtCheckPlate" class="form-control text-uppercase text-center font-monospace" placeholder="例: ABC-1234" maxlength="10">
                <button class="btn btn-outline-secondary" type="button" onclick="verifyPlateManual();">
                    <i class="bi bi-search"></i> 查驗
                </button>
            </div>
        </div>
    </div>

    <!-- 查驗結果動態卡片 -->
    <div id="checkResultContainer" style="display:none;"></div>
</div>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ScriptContent" runat="server">
<script>
    // 手動輸入查核
    function verifyPlateManual() {
        var plate = $('#txtCheckPlate').val().trim().toUpperCase();
        var zoneId = parseInt($('#ddlCurrentZone').val());
        if (!plate) {
            alert('請輸入車牌號碼！');
            return;
        }
        executeVerification(plate, zoneId, null);
    }

    // 拍照後處理 (前端可壓縮轉 Base64 後送至後端進行 OCR 辨識或存檔)
    function handleImageCaptured(input) {
        if (input.files && input.files[0]) {
            var reader = new FileReader();
            reader.onload = function(e) {
                var base64Img = e.target.result; // data:image/jpeg;base64,...
                // 模擬 OCR 或呼叫 OCR WebMethod 取得車牌，此處示範直接送審
                callOcrAndVerify(base64Img);
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function callOcrAndVerify(base64Image) {
        var zoneId = parseInt($('#ddlCurrentZone').val());
        // 呼叫後端進行 OCR 解析與查驗
        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/RecognizeAndVerify",
            data: JSON.stringify({ base64Image: base64Image, currentZoneId: zoneId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function(res) {
                renderResultCard(res.d);
            }
        });
    }

    function executeVerification(plate, zoneId, photoPath) {
        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/VerifyLicensePlate",
            data: JSON.stringify({ plate: plate, currentZoneId: zoneId, photoRef: photoPath }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function(res) {
                renderResultCard(res.d);
            }
        });
    }

    function renderResultCard(data) {
        var container = $('#checkResultContainer');
        var cardClass = "border-success bg-light";
        var badge = '<span class="badge bg-success fs-6">合格 - 准予停放</span>';

        if (data.Status === 'WRONG_ZONE') {
            cardClass = "border-warning bg-warning bg-opacity-10";
            badge = '<span class="badge bg-warning text-dark fs-6">違規 - 跨區停放</span>';
        } else if (data.Status === 'EXPIRED') {
            cardClass = "border-danger bg-danger bg-opacity-10";
            badge = '<span class="badge bg-danger fs-6">違規 - 證件已過期</span>';
        } else if (data.Status === 'NOT_FOUND') {
            cardClass = "border-dark bg-secondary bg-opacity-10";
            badge = '<span class="badge bg-dark fs-6">警告 - 無通行證紀錄</span>';
        }

        var html = `
            <div class="card shadow border-2 ${cardClass}">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <span class="font-monospace fs-4 fw-bold">${data.Plate}</span>
                    ${badge}
                </div>
                <div class="card-body">
                    <p class="mb-1"><strong>車主姓名：</strong>${data.OwnerName || '未知'}</p>
                    <p class="mb-1"><strong>所屬部門：</strong>${data.DeptName || '未知'}</p>
                    <p class="mb-1"><strong>授權區域：</strong>${data.PermittedZoneName || '無'} (目前所在: ${data.CurrentZoneName})</p>
                    <p class="mb-1"><strong>有效期限：</strong>${data.ExpireDate || '--'}</p>
                    <div class="mt-3 text-muted small">${data.Message}</div>
                </div>
            </div>`;
        container.html(html).show();
    }
</script>
</asp:Content>
```

#### 巡檢判定邏輯 Code-Behind (`Mobile_Check.aspx.cs`)
```csharp
using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;

namespace HospitalParking
{
    public partial class Mobile_Check : System.Web.UI.Page
    {
        private static readonly string connStr = ConfigurationManager.ConnectionStrings["HospitalParkingDB"].ConnectionString;

        public class VerificationResultDto
        {
            public string Plate { get; set; }
            public string Status { get; set; } // VALID, WRONG_ZONE, EXPIRED, NOT_FOUND
            public string OwnerName { get; set; }
            public string DeptName { get; set; }
            public string PermittedZoneName { get; set; }
            public string CurrentZoneName { get; set; }
            public string ExpireDate { get; set; }
            public string Message { get; set; }
        }

        [WebMethod]
        public static VerificationResultDto VerifyLicensePlate(string plate, int currentZoneId, string photoRef)
        {
            plate = plate.Replace("-", "").Trim().ToUpper(); // 正規化車牌字串 (比對無破折號)
            var result = new VerificationResultDto { Plate = plate };

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                // 取得當前巡檢區域名稱
                string zoneSql = "SELECT ZoneName FROM ParkingZones WHERE ZoneID = @ZoneID";
                using (var zoneCmd = new SqlCommand(zoneSql, conn))
                {
                    zoneCmd.Parameters.AddWithValue("@ZoneID", currentZoneId);
                    result.CurrentZoneName = zoneCmd.ExecuteScalar()?.ToString() ?? "未知區域";
                }

                // 查詢車籍主檔 (車牌去除符號進行比對)
                string permitSql = @"
                    SELECT p.PermitID, p.OwnerName, d.DeptName, p.ZoneID, z.ZoneName, 
                           CONVERT(VARCHAR(10), p.ExpireDate, 120) AS ExpireDate,
                           p.ExpireDate AS ExpDateRaw, p.Status
                    FROM Permits p
                    INNER JOIN Departments d ON p.DeptID = d.DeptID
                    INNER JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                    WHERE REPLACE(p.LicensePlate, '-', '') = @Plate";

                using (var cmd = new SqlCommand(permitSql, conn))
                {
                    cmd.Parameters.AddWithValue("@Plate", plate);
                    using (var dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            int permitId = Convert.ToInt32(dr["PermitID"]);
                            result.OwnerName = dr["OwnerName"].ToString();
                            result.DeptName = dr["DeptName"].ToString();
                            int permittedZoneId = Convert.ToInt32(dr["ZoneID"]);
                            result.PermittedZoneName = dr["ZoneName"].ToString();
                            result.ExpireDate = dr["ExpireDate"].ToString();
                            DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);

                            // 狀態檢核演算法
                            if (expDate < DateTime.Today)
                            {
                                result.Status = "EXPIRED";
                                result.Message = "該車輛之通行證已於 " + result.ExpireDate + " 到期，尚未完成展期手續！";
                            }
                            else if (permittedZoneId != currentZoneId)
                            {
                                result.Status = "WRONG_ZONE";
                                result.Message = $"違規跨區！該車登記區域為【{result.PermittedZoneName}】，不得停放於【{result.CurrentZoneName}】。";
                            }
                            else
                            {
                                result.Status = "VALID";
                                result.Message = "該車輛具備本區域合法停放權限。";
                            }

                            dr.Close();
                            LogInspection(conn, permitId, plate, currentZoneId, result.Status, photoRef);
                            return result;
                        }
                    }
                }

                // 查無資料
                result.Status = "NOT_FOUND";
                result.Message = "系統中查無此車牌之登記資訊，請警衛人員留意是否為外來未登記車輛。";
                LogInspection(conn, null, plate, currentZoneId, result.Status, photoRef);
            }

            return result;
        }

        private static void LogInspection(SqlConnection conn, int? permitId, string plate, int zoneId, string status, string photoPath)
        {
            string sql = @"
                INSERT INTO InspectionLogs (InspectTime, InspectorAccount, ZoneID, PlateScanned, PermitID, ResultStatus, PhotoPath)
                VALUES (GETDATE(), 'SECURITY_DUTY', @ZoneID, @Plate, @PermitID, @Status, @PhotoPath)";

            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@ZoneID", zoneId);
                cmd.Parameters.AddWithValue("@Plate", plate);
                cmd.Parameters.AddWithValue("@PermitID", (object)permitId ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Status", status);
                cmd.Parameters.AddWithValue("@PhotoPath", (object)photoPath ?? DBNull.Value);
                cmd.ExecuteNonQuery();
            }
        }
    }
}
```

---

## 4. 系統安全、效能優化與驗收標準 (Security & Performance)

### 4.1 資安防護標準 (Security Guidelines)
1. **防範 SQL 注入 (SQL Injection)**：
   * 資料庫存取層一律採用 `SqlCommand.Parameters.AddWithValue` 或預存程序（Stored Procedure），**嚴禁**使用字串拼接動態 SQL。
2. **防範跨站腳本與請求偽造 (XSS & CSRF)**：
   * 前端渲染所有使用者自訂輸入（如姓名、車輛顏色、備註）時，透過 text 或安全的 template engine 渲染，避開 `innerHTML`。
   * Web Forms `Page.ViewStateUserKey = Session.SessionID;` 於 MasterPage 中啟用防禦 CSRF。
3. **敏感資訊與連線字串安全**：
   * `web.config` 內的 `connectionStrings` 於上線部署時，應透過 `aspnet_regiis -pe "connectionStrings" -app "/HospitalParking"` 進行 RSA 密文加密。

### 4.2 效能優化標準 (Performance Tuning)
* **車牌去符號正規化索引**：由於巡檢比對經常輸入或辨識無橫線之車牌，可於 SQL Server 建立計算欄位（Computed Column）`CleanPlate AS REPLACE(LicensePlate, '-', '')` 並建立索引，將查詢效能提升至毫秒級。
* **靜態資源快取**：MasterPage 引入之 Bootstrap、jQuery 及樣式表加入版本戳記（Cache Busting），如 `Site.css?v=20261017`。

### 4.3 驗收測試檢查表 (Acceptance Checklist)

| 測試項目 | 預期結果 | 驗收方式 |
| :--- | :--- | :--- |
| **13 項完整欄位儲存** | 新增/修改通行證時，13 個欄位均能正確持久化至資料庫且不遺失。 | 資料庫 SELECT 檢驗 |
| **車牌唯一性檢核** | 輸入已存在之車牌嘗試新增時，系統即時提示重複並阻止儲存。 | 介面表單測試 |
| **行動端相機連動** | 在 iOS Safari 與 Android Chrome 點擊拍攝按鈕，能直接叫起系統相機拍攝。 | 實機測試 |
| **跨區停放違規判定** | 當車輛登記為 B 區，巡檢選擇 A 區進行查核時，系統精準呈現橘黃色跨區違規提示。 | 業務情境驗證 |
| **看板非同步刷新** | 儀表板切換區域時，圖表與指標即時刷新且網頁無全頁重新整理現象。 | 開發者工具 Network 監控 |