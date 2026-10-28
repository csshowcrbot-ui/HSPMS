<%@ Page Title="員工停車證申請與進度查詢" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Employee_Portal.aspx.cs" Inherits="HospitalParking.Employee_Portal" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .portal-nav-pills .nav-link {
            border-radius: 10px;
            font-weight: 600;
            padding: 0.75rem 1.5rem;
            color: #4B5563;
        }
        .portal-nav-pills .nav-link.active {
            background-color: var(--hsp-primary);
            color: white;
            box-shadow: 0 4px 10px rgba(26, 86, 219, 0.25);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container py-3" style="max-width: 900px;">
    <!-- 頂部標題 -->
    <div class="text-center mb-4">
        <h3 class="fw-bold text-dark mb-1">
            <i class="bi bi-person-badge text-primary me-2"></i>員工停車證自助申辦與進度追蹤
        </h3>
        <p class="text-muted">全院同仁、醫師與醫護人員停車證新辦、展期與審核進度即時可視化查詢。</p>
    </div>

    <!-- 頁籤導覽列 (Tabs) -->
    <ul class="nav nav-pills portal-nav-pills justify-content-center mb-4" id="portalTabs">
        <li class="nav-item">
            <button class="nav-link active" id="tab-apply" data-bs-toggle="pill" data-bs-target="#panel-apply" type="button">
                <i class="bi bi-pencil-square me-1"></i>線上填寫申請表 (新辦/換車)
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link" id="tab-track" data-bs-toggle="pill" data-bs-target="#panel-track" type="button">
                <i class="bi bi-clock-history me-1"></i>審核進度可視化追蹤 (Timeline)
            </button>
        </li>
    </ul>

    <!-- 頁籤內容面板 -->
    <div class="tab-content" id="portalTabsContent">
        <!-- ========================================== -->
        <!-- Tab 1: 線上申辦表單 -->
        <!-- ========================================== -->
        <div class="tab-pane fade show active" id="panel-apply">
            <div class="hsp-card p-4">
                <!-- 草稿提示列 -->
                <div id="draftAlert" class="alert alert-light border d-flex justify-content-between align-items-center py-2 px-3 mb-3 small" style="display:none !important;">
                    <span><i class="bi bi-cloud-check text-primary me-1"></i>系統已為您自動儲存草稿，切換頁面不遺失。</span>
                    <div>
                        <button type="button" class="btn btn-outline-danger btn-sm py-0 px-2" onclick="clearDraft();">清空重填</button>
                    </div>
                </div>

                <form id="frmApply" onsubmit="return false;">
                    <!-- 1. 申請人身分資訊 -->
                    <h6 class="text-primary fw-bold border-bottom pb-2 mb-3">
                        <i class="bi bi-person-vcard me-1"></i>1. 申請人身分與科室
                    </h6>
                    <div class="row g-3 mb-4">
                        <div class="col-md-6">
                            <label class="form-label required small">申請人姓名</label>
                            <input type="text" id="txtApplicantName" class="form-control" required placeholder="例: 陳怡君 護理師" oninput="saveDraft();" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label required small">員工工號 (識別證號)</label>
                            <input type="text" id="txtEmpNo" class="form-control text-uppercase font-monospace" required placeholder="例: EMP2088" oninput="saveDraft();" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label required small">服務部門科室</label>
                            <select id="ddlApplyDept" class="form-select" required onchange="saveDraft();"></select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small">院內分機 / 聯絡手機</label>
                            <input type="text" id="txtContactPhone" class="form-control" placeholder="例: 分機 3201 或 0912-345678" oninput="saveDraft();" />
                        </div>
                    </div>

                    <!-- 2. 車輛資訊 -->
                    <h6 class="text-primary fw-bold border-bottom pb-2 mb-3">
                        <i class="bi bi-car-front me-1"></i>2. 申請車輛資訊與停放區域
                    </h6>
                    <div class="row g-3 mb-4">
                        <div class="col-md-4">
                            <label class="form-label required small">車牌號碼</label>
                            <input type="text" id="txtLicensePlate" class="form-control text-uppercase font-monospace" required placeholder="例: ABC-1234 或 5678-EF" oninput="validatePlate(this); saveDraft();" />
                            <div class="form-text small" id="plateHelp">輸入後自動強制大寫轉換（全院採一車一證，同一車輛不可二人重複申辦）</div>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">車輛廠牌</label>
                            <input type="text" id="txtVehicleBrand" class="form-control" required placeholder="例: Toyota Corolla Cross" oninput="saveDraft();" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label required small">車輛顏色</label>
                            <input type="text" id="txtVehicleColor" class="form-control" required placeholder="例: 珍珠白" oninput="saveDraft();" />
                        </div>
                        <div class="col-md-12">
                            <label class="form-label required small">第一志願停放區域</label>
                            <select id="ddlApplyZone" class="form-select form-select-lg" required onchange="saveDraft();"></select>
                            <div class="form-text text-muted" id="zoneQuotaHelp">
                                請依您的值勤排班與大樓出入動線選擇最適分區（實際安排停放區，依實際配置為主）。
                            </div>
                        </div>
                    </div>

                    <!-- 3. 硬體配發與注意事項說明 -->
                    <div class="alert alert-primary bg-opacity-10 border-primary border-opacity-25 p-3 mb-4 rounded-3">
                        <h6 class="alert-heading fw-bold small text-primary mb-1">
                            <i class="bi bi-shield-exclamation me-1"></i>停車位申辦與門禁設備配發注意事項
                        </h6>
                        <ul class="mb-0 small text-muted ps-3">
                            <li class="text-primary fw-bold">實際安排停放區，依院區總務處車位配額與現場實際配置為主。</li>
                            <li><strong>車輛申辦原則：</strong>同仁<b>一人可依用車需求申辦多台車輛</b>（每台車輛請各別獨立送件）；但<b>同一車輛全院僅限一人申請</b>，系統設有重複比對防呆機制，不得由二人重複提出申請。</li>
                            <li>審核通過後，總務處將主動發布通知，請於 7 個工作日內攜帶<b>員工識別證</b>至總務處車管中心領證。</li>
                            <li>首次配發 eTag/RFID 車載感應卡及鐵捲門遙控器需配合現場登錄碼點對點綁定。</li>
                            <li>若離職或退租車位，請務必歸還門禁硬體設備並辦理保證金結清手續。</li>
                        </ul>
                    </div>

                    <!-- 按鈕群 -->
                    <div class="d-flex justify-content-between align-items-center pt-2">
                        <button type="button" class="btn btn-outline-secondary" onclick="manualSaveDraft();">
                            <i class="bi bi-save me-1"></i>暫存草稿
                        </button>
                        <button type="button" class="btn btn-primary btn-lg px-4 shadow" onclick="submitApplication();">
                            <i class="bi bi-send-check me-1"></i>確認送出申請單
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- ========================================== -->
        <!-- Tab 2: 進度可視化追蹤 -->
        <!-- ========================================== -->
        <div class="tab-pane fade" id="panel-track">
            <!-- 查詢輸入列 -->
            <div class="hsp-card p-4 mb-4">
                <div class="row g-2 justify-content-center">
                    <div class="col-12 col-md-8">
                        <label class="form-label fw-bold small">請輸入 員工工號 或 申請單號 查詢進度：</label>
                        <div class="input-group input-group-lg">
                            <input type="text" id="txtTrackQuery" class="form-control text-uppercase font-monospace" placeholder="例: EMP2001 或 APP-20261017-001" />
                            <button class="btn btn-primary px-4" type="button" onclick="executeTrack();">
                                <i class="bi bi-search me-1"></i>查詢進度
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 查詢結果區塊 (動態呈現) -->
            <div id="trackResultContainer" style="display:none;">
                <!-- 填入動態追蹤卡片 -->
            </div>

            <div id="trackEmptyState" class="text-center py-5 text-muted">
                <i class="bi bi-search fs-1 d-block mb-2 text-primary opacity-50"></i>
                <p>請輸入上方工號或單號，以檢視案件審核即時時間軸進度。</p>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script>
    var DRAFT_STORAGE_KEY = 'HSPMS_APPLY_FORM_DRAFT';

    $(document).ready(function () {
        loadApplyLookups();
        restoreDraft();

        // 綁定斷行檢核
        $('#txtTrackQuery').keypress(function (e) {
            if (e.which === 13) {
                executeTrack();
                return false;
            }
        });
    });

    function loadApplyLookups() {
        $.ajax({
            type: "POST",
            url: "Employee_Portal.aspx/GetLookupOptions",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                var deptOpts = '<option value="">-- 請選擇您的所屬部門 --</option>';
                d.Departments.forEach(dept => {
                    deptOpts += `<option value="${dept.DeptID}">${dept.DeptName}</option>`;
                });
                $('#ddlApplyDept').html(deptOpts);

                var zoneOpts = '<option value="">-- 請選擇第一志願停放分區 --</option>';
                d.Zones.forEach(zone => {
                    zoneOpts += `<option value="${zone.ZoneID}">${zone.ZoneName}</option>`;
                });
                $('#ddlApplyZone').html(zoneOpts);

                // 若有草稿且包含選單值，還原之
                var draftStr = localStorage.getItem(DRAFT_STORAGE_KEY);
                if (draftStr) {
                    var draft = JSON.parse(draftStr);
                    if (draft.DeptID) $('#ddlApplyDept').val(draft.DeptID);
                    if (draft.ZoneID) $('#ddlApplyZone').val(draft.ZoneID);
                }
            }
        });
    }

    function validatePlate(input) {
        input.value = input.value.toUpperCase();
        var val = input.value.trim();
        // 台灣車牌格式基本正則 (2~4英文 + 2~4數字)
        var plateRegex = /^[A-Z0-9]{2,4}-?[A-Z0-9]{2,4}$/;
        if (val.length >= 5) {
            if (plateRegex.test(val)) {
                $('#plateHelp').html('<span class="text-success"><i class="bi bi-check-circle me-1"></i>車牌格式合規</span>');
                $(input).removeClass('is-invalid').addClass('is-valid');
            } else {
                $('#plateHelp').html('<span class="text-danger"><i class="bi bi-exclamation-circle me-1"></i>請輸入有效車牌格式 (如 ABC-1234 或 5678-EF)</span>');
                $(input).removeClass('is-valid').addClass('is-invalid');
            }
        } else {
            $('#plateHelp').text('輸入後自動強制大寫轉換');
            $(input).removeClass('is-valid is-invalid');
        }
    }

    // 草稿儲存至 LocalStorage (防遺失規格)
    function saveDraft() {
        var draft = {
            ApplicantName: $('#txtApplicantName').val(),
            EmpNo: $('#txtEmpNo').val(),
            DeptID: $('#ddlApplyDept').val(),
            ContactPhone: $('#txtContactPhone').val(),
            LicensePlate: $('#txtLicensePlate').val(),
            VehicleBrand: $('#txtVehicleBrand').val(),
            VehicleColor: $('#txtVehicleColor').val(),
            ZoneID: $('#ddlApplyZone').val()
        };
        localStorage.setItem(DRAFT_STORAGE_KEY, JSON.stringify(draft));
        $('#draftAlert').attr('style', 'display: flex !important;');
    }

    function manualSaveDraft() {
        saveDraft();
        Swal.fire({
            toast: true,
            position: 'top-end',
            icon: 'success',
            title: '草稿已暫存於本機瀏覽器',
            showConfirmButton: false,
            timer: 2000
        });
    }

    function restoreDraft() {
        var draftStr = localStorage.getItem(DRAFT_STORAGE_KEY);
        if (draftStr) {
            try {
                var draft = JSON.parse(draftStr);
                $('#txtApplicantName').val(draft.ApplicantName || '');
                $('#txtEmpNo').val(draft.EmpNo || '');
                $('#txtContactPhone').val(draft.ContactPhone || '');
                $('#txtLicensePlate').val(draft.LicensePlate || '');
                $('#txtVehicleBrand').val(draft.VehicleBrand || '');
                $('#txtVehicleColor').val(draft.VehicleColor || '');
                $('#draftAlert').attr('style', 'display: flex !important;');
            } catch (e) { }
        }
    }

    function clearDraft() {
        localStorage.removeItem(DRAFT_STORAGE_KEY);
        $('#frmApply')[0].reset();
        $('#draftAlert').attr('style', 'display: none !important;');
        $('#txtLicensePlate').removeClass('is-valid is-invalid');
        $('#plateHelp').text('輸入後自動強制大寫轉換');
    }

    function submitApplication() {
        var dto = {
            ApplicantName: $('#txtApplicantName').val().trim(),
            EmpNo: $('#txtEmpNo').val().trim().toUpperCase(),
            DeptID: parseInt($('#ddlApplyDept').val()),
            ContactPhone: $('#txtContactPhone').val().trim(),
            LicensePlate: $('#txtLicensePlate').val().trim().toUpperCase(),
            VehicleBrand: $('#txtVehicleBrand').val().trim(),
            VehicleColor: $('#txtVehicleColor').val().trim(),
            PreferredZoneID: parseInt($('#ddlApplyZone').val())
        };

        if (!dto.ApplicantName || !dto.EmpNo || !dto.DeptID || !dto.LicensePlate || !dto.VehicleBrand || !dto.VehicleColor || !dto.PreferredZoneID) {
            Swal.fire('欄位未齊全', '請填寫所有標記紅星之必填欄位！', 'warning');
            return;
        }

        Swal.fire({
            title: '確認送出停車證申請？',
            text: `申請車牌：${dto.LicensePlate} (志願分區：${$('#ddlApplyZone option:selected').text()})`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: '確定送出',
            cancelButtonText: '再檢查一下',
            confirmButtonColor: '#1A56DB'
        }).then(result => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Employee_Portal.aspx/SubmitApplication",
                    data: JSON.stringify({ dto: dto }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        if (res.d.Success) {
                            var appNo = res.d.Data;
                            clearDraft();
                            Swal.fire({
                                icon: 'success',
                                title: '申請單送出成功！',
                                html: `您的申請單號為：<strong class="text-primary font-monospace fs-5">${appNo}</strong><br><br>系統已自動為您切換至進度追蹤分頁。`,
                                confirmButtonText: '前往追蹤'
                            }).then(() => {
                                // 切換至追蹤 Tab
                                $('#tab-track').tab('show');
                                $('#txtTrackQuery').val(appNo);
                                executeTrack();
                            });
                        } else {
                            Swal.fire('申請失敗', res.d.Message, 'error');
                        }
                    }
                });
            }
        });
    }

    function executeTrack() {
        var query = $('#txtTrackQuery').val().trim().toUpperCase();
        if (!query) {
            Swal.fire('提示', '請輸入欲查詢的工號或申請單號！', 'info');
            return;
        }

        $('#trackEmptyState').hide();
        $('#trackResultContainer').html('<div class="text-center py-5"><span class="spinner-border text-primary"></span><div class="mt-2 text-muted">查詢審核進度中...</div></div>').show();

        $.ajax({
            type: "POST",
            url: "Employee_Portal.aspx/SearchApplications",
            data: JSON.stringify({ query: query }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var list = res.d || [];
                renderTrackResults(list);
            },
            error: function () {
                $('#trackResultContainer').html('<div class="alert alert-danger text-center">查詢失敗，請重試。</div>');
            }
        });
    }

    function renderTrackResults(list) {
        if (list.length === 0) {
            $('#trackResultContainer').html(`
                <div class="hsp-card p-5 text-center text-muted">
                    <i class="bi bi-question-circle fs-1 text-warning mb-2 d-block"></i>
                    <h5>查無相符之申請單紀錄</h5>
                    <p class="small">請確認您輸入的工號或單號是否正確，或尚未送出線上申請。</p>
                </div>`);
            return;
        }

        var html = '';
        list.forEach(app => {
            var status = app.ReviewStatus;
            var step1Class = 'completed'; // 送出
            var step2Class = ''; // 收案
            var step3Class = ''; // 排序/配額
            var step4Class = ''; // 待領證
            var step5Class = ''; // 發證結案

            var statusBadge = '';
            if (status === 'PENDING') {
                step2Class = 'active';
                statusBadge = '<span class="badge bg-warning text-dark fs-6"><i class="bi bi-hourglass-split me-1"></i>新申請待審核</span>';
            } else if (status === 'PROCESSING') {
                step2Class = 'completed';
                step3Class = 'active';
                statusBadge = '<span class="badge bg-primary fs-6"><i class="bi bi-inbox-fill me-1"></i>已收案審理中</span>';
            } else if (status === 'WAITLIST') {
                step2Class = 'completed';
                step3Class = 'active';
                statusBadge = '<span class="badge bg-secondary fs-6"><i class="bi bi-clock-history me-1"></i>待排序輪候中</span>';
            } else if (status === 'APPROVED') {
                step2Class = 'completed';
                step3Class = 'completed';
                step4Class = 'active';
                statusBadge = '<span class="badge bg-info text-dark fs-6"><i class="bi bi-card-checklist me-1"></i>已核准待領證</span>';
            } else if (status === 'COMPLETED') {
                step2Class = 'completed';
                step3Class = 'completed';
                step4Class = 'completed';
                step5Class = 'completed';
                statusBadge = '<span class="badge bg-success fs-6"><i class="bi bi-patch-check-fill me-1"></i>已發證正式啟用</span>';
            } else if (status === 'REJECTED') {
                step2Class = 'rejected';
                statusBadge = '<span class="badge bg-danger fs-6"><i class="bi bi-x-circle me-1"></i>未通過駁回</span>';
            }

            html += `
                <div class="hsp-card p-4 mb-4">
                    <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center border-bottom pb-3 mb-3 gap-2">
                        <div>
                            <span class="badge bg-light text-primary border font-monospace me-2">${app.ApplicationNo}</span>
                            <span class="fw-bold fs-5">${app.ApplicantName} (${app.EmpNo})</span>
                            <small class="text-muted d-block mt-1">服務部門：${app.DeptName} | 聯絡電話：${app.ContactPhone || '--'}</small>
                        </div>
                        <div>${statusBadge}</div>
                    </div>

                    <div class="row g-2 small mb-4 bg-light p-3 rounded-3">
                        <div class="col-6 col-md-3"><strong>車牌號碼：</strong><span class="license-plate-badge">${app.LicensePlate}</span></div>
                        <div class="col-6 col-md-3"><strong>車型顏色：</strong>${app.VehicleBrand} / ${app.VehicleColor}</div>
                        <div class="col-6 col-md-3">
                            <strong>停放分區：</strong>
                            ${app.AssignedZoneName && app.AssignedZoneID && app.AssignedZoneID !== app.PreferredZoneID
                                ? `<span class="badge bg-primary text-white" title="總務處依院區現況彈性調整配置">${app.AssignedZoneName}</span> <small class="text-muted d-block" style="font-size:0.72rem;">(原志願: ${app.PreferredZoneName})</small>`
                                : `<span class="badge bg-info text-dark">${app.PreferredZoneName}</span>`}
                        </div>
                        <div class="col-6 col-md-3"><strong>送件時間：</strong>${app.ApplyDate}</div>
                    </div>

                    <!-- 垂直進度時間軸 (5 大審核流程步驟) -->
                    <div class="timeline">
                        <!-- Step 1 -->
                        <div class="timeline-step ${step1Class}">
                            <div class="timeline-marker"><i class="bi bi-check"></i></div>
                            <div class="fw-bold">1. 線上申請已送出</div>
                            <small class="text-muted">同仁已於系統登錄車籍資料並完成送件 (${app.ApplyDate})</small>
                        </div>

                        <!-- Step 2 -->
                        <div class="timeline-step ${step2Class}">
                            <div class="timeline-marker">
                                ${status === 'REJECTED' ? '<i class="bi bi-x"></i>' : (status === 'PENDING' ? '<i class="bi bi-dot"></i>' : '<i class="bi bi-check"></i>')}
                            </div>
                            <div class="fw-bold">2. 總務處受理收案</div>
                            <small class="text-muted">
                                ${status === 'PENDING' ? '案件已送達總務處，等候管理專員初審收案' : (status === 'PROCESSING' ? '<span class="text-primary fw-bold">已正式收案受理！專員刻正審查車籍證件與科室資格。</span>' : '總務處已完成初審收案')}
                            </small>
                            ${status === 'REJECTED' ? `
                                <div class="alert alert-danger mt-2 py-2 px-3 small">
                                    <strong>駁回原因：</strong>${app.RejectReason || '未符合申請資格或配額已滿'}
                                    <div class="mt-2">
                                        <button class="btn btn-sm btn-outline-danger" onclick="$('#tab-apply').tab('show');">重新填表申請</button>
                                    </div>
                                </div>` : ''}
                        </div>

                        <!-- Step 3 -->
                        <div class="timeline-step ${step3Class}">
                            <div class="timeline-marker">
                                ${step3Class === 'completed' ? '<i class="bi bi-check"></i>' : '<i class="bi bi-dot"></i>'}
                            </div>
                            <div class="fw-bold">3. 配額排序與資格比對</div>
                            <small class="text-muted">
                                ${status === 'WAITLIST' ? '<span class="text-warning fw-bold">★ 因志願停車場目前滿載，案件已列入【待排序】輪候名單，配額釋出將依序通知。</span>' : (step3Class === 'completed' ? '停車場額度比對完成，已配置車位配額' : '比對該區域停車容量與科室配額指標')}
                            </small>
                        </div>

                        <!-- Step 4 -->
                        <div class="timeline-step ${step4Class}">
                            <div class="timeline-marker">
                                ${step4Class === 'completed' ? '<i class="bi bi-check"></i>' : '<i class="bi bi-dot"></i>'}
                            </div>
                            <div class="fw-bold">4. 審核核准待領證</div>
                            <small class="text-muted">
                                ${status === 'APPROVED' ? '<span class="text-info fw-bold">★ 審核通過！請攜帶員工識別證至總務行政處領取 RFID 感應卡與鐵捲門遙控器。</span>' : (step4Class === 'completed' ? '同仁已完成臨櫃領卡' : '審核通過後發出領證通知')}
                            </small>
                        </div>

                        <!-- Step 5 -->
                        <div class="timeline-step ${step5Class}">
                            <div class="timeline-marker">
                                ${step5Class === 'completed' ? '<i class="bi bi-check"></i>' : '<i class="bi bi-dot"></i>'}
                            </div>
                            <div class="fw-bold">5. 發證結案與生效啟用</div>
                            <small class="text-muted">
                                ${status === 'COMPLETED' ? '<span class="text-success fw-bold">★ 通行證已核發並生效啟用！車籍已即時匯入全院門禁與警衛巡檢查驗系統。</span>' : '臨櫃完成硬體序號綁定，車籍正式匯入停車場門禁與巡檢系統'}
                            </small>
                        </div>
                    </div>
                </div>`;
        });

        $('#trackResultContainer').html(html);
    }
</script>
</asp:Content>
