# 智慧停車場車輛管理系統 UI/UX 規格規劃書 (UI/UX Specification)

## 1. 系統設計準則與視覺規範 (Design System)

### 1.1 色彩計畫 (Color Palette)
為符合醫療院區專業、嚴謹且高可讀性的需求，採用以下標準色票：

| 色彩角色 | 色碼 (HEX) | 代表含意 / 使用場景 |
| :--- | :--- | :--- |
| **Primary (主色)** | `#1A56DB` | 醫療深藍；導覽列頂部、主要執行按鈕、選中狀態 |
| **Secondary (輔色)** | `#4B5563` | 中性冷灰；次要按鈕、邊框、次要標題 |
| **Success (合格/成功)** | `#0E9F6E` | 查驗合格、審核通過、正常有效證件 |
| **Warning (警示/跨區)** | `#E3A008` | 跨區停放違規、即將到期（30天內）、審核中 |
| **Danger (危險/違規)** | `#F05252` | 未授權車牌、逾期停權、駁回申請、違規舉報 |
| **Background (背景底色)** | `#F9FAFB` | 頁面底色，降低高對比產生的視覺疲勞 |
| **Surface (卡片面板)** | `#FFFFFF` | 表單卡片、彈窗面板、資料表格容器 |

### 1.2 字體與排版階層 (Typography Hierarchy)
* **字體家族**：優先使用系統原生無襯線字體，確保不同裝置渲染一致性：
  `font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", "PingFang TC", "Microsoft JhengHei", sans-serif;`
* **階層大小與行距**：
  * **H1 / 戰情指標數值**：`28px ~ 32px` / Bold / 行高 `1.2`
  * **H2 / 頁面主要標題**：`20px ~ 24px` / Semi-bold / 行高 `1.3`
  * **H3 / 卡片區塊標題**：`16px ~ 18px` / Medium / 行高 `1.4`
  * **Body / 表單標籤與內文**：`14px ~ 15px` / Regular / 行高 `1.5`
  * **Caption / 提示與註解文字**：`12px` / Regular / 行高 `1.4`

### 1.3 互動與反饋原則 (Interaction & Feedback)
* **表單即時檢核**：車牌輸入欄位強制轉換大寫，離焦（`blur`）時即刻驗證台灣車牌正規表達式，錯誤以紅色外框與下方文字提示。
* **行動端大觸控熱區**：行動巡檢畫面按鈕最小高度不低於 **48px**，關鍵「拍攝查核」按鈕設定為大尺寸按鈕（`btn-lg`，高度 **54px**）。
* **異步無感刷新**：所有統計數據、進度查詢與辨識結果皆透過 jQuery AJAX / Fetch 呼叫後端 `[WebMethod]`，避免 Web Forms 傳統 PostBack 造成畫面全頁閃爍。

---

## 2. 核心介面版面規劃 (Screen Layouts & Wireframes)

### 2.1 頁面 1：管理者戰情看板 (`Admin_Dashboard.aspx`)
* **使用者**：總務主管、停車場管理員
* **裝置**：桌面寬螢幕（Desktop 1920x1080 / 1440x900）
* **版面結構**：左側固定選單（240px），右側主工作區（Fluid Container）。

```
+-----------------------------------------------------------------------------------------+
| [LOGO] 醫療院區停車場管理系統              [分區快選: 全部 v] [通知 (3)] [管理員: 陳專員 v]|
+-------------+---------------------------------------------------------------------------+
| [功能選單]  |  總覽戰情看板                                             2026/10/17 10:30|
| - 戰情看板  +--------------------+--------------------+--------------------+------------+
| - 車籍維護  | [有效停車證總數]   | [待審核申請單]     | [30日內即將到期]   | [今日巡檢] |
| - 部門配額  |      482 張        |       14 件        |       28 張        |   126 次   |
| - 區域管理  +--------------------+--------------------+--------------------+------------+
| - 審核中心  | 各停車區域容量飽和度 (Doughnut)         | 部門車位佔用排行 (Bar Chart)       |
| - 巡檢紀錄  |   [ A區: 88%  B區: 92%  C區: 65% ]     |   [ 婦兒科: 45  心臟超音波: 38 ...]|
|             +-----------------------------------------+---------------------------------+
|             | 最新待辦審核 (前 5 筆)                                                    |
|             | 單號           工號     姓名     科室         車牌       志願區   操作    |
|             | APP-202610-01  EMP102   王大明   心臟超音波   ABC-1234   A區     [審核]   |
+-------------+---------------------------------------------------------------------------+
```

