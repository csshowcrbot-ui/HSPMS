<%@ Page Title="停車場場域維護" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Zone_Management.aspx.cs" Inherits="HospitalParking.Zone_Management" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .zone-card {
            border-radius: 12px;
            border: 1px solid #E5E7EB;
            background: #fff;
            transition: all 0.25s ease;
        }
        .zone-card:hover {
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.06);
            transform: translateY(-2px);
        }
        .zone-code-badge {
            font-size: 1.15rem;
            font-weight: 700;
            padding: 0.35rem 0.75rem;
            border-radius: 8px;
            background: #EFF6FF;
            color: #1D4ED8;
            border: 1px solid #BFDBFE;
            letter-spacing: 0.5px;
        }
        .capacity-bar-container {
            height: 10px;
            border-radius: 6px;
            background-color: #F3F4F6;
            overflow: hidden;
        }
        .capacity-bar-fill {
            height: 100%;
            border-radius: 6px;
            transition: width 0.6s ease;
        }
        .bar-safe { background: linear-gradient(90deg, #10B981, #059669); }
        .bar-normal { background: linear-gradient(90deg, #3B82F6, #1D4ED8); }
        .bar-warning { background: linear-gradient(90deg, #F59E0B, #DC2626); }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container-fluid px-3 px-lg-4">
    <!-- 頂部頁籤標題與操作按鈕 -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center py-2 mb-3 border-bottom gap-2">
        <div>
            <h4 class="mb-1 fw-bold text-dark">
                <i class="bi bi-geo-alt-fill text-primary me-2"></i>停車場場域維護 (Parking Zone Management)
            </h4>
            <p class="text-muted small mb-0">全院各棟大樓停車場域、總車位容量配置、飽和警戒門檻設定與場域營運狀態控管。</p>
        </div>
        <div class="d-flex align-items-center gap-2">
            <button type="button" class="btn btn-primary shadow-sm" onclick="openAddZoneModal();">
                <i class="bi bi-plus-circle-fill me-1"></i>新增停車場域
            </button>
            <button type="button" class="btn btn-outline-secondary" onclick="loadZoneOverview();" title="重新整理">
                <i class="bi bi-arrow-clockwise me-1"></i>刷新
            </button>
        </div>
    </div>

    <!-- 4 大 KPI 統計指標卡片 -->
    <div class="row g-3 mb-4">
        <!-- 1. 全院場域總數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-blue">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">全院場域總數 (Zones)</div>
                        <div class="kpi-value" id="kpiTotalZones">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-building"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    <span class="text-success fw-bold" id="kpiActiveZones">--</span> 個營運啟用中
                </div>
            </div>
        </div>

        <!-- 2. 全院總車位容量 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-indigo">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">全院總車位容量 (Capacity)</div>
                        <div class="kpi-value" id="kpiTotalCapacity">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-p-square"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    全院規劃核配車格總額
                </div>
            </div>
        </div>

        <!-- 3. 目前有效核發總數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-teal">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">已核發有效車位 (Occupied)</div>
                        <div class="kpi-value" id="kpiTotalOccupied">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-check2-circle"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    全院整體飽和率 <span class="fw-bold text-primary" id="kpiOverallOccupancyPct">0%</span>
                </div>
            </div>
        </div>

        <!-- 4. 飽和警戒場域數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-amber">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">飽和警戒場域 (Alert)</div>
                        <div class="kpi-value text-danger" id="kpiWarningZones">--</div>
                    </div>
                    <div class="kpi-icon text-warning">
                        <i class="bi bi-exclamation-triangle"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    達預警門檻 (預設 &ge; 85%) 之場域
                </div>
            </div>
        </div>
    </div>

    <!-- 篩選器與工具列 -->
    <div class="hsp-card mb-4">
        <div class="card-body p-3">
            <div class="row g-2 align-items-center">
                <div class="col-12 col-md-4">
                    <div class="input-group input-group-sm">
                        <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                        <input type="text" id="txtSearchZone" class="form-control" placeholder="依場域代碼、名稱即時篩選..." onkeyup="filterZones();" />
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <select id="ddlStatusFilter" class="form-select form-select-sm" onchange="filterZones();">
                        <option value="ALL">全部場域狀態</option>
                        <option value="ACTIVE" selected>僅顯示啟用中</option>
                        <option value="INACTIVE">僅顯示已停用</option>
                    </select>
                </div>
                <div class="col-6 col-md-3">
                    <select id="ddlAlertFilter" class="form-select form-select-sm" onchange="filterZones();">
                        <option value="ALL">全部容量狀態</option>
                        <option value="WARNING">僅顯示達到警戒門檻</option>
                        <option value="NORMAL">正常未達警戒</option>
                    </select>
                </div>
                <div class="col-12 col-md-2 text-md-end text-muted small">
                    共 <span class="fw-bold text-primary" id="lblZoneCount">0</span> 個場域
                </div>
            </div>
        </div>
    </div>

    <!-- 場域列表主表格 -->
    <div class="hsp-card mb-4">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table hsp-table align-middle mb-0" id="tblZones">
                    <thead>
                        <tr>
                            <th style="width: 90px;" class="text-center">場域代碼</th>
                            <th style="min-width: 220px;">場域名稱與說明</th>
                            <th style="width: 110px;" class="text-center">總容量 (格)</th>
                            <th style="width: 110px;" class="text-center">已核發 (車)</th>
                            <th style="width: 100px;" class="text-center">剩餘車位</th>
                            <th style="min-width: 200px;">容量飽和度 / 警戒閥值</th>
                            <th style="width: 140px;" class="text-center">關聯數據</th>
                            <th style="width: 90px;" class="text-center">狀態</th>
                            <th style="width: 140px;" class="text-center">操作</th>
                        </tr>
                    </thead>
                    <tbody id="zoneTableBody">
                        <tr>
                            <td colspan="9" class="text-center py-4 text-muted">
                                <span class="spinner-border spinner-border-sm me-2"></span>載入停車場域資料中...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- 新增 / 編輯場域 Modal -->
<div class="modal fade" id="modalZoneEdit" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title fw-bold" id="modalZoneTitle">
                    <i class="bi bi-geo-alt-fill me-2"></i>新增停車場域
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <form id="formZone" onsubmit="return false;">
                    <input type="hidden" id="modalZoneId" value="0" />

                    <div class="row g-3 mb-3">
                        <div class="col-md-4">
                            <label class="form-label required small fw-bold">場域代碼 (Zone Code)</label>
                            <input type="text" id="modalZoneCode" class="form-control text-uppercase font-monospace fw-bold" 
                                   maxlength="10" placeholder="例: D, P2, VIP" required oninput="updateModalPreview();" />
                            <small class="text-muted d-block mt-1">代碼為全院唯一識別碼，支援英數字。</small>
                        </div>
                        <div class="col-md-8">
                            <label class="form-label required small fw-bold">場域名稱與位置標示</label>
                            <input type="text" id="modalZoneName" class="form-control" 
                                   maxlength="50" placeholder="例: 地下D區 (醫療二期擴建/專科夜診)" required oninput="updateModalPreview();" />
                            <small class="text-muted d-block mt-1">請標註大樓棟別、樓層或指定車位群組名稱。</small>
                        </div>
                    </div>

                    <div class="row g-3 mb-4">
                        <div class="col-md-4">
                            <label class="form-label required small fw-bold">總格位容量 (車格數)</label>
                            <div class="input-group">
                                <input type="number" id="modalCapacity" class="form-control fw-bold" 
                                       min="1" max="9999" placeholder="100" required oninput="updateModalPreview();" />
                                <span class="input-group-text">格</span>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small fw-bold">飽和警戒門檻 (%)</label>
                            <div class="input-group">
                                <input type="number" id="modalWarningPct" class="form-control fw-bold" 
                                       min="50" max="100" value="85" required oninput="updateModalPreview();" />
                                <span class="input-group-text">%</span>
                            </div>
                            <small class="text-muted d-block mt-1">達此百分比將於看板發出告警標示。</small>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">營運啟用狀態</label>
                            <div class="form-check form-switch mt-2">
                                <input class="form-check-input" type="checkbox" id="modalIsActive" checked onchange="updateModalPreview();" />
                                <label class="form-check-label fw-bold" for="modalIsActive" id="lblModalActive">正常營運中</label>
                            </div>
                            <small class="text-muted d-block">停用後員工申請與新車籍將無法選用。</small>
                        </div>
                    </div>

                    <!-- 即時卡片視覺預覽 -->
                    <div class="card bg-light border-0 rounded-3 p-3">
                        <h6 class="text-muted small fw-bold mb-2">
                            <i class="bi bi-eye me-1"></i>場域視覺呈現即時預覽：
                        </h6>
                        <div class="d-flex align-items-center justify-content-between">
                            <div class="d-flex align-items-center gap-2">
                                <span class="zone-code-badge" id="previewCode">A</span>
                                <div>
                                    <div class="fw-bold" id="previewName">場域名稱預覽</div>
                                    <small class="text-muted" id="previewMeta">容量: 100 格 / 警戒門檻: 85%</small>
                                </div>
                            </div>
                            <span class="badge bg-success" id="previewStatus">營運中</span>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer bg-light">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary px-4" onclick="saveZoneData();">
                    <i class="bi bi-check-circle-fill me-1"></i>確認儲存
                </button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
    var allZones = [];
    var zoneEditModal = null;

    $(document).ready(function () {
        zoneEditModal = new bootstrap.Modal(document.getElementById('modalZoneEdit'));
        loadZoneOverview();

        $('#modalIsActive').on('change', function () {
            $('#lblModalActive').text(this.checked ? '正常營運中' : '已暫停營運');
        });
    });

    // 載入全院停車場域總覽與統計
    function loadZoneOverview() {
        $('#zoneTableBody').html('<tr><td colspan="9" class="text-center py-4 text-muted"><span class="spinner-border spinner-border-sm me-2"></span>載入停車場域資料中...</td></tr>');

        $.ajax({
            type: "POST",
            url: "Zone_Management.aspx/GetZoneOverview",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                if (!d) return;

                // 更新 KPI 指標卡片
                $('#kpiTotalZones').text(d.TotalZones);
                $('#kpiActiveZones').text(d.ActiveZones);
                $('#kpiTotalCapacity').text(d.TotalCapacity);
                $('#kpiTotalOccupied').text(d.TotalOccupied);
                $('#kpiWarningZones').text(d.WarningZoneCount);

                var overallPct = d.TotalCapacity > 0 ? Math.round((d.TotalOccupied * 100) / d.TotalCapacity) : 0;
                $('#kpiOverallOccupancyPct').text(overallPct + '%');

                allZones = d.ZoneList || [];
                filterZones();
            },
            error: function (xhr, status, error) {
                Swal.fire('載入異常', '無法取得停車場域資料，請確認資料庫服務是否正常。', 'error');
            }
        });
    }

    // 依篩選條件過濾並渲染表格
    function filterZones() {
        var keyword = $('#txtSearchZone').val().trim().toUpperCase();
        var statusFilter = $('#ddlStatusFilter').val();
        var alertFilter = $('#ddlAlertFilter').val();

        var filtered = allZones.filter(function (z) {
            // 關鍵字
            if (keyword) {
                var matchCode = z.ZoneCode && z.ZoneCode.toUpperCase().indexOf(keyword) >= 0;
                var matchName = z.ZoneName && z.ZoneName.toUpperCase().indexOf(keyword) >= 0;
                if (!matchCode && !matchName) return false;
            }
            // 狀態篩選
            if (statusFilter === 'ACTIVE' && !z.IsActive) return false;
            if (statusFilter === 'INACTIVE' && z.IsActive) return false;

            // 警戒篩選
            if (alertFilter === 'WARNING' && !z.IsWarning) return false;
            if (alertFilter === 'NORMAL' && z.IsWarning) return false;

            return true;
        });

        renderZoneTable(filtered);
    }

    // 渲染場域清單表格
    function renderZoneTable(list) {
        $('#lblZoneCount').text(list.length);

        if (list.length === 0) {
            $('#zoneTableBody').html('<tr><td colspan="9" class="text-center py-5 text-muted"><i class="bi bi-inbox fs-3 d-block mb-1"></i>無符合篩選條件之停車場域紀錄</td></tr>');
            return;
        }

        var html = '';
        list.forEach(function (z) {
            // 進度條色彩
            var barClass = 'bar-safe';
            if (z.OccupancyPct >= z.WarningThresholdPct) {
                barClass = 'bar-warning';
            } else if (z.OccupancyPct >= 70) {
                barClass = 'bar-normal';
            }

            var warningBadge = z.IsWarning
                ? '<span class="badge bg-danger ms-1 animate-pulse"><i class="bi bi-exclamation-triangle-fill me-1"></i>已達警戒</span>'
                : '';

            var statusHtml = z.IsActive
                ? '<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-check-circle-fill me-1"></i>啟用</span>'
                : '<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-2 py-1"><i class="bi bi-dash-circle-fill me-1"></i>停用</span>';

            html += `
                <tr>
                    <td class="text-center">
                        <span class="zone-code-badge">${z.ZoneCode}</span>
                    </td>
                    <td>
                        <strong class="fs-6 text-dark">${z.ZoneName}</strong>
                        <div class="text-muted small mt-1">建置日期：${z.CreatedDate || '--'}</div>
                    </td>
                    <td class="text-center fw-bold text-dark fs-6">
                        ${z.TotalCapacity}
                    </td>
                    <td class="text-center fw-bold text-primary fs-6">
                        ${z.CurrentOccupied}
                    </td>
                    <td class="text-center fw-bold ${z.RemainingQuota <= 5 ? 'text-danger' : 'text-success'} fs-6">
                        ${z.RemainingQuota}
                    </td>
                    <td>
                        <div class="d-flex justify-content-between align-items-center mb-1 small">
                            <span class="fw-bold">${z.OccupancyPct}% ${warningBadge}</span>
                            <span class="text-muted">警戒線: ${z.WarningThresholdPct}%</span>
                        </div>
                        <div class="capacity-bar-container">
                            <div class="capacity-bar-fill ${barClass}" style="width: ${Math.min(100, z.OccupancyPct)}%;"></div>
                        </div>
                    </td>
                    <td class="text-center small">
                        <span class="badge bg-light text-dark border me-1" title="通行證總數">證: ${z.PermitCount}</span>
                        <span class="badge bg-light text-dark border me-1" title="待審申請">待: ${z.PendingAppCount}</span>
                        <span class="badge bg-light text-dark border" title="巡檢日誌">巡: ${z.InspectionCount}</span>
                    </td>
                    <td class="text-center">
                        ${statusHtml}
                    </td>
                    <td class="text-center text-nowrap">
                        <button type="button" class="btn btn-sm btn-outline-primary me-1" title="編輯場域" onclick="event.preventDefault(); openEditZoneModal(${z.ZoneID});">
                            <i class="bi bi-pencil-square"></i>
                        </button>
                        <button type="button" class="btn btn-sm ${z.IsActive ? 'btn-outline-warning' : 'btn-outline-success'} me-1" 
                                title="${z.IsActive ? '停用場域' : '啟用場域'}" 
                                onclick="event.preventDefault(); toggleZoneStatus(${z.ZoneID}, ${!z.IsActive});">
                            <i class="bi ${z.IsActive ? 'bi-pause-circle' : 'bi-play-circle'}"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-danger" title="刪除場域" onclick="event.preventDefault(); deleteZone(${z.ZoneID}, '${z.ZoneCode}', '${z.ZoneName}');">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                </tr>`;
        });

        $('#zoneTableBody').html(html);
    }

    // 開啟新增 Modal
    function openAddZoneModal() {
        $('#modalZoneTitle').html('<i class="bi bi-plus-circle-fill me-2"></i>新增停車場域');
        $('#modalZoneId').val('0');
        $('#modalZoneCode').val('').prop('readonly', false);
        $('#modalZoneName').val('');
        $('#modalCapacity').val('100');
        $('#modalWarningPct').val('85');
        $('#modalIsActive').prop('checked', true);
        $('#lblModalActive').text('正常營運中');

        updateModalPreview();
        zoneEditModal.show();
    }

    // 開啟編輯 Modal
    function openEditZoneModal(zoneId) {
        var zone = allZones.find(x => x.ZoneID === zoneId);
        if (!zone) return;

        $('#modalZoneTitle').html('<i class="bi bi-pencil-square me-2"></i>編輯停車場域');
        $('#modalZoneId').val(zone.ZoneID);
        $('#modalZoneCode').val(zone.ZoneCode).prop('readonly', false);
        $('#modalZoneName').val(zone.ZoneName);
        $('#modalCapacity').val(zone.TotalCapacity);
        $('#modalWarningPct').val(zone.WarningThresholdPct);
        $('#modalIsActive').prop('checked', zone.IsActive);
        $('#lblModalActive').text(zone.IsActive ? '正常營運中' : '已暫停營運');

        updateModalPreview();
        zoneEditModal.show();
    }

    // 即時預覽更新
    function updateModalPreview() {
        var code = $('#modalZoneCode').val().trim().toUpperCase() || '代碼';
        var name = $('#modalZoneName').val().trim() || '請輸入場域名稱';
        var cap = $('#modalCapacity').val() || '0';
        var warn = $('#modalWarningPct').val() || '85';
        var active = $('#modalIsActive').is(':checked');

        $('#previewCode').text(code);
        $('#previewName').text(name);
        $('#previewMeta').text(`容量: ${cap} 格 / 警戒門檻: ${warn}%`);

        if (active) {
            $('#previewStatus').removeClass('bg-secondary').addClass('bg-success').text('營運中');
        } else {
            $('#previewStatus').removeClass('bg-success').addClass('bg-secondary').text('已停用');
        }
    }

    // 儲存場域 (新增或更新)
    function saveZoneData() {
        var zoneId = parseInt($('#modalZoneId').val()) || 0;
        var code = $('#modalZoneCode').val().trim().toUpperCase();
        var name = $('#modalZoneName').val().trim();
        var capacity = parseInt($('#modalCapacity').val()) || 0;
        var warningPct = parseInt($('#modalWarningPct').val()) || 85;
        var isActive = $('#modalIsActive').is(':checked');

        if (!code) {
            Swal.fire('提醒', '請填寫場域代碼 (如 A, B, C, D, P1 等)！', 'warning');
            $('#modalZoneCode').focus();
            return;
        }

        if (!name) {
            Swal.fire('提醒', '請填寫場域名稱 (如: 地下A區、立體二館等)！', 'warning');
            $('#modalZoneName').focus();
            return;
        }

        if (capacity <= 0) {
            Swal.fire('提醒', '總格位容量必須大於 0 格！', 'warning');
            $('#modalCapacity').focus();
            return;
        }

        var dto = {
            ZoneID: zoneId,
            ZoneCode: code,
            ZoneName: name,
            TotalCapacity: capacity,
            WarningThresholdPct: warningPct,
            IsActive: isActive
        };

        $.ajax({
            type: "POST",
            url: "Zone_Management.aspx/SaveZone",
            data: JSON.stringify({ dto: dto }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var result = res.d;
                if (result.Success) {
                    zoneEditModal.hide();
                    Swal.fire({
                        icon: 'success',
                        title: '成功',
                        text: result.Message,
                        timer: 1800,
                        showConfirmButton: false
                    });
                    loadZoneOverview();
                } else {
                    Swal.fire('儲存失敗', result.Message, 'error');
                }
            },
            error: function () {
                Swal.fire('系統異常', '伺服器處理異常，請檢查連線後重試。', 'error');
            }
        });
    }

    // 快速切換場域狀態
    function toggleZoneStatus(zoneId, targetStatus) {
        var actionText = targetStatus ? '啟用' : '停用';
        Swal.fire({
            title: `確定要${actionText}此場域？`,
            text: targetStatus ? '啟用後，該場域將開放供同仁申請與車籍指派。' : '停用後，該場域將停止接受新車證指派，但歷史資料皆妥善保留。',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: `確定${actionText}`,
            cancelButtonText: '取消'
        }).then((result) => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Zone_Management.aspx/ToggleZoneStatus",
                    data: JSON.stringify({ zoneId: zoneId, targetStatus: targetStatus }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        var r = res.d;
                        if (r.Success) {
                            Swal.fire({
                                icon: 'success',
                                title: '操作成功',
                                text: r.Message,
                                timer: 1500,
                                showConfirmButton: false
                            });
                            loadZoneOverview();
                        } else {
                            Swal.fire('操作失敗', r.Message, 'error');
                        }
                    }
                });
            }
        });
    }

    // 刪除場域 (含防呆檢查)
    function deleteZone(zoneId, code, name) {
        Swal.fire({
            title: `確定要刪除場域【${code} - ${name}】？`,
            text: '注意：若該場域已有任何通行證、申請單或巡檢歷史紀錄，系統將自動保護資料安全，不允許硬刪除。',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#DC2626',
            confirmButtonText: '確認刪除',
            cancelButtonText: '取消'
        }).then((result) => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Zone_Management.aspx/DeleteZone",
                    data: JSON.stringify({ zoneId: zoneId }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        var r = res.d;
                        if (r.Success) {
                            Swal.fire({
                                icon: 'success',
                                title: '已刪除',
                                text: r.Message,
                                timer: 1500,
                                showConfirmButton: false
                            });
                            loadZoneOverview();
                        } else {
                            Swal.fire({
                                icon: 'error',
                                title: '無法刪除場域',
                                text: r.Message
                            });
                        }
                    },
                    error: function () {
                        Swal.fire('系統異常', '刪除操作時發生錯誤。', 'error');
                    }
                });
            }
        });
    }
</script>
</asp:Content>
