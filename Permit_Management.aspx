<%@ Page Title="車輛通行證維護" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Permit_Management.aspx.cs" Inherits="HospitalParking.Permit_Management" EnableViewState="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .filter-card {
            background-color: #FFFFFF;
            border-radius: var(--hsp-radius);
            box-shadow: var(--hsp-shadow-sm);
            border: 1px solid var(--hsp-border);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container-fluid px-3 px-lg-4">
    <!-- 頂部標題與主操作 -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center py-2 mb-3 border-bottom gap-2">
        <div>
            <h4 class="mb-1 fw-bold text-dark">
                <i class="bi bi-card-checklist text-primary me-2"></i>車輛通行證主檔維護 (Permit Master)
            </h4>
            <p class="text-muted small mb-0">全面管理院區 13 項通行證資訊、門禁感應卡、鐵捲門遙控器綁定與效期展期。</p>
        </div>
        <div class="d-flex align-items-center gap-2 flex-wrap">
            <button type="button" class="btn btn-sm btn-outline-success" onclick="openBatchImportModal();">
                <i class="bi bi-file-earmark-excel me-1"></i>批次匯入 (Excel)
            </button>
            <button type="button" class="btn btn-sm btn-outline-primary" onclick="openBatchExtendModal();">
                <i class="bi bi-calendar-plus me-1"></i>批次展期
            </button>
            <button type="button" class="btn btn-sm btn-outline-secondary" onclick="exportPermitsCsv();">
                <i class="bi bi-file-earmark-spreadsheet me-1"></i>匯出 CSV
            </button>
            <button type="button" class="btn btn-sm btn-primary shadow-sm" onclick="openCreateModal();">
                <i class="bi bi-plus-circle me-1"></i>新增通行證
            </button>
        </div>
    </div>

    <!-- 篩選查詢條件卡片 -->
    <div class="filter-card p-3 mb-3">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-sm-6 col-md-2">
                <label class="form-label small text-muted mb-1">所屬部門</label>
                <select id="ddlSearchDept" class="form-select form-select-sm">
                    <option value="">-- 全部部門 --</option>
                </select>
            </div>
            <div class="col-12 col-sm-6 col-md-2">
                <label class="form-label small text-muted mb-1">停車區域</label>
                <select id="ddlSearchZone" class="form-select form-select-sm">
                    <option value="">-- 全部區域 --</option>
                </select>
            </div>
            <div class="col-12 col-sm-6 col-md-2">
                <label class="form-label small text-muted mb-1">效期狀態</label>
                <select id="ddlSearchStatus" class="form-select form-select-sm">
                    <option value="">-- 全部狀態 --</option>
                    <option value="ACTIVE" selected>正常有效 (Active)</option>
                    <option value="EXPIRING_SOON">30日內即將到期</option>
                    <option value="EXPIRED">已過期 (Expired)</option>
                    <option value="REVOKED">已註銷 (Revoked)</option>
                </select>
            </div>
            <div class="col-12 col-sm-6 col-md-4">
                <label class="form-label small text-muted mb-1">關鍵字檢索</label>
                <div class="input-group input-group-sm">
                    <input type="text" id="txtKeyword" class="form-control" placeholder="輸入 車牌 / 姓名 / 卡號 / 停車證號 / 感應卡..." />
                    <button class="btn btn-primary" type="button" onclick="loadPermitsData();">
                        <i class="bi bi-search me-1"></i>查詢
                    </button>
                    <button class="btn btn-outline-secondary" type="button" onclick="resetSearch();">
                        <i class="bi bi-arrow-counterclockwise"></i>
                    </button>
                </div>
            </div>
            <div class="col-12 col-md-2 text-md-end">
                <span class="small text-muted" id="lblResultCount">顯示 0 筆資料</span>
            </div>
        </div>
    </div>

    <!-- 通行證清單表格 -->
    <div class="hsp-card">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table hsp-table align-middle mb-0" id="tblPermits">
                    <thead>
                        <tr>
                            <th style="width: 40px;" class="text-center">
                                <input type="checkbox" id="chkSelectAll" class="form-check-input" onchange="toggleSelectAll(this);" />
                            </th>
                            <th>停車證號</th>
                            <th>部門科室</th>
                            <th>姓名 (卡號)</th>
                            <th>車牌號碼</th>
                            <th>廠牌 / 顏色</th>
                            <th>停車區域</th>
                            <th>感應卡 / 遙控器</th>
                            <th>有效起訖日期</th>
                            <th>狀態</th>
                            <th class="text-center" style="min-width: 140px;">操作</th>
                        </tr>
                    </thead>
                    <tbody id="permitTableBody">
                        <tr>
                            <td colspan="11" class="text-center py-5 text-muted">
                                <span class="spinner-border spinner-border-sm me-2"></span>載入通行證清單中...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- 新增 / 編輯通行證 Modal (完整 13 欄位) -->
<div class="modal fade" id="permitModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title" id="modalTitle"><i class="bi bi-credit-card-2-front me-2"></i>新增車輛通行證</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <div id="frmPermit">
                    <input type="hidden" id="hidPermitID" value="0" />
                    
                    <h6 class="text-primary border-bottom pb-2 mb-3 fw-bold">
                        <i class="bi bi-info-circle me-1"></i>1. 基本證照與持有人資訊
                    </h6>
                    <div class="row g-3 mb-3">
                        <div class="col-md-4">
                            <label class="form-label required small">停車證號</label>
                            <input type="text" id="txtPermitNumber" class="form-control text-uppercase font-monospace" required placeholder="例: PRK-202610-001" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">所屬部門科室</label>
                            <select id="modalDept" class="form-select" required></select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">車主姓名</label>
                            <input type="text" id="txtOwnerName" class="form-control" required placeholder="例: 林志豪 醫師" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small">員工卡號 / 工號</label>
                            <input type="text" id="txtCardNumber" class="form-control font-monospace" placeholder="例: EMP1024" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small">門禁感應卡號 (RFID/eTag)</label>
                            <input type="text" id="txtSensorTagNumber" class="form-control font-monospace" placeholder="例: TAG-8812" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small">鐵捲門遙控器編號</label>
                            <input type="text" id="txtRemoteControllerNo" class="form-control font-monospace" placeholder="例: RC-205" />
                        </div>
                    </div>

                    <h6 class="text-primary border-bottom pb-2 mb-3 fw-bold">
                        <i class="bi bi-car-front me-1"></i>2. 車籍與停放區域資訊
                    </h6>
                    <div class="row g-3 mb-3">
                        <div class="col-md-4">
                            <label class="form-label required small">車牌號碼</label>
                            <input type="text" id="txtLicensePlate" class="form-control text-uppercase font-monospace" required placeholder="例: ABC-1234" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">車輛廠牌</label>
                            <input type="text" id="txtVehicleBrand" class="form-control" required placeholder="例: Toyota RAV4" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">車輛顏色</label>
                            <input type="text" id="txtVehicleColor" class="form-control" required placeholder="例: 珍珠白" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label required small">核准停車區域</label>
                            <select id="modalZone" class="form-select" required></select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small">證件狀態</label>
                            <select id="modalStatus" class="form-select">
                                <option value="ACTIVE">正常有效 (ACTIVE)</option>
                                <option value="EXPIRED">逾期未繳 (EXPIRED)</option>
                                <option value="REVOKED">註銷停權 (REVOKED)</option>
                            </select>
                        </div>
                    </div>

                    <h6 class="text-primary border-bottom pb-2 mb-3 fw-bold">
                        <i class="bi bi-calendar3 me-1"></i>3. 有效起訖日期與備註
                    </h6>
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label small">登記日期</label>
                            <input type="date" id="txtRegisterDate" class="form-control" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">開始生效日期</label>
                            <input type="date" id="txtStartDate" class="form-control" required />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">停車到期日期</label>
                            <input type="date" id="txtExpireDate" class="form-control" required />
                        </div>
                        <div class="col-12">
                            <label class="form-label small">備註說明</label>
                            <input type="text" id="txtRemarks" class="form-control" placeholder="例: 心臟內科門診主任專用格位配給、繳費收據號碼..." />
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer bg-light">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary px-4" onclick="savePermitData();">
                    <i class="bi bi-check-lg me-1"></i>確認儲存
                </button>
            </div>
        </div>
    </div>
</div>

<!-- 檢視數位虛擬通行證 Modal (Virtual Card) -->
<div class="modal fade" id="modalViewPermit" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-body p-4">
                <div class="permit-virtual-card mb-3">
                    <div class="d-flex justify-content-between align-items-start mb-3">
                        <div>
                            <div class="badge bg-white text-primary mb-1">HSPMS 醫療院區通行證</div>
                            <div class="fs-4 fw-bold" id="viewPermitNum">PRK-202610-001</div>
                        </div>
                        <span class="badge bg-success fs-6" id="viewStatusBadge">正常</span>
                    </div>

                    <div class="d-flex align-items-center mb-3">
                        <div class="display-6 fw-bold font-monospace bg-white text-dark px-3 py-1 rounded-3 shadow-sm me-3" id="viewPlate">
                            ABC-1234
                        </div>
                        <div>
                            <div class="fw-bold fs-5" id="viewOwner">李建榮 醫師</div>
                            <small class="opacity-75" id="viewDept">心臟超音波室</small>
                        </div>
                    </div>

                    <div class="row g-2 small border-top border-white border-opacity-25 pt-2">
                        <div class="col-6"><strong>核准分區：</strong><span id="viewZone">地下A區</span></div>
                        <div class="col-6"><strong>車型顏色：</strong><span id="viewVehicle">Toyota / 白</span></div>
                        <div class="col-6"><strong>感應卡號：</strong><span id="viewTag">TAG-8801</span></div>
                        <div class="col-6"><strong>遙控編號：</strong><span id="viewRc">RC-101</span></div>
                        <div class="col-12 mt-2"><strong>有效期限：</strong><span id="viewDates">2026-01-01 ~ 2027-12-31</span></div>
                    </div>
                </div>

                <div class="text-center">
                    <small class="text-muted d-block mb-3">※ 本證為院區合法停車憑證，出入請配合警衛人員查核。</small>
                    <button type="button" class="btn btn-secondary btn-sm px-4" data-bs-dismiss="modal">關閉</button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 批次展期 Modal -->
<div class="modal fade" id="modalBatchExtend" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title"><i class="bi bi-calendar-plus me-2"></i>車籍通行證批次展期</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <p>已勾選 <strong class="text-primary fs-5" id="lblBatchSelectedCount">0</strong> 筆車籍通行證進行延長效期。</p>
                <div class="mb-3">
                    <label class="form-label font-weight-bold">展期時長：</label>
                    <select id="ddlBatchMonths" class="form-select form-select-lg">
                        <option value="12" selected>延長 1 年 (12 個月)</option>
                        <option value="6">延長 半年 (6 個月)</option>
                        <option value="3">延長 1 季 (3 個月)</option>
                    </select>
                </div>
                <div class="alert alert-info small mb-0">
                    <i class="bi bi-info-circle me-1"></i>展期將自各證件原到期日累計展期；若該證件目前已逾期，則自今日起算。
                </div>
            </div>
            <div class="modal-footer bg-light">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-success px-4" onclick="submitBatchExtend();">
                    <i class="bi bi-check-lg me-1"></i>執行展期
                </button>
            </div>
        </div>
    </div>
</div>

<!-- 批次匯入 Modal (以 Excel 試算表為主) -->
<div class="modal fade" id="modalBatchImport" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title d-flex align-items-center">
                    <i class="bi bi-file-earmark-excel-fill me-2"></i>車輛通行證批次匯入 (Excel 試算表)
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <!-- 流程指引卡片 -->
                <div class="row g-3 mb-3">
                    <div class="col-md-4">
                        <div class="card h-100 border-0 bg-light p-3">
                            <div class="d-flex align-items-center mb-2">
                                <span class="badge bg-success rounded-circle me-2 px-2 py-1">1</span>
                                <h6 class="mb-0 fw-bold">下載 Excel 標準範本</h6>
                            </div>
                            <p class="text-muted small mb-3">請下載標準 Excel (.xlsx) 範本，內建標準車籍欄位、資料填寫規範與院區代碼對照表。</p>
                            <button type="button" class="btn btn-success btn-sm w-100 fw-bold shadow-sm mb-2" onclick="downloadImportExcelTemplate();">
                                <i class="bi bi-file-earmark-arrow-down-fill me-1"></i>下載 Excel 範本檔 (.xlsx)
                            </button>
                            <div class="text-center mt-auto">
                                <a href="javascript:void(0)" onclick="downloadImportCsvTemplate();" class="text-muted small text-decoration-none">
                                    <i class="bi bi-filetype-csv me-1"></i>或下載 CSV 格式範本
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-8">
                        <div class="card h-100 border-0 bg-light p-3">
                            <div class="d-flex align-items-center mb-2">
                                <span class="badge bg-success rounded-circle me-2 px-2 py-1">2</span>
                                <h6 class="mb-0 fw-bold">選擇匯入方式並上傳 Excel</h6>
                            </div>
                            <ul class="nav nav-pills nav-fill mb-2" id="importTab" role="tablist">
                                <li class="nav-item" role="presentation">
                                    <button class="nav-link active py-1 small fw-bold" id="tab-file-btn" data-bs-toggle="pill" data-bs-target="#tab-file" type="button" role="tab">
                                        <i class="bi bi-file-earmark-excel-fill text-success me-1"></i>上傳 Excel 檔案 (.xlsx / .xls)
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button class="nav-link py-1 small" id="tab-text-btn" data-bs-toggle="pill" data-bs-target="#tab-text" type="button" role="tab">
                                        <i class="bi bi-clipboard2-data me-1"></i>直接貼上 Excel 儲存格內容
                                    </button>
                                </li>
                            </ul>
                            <div class="tab-content" id="importTabContent">
                                <div class="tab-pane fade show active" id="tab-file" role="tabpanel">
                                    <div class="input-group">
                                        <input type="file" id="fileExcelInput" class="form-control" accept=".xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel" onchange="handleExcelFile(this);" />
                                        <button class="btn btn-secondary" type="button" onclick="clearImportData();">清空</button>
                                    </div>
                                    <small class="text-muted mt-1 d-block">
                                        <i class="bi bi-check2-circle text-success me-1"></i>支援 Microsoft Excel (.xlsx / .xls) 及 CSV 檔案，系統自動讀取第一工作表並解析。
                                    </small>
                                </div>
                                <div class="tab-pane fade" id="tab-text" role="tabpanel">
                                    <textarea id="txtCsvContent" class="form-control font-monospace small" rows="3" placeholder="支援直接從 Excel 表格反白複製 (Ctrl+C) 並貼於此處 (Ctrl+V)（支援定位點 Tab 及逗號分隔）..."></textarea>
                                    <div class="d-flex justify-content-end mt-1">
                                        <button type="button" class="btn btn-sm btn-outline-success" onclick="parseRawPasteText();">
                                            <i class="bi bi-check-circle me-1"></i>解析貼上內容
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 匯入選項與預覽資訊條 -->
                <div class="d-flex flex-wrap justify-content-between align-items-center bg-white p-2 rounded border mb-2">
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" id="chkSkipDuplicates" checked>
                        <label class="form-check-label small fw-semibold" for="chkSkipDuplicates">
                            遇到已存在之有效車牌時自動略過（允許同仁一人多車，但一車不可二人申請）
                        </label>
                    </div>
                    <div>
                        <span class="badge bg-secondary me-2" id="badgeParsedCount">尚未讀取資料</span>
                        <span class="badge bg-success" id="badgeValidCount" style="display:none;">可匯入: 0 筆</span>
                    </div>
                </div>

                <!-- 解析預覽表格 -->
                <div class="card border">
                    <div class="card-header bg-white py-2 d-flex justify-content-between align-items-center">
                        <span class="small fw-bold text-dark"><i class="bi bi-file-earmark-spreadsheet text-success me-1"></i>Excel 資料預覽與檢核 (<span id="lblPreviewSummary">請先載入 Excel 檔案</span>)</span>
                        <small class="text-muted">綠色表示合格，紅字表示必填欄位缺漏</small>
                    </div>
                    <div class="table-responsive" style="max-height: 280px;">
                        <table class="table table-sm table-hover align-middle mb-0" id="tblImportPreview" style="font-size: 0.85rem;">
                            <thead class="table-light sticky-top">
                                <tr>
                                    <th style="width: 45px;" class="text-center">#</th>
                                    <th>部門名稱</th>
                                    <th>員工姓名</th>
                                    <th>員工卡號</th>
                                    <th>車牌號碼</th>
                                    <th>廠牌 / 顏色</th>
                                    <th>停放區域</th>
                                    <th>感應卡 / 遙控器</th>
                                    <th>起訖日期</th>
                                    <th>備註</th>
                                    <th>檢核狀態</th>
                                </tr>
                            </thead>
                            <tbody id="importPreviewBody">
                                <tr>
                                    <td colspan="11" class="text-center text-muted py-4">
                                        <i class="bi bi-file-earmark-excel display-6 d-block text-success opacity-75 mb-2"></i>
                                        請由上方下載 Excel 範本、填妥後上傳 Excel 檔案 (.xlsx / .xls) 進行預覽檢核
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- 錯誤與警告資訊區塊 (匯入執行後或預覽發現) -->
                <div id="importErrorAlert" class="alert alert-danger mt-3 py-2 px-3 small" style="display:none; max-height: 150px; overflow-y: auto;">
                </div>
            </div>
            <div class="modal-footer bg-light py-2">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-success btn-sm px-4 shadow-sm" id="btnExecuteImport" onclick="executeBatchImport();" disabled>
                    <i class="bi bi-cloud-arrow-up me-1"></i>開始執行 Excel 批次匯入 (<span id="btnImportCount">0</span> 筆)
                </button>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script>
    var currentPermits = [];
    var currentLookups = null;

    $(document).ready(function () {
        loadLookups();
        loadPermitsData();
    });

    function loadLookups() {
        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/GetLookupOptions",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                currentLookups = d;
                var deptOpts = '<option value="">-- 全部部門 --</option>';
                var modalDeptOpts = '<option value="">-- 請選擇部門 --</option>';
                d.Departments.forEach(dept => {
                    deptOpts += `<option value="${dept.DeptID}">${dept.DeptName}</option>`;
                    modalDeptOpts += `<option value="${dept.DeptID}">${dept.DeptName} (上限: ${dept.QuotaLimit})</option>`;
                });
                $('#ddlSearchDept').html(deptOpts);
                $('#modalDept').html(modalDeptOpts);

                var zoneOpts = '<option value="">-- 全部區域 --</option>';
                var modalZoneOpts = '<option value="">-- 請選擇區域 --</option>';
                d.Zones.forEach(zone => {
                    zoneOpts += `<option value="${zone.ZoneID}">${zone.ZoneName}</option>`;
                    modalZoneOpts += `<option value="${zone.ZoneID}">${zone.ZoneName} (剩餘: ${zone.RemainingQuota})</option>`;
                });
                $('#ddlSearchZone').html(zoneOpts);
                $('#modalZone').html(modalZoneOpts);
            }
        });
    }

    function loadPermitsData() {
        var criteria = {
            DeptID: $('#ddlSearchDept').val() ? parseInt($('#ddlSearchDept').val()) : null,
            ZoneID: $('#ddlSearchZone').val() ? parseInt($('#ddlSearchZone').val()) : null,
            Status: $('#ddlSearchStatus').val(),
            Keyword: $('#txtKeyword').val().trim()
        };

        $('#permitTableBody').html('<tr><td colspan="11" class="text-center py-4 text-muted"><span class="spinner-border spinner-border-sm me-2"></span>載入中...</td></tr>');

        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/SearchPermits",
            data: JSON.stringify({ criteria: criteria }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                currentPermits = res.d || [];
                renderTable(currentPermits);
            },
            error: function () {
                Swal.fire('錯誤', '無法載入通行證資料，請重試。', 'error');
            }
        });
    }

    function renderTable(list) {
        $('#chkSelectAll').prop('checked', false);
        $('#lblResultCount').text(`顯示 ${list.length} 筆資料`);

        if (list.length === 0) {
            $('#permitTableBody').html('<tr><td colspan="11" class="text-center py-5 text-muted"><i class="bi bi-inbox fs-3 d-block mb-1"></i>查無相符之通行證紀錄</td></tr>');
            return;
        }

        var html = '';
        list.forEach((p, idx) => {
            var statusBadge = '';
            if (p.Status === 'ACTIVE') {
                if (p.IsExpiringSoon) {
                    statusBadge = `<span class="badge badge-status-warning"><i class="bi bi-hourglass-split me-1"></i>即期 (${p.DaysRemaining}天)</span>`;
                } else {
                    statusBadge = '<span class="badge badge-status-valid"><i class="bi bi-check-circle me-1"></i>正常</span>';
                }
            } else if (p.Status === 'EXPIRED') {
                statusBadge = '<span class="badge badge-status-danger"><i class="bi bi-exclamation-octagon me-1"></i>逾期</span>';
            } else {
                statusBadge = '<span class="badge badge-status-dark">已註銷</span>';
            }

            html += `
                <tr>
                    <td class="text-center">
                        <input type="checkbox" class="form-check-input chk-permit" value="${p.PermitID}" />
                    </td>
                    <td><strong class="font-monospace text-primary">${p.PermitNumber}</strong></td>
                    <td>${p.DeptName}</td>
                    <td>
                        <strong>${p.OwnerName}</strong>
                        ${p.CardNumber ? `<br><small class="text-muted font-monospace">${p.CardNumber}</small>` : ''}
                    </td>
                    <td><span class="license-plate-badge">${p.LicensePlate}</span></td>
                    <td>
                        <span class="small">${p.VehicleBrand}</span><br>
                        <span class="badge bg-light text-dark border small">${p.VehicleColor}</span>
                    </td>
                    <td><span class="badge bg-info text-dark">${p.ZoneName}</span></td>
                    <td>
                        <small class="d-block text-nowrap"><i class="bi bi-broadcast text-primary me-1"></i>${p.SensorTagNumber || '--'}</small>
                        <small class="d-block text-nowrap"><i class="bi bi-controller text-secondary me-1"></i>${p.RemoteControllerNo || '--'}</small>
                    </td>
                    <td>
                        <small class="d-block">${p.StartDate} ~</small>
                        <small class="d-block fw-bold ${p.IsExpiringSoon ? 'text-warning' : (p.Status === 'EXPIRED' ? 'text-danger' : '')}">${p.ExpireDate}</small>
                    </td>
                    <td>${statusBadge}</td>
                    <td class="text-center text-nowrap">
                        <button type="button" class="btn btn-sm btn-outline-info me-1" title="檢視證件" onclick="event.preventDefault(); viewPermitCard(${idx});">
                            <i class="bi bi-eye"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-primary me-1" title="編輯" onclick="event.preventDefault(); editPermit(${idx});">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-success me-1" title="展期" onclick="event.preventDefault(); quickExtendSingle(${p.PermitID});">
                            <i class="bi bi-calendar-plus"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-danger" title="註銷/刪除" onclick="event.preventDefault(); deletePermit(${p.PermitID});">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                </tr>`;
        });

        $('#permitTableBody').html(html);
    }

    function resetSearch() {
        $('#ddlSearchDept').val('');
        $('#ddlSearchZone').val('');
        $('#ddlSearchStatus').val('');
        $('#txtKeyword').val('');
        loadPermitsData();
    }

    function toggleSelectAll(master) {
        $('.chk-permit').prop('checked', master.checked);
    }

    function getPermitModal() {
        var el = document.getElementById('permitModal');
        return bootstrap.Modal.getOrCreateInstance(el);
    }

    function getViewPermitModal() {
        var el = document.getElementById('modalViewPermit');
        return bootstrap.Modal.getOrCreateInstance(el);
    }

    function getBatchExtendModal() {
        var el = document.getElementById('modalBatchExtend');
        return bootstrap.Modal.getOrCreateInstance(el);
    }

    function openCreateModal(e) {
        if (e && e.preventDefault) e.preventDefault();
        $('#hidPermitID').val('0');
        $('#modalTitle').html('<i class="bi bi-plus-circle me-2"></i>新增車輛通行證');
        
        $('#txtPermitNumber').val('');
        $('#modalDept').val('');
        $('#txtOwnerName').val('');
        $('#txtCardNumber').val('');
        $('#txtSensorTagNumber').val('');
        $('#txtRemoteControllerNo').val('');
        $('#txtLicensePlate').val('');
        $('#txtVehicleBrand').val('');
        $('#txtVehicleColor').val('');
        $('#modalZone').val('');
        $('#modalStatus').val('ACTIVE');
        $('#txtRemarks').val('');

        var today = new Date().toISOString().split('T')[0];
        $('#txtRegisterDate').val(today);
        $('#txtStartDate').val(today);
        
        var nextYear = new Date();
        nextYear.setFullYear(nextYear.getFullYear() + 1);
        $('#txtExpireDate').val(nextYear.toISOString().split('T')[0]);

        var yyyymm = today.replace(/-/g, '').substring(0, 6);
        $('#txtPermitNumber').val('PRK-' + yyyymm + '-' + Math.floor(100 + Math.random() * 900));

        getPermitModal().show();
    }

    function editPermit(idxOrId) {
        var p = null;
        if (typeof idxOrId === 'number' && idxOrId >= 0 && idxOrId < currentPermits.length) {
            p = currentPermits[idxOrId];
        }
        if (!p) {
            p = currentPermits.find(x => x.PermitID === idxOrId);
        }
        if (!p) {
            console.error('查無對應通行證資料', idxOrId);
            return;
        }

        $('#hidPermitID').val(p.PermitID);
        $('#modalTitle').html('<i class="bi bi-pencil-square me-2"></i>編輯車輛通行證 - ' + p.PermitNumber);
        $('#txtPermitNumber').val(p.PermitNumber);
        $('#modalDept').val(p.DeptID);
        $('#txtOwnerName').val(p.OwnerName);
        $('#txtCardNumber').val(p.CardNumber);
        $('#txtSensorTagNumber').val(p.SensorTagNumber);
        $('#txtRemoteControllerNo').val(p.RemoteControllerNo);
        $('#txtLicensePlate').val(p.LicensePlate);
        $('#txtVehicleBrand').val(p.VehicleBrand);
        $('#txtVehicleColor').val(p.VehicleColor);
        $('#modalZone').val(p.ZoneID);
        $('#modalStatus').val(p.Status);
        $('#txtRegisterDate').val(p.RegisterDate);
        $('#txtStartDate').val(p.StartDate);
        $('#txtExpireDate').val(p.ExpireDate);
        $('#txtRemarks').val(p.Remarks);

        getPermitModal().show();
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
            ExpireDate: $('#txtExpireDate').val(),
            Status: $('#modalStatus').val(),
            Remarks: $('#txtRemarks').val().trim()
        };

        if (!dto.PermitNumber || !dto.DeptID || !dto.OwnerName || !dto.LicensePlate || !dto.VehicleBrand || !dto.VehicleColor || !dto.ZoneID || !dto.StartDate || !dto.ExpireDate) {
            Swal.fire('提醒', '請填寫所有標記必填的紅星欄位！', 'warning');
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
                    getPermitModal().hide();
                    Swal.fire('成功', res.d.Message, 'success');
                    loadPermitsData();
                } else {
                    Swal.fire('儲存失敗', res.d.Message, 'error');
                }
            }
        });
    }

    function viewPermitCard(idxOrId) {
        var p = null;
        if (typeof idxOrId === 'number' && idxOrId >= 0 && idxOrId < currentPermits.length) {
            p = currentPermits[idxOrId];
        }
        if (!p) {
            p = currentPermits.find(x => x.PermitID === idxOrId);
        }
        if (!p) return;

        $('#viewPermitNum').text(p.PermitNumber);
        $('#viewPlate').text(p.LicensePlate);
        $('#viewOwner').text(p.OwnerName + (p.CardNumber ? ` (${p.CardNumber})` : ''));
        $('#viewDept').text(p.DeptName);
        $('#viewZone').text(p.ZoneName);
        $('#viewVehicle').text(p.VehicleBrand + ' / ' + p.VehicleColor);
        $('#viewTag').text(p.SensorTagNumber || '--');
        $('#viewRc').text(p.RemoteControllerNo || '--');
        $('#viewDates').text(p.StartDate + ' ~ ' + p.ExpireDate);

        var badge = p.Status === 'ACTIVE' ? '<span class="badge bg-success">正常有效</span>' : '<span class="badge bg-danger">逾期/停權</span>';
        $('#viewStatusBadge').html(badge);

        getViewPermitModal().show();
    }

    function quickExtendSingle(permitId) {
        Swal.fire({
            title: '通行證展期',
            text: '確定將此車籍通行證展期 1 年 (12 個月) 嗎？',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: '確定展期',
            cancelButtonText: '取消',
            confirmButtonColor: '#0E9F6E'
        }).then(res => {
            if (res.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Permit_Management.aspx/BatchExtend",
                    data: JSON.stringify({ dto: { PermitIDs: [permitId], ExtendMonths: 12 } }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (r) {
                        if (r.d.Success) {
                            Swal.fire('已完成', r.d.Message, 'success');
                            loadPermitsData();
                        } else {
                            Swal.fire('失敗', r.d.Message, 'error');
                        }
                    }
                });
            }
        });
    }

    function openBatchExtendModal() {
        var selected = [];
        $('.chk-permit:checked').each(function () {
            selected.push(parseInt($(this).val()));
        });

        if (selected.length === 0) {
            Swal.fire('提示', '請先在表格左側勾選欲批次展期的車籍！', 'info');
            return;
        }

        $('#lblBatchSelectedCount').text(selected.length);
        getBatchExtendModal().show();
    }

    function submitBatchExtend() {
        var selected = [];
        $('.chk-permit:checked').each(function () {
            selected.push(parseInt($(this).val()));
        });
        var months = parseInt($('#ddlBatchMonths').val());

        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/BatchExtend",
            data: JSON.stringify({ dto: { PermitIDs: selected, ExtendMonths: months } }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (r) {
                if (r.d.Success) {
                    getBatchExtendModal().hide();
                    Swal.fire('成功', r.d.Message, 'success');
                    loadPermitsData();
                } else {
                    Swal.fire('失敗', r.d.Message, 'error');
                }
            }
        });
    }

    function deletePermit(permitId) {
        Swal.fire({
            title: '確認註銷或刪除？',
            text: '若該車籍有巡檢查核紀錄，系統將安全轉為【註銷停權】以保全軌跡。',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#F05252',
            confirmButtonText: '確定執行',
            cancelButtonText: '取消'
        }).then(result => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Permit_Management.aspx/DeletePermit",
                    data: JSON.stringify({ permitId: permitId }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        if (res.d.Success) {
                            Swal.fire('已處理', res.d.Message, 'success');
                            loadPermitsData();
                        } else {
                            Swal.fire('操作失敗', res.d.Message, 'error');
                        }
                    }
                });
            }
        });
    }

    function exportPermitsCsv() {
        var criteria = {
            DeptID: $('#ddlSearchDept').val() ? parseInt($('#ddlSearchDept').val()) : null,
            ZoneID: $('#ddlSearchZone').val() ? parseInt($('#ddlSearchZone').val()) : null,
            Status: $('#ddlSearchStatus').val(),
            Keyword: $('#txtKeyword').val().trim()
        };

        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/ExportCsv",
            data: JSON.stringify({ criteria: criteria }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var csvContent = res.d;
                var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
                var link = document.createElement("a");
                var url = URL.createObjectURL(blob);
                link.setAttribute("href", url);
                link.setAttribute("download", `Hospital_Permits_${new Date().toISOString().split('T')[0]}.csv`);
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        });
    }

    // --- 批次匯入 (Excel / 試算表 Batch Import) ---
    var parsedImportItems = [];

    function openBatchImportModal() {
        clearImportData();
        getBatchImportModal().show();
    }

    function getBatchImportModal() {
        var el = document.getElementById('modalBatchImport');
        return bootstrap.Modal.getOrCreateInstance(el);
    }

    function clearImportData() {
        parsedImportItems = [];
        $('#fileExcelInput').val('');
        $('#txtCsvContent').val('');
        $('#badgeParsedCount').text('尚未讀取資料').removeClass('bg-success bg-primary').addClass('bg-secondary');
        $('#badgeValidCount').hide();
        $('#lblPreviewSummary').text('請先載入 Excel 檔案');
        $('#btnImportCount').text('0');
        $('#btnExecuteImport').prop('disabled', true);
        $('#importErrorAlert').hide().html('');
        $('#importPreviewBody').html(`
            <tr>
                <td colspan="11" class="text-center text-muted py-4">
                    <i class="bi bi-file-earmark-excel display-6 d-block text-success opacity-75 mb-2"></i>
                    請由上方下載 Excel 範本、填妥後上傳 Excel 檔案 (.xlsx / .xls) 進行預覽檢核
                </td>
            </tr>
        `);
    }

    // 下載標準 Excel 範本 (.xlsx)
    function downloadImportExcelTemplate() {
        if (typeof XLSX === 'undefined') {
            Swal.fire('錯誤', 'Excel 處理程式庫尚未載入完成，請重新整理頁面！', 'error');
            return;
        }

        // 即時向伺服器取得最新 Lookups (確保與 ParkingZones 和 ParkingDepartments 100% 同步)
        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/GetLookupOptions",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                currentLookups = res.d || {};
                buildAndSaveExcelTemplate(currentLookups);
            },
            error: function () {
                buildAndSaveExcelTemplate(currentLookups || { Departments: [], Zones: [] });
            }
        });
    }

    function buildAndSaveExcelTemplate(lookups) {
        var wb = XLSX.utils.book_new();

        var deptList = (lookups && lookups.Departments) ? lookups.Departments : [];
        var zoneList = (lookups && lookups.Zones) ? lookups.Zones : [];

        var today = new Date().toISOString().split('T')[0];
        var nextYear = new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().split('T')[0];

        // 動態決定範例資料使用的部門與區域代碼/名稱
        var dSample1 = deptList.length > 0 ? (deptList[0].DeptCode || deptList[0].DeptName) : "DEPT01";
        var dSample2 = deptList.length > 1 ? deptList[1].DeptName : (deptList.length > 0 ? deptList[0].DeptName : "總務處");
        var dSample3 = deptList.length > 2 ? deptList[2].DeptName : dSample2;

        var zSample1 = zoneList.length > 0 ? (zoneList[0].ZoneCode || zoneList[0].ZoneName) : "";
        var zSample2 = zoneList.length > 1 ? zoneList[1].ZoneName : (zoneList.length > 0 ? zoneList[0].ZoneName : "");
        var zSample3 = zoneList.length > 2 ? zoneList[2].ZoneName : zSample2;

        // 1. 車籍匯入主要資料工作表
        var headers = ["部門科室 (代碼或全稱皆可)", "員工姓名", "員工卡號", "車牌號碼", "車輛廠牌", "車輛顏色", "停放區域 (代碼或名稱皆可)", "感應卡號", "遙控器編號", "開始日期", "到期日期", "備註說明"];
        var sampleData = [
            headers,
            [dSample1, "王大明", "EMP2001", "BPK-8899", "Toyota RAV4", "極光銀", zSample1, "TAG-8821", "RC-8821", today, nextYear, "填寫科室代碼與區域代碼範例"],
            [dSample2, "周雅婷", "EMP9999", "TES-8888", "Toyota Yaris", "極光白", zSample2, "", "", today, nextYear, "填寫科室全稱與區域名稱範例"]
        ];

        if (deptList.length > 2 || zoneList.length > 2) {
            sampleData.push([dSample3, "吳孟勳", "EMP1006", "KEA-2468", "Ford Focus", "雲河灰", zSample3, "TAG-8806", "", today, nextYear, "依現場實際配置停放為主"]);
        }

        var wsData = XLSX.utils.aoa_to_sheet(sampleData);

        // 設定欄寬提升在 Excel 中的閱讀體驗
        wsData['!cols'] = [
            { wch: 26 }, // 部門科室 (代碼或全稱皆可)
            { wch: 14 }, // 員工姓名
            { wch: 14 }, // 員工卡號
            { wch: 16 }, // 車牌號碼
            { wch: 16 }, // 車輛廠牌
            { wch: 12 }, // 車輛顏色
            { wch: 28 }, // 停放區域 (代碼或名稱皆可)
            { wch: 16 }, // 感應卡號
            { wch: 16 }, // 遙控器編號
            { wch: 14 }, // 開始日期
            { wch: 14 }, // 到期日期
            { wch: 32 }  // 備註說明
        ];

        XLSX.utils.book_append_sheet(wb, wsData, "車輛通行證匯入資料");

        // 2. 說明與院區代碼對照工作表
        var zoneNotice = zoneList.length > 0 
            ? "4. 【停放區域欄位】：填寫「停放區代碼」或「停放區域名稱」皆可，系統自動雙向比對識別（請參考下方對照表）。"
            : "4. 【停放區域欄位】：目前資料庫尚未建立停放區域，請管理員先至【場域維護】建立停車分區後再行填寫。";

        var instructionRows = [
            ["【醫療院區車輛通行證批次匯入說明與注意事項】"],
            ["1. 【部門科室欄位】：填寫「科室代碼」或「部門科室全稱」皆可，系統自動雙向比對識別（請參考下方對照表）。"],
            ["2. 車牌號碼為必填欄位，系統自動移除空格與橫線比對資料庫合法性。"],
            ["3. 員工通行證申請可一人擁有多台車輛，但同一車輛嚴禁兩人重複登記。"],
            [zoneNotice],
            ["5. 感應卡號與遙控器編號若尚未配發可留空，系統寫入時會自動配發標籤。"],
            ["6. 起始日期若空白預設為今日；到期日期若空白預設為起始日展期一年。"],
            ["7. 停放區域依院區現場實際配置安排為主。"],
            [""],
            ["【科室代碼】", "【部門科室全稱】", "", "【停放區代碼】", "【停放區域名稱】"]
        ];

        var maxRows = Math.max(deptList.length, zoneList.length);
        if (maxRows === 0) {
            instructionRows.push(["(尚未建立部門)", "(請先至部門維護建立)", "", "(尚未建立停放區域)", "(請先至場域維護建立)"]);
        } else {
            for (var i = 0; i < maxRows; i++) {
                var dCode = i < deptList.length ? (deptList[i].DeptCode || "") : "";
                var dName = i < deptList.length ? (deptList[i].DeptName || "") : "";
                var zCode = i < zoneList.length ? (zoneList[i].ZoneCode || "") : (zoneList.length === 0 && i === 0 ? "(無停放區域)" : "");
                var zName = i < zoneList.length ? (zoneList[i].ZoneName || "") : (zoneList.length === 0 && i === 0 ? "(請先至場域維護建立)" : "");
                instructionRows.push([dCode, dName, "", zCode, zName]);
            }
        }

        var wsInstructions = XLSX.utils.aoa_to_sheet(instructionRows);
        wsInstructions['!cols'] = [
            { wch: 16 }, // 科室代碼
            { wch: 28 }, // 部門全稱
            { wch: 6 },  // 分隔
            { wch: 16 }, // 區域代碼
            { wch: 40 }  // 區域名稱
        ];

        XLSX.utils.book_append_sheet(wb, wsInstructions, "填寫說明與代碼參考");

        // 下載 Excel 檔案
        XLSX.writeFile(wb, `醫療院區車輛通行證批次匯入範本_${today}.xlsx`);
    }

    // 下載標準 CSV 範本 (相容備用)
    function downloadImportCsvTemplate() {
        $.ajax({
            type: "POST",
            url: "Permit_Management.aspx/GetImportCsvTemplate",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var csvText = res.d;
                var blob = new Blob([csvText], { type: 'text/csv;charset=utf-8;' });
                var link = document.createElement("a");
                var url = URL.createObjectURL(blob);
                link.setAttribute("href", url);
                link.setAttribute("download", `車輛通行證批次匯入範本_${new Date().toISOString().split('T')[0]}.csv`);
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            },
            error: function () {
                Swal.fire('錯誤', '無法下載 CSV 範本，請重試！', 'error');
            }
        });
    }

    // 處理 Excel (.xlsx / .xls) 或 CSV 上傳
    function handleExcelFile(fileInput) {
        if (!fileInput.files || fileInput.files.length === 0) return;
        var file = fileInput.files[0];
        var fileName = file.name.toLowerCase();

        if (typeof XLSX === 'undefined') {
            Swal.fire('錯誤', 'Excel 解析程式庫尚未就緒，請重新整理頁面！', 'error');
            return;
        }

        var reader = new FileReader();
        if (fileName.endsWith('.csv')) {
            reader.onload = function (e) {
                try {
                    var data = new Uint8Array(e.target.result);
                    var workbook = XLSX.read(data, { type: 'array' });
                    var sheetName = workbook.SheetNames[0];
                    var rawRows = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { header: 1, defval: '', raw: false });
                    processRowsArray(rawRows, file.name);
                } catch (err) {
                    var textReader = new FileReader();
                    textReader.onload = function(evt) {
                        parseRawTextLines(evt.target.result, file.name);
                    };
                    textReader.readAsText(file, 'utf-8');
                }
            };
            reader.readAsArrayBuffer(file);
        } else {
            // Excel (.xlsx / .xls)
            reader.onload = function (e) {
                try {
                    var data = new Uint8Array(e.target.result);
                    var workbook = XLSX.read(data, { type: 'array', cellDates: true });
                    var sheetName = workbook.SheetNames[0];
                    var worksheet = workbook.Sheets[sheetName];
                    var rawRows = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '', raw: false, dateNF: 'yyyy-mm-dd' });
                    processRowsArray(rawRows, file.name);
                } catch (err) {
                    console.error('Excel parse error:', err);
                    Swal.fire('Excel 讀取失敗', '無法解析該 Excel 檔案，請確認檔案格式是否正確或檔案未受保護損毀！', 'error');
                }
            };
            reader.readAsArrayBuffer(file);
        }
    }

    // 貼上文字 (Excel 複製表格 或 CSV) 解析
    function parseRawPasteText() {
        var text = $('#txtCsvContent').val();
        if (!text || !text.trim()) {
            Swal.fire('提示', '請先貼上 Excel 儲存格內容！', 'warning');
            return;
        }
        parseRawTextLines(text, '貼上文字');
    }

    function parseRawTextLines(text, sourceName) {
        if (text.charCodeAt(0) === 0xFEFF) {
            text = text.substring(1);
        }

        var isTabDelimited = text.indexOf('\t') >= 0;
        var rows = [];
        var lines = text.split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (!line || !line.trim()) continue;
            var cols = isTabDelimited ? line.split('\t') : parseCsvLine(line);
            rows.push(cols);
        }
        processRowsArray(rows, sourceName);
    }

    function parseCsvLine(line) {
        var row = [];
        var inQuotes = false;
        var cell = '';
        for (var i = 0; i < line.length; i++) {
            var c = line[i];
            var next = line[i + 1];
            if (c === '"') {
                if (inQuotes && next === '"') {
                    cell += '"';
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c === ',' && !inQuotes) {
                row.push(cell.trim());
                cell = '';
            } else {
                cell += c;
            }
        }
        row.push(cell.trim());
        return row;
    }

    // 核心統一二維陣列處理函式 (支援 Excel 物件、字串、日期格式)
    function processRowsArray(rows, sourceName) {
        if (!rows || rows.length === 0) {
            Swal.fire('提示', '檔案內查無資料列！', 'warning');
            return;
        }

        // 搜尋標題欄位列
        var headerIdx = -1;
        var colMap = {
            dept: -1, owner: -1, card: -1, plate: -1, brand: -1, color: -1,
            zone: -1, tag: -1, remote: -1, start: -1, expire: -1, remarks: -1
        };

        for (var r = 0; r < Math.min(rows.length, 5); r++) {
            var rowText = rows[r].map(x => (x || '').toString().trim()).join(' ');
            if (rowText.indexOf('車牌') >= 0 || rowText.indexOf('部門') >= 0 || rowText.indexOf('科室') >= 0 || rowText.indexOf('姓名') >= 0) {
                headerIdx = r;
                var hRow = rows[r];
                for (var c = 0; c < hRow.length; c++) {
                    var h = (hRow[c] || '').toString().trim().toUpperCase();
                    if (!h) continue;

                    // 1. 感應卡號 / RFID / TAG (需在卡號前判斷，避免「感應卡號」被「卡號」誤判)
                    if (h.indexOf('感應') >= 0 || h.indexOf('TAG') >= 0 || h.indexOf('RFID') >= 0) {
                        colMap.tag = c;
                    }
                    // 2. 遙控器編號 / RC
                    else if (h.indexOf('遙控') >= 0 || h.indexOf('RC') >= 0) {
                        colMap.remote = c;
                    }
                    // 3. 員工卡號 / 工號 (排除感應卡)
                    else if (h.indexOf('員工卡') >= 0 || h.indexOf('員工編號') >= 0 || h.indexOf('工號') >= 0 || (h.indexOf('卡號') >= 0 && h.indexOf('感應') < 0)) {
                        colMap.card = c;
                    }
                    // 4. 車牌號碼
                    else if (h.indexOf('車牌') >= 0 || h.indexOf('車號') >= 0) {
                        colMap.plate = c;
                    }
                    // 5. 車輛廠牌 / 車型
                    else if (h.indexOf('廠牌') >= 0 || h.indexOf('車型') >= 0) {
                        colMap.brand = c;
                    }
                    // 6. 車輛顏色
                    else if (h.indexOf('顏色') >= 0) {
                        colMap.color = c;
                    }
                    // 7. 停放區域
                    else if (h.indexOf('區域') >= 0 || h.indexOf('停放') >= 0) {
                        colMap.zone = c;
                    }
                    // 8. 部門科室
                    else if (h.indexOf('部門') >= 0 || h.indexOf('科室') >= 0) {
                        colMap.dept = c;
                    }
                    // 9. 員工姓名 / 車主姓名
                    else if (h.indexOf('姓名') >= 0 || h.indexOf('車主') >= 0) {
                        colMap.owner = c;
                    }
                    // 10. 開始日期 / 起日
                    else if (h.indexOf('開始') >= 0 || h.indexOf('起日') >= 0 || h.indexOf('起始') >= 0) {
                        colMap.start = c;
                    }
                    // 11. 到期日期 / 迄日
                    else if (h.indexOf('到期') >= 0 || h.indexOf('迄日') >= 0 || h.indexOf('結束') >= 0) {
                        colMap.expire = c;
                    }
                    // 12. 備註說明
                    else if (h.indexOf('備註') >= 0 || h.indexOf('說明') >= 0) {
                        colMap.remarks = c;
                    }
                }
                break;
            }
        }

        if (headerIdx === -1) {
            colMap = { dept: 0, owner: 1, card: 2, plate: 3, brand: 4, color: 5, zone: 6, tag: 7, remote: 8, start: 9, expire: 10, remarks: 11 };
        }

        var dataStartIdx = headerIdx + 1;
        parsedImportItems = [];
        var previewHtml = '';
        var validCount = 0;
        var todayStr = new Date().toISOString().split('T')[0];
        var nextYearDate = new Date();
        nextYearDate.setFullYear(nextYearDate.getFullYear() + 1);
        var nextYearStr = nextYearDate.toISOString().split('T')[0];

        function cleanDate(val, defaultVal) {
            if (!val) return defaultVal;
            if (val instanceof Date) {
                return val.toISOString().split('T')[0];
            }
            var s = val.toString().trim().replace(/\//g, '-').replace(/\./g, '-');
            return s || defaultVal;
        }

        for (var i = dataStartIdx; i < rows.length; i++) {
            var r = rows[i];
            if (!r || r.length === 0) continue;

            var isAllEmpty = true;
            for (var c = 0; c < r.length; c++) {
                if (r[c] !== undefined && r[c] !== null && r[c].toString().trim() !== '') {
                    isAllEmpty = false;
                    break;
                }
            }
            if (isAllEmpty) continue;

            var getVal = function(colIdx) {
                if (colIdx === -1 || colIdx === undefined || colIdx >= r.length) return '';
                var v = r[colIdx];
                return (v !== undefined && v !== null) ? v.toString().trim() : '';
            };

            var item = {
                DeptName: getVal(colMap.dept),
                OwnerName: getVal(colMap.owner),
                CardNumber: getVal(colMap.card),
                LicensePlate: getVal(colMap.plate).toUpperCase(),
                VehicleBrand: getVal(colMap.brand),
                VehicleColor: getVal(colMap.color),
                ZoneName: getVal(colMap.zone),
                SensorTagNumber: getVal(colMap.tag),
                RemoteControllerNo: getVal(colMap.remote),
                StartDate: cleanDate(getVal(colMap.start), todayStr),
                ExpireDate: cleanDate(getVal(colMap.expire), nextYearStr),
                Remarks: getVal(colMap.remarks)
            };

            var issues = [];
            if (!item.LicensePlate) issues.push('車牌未填');
            if (!item.DeptName) issues.push('部門未填');
            if (!item.ZoneName) issues.push('區域未填');

            var isValid = issues.length === 0;
            if (isValid) validCount++;

            parsedImportItems.push(item);

            var rowNum = parsedImportItems.length;
            previewHtml += `
                <tr class="${isValid ? '' : 'table-danger'}">
                    <td class="text-center font-monospace">${rowNum}</td>
                    <td>${item.DeptName || '<span class="text-danger small">必填</span>'}</td>
                    <td><strong>${item.OwnerName || '<span class="text-muted small">(同仁)</span>'}</strong></td>
                    <td class="font-monospace small">${item.CardNumber || '--'}</td>
                    <td><span class="badge bg-dark">${item.LicensePlate || '<span class="text-danger">缺</span>'}</span></td>
                    <td><span class="small">${item.VehicleBrand || '--'} / ${item.VehicleColor || '--'}</span></td>
                    <td><span class="badge bg-info text-dark">${item.ZoneName || '<span class="text-danger">必填</span>'}</span></td>
                    <td class="small font-monospace">${item.SensorTagNumber || '--'} / ${item.RemoteControllerNo || '--'}</td>
                    <td class="small text-nowrap">${item.StartDate} ~ ${item.ExpireDate}</td>
                    <td class="small text-truncate" style="max-width: 120px;">${item.Remarks || '--'}</td>
                    <td>
                        ${isValid 
                            ? '<span class="badge bg-success-subtle text-success border border-success-subtle"><i class="bi bi-check-circle me-1"></i>合格</span>' 
                            : `<span class="badge bg-danger-subtle text-danger border border-danger-subtle"><i class="bi bi-x-circle me-1"></i>${issues.join(', ')}</span>`}
                    </td>
                </tr>
            `;
        }

        if (parsedImportItems.length === 0) {
            Swal.fire('提示', '未解析出有效資料，請確認 Excel / 檔案內容！', 'warning');
            return;
        }

        $('#importPreviewBody').html(previewHtml);
        $('#badgeParsedCount').text(`解析筆數: ${parsedImportItems.length} 筆`).removeClass('bg-secondary bg-primary').addClass('bg-success');
        $('#badgeValidCount').show().text(`合格預覽: ${validCount} 筆`);
        $('#lblPreviewSummary').text(`來源: ${sourceName || 'Excel 檔案'} (共 ${parsedImportItems.length} 筆，合格 ${validCount} 筆)`);
        $('#btnImportCount').text(parsedImportItems.length);
        $('#btnExecuteImport').prop('disabled', parsedImportItems.length === 0);
        $('#importErrorAlert').hide().html('');
    }

    // 執行 Excel 批次匯入
    function executeBatchImport() {
        if (!parsedImportItems || parsedImportItems.length === 0) {
            Swal.fire('提示', '目前尚無欲匯入的資料！', 'warning');
            return;
        }

        var skipDup = $('#chkSkipDuplicates').is(':checked');

        Swal.fire({
            title: '確認執行 Excel 批次匯入？',
            html: `準備匯入 <strong>${parsedImportItems.length}</strong> 筆通行證資料。<br><small class="text-muted">重複車牌策略：${skipDup ? '【自動略過已存在車牌】' : '【不略過 (重名報錯)】'}</small>`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: '確定匯入',
            cancelButtonText: '取消',
            confirmButtonColor: '#16A34A'
        }).then(res => {
            if (res.isConfirmed) {
                $('#btnExecuteImport').prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-2"></span>Excel 匯入處理中...');

                $.ajax({
                    type: "POST",
                    url: "Permit_Management.aspx/BatchImport",
                    data: JSON.stringify({ items: parsedImportItems, skipDuplicates: skipDup }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (resp) {
                        $('#btnExecuteImport').prop('disabled', false).html('<i class="bi bi-cloud-arrow-up me-1"></i>開始執行 Excel 批次匯入 (<span id="btnImportCount">' + parsedImportItems.length + '</span> 筆)');

                        var result = resp.d;
                        if (!result) {
                            Swal.fire('錯誤', '後端伺服器未回傳匯入結果！', 'error');
                            return;
                        }

                        if (result.Success && result.FailCount === 0) {
                            getBatchImportModal().hide();
                            Swal.fire({
                                icon: 'success',
                                title: 'Excel 批次匯入成功！',
                                text: `已順利為院區建立 ${result.SuccessCount} 筆車輛通行證！`,
                                confirmButtonColor: '#16A34A'
                            });
                            loadPermitsData();
                        } else if (result.Success && result.FailCount > 0) {
                            var errHtml = '<div class="text-start">';
                            errHtml += `<p class="mb-2"><strong>成功 ${result.SuccessCount} 筆，失敗 / 略過 ${result.FailCount} 筆：</strong></p>`;
                            errHtml += '<ul class="text-danger small mb-0" style="max-height: 200px; overflow-y: auto;">';
                            result.ErrorMessages.forEach(msg => {
                                errHtml += `<li>${msg}</li>`;
                            });
                            errHtml += '</ul></div>';

                            $('#importErrorAlert').show().html(errHtml);

                            Swal.fire({
                                icon: 'warning',
                                title: '部分資料匯入完成',
                                html: `成功匯入 <strong>${result.SuccessCount}</strong> 筆，另有 <strong>${result.FailCount}</strong> 筆未匯入。<br><small class="text-muted">詳細原因已列於匯入對話框下方。</small>`,
                                confirmButtonColor: '#16A34A'
                            });
                            loadPermitsData();
                        } else {
                            var errHtml = '<div class="text-start">';
                            errHtml += `<p class="mb-2"><strong>全數未匯入成功（共 ${result.FailCount} 筆）：</strong></p>`;
                            errHtml += '<ul class="text-danger small mb-0" style="max-height: 200px; overflow-y: auto;">';
                            result.ErrorMessages.forEach(msg => {
                                errHtml += `<li>${msg}</li>`;
                            });
                            errHtml += '</ul></div>';

                            $('#importErrorAlert').show().html(errHtml);

                            Swal.fire({
                                icon: 'error',
                                title: '批次匯入失敗',
                                html: result.Message || '資料檢核未通過，請查看匯入清單下方說明！',
                                confirmButtonColor: '#F05252'
                            });
                        }
                    },
                    error: function () {
                        $('#btnExecuteImport').prop('disabled', false).html('<i class="bi bi-cloud-arrow-up me-1"></i>開始執行 Excel 批次匯入 (<span id="btnImportCount">' + parsedImportItems.length + '</span> 筆)');
                        Swal.fire('錯誤', '批次匯入通訊異常或系統錯誤！', 'error');
                    }
                });
            }
        });
    }
</script>
</asp:Content>
