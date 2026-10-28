<%@ Page Title="部門科室維護" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dept_Management.aspx.cs" Inherits="HospitalParking.Dept_Management" EnableViewState="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .filter-card {
            background-color: #FFFFFF;
            border-radius: var(--hsp-radius);
            box-shadow: var(--hsp-shadow-sm);
            border: 1px solid var(--hsp-border);
        }
        .dept-stat-card {
            background: #FFFFFF;
            border-radius: var(--hsp-radius);
            box-shadow: var(--hsp-shadow-sm);
            border: 1px solid var(--hsp-border);
            padding: 1.25rem;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .dept-stat-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--hsp-shadow);
        }
        .dept-stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }
        .code-pill {
            font-family: var(--bs-font-monospace);
            font-weight: 700;
            padding: 0.2rem 0.55rem;
            border-radius: 6px;
            background-color: #EFF6FF;
            color: #1A56DB;
            border: 1px solid #BFDBFE;
            letter-spacing: 0.5px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container-fluid px-3 px-lg-4">
    <!-- 頂部標題與主操作 -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center py-2 mb-3 border-bottom gap-2">
        <div>
            <h4 class="mb-1 fw-bold text-dark">
                <i class="bi bi-hospital text-primary me-2"></i>部門科室主檔維護 (Department Master)
            </h4>
            <p class="text-muted small mb-0">全面管理院區醫療科室與行政單位、車位配額上限控管、車輛通行證綁定與使用率分析。</p>
        </div>
        <div class="d-flex align-items-center gap-2 flex-wrap">
            <button type="button" class="btn btn-sm btn-outline-success" onclick="exportDeptList();">
                <i class="bi bi-file-earmark-excel me-1"></i>匯出科室清單 (Excel)
            </button>
            <button type="button" class="btn btn-sm btn-primary shadow-sm" onclick="openCreateModal();">
                <i class="bi bi-plus-circle me-1"></i>新增部門科室
            </button>
        </div>
    </div>

    <!-- 統計指標卡片 -->
    <div class="row g-3 mb-3">
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="dept-stat-card d-flex align-items-center">
                <div class="dept-stat-icon bg-primary bg-opacity-10 text-primary me-3">
                    <i class="bi bi-building"></i>
                </div>
                <div>
                    <span class="text-muted small d-block">全院科室總數</span>
                    <h3 class="fw-bold mb-0 text-dark" id="lblTotalDepts">0</h3>
                    <small class="text-muted">已建置科室單位</small>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="dept-stat-card d-flex align-items-center">
                <div class="dept-stat-icon bg-success bg-opacity-10 text-success me-3">
                    <i class="bi bi-check-circle"></i>
                </div>
                <div>
                    <span class="text-muted small d-block">正常啟用科室</span>
                    <h3 class="fw-bold mb-0 text-success" id="lblActiveDepts">0</h3>
                    <small class="text-muted">正常提供車證申請</small>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="dept-stat-card d-flex align-items-center">
                <div class="dept-stat-icon bg-info bg-opacity-10 text-info me-3">
                    <i class="bi bi-p-square"></i>
                </div>
                <div>
                    <span class="text-muted small d-block">全院總配額車位</span>
                    <h3 class="fw-bold mb-0 text-dark" id="lblTotalQuota">0</h3>
                    <small class="text-muted">各科室車位額度總和</small>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="dept-stat-card d-flex align-items-center">
                <div class="dept-stat-icon bg-warning bg-opacity-10 text-warning me-3">
                    <i class="bi bi-card-checklist"></i>
                </div>
                <div>
                    <span class="text-muted small d-block">已核發有效車籍</span>
                    <h3 class="fw-bold mb-0 text-dark" id="lblTotalActivePermits">0</h3>
                    <small class="text-muted">平均使用率: <strong class="text-primary" id="lblAvgUtilization">0%</strong></small>
                </div>
            </div>
        </div>
    </div>

    <!-- 篩選卡片 -->
    <div class="filter-card p-3 mb-3">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-sm-6 col-md-4">
                <label class="form-label small text-muted mb-1">關鍵字檢索</label>
                <div class="input-group input-group-sm">
                    <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                    <input type="text" id="txtSearchKeyword" class="form-control" placeholder="輸入 科室代碼 (例 CARDIO) 或 科室名稱..." oninput="applyFilters();" />
                </div>
            </div>
            <div class="col-12 col-sm-6 col-md-3">
                <label class="form-label small text-muted mb-1">營運狀態</label>
                <select id="ddlFilterStatus" class="form-select form-select-sm" onchange="applyFilters();">
                    <option value="">-- 全部狀態 --</option>
                    <option value="ACTIVE" selected>正常啟用中</option>
                    <option value="INACTIVE">已停用</option>
                </select>
            </div>
            <div class="col-12 col-sm-6 col-md-3">
                <label class="form-label small text-muted mb-1">額度配額狀態</label>
                <select id="ddlFilterQuota" class="form-select form-select-sm" onchange="applyFilters();">
                    <option value="">-- 全部配額狀態 --</option>
                    <option value="OVER">額度已飽和 / 超額</option>
                    <option value="AVAILABLE">尚有充裕額度</option>
                </select>
            </div>
            <div class="col-12 col-sm-6 col-md-2 text-md-end">
                <button type="button" class="btn btn-outline-secondary btn-sm w-100" onclick="resetFilters();">
                    <i class="bi bi-arrow-counterclockwise me-1"></i>重設條件
                </button>
            </div>
        </div>
    </div>

    <!-- 部門科室清單表格 -->
    <div class="hsp-card mb-4">
        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
            <h6 class="mb-0 fw-bold text-dark">
                <i class="bi bi-table me-2 text-primary"></i>科室資料清單
            </h6>
            <span class="badge bg-light text-dark border" id="lblResultCount">顯示 0 筆資料</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table hsp-table align-middle mb-0" id="tblDepts">
                    <thead>
                        <tr>
                            <th style="width: 50px;" class="text-center">#</th>
                            <th style="width: 130px;">科室代碼</th>
                            <th>部門科室名稱</th>
                            <th style="width: 120px;" class="text-center">配額上限</th>
                            <th style="width: 120px;" class="text-center">有效通行證</th>
                            <th style="min-width: 180px;">額度使用進度</th>
                            <th style="width: 110px;" class="text-center">待審核申請</th>
                            <th style="width: 110px;" class="text-center">狀態</th>
                            <th style="width: 150px;" class="text-center">操作</th>
                        </tr>
                    </thead>
                    <tbody id="deptTableBody">
                        <tr>
                            <td colspan="9" class="text-center py-4 text-muted">
                                <span class="spinner-border spinner-border-sm me-2"></span>載入科室資料中...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- 新增 / 編輯部門科室 Modal -->
<div class="modal fade" id="modalDept" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title" id="modalDeptTitle">
                    <i class="bi bi-building-add me-2"></i>新增部門科室
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <input type="hidden" id="hidDeptID" value="0" />
                
                <div class="mb-3">
                    <label class="form-label small fw-bold">科室代碼 (Dept Code) <span class="text-danger">*</span></label>
                    <input type="text" id="txtDeptCode" class="form-control font-monospace" placeholder="例如: CARDIO, PED, DENT, SURG" maxlength="20" style="text-transform: uppercase;" />
                    <small class="text-muted">建議使用大寫英數字，作為院區系統間介接之唯一識別代碼。</small>
                </div>

                <div class="mb-3">
                    <label class="form-label small fw-bold">部門科室全稱 (Dept Name) <span class="text-danger">*</span></label>
                    <input type="text" id="txtDeptName" class="form-control" placeholder="例如: 心臟超音波室、婦兒科部、一般外科部" maxlength="50" />
                </div>

                <div class="mb-3">
                    <label class="form-label small fw-bold">車位配額上限 (Quota Limit)</label>
                    <div class="input-group">
                        <input type="number" id="txtQuotaLimit" class="form-control" min="0" max="9999" value="30" />
                        <span class="input-group-text">格位</span>
                    </div>
                    <small class="text-muted">該科室同仁申辦車位之全院總授權上限，超過將列入飽和警示。</small>
                </div>

                <div class="mb-3">
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="chkDeptActive" checked>
                        <label class="form-check-label fw-bold" for="chkDeptActive">啟用此科室 (供員工線上申請與批次匯入對照)</label>
                    </div>
                </div>
            </div>
            <div class="modal-footer bg-light py-2">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary btn-sm px-4" onclick="saveDept();">
                    <i class="bi bi-save me-1"></i>儲存科室
                </button>
            </div>
        </div>
    </div>
</div>

<!-- 檢視科室所屬車輛 Modal -->
<div class="modal fade" id="modalDeptPermits" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-light">
                <h5 class="modal-title text-dark">
                    <i class="bi bi-car-front text-primary me-2"></i>【<span id="lblPermitsDeptName" class="text-primary fw-bold">--</span>】有效車輛通行證清單
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <span class="small text-muted" id="lblDeptPermitCount">共 0 筆車輛</span>
                    <button type="button" class="btn btn-outline-success btn-sm" onclick="exportDeptPermits();">
                        <i class="bi bi-file-earmark-excel me-1"></i>匯出此科室車籍
                    </button>
                </div>
                <div class="table-responsive" style="max-height: 400px;">
                    <table class="table table-sm table-hover align-middle mb-0" id="tblDeptPermits" style="font-size: 0.88rem;">
                        <thead class="table-light sticky-top">
                            <tr>
                                <th>停車證號</th>
                                <th>同仁姓名</th>
                                <th>工號/卡號</th>
                                <th>車牌號碼</th>
                                <th>車輛廠牌 / 顏色</th>
                                <th>停放區域</th>
                                <th>有效起訖</th>
                                <th>狀態</th>
                            </tr>
                        </thead>
                        <tbody id="deptPermitTableBody">
                            <tr>
                                <td colspan="8" class="text-center py-4 text-muted">讀取中...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="modal-footer bg-light py-2">
                <button type="button" class="btn btn-secondary btn-sm px-4" data-bs-dismiss="modal">關閉</button>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script>
    var allDepts = [];
    var currentFilteredDepts = [];
    var activeDeptPermits = [];
    var currentViewDeptName = '';

    $(document).ready(function () {
        loadDepartmentOverview();
    });

    function getDeptModal() {
        return bootstrap.Modal.getOrCreateInstance(document.getElementById('modalDept'));
    }

    function getDeptPermitsModal() {
        return bootstrap.Modal.getOrCreateInstance(document.getElementById('modalDeptPermits'));
    }

    function loadDepartmentOverview() {
        $('#deptTableBody').html('<tr><td colspan="9" class="text-center py-4 text-muted"><span class="spinner-border spinner-border-sm me-2"></span>載入科室資料中...</td></tr>');

        $.ajax({
            type: "POST",
            url: "Dept_Management.aspx/GetDepartmentOverview",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                if (!d) return;

                // 更新 KPI 指標卡片
                $('#lblTotalDepts').text(d.TotalDepts);
                $('#lblActiveDepts').text(d.ActiveDepts);
                $('#lblTotalQuota').text(d.TotalQuotaLimit.toLocaleString());
                $('#lblTotalActivePermits').text(d.TotalActivePermits.toLocaleString());

                var avgPct = d.TotalQuotaLimit > 0 ? Math.round((d.TotalActivePermits / d.TotalQuotaLimit) * 100) : 0;
                $('#lblAvgUtilization').text(avgPct + '%');

                allDepts = d.DeptList || [];
                applyFilters();
            },
            error: function () {
                Swal.fire('錯誤', '無法載入部門科室資料，請重試！', 'error');
            }
        });
    }

    function applyFilters() {
        var keyword = $('#txtSearchKeyword').val().trim().toLowerCase();
        var status = $('#ddlFilterStatus').val();
        var quota = $('#ddlFilterQuota').val();

        currentFilteredDepts = allDepts.filter(dept => {
            var matchKw = true;
            if (keyword) {
                var code = (dept.DeptCode || '').toLowerCase();
                var name = (dept.DeptName || '').toLowerCase();
                matchKw = code.indexOf(keyword) >= 0 || name.indexOf(keyword) >= 0;
            }

            var matchStatus = true;
            if (status === 'ACTIVE') matchStatus = dept.IsActive === true;
            else if (status === 'INACTIVE') matchStatus = dept.IsActive === false;

            var matchQuota = true;
            if (quota === 'OVER') matchQuota = dept.IsOverQuota === true;
            else if (quota === 'AVAILABLE') matchQuota = dept.IsOverQuota === false;

            return matchKw && matchStatus && matchQuota;
        });

        renderDeptTable(currentFilteredDepts);
    }

    function resetFilters() {
        $('#txtSearchKeyword').val('');
        $('#ddlFilterStatus').val('ACTIVE');
        $('#ddlFilterQuota').val('');
        applyFilters();
    }

    function renderDeptTable(list) {
        $('#lblResultCount').text(`顯示 ${list.length} 筆資料`);

        if (list.length === 0) {
            $('#deptTableBody').html('<tr><td colspan="9" class="text-center py-5 text-muted"><i class="bi bi-inbox fs-3 d-block mb-1"></i>查無相符之部門科室紀錄</td></tr>');
            return;
        }

        var html = '';
        list.forEach((d, idx) => {
            // 計算額度進度條色彩
            var barColor = 'bg-primary';
            if (d.UtilizationPct >= 100) {
                barColor = 'bg-danger';
            } else if (d.UtilizationPct >= 85) {
                barColor = 'bg-warning';
            }

            var statusBadge = d.IsActive 
                ? '<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-check-circle me-1"></i>啟用中</span>'
                : '<span class="badge bg-secondary-subtle text-secondary border px-2 py-1"><i class="bi bi-dash-circle me-1"></i>已停用</span>';

            var pendingBadge = d.PendingAppCount > 0
                ? `<a href="Employee_Portal.aspx" class="badge bg-info text-dark text-decoration-none px-2 py-1" title="點擊前往申請審核"><i class="bi bi-clock-history me-1"></i>${d.PendingAppCount} 筆待審</a>`
                : '<span class="text-muted small">0</span>';

            html += `
                <tr>
                    <td class="text-center font-monospace text-muted">${idx + 1}</td>
                    <td><span class="code-pill">${d.DeptCode}</span></td>
                    <td>
                        <strong class="text-dark">${d.DeptName}</strong>
                    </td>
                    <td class="text-center fw-bold text-secondary font-monospace">${d.QuotaLimit} 格</td>
                    <td class="text-center">
                        <span class="badge bg-light text-dark border font-monospace fs-6 px-2 py-1">${d.ActivePermitCount} 張</span>
                    </td>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <div class="progress flex-grow-1" style="height: 8px;">
                                <div class="progress-bar ${barColor}" style="width: ${Math.min(100, d.UtilizationPct)}%;"></div>
                            </div>
                            <span class="small font-monospace text-nowrap fw-bold ${d.IsOverQuota ? 'text-danger' : 'text-muted'}" style="width: 45px; text-align: right;">
                                ${d.UtilizationPct}%
                            </span>
                        </div>
                        <small class="text-muted d-block" style="font-size: 0.75rem;">
                            剩餘: ${d.RemainingQuota} 格 ${d.IsOverQuota ? '<span class="text-danger fw-bold">(額度已飽和)</span>' : ''}
                        </small>
                    </td>
                    <td class="text-center">${pendingBadge}</td>
                    <td class="text-center">${statusBadge}</td>
                    <td class="text-center text-nowrap">
                        <button type="button" class="btn btn-sm btn-outline-info me-1" title="檢視此科室車輛" onclick="viewDeptPermits(${d.DeptID}, '${d.DeptName}');">
                            <i class="bi bi-car-front"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-primary me-1" title="編輯科室" onclick="editDept(${d.DeptID});">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-danger" title="刪除科室" onclick="deleteDept(${d.DeptID}, '${d.DeptName}');">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                </tr>
            `;
        });

        $('#deptTableBody').html(html);
    }

    function openCreateModal() {
        $('#hidDeptID').val('0');
        $('#modalDeptTitle').html('<i class="bi bi-building-add me-2"></i>新增部門科室');
        $('#txtDeptCode').val('').prop('readonly', false);
        $('#txtDeptName').val('');
        $('#txtQuotaLimit').val('30');
        $('#chkDeptActive').prop('checked', true);
        getDeptModal().show();
    }

    function editDept(deptId) {
        var d = allDepts.find(x => x.DeptID === deptId);
        if (!d) return;

        $('#hidDeptID').val(d.DeptID);
        $('#modalDeptTitle').html('<i class="bi bi-pencil-square me-2"></i>編輯部門科室 - ' + d.DeptName);
        $('#txtDeptCode').val(d.DeptCode).prop('readonly', false);
        $('#txtDeptName').val(d.DeptName);
        $('#txtQuotaLimit').val(d.QuotaLimit);
        $('#chkDeptActive').prop('checked', d.IsActive);
        getDeptModal().show();
    }

    function saveDept() {
        var deptId = parseInt($('#hidDeptID').val()) || 0;
        var code = $('#txtDeptCode').val().trim().toUpperCase();
        var name = $('#txtDeptName').val().trim();
        var quota = parseInt($('#txtQuotaLimit').val()) || 0;
        var isActive = $('#chkDeptActive').is(':checked');

        if (!code) {
            Swal.fire('提示', '請輸入科室代碼 (例如: CARDIO, SURG)！', 'warning');
            return;
        }
        if (!name) {
            Swal.fire('提示', '請輸入部門科室全稱！', 'warning');
            return;
        }

        var dto = {
            DeptID: deptId,
            DeptCode: code,
            DeptName: name,
            QuotaLimit: quota,
            IsActive: isActive
        };

        $.ajax({
            type: "POST",
            url: "Dept_Management.aspx/SaveDepartment",
            data: JSON.stringify({ dto: dto }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var r = res.d;
                if (r.Success) {
                    getDeptModal().hide();
                    Swal.fire('成功', r.Message, 'success');
                    loadDepartmentOverview();
                } else {
                    Swal.fire('儲存失敗', r.Message, 'error');
                }
            },
            error: function () {
                Swal.fire('錯誤', '通訊異常或系統錯誤，請重試！', 'error');
            }
        });
    }

    function deleteDept(deptId, deptName) {
        Swal.fire({
            title: `確定刪除【${deptName}】？`,
            text: '系統將自動檢核是否有車輛通行證或申請記錄關聯。若已有紀錄，將安全阻擋以維護歷史軌跡。',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#F05252',
            confirmButtonText: '確定刪除',
            cancelButtonText: '取消'
        }).then(result => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Dept_Management.aspx/DeleteDepartment",
                    data: JSON.stringify({ deptId: deptId }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        var r = res.d;
                        if (r.Success) {
                            Swal.fire('已刪除', r.Message, 'success');
                            loadDepartmentOverview();
                        } else {
                            Swal.fire('無法刪除', r.Message, 'warning');
                        }
                    },
                    error: function () {
                        Swal.fire('錯誤', '操作失敗，請重試！', 'error');
                    }
                });
            }
        });
    }

    function viewDeptPermits(deptId, deptName) {
        currentViewDeptName = deptName;
        $('#lblPermitsDeptName').text(deptName);
        $('#deptPermitTableBody').html('<tr><td colspan="8" class="text-center py-4 text-muted"><span class="spinner-border spinner-border-sm me-2"></span>載入此科室車輛中...</td></tr>');
        getDeptPermitsModal().show();

        $.ajax({
            type: "POST",
            url: "Dept_Management.aspx/GetDepartmentPermits",
            data: JSON.stringify({ deptId: deptId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                activeDeptPermits = res.d || [];
                $('#lblDeptPermitCount').text(`共 ${activeDeptPermits.length} 筆車輛紀錄`);

                if (activeDeptPermits.length === 0) {
                    $('#deptPermitTableBody').html('<tr><td colspan="8" class="text-center py-4 text-muted"><i class="bi bi-inbox fs-4 d-block mb-1"></i>目前此科室尚無任何車輛通行證紀錄</td></tr>');
                    return;
                }

                var html = '';
                activeDeptPermits.forEach(p => {
                    var statusBadge = p.Status === 'ACTIVE'
                        ? '<span class="badge bg-success-subtle text-success border border-success-subtle">正常有效</span>'
                        : '<span class="badge bg-secondary">非有效</span>';

                    html += `
                        <tr>
                            <td><strong class="font-monospace text-primary">${p.PermitNumber}</strong></td>
                            <td><strong>${p.OwnerName}</strong></td>
                            <td class="font-monospace small text-muted">${p.CardNumber || '--'}</td>
                            <td><span class="badge bg-dark">${p.LicensePlate}</span></td>
                            <td>${p.VehicleBrand} / ${p.VehicleColor}</td>
                            <td><span class="badge bg-info text-dark">${p.ZoneName || '--'}</span></td>
                            <td class="small font-monospace">${p.StartDate} ~ ${p.ExpireDate}</td>
                            <td>${statusBadge}</td>
                        </tr>
                    `;
                });
                $('#deptPermitTableBody').html(html);
            },
            error: function () {
                $('#deptPermitTableBody').html('<tr><td colspan="8" class="text-center py-4 text-danger">載入失敗，請重試。</td></tr>');
            }
        });
    }

    // 匯出科室清單至 Excel
    function exportDeptList() {
        if (typeof XLSX === 'undefined') {
            Swal.fire('錯誤', 'Excel 程式庫尚未載入完成！', 'error');
            return;
        }

        var rows = [
            ["科室代碼", "部門科室名稱", "車位配額上限", "有效通行證數", "額度使用率", "待審核申請數", "營運狀態", "建置日期"]
        ];

        allDepts.forEach(d => {
            rows.push([
                d.DeptCode,
                d.DeptName,
                d.QuotaLimit,
                d.ActivePermitCount,
                d.UtilizationPct + '%',
                d.PendingAppCount,
                d.IsActive ? '啟用中' : '已停用',
                d.CreatedDate
            ]);
        });

        var wb = XLSX.utils.book_new();
        var ws = XLSX.utils.aoa_to_sheet(rows);
        ws['!cols'] = [
            { wch: 14 },
            { wch: 22 },
            { wch: 14 },
            { wch: 14 },
            { wch: 14 },
            { wch: 14 },
            { wch: 12 },
            { wch: 20 }
        ];
        XLSX.utils.book_append_sheet(wb, ws, "部門科室清單");
        XLSX.writeFile(wb, `醫療院區部門科室清單_${new Date().toISOString().split('T')[0]}.xlsx`);
    }

    // 匯出特定科室之車籍清單
    function exportDeptPermits() {
        if (!activeDeptPermits || activeDeptPermits.length === 0) {
            Swal.fire('提示', '目前此科室尚無車籍資料可匯出！', 'info');
            return;
        }
        if (typeof XLSX === 'undefined') {
            Swal.fire('錯誤', 'Excel 程式庫尚未載入完成！', 'error');
            return;
        }

        var rows = [
            ["停車證號", "同仁姓名", "工號卡號", "車牌號碼", "車輛廠牌", "車輛顏色", "停放區域", "開始日期", "到期日期", "狀態"]
        ];

        activeDeptPermits.forEach(p => {
            rows.push([
                p.PermitNumber,
                p.OwnerName,
                p.CardNumber,
                p.LicensePlate,
                p.VehicleBrand,
                p.VehicleColor,
                p.ZoneName,
                p.StartDate,
                p.ExpireDate,
                p.Status === 'ACTIVE' ? '正常有效' : p.Status
            ]);
        });

        var wb = XLSX.utils.book_new();
        var ws = XLSX.utils.aoa_to_sheet(rows);
        ws['!cols'] = [
            { wch: 16 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }, { wch: 12 }, { wch: 16 }, { wch: 14 }, { wch: 14 }, { wch: 12 }
        ];
        XLSX.utils.book_append_sheet(wb, ws, currentViewDeptName + "車籍清單");
        XLSX.writeFile(wb, `${currentViewDeptName}_車籍通行證清單_${new Date().toISOString().split('T')[0]}.xlsx`);
    }
</script>
</asp:Content>