### 2.2 頁面 2：車輛通行證維護與管理 (`Permit_Management.aspx`)
* **使用者**：後台管理人員
* **功能要點**：包含所有 13 項欄位（停車證號、部門、卡號、姓名、感應卡、遙控器、車輛顏色、車牌號碼、車輛廠牌、停車區域、登記日期、開始日期、停車日期）之 CRUD、進階多條件篩選、批次展期與 Excel 匯出。

```
+-----------------------------------------------------------------------------------------+
| 車輛通行證主檔維護                          [+ 新增通行證] [批次展期] [匯出 Excel]      |
+-----------------------------------------------------------------------------------------+
| 篩選條件：                                                                              |
| [部門: 全部 v]  [區域: 全部 v]  [狀態: 有效 v]  [關鍵字: 車牌/姓名/卡號...]   [查詢] [重置]|
+-----------------------------------------------------------------------------------------+
| 停車證號   | 部門     | 姓名   | 車牌號碼 | 廠牌/顏色  | 區域 | 門禁卡號 | 遙控器 | 到期日     | 狀態 | 操作      |
+------------+----------+--------+----------+------------+------+----------+--------+------------+------+-----------+
| PRK-202601 | 心臟超音波| 李醫師 | ABC-1234 | Toyota/白  | A區  | CAD-8891 | RC-102 | 2027/10/31 | 正常 | [編][展][退]|
| PRK-202602 | 婦兒科   | 林護理 | 5678-EF  | Honda/灰   | B區  | CAD-8892 | RC-103 | 2026/11/05 | 即期 | [編][展][退]|
| PRK-202603 | 牙科     | 張技術 | 9876-AA  | Nissan/黑  | C區  | CAD-8893 | --     | 2026/09/30 | 逾期 | [編][展][退]|
+-----------------------------------------------------------------------------------------+
| 共 482 筆資料 | << < [1] 2 3 4 5 > >> | 每頁顯示 [20 v] 筆                              |
+-----------------------------------------------------------------------------------------+
```

### 2.3 頁面 3：員工自助申請與進度查詢 (`Employee_Portal.aspx`)
* **使用者**：全體員工、醫護人員
* **裝置**：桌面瀏覽器、手機平板自適應（Mobile Responsive）
* **版面結構**：頁籤切換（Tab 1: 填寫申請 / Tab 2: 進度追蹤）。

#### Tab 1: 線上申辦表單
```
+-------------------------------------------------------------+
| 停車證線上申請                                              |
+-------------------------------------------------------------+
| 申請人姓名: [ 陳護理師         ]  員工工號: [ EMP0823     ] |
| 服務部門  : [ 婦兒科         v ]  聯絡分機: [ 31012       ] |
+-------------------------------------------------------------+
| 車輛資訊                                                    |
| 車牌號碼  : [ ABC-5678        ]  (例: ABC-1234 或 1234-AB) |
| 車輛廠牌  : [ Toyota          ]  車輛顏色: [ 珍珠白       ] |
| 志願停放區: [ B區 (地下室)    v ]  (該區目前剩餘配額: 12 位) |
+-------------------------------------------------------------+
| 硬體配發注意事項                                            |
| ※ 門禁感應卡與鐵捲門遙控器將於管理單位審核通過後，至總務處領證 |
|   時現場登錄配發並收取保證金。                              |
+-------------------------------------------------------------+
|                    [ 暫存草稿 ]   [ 確認送出申請 ]          |
+-------------------------------------------------------------+
```

