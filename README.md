# 醫療院區智慧停車場車輛管理系統 (Hospital Parking Management System - HSPMS)

本系統依據 [code_artifact.md](file:///c:/AI%20TOOLS/HSPMS/code_artifact.md) 與 [ui_ux.md](file:///c:/AI%20TOOLS/HSPMS/ui_ux.md) 規格書完整開發，採用經典企業級 **ASP.NET C# Web Forms 三層架構 (3-Tier Architecture)**，搭配 **Microsoft SQL Server** 資料庫、**Bootstrap 5.3** 響應式前端與 **Chart.js** 戰情視覺化圖表，專門針對醫療院區停車管理、車位配額、員工自助申請與警衛現場行動端巡檢查核量身打造。

---

## 1. 系統架構與技術棧 (Architecture & Tech * **商業邏輯層 (BLL)**：
  * `PermitService.cs`：13 項完整車籍 CRUD、重複車牌防呆、批次展期、Excel (.xlsx)/CSV 批次匯入（智慧雙向解析科室與區域代碼/名稱）、Excel/CSV 匯出
  * `DepartmentService.cs`：部門科室配額規劃、車位使用率計算、在籍車籍檢視彈窗、科室代碼唯一性與防刪關聯保護
  * `ZoneService.cs`：停車場場域容量配置、飽和警戒門檻設定、場域啟用/停用控制與安全關聯刪除防呆
  * `ApplicationWorkflowService.cs`：員工線上申辦流程、單號自動編碼、審核狀態機流轉（支援一人申請多台車輛、嚴格限制同一車輛不可二人申請；發證時管理者可依現場配置彈性調整實際停放區域）
  * `InspectionService.cs`：車牌去符號正規化比對、跨區違規判定、過期判定、稽核日誌寫入與拍照舉證
  * `DashboardService.cs`：戰情看板 KPI 聚合、分區容量飽和度、科室佔用排行、違規趨勢分析
* **前端框架與套件**：
  * **MasterPage**：`Site.Master` 深藍醫療專業版型 (`#1A56DB`)
  * **UI 框架**：Bootstrap 5.3 + Bootstrap Icons
  * **圖表視覺**：Chart.js 4.4+ (甜甜圈飽和度圖、橫向長條圖、態勢分佈圖)
  * **試算表處理**：SheetJS (xlsx.full.min.js) 前端 Excel 讀取與雙工作表標準範本生成
  * **非同步通訊**：jQuery AJAX 串接後端 `[WebMethod]` PageMethods (全無感局部刷新，無全頁 PostBack 閃爍)
  * **警示回饋**：SweetAlert2 (現代化對話框與提示通知)

---

## 2. 核心功能頁面清單

| 頁面檔案 | 角色定位 | 核心功能特色 |
| :--- | :--- | :--- |
| **`Admin_Dashboard.aspx`** | 總務主管 / 車管中心戰情看板 | 4 大 KPI 統計卡片、各區域飽和度 (警戒線 85%)、部門車位排行、巡檢態勢、案件審核管理（支援【駁回申請、收案、待排序、待領證、發證】5 大流程、勾選發證時管理者可彈性調整實際停放區域、狀態切換過濾與關鍵字搜尋）、分區即時篩選。 |
| **`Admin_Management.aspx`** | 系統權限與人員帳號維護 | 4 大人員帳號 KPI 卡片、管理者與現場巡檢警衛帳號維護、新增/編輯權限帳號、身分角色連動設定（總務管理主管/現場巡檢人員）、快速重設密碼、一鍵帳號啟用/停用開關、防呆保護（防刪除最後一位最高管理員、防停用當前操作者）。 |
| **`Permit_Management.aspx`** | 通行證主檔維護 (13項欄位) | 完整維護 13 項核心欄位 (證號、部門、卡號、姓名、感應卡、遙控器、車色、車牌、廠牌、區域、登記日、起日、迄日)、Excel (.xlsx) 批次匯入（內建標準多工作表範本下載，科室與分區欄位皆支援代碼或全稱雙向識別）、多條件複合篩選、數位虛擬卡檢視、批次展期 (+6/+12月)、Excel/CSV 匯出。 |
| **`Dept_Management.aspx`** | 部門科室與車位配額維護 | 4 大科室指標卡片、科室代碼與全稱維護、車位配額上限規劃、視覺化配額佔用進度條、在籍車籍彈窗明細檢視、一鍵啟用/停用開關、防呆關聯保護與 Excel 匯出。 |
| **`Zone_Management.aspx`** | 停車場場域維護與容量配置 | 全院停車場域維護 (代碼唯一防呆、容量規劃、警戒門檻 %)、4 大容量指標卡片、即時視覺化飽和度進度條、一鍵營運啟用/停用開關、防呆安全關聯防刪保護。 |
| **`Employee_Portal.aspx`** | 員工自助服務入口 | **Tab 1 線上申辦** (車牌格式即時正規化驗證、停放分區志願選擇、注意事項明載實際安排停放區依院區配置為主、支援一人申請多台車輛但同一車輛禁止重複登記、LocalStorage 草稿自動防遺失)<br>**Tab 2 進度追蹤** (依工號/單號即時查詢 5 階段垂直視覺時間軸 Timeline：送件、收案、待排序、待領證、發證結案，透明呈現同仁原志願與實際核發分區)。 |
| **`Mobile_Check.aspx`** | 警衛/巡檢人員行動端專用 | 手機直向高對比 UI (WCAG 2.1 AA)、56px 大觸控熱區、HTML5 後置相機取像 (`capture="environment"`)、模擬 OCR 車牌抽取、合格 (綠)/跨區 (黃橘)/過期 (紅)/無證 (灰黑) 4 大色塊卡片、現場違規舉證拍照登錄、通報移車。 |
| **`Default.aspx`** | 系統首頁轉導 | 自動轉導至 `Admin_Dashboard.aspx`。 |

---

## 3. 資料庫結構 (`HospitalParkingDB` / `WebData`)

1. **`ParkingDepartments` (部門字典檔)**：8 大主要醫療科室 (心臟超音波、婦兒科、牙科、急診、放射、外科、護理、總務)，設定配額上限與啟用開關。
2. **`ParkingZones` (分區字典檔)**：地下 A 區 (主管醫師, 容量 100)、露天 B 區 (全日醫護, 容量 150)、第三立體 C 區 (全院綜合, 容量 250)，設定 85% 告警閥值。
3. **`ParkingPermits` (通行證主檔)**：13 個核心欄位、`CleanPlate` 計算欄位及索引、`CK_ParkingPermit_DateRange` 約束。
4. **`ParkingEmployeeApplications` (員工申請主檔)**：單號 `APP-YYYYMMDD-XXX`，狀態機 (`PENDING` $\rightarrow$ `PROCESSING` $\rightarrow$ `WAITLIST` $\rightarrow$ `APPROVED` $\rightarrow$ `COMPLETED` / `REJECTED`)，記錄 `PreferredZoneID` (同仁志願) 與 `AssignedZoneID` (管理者核定實際分區)。
5. **`ParkingInspectionLogs` (巡檢查核紀錄檔)**：現場稽核日誌 (`VALID`, `WRONG_ZONE`, `EXPIRED`, `NOT_FOUND`)、照片路徑、備註說明。
6. **`ParkingSystemAdmins` (管理者與巡檢人員權限檔)**：系統管理員與警衛帳號維護 (`Username`, `Password`, `DisplayName`, `Role`, `RoleName`, `DeptName`, `ContactPhone`, `Email`, `IsActive`, `Remarks`)。

---

## 4. 快速建置與執行說明

### 步驟 1：資料庫連線配置與初始化
系統支援連線至遠端主機或本機 LocalDB，預設已配置於 `Web.config`：
* **遠端資料庫連線字串**：
  ```text
  Server=210.61.91.243;Database=WebData;User Id=sa;Password=pjk223ty;TrustServerCertificate=True;MultipleActiveResultSets=true;
  ```
* **本機測試 LocalDB 初始化**（若欲於本機測試）：
  ```powershell
  sqlcmd -S "(localdb)\MSSQLLocalDB" -f 65001 -i "g:\AI Tools\HSPMS\init_database.sql"
  ```

### 步驟 2：編譯專案
專案已提供標準 MSBuild 檔案，可直接使用 Visual Studio 開啟 `HospitalParking.sln`，或於終端機執行 MSBuild：
```powershell
& "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" "HospitalParking.sln" /p:Configuration=Debug /v:m
```
編譯成功後輸出成果於 `bin\HospitalParking.dll`。

### 步驟 3：啟動 IIS Express 本地伺服器
```powershell
& "C:\Program Files\IIS Express\iisexpress.exe" /path:"g:\AI Tools\HSPMS" /port:8088 /clr:v4.0
```

### 步驟 4：瀏覽系統端點
使用瀏覽器造訪以下端點：
* **首頁 / 戰情看板**：`http://localhost:8088/Admin_Dashboard.aspx`
* **管理者與巡檢人員維護**：`http://localhost:8088/Admin_Management.aspx`
* **車輛通行證主檔維護 (含 Excel 批次匯入)**：`http://localhost:8088/Permit_Management.aspx`
* **部門科室與配額維護**：`http://localhost:8088/Dept_Management.aspx`
* **停車場場域維護與配置**：`http://localhost:8088/Zone_Management.aspx`
* **員工線上申辦與進度追蹤**：`http://localhost:8088/Employee_Portal.aspx`
* **警衛現場行動巡檢查核**：`http://localhost:8088/Mobile_Check.aspx`
* **首頁自動轉導**：`http://localhost:8088/Default.aspx`