#### Tab 2: 進度可視化追蹤 (Progress Timeline)
```
+-------------------------------------------------------------+
| 申請單號: APP-20261017-003           申請日期: 2026/10/17   |
| 車牌號碼: ABC-5678                   申請區域: B區          |
+-------------------------------------------------------------+
| 處理進度：                                                  |
|   (v) 已送出申請      ── 2026/10/17 09:15                   |
|    |                                                        |
|   (*) 總務審核中      ── 預計 1~2 個工作天                  |
|    |                                                        |
|   ( ) 核准待領證      ── 待通知 (攜帶證件與保證金至總務處)  |
|    |                                                        |
|   ( ) 已發證結案      ── 完成感應卡/遙控器綁定              |
+-------------------------------------------------------------+
```

### 2.4 頁面 4：行動端現場查核巡檢 (`Mobile_Check.aspx`)
* **使用者**：停車場警衛、駐衛巡檢人員
* **裝置**：智慧型手機直向螢幕（iOS Safari / Android Chrome）
* **版面重點**：高對比、單手操作、拍照辨識與手動快速查核。

```
+-----------------------------------+
| [=] 停車場行動巡檢         [A區 v] |
+-----------------------------------+
|                                   |
|   +---------------------------+   |
|   |                           |   |
|   |    [ 相機圖示 ]           |   |
|   |                           |   |
|   |    點擊拍攝車牌快速查核   |   |
|   |                           |   |
|   +---------------------------+   |
|                                   |
|   ── 或輸入車牌號碼查驗 ──        |
|   +--------------------+--------+ |
|   | ABC-1234           | [查核] | |
|   +--------------------+--------+ |
|                                   |
+-----------------------------------+
| [查驗結果狀態卡片]                |
| +-------------------------------+ |
| | 判定: [ 合格 - 授權停放 ]      | |
| | 車牌: ABC-1234   車色: 白色   | |
| | 車主: 李醫師     科室: 心臟科 | |
| | 授權區域: A區    到期: 2027年 | |
| | 感應卡: CAD-8891 遙控: RC-102 | |
| +-------------------------------+ |
| (若跨區違規，此處顯示紅色並出現按鈕) |
| [ 登記跨區違規 / 拍照舉證存檔 ]   |
+-----------------------------------+
```

---

## 3. UI 狀態規範與反饋邏輯 (UI States & Feedback Matrix)

針對巡檢與維護過程中的不同情境，嚴格規範介面元件的視覺呈現與輔助文案：

| 業務狀態 (State) | 標籤樣式 (Badge) | 卡片邊框 / 背景色 | 輔助文字與提示訊息 | 允許後續動作 |
| :--- | :--- | :--- | :--- | :--- |
| **正常授權 (Valid)** | `bg-success` 綠色 | `#DEF7EC` 淡綠底 / 綠框 | 「該車輛具備本區域有效停放授權」 | 檢視詳細車籍資料 |
| **跨區違規 (Wrong Zone)** | `bg-warning` 黃/橘 | `#FEF08A` 銘黃底 / 橘框 | 「警告：該車登記為【B區】，目前停放於【A區】」 | [登記跨區違規] [發送移車通知] |
| **過期停權 (Expired)** | `bg-danger` 紅色 | `#FDE8E8` 淺紅底 / 紅框 | 「證件已於 2026/09/30 屆期，尚未展期」 | [登記過期違規] [通報管理處] |
| **無紀錄車輛 (Unknown)** | `bg-dark` 黑色 | `#F3F4F6` 灰黑底 / 黑框 | 「系統查無此車籍資料，疑為外來未授權車輛」 | [通報警衛室] [現場拍照留存] |
| **網路中斷 (Offline)** | `bg-secondary` 灰色 | `#E5E7EB` 灰底 | 「網路連線異常，已切換至快取離線查對模式」 | [重試連線] |

---

## 4. ASP.NET C# Web Forms 前端實作骨架範例

### 4.1 通用前端 MasterPage 設定 (`Site.Master`)
引入 Bootstrap 5、Bootstrap Icons 與 jQuery，確保響應式容器正常運作：

```html
<%@ Master Language="C#" AutoEventWireup="true" CodeBehind="Site.master.cs" Inherits="HospitalParking.SiteMaster" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title><%: Page.Title %> - 醫療院區停車場管理系統</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet" />
    <style>
        :root {
            --bs-primary: #1A56DB;
            --bs-body-bg: #F9FAFB;
        }
        body { background-color: var(--bs-body-bg); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang TC", sans-serif; }
        .navbar-hospital { background-color: #1A56DB; color: white; }
        .card-dashboard { border-radius: 10px; border: none; box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
    </style>
    <asp:ContentPlaceHolder ID="HeadContent" runat="server"></asp:ContentPlaceHolder>
</head>
<body>
    <form id="formMain" runat="server">
        <asp:ScriptManager ID="smGlobal" runat="server" EnablePageMethods="true"></asp:ScriptManager>
        
        <nav class="navbar navbar-expand-lg navbar-dark navbar-hospital sticky-top">
            <div class="container-fluid">
                <a class="navbar-brand font-weight-bold" href="Admin_Dashboard.aspx">
                    <i class="bi bi-p-square-fill me-2"></i>院區車輛管理系統
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navContent">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navContent">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                        <li class="nav-item"><a class="nav-link" href="Admin_Dashboard.aspx"><i class="bi bi-speedometer2 me-1"></i>管理看板</a></li>
                        <li class="nav-item"><a class="nav-link" href="Permit_Management.aspx"><i class="bi bi-card-checklist me-1"></i>車籍維護</a></li>
                        <li class="nav-item"><a class="nav-link" href="Employee_Portal.aspx"><i class="bi bi-person-badge me-1"></i>員工申請</a></li>
                        <li class="nav-item"><a class="nav-link text-warning" href="Mobile_Check.aspx"><i class="bi bi-camera me-1"></i>行動巡檢</a></li>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="container-fluid py-3">
            <asp:ContentPlaceHolder ID="MainContent" runat="server"></asp:ContentPlaceHolder>
        </div>
    </form>

    <!-- JS Scripts -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <asp:ContentPlaceHolder ID="ScriptContent" runat="server"></asp:ContentPlaceHolder>
</body>
</html>
```

---

## 5. 易用性評估與測試驗收清單 (UX Acceptance Criteria)

為確保上線後符合醫護人員與巡檢人員的操作直覺，驗收測試應涵蓋以下項目：

* [ ] **行動端取像延遲指標**：警衛於行動裝置點擊「拍攝車牌」，開啟相機、對焦拍照至前端壓縮完成，應於 **2 秒內** 進入辨識佇列。
* [ ] **車牌輸入自動防呆**：手動輸入車牌時，若輸入小寫字母自動強制轉換為大寫；輸入非合法字符（如特殊標點）時應即時阻絕。
* [ ] **高對比陽光可讀性**：在戶外強光（如地面露天 C 區）操作行動查驗頁面時，合格與違規狀態卡片對比度符合 **WCAG 2.1 AA 級標準（4.5:1 以上）**。
* [ ] **三班制輪班友善性**：夜間值班人員於夜間 02:00 使用手機查詢進度或填單時，文字與按鈕元件無擠壓、無斷行跑版情形。
* [ ] **表單狀態防遺失**：員工填寫申請表若中途跳轉頁面，返回時已輸入之車號與科室資料需由 LocalStorage 自動還原暫存草稿。