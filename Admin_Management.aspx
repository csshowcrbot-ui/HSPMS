<%@ Page Title="管理者與巡檢人員維護" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Admin_Management.aspx.cs" Inherits="HospitalParking.Admin_Management" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .user-card {
            border-radius: 12px;
            border: 1px solid #E5E7EB;
            background: #fff;
            transition: all 0.25s ease;
        }
        .user-card:hover {
            box-shadow: 0 10px 22px rgba(0, 0, 0, 0.06);
            transform: translateY(-2px);
        }
        .avatar-box {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            font-weight: 700;
        }
        .avatar-admin {
            background: #EEF2FF;
            color: #4F46E5;
            border: 1px solid #C7D2FE;
        }
        .avatar-security {
            background: #ECFDF5;
            color: #059669;
            border: 1px solid #A7F3D0;
        }
        .avatar-super {
            background: #FEF3C7;
            color: #D97706;
            border: 1px solid #FDE68A;
        }
        .role-badge-super {
            background-color: #FEF3C7;
            color: #92400E;
            border: 1px solid #FCD34D;
        }
        .role-badge-admin {
            background-color: #EEF2FF;
            color: #3730A3;
            border: 1px solid #C7D2FE;
        }
        .role-badge-security {
            background-color: #ECFDF5;
            color: #065F46;
            border: 1px solid #A7F3D0;
        }
        .table-users tbody tr {
            transition: background-color 0.15s ease;
        }
        .table-users tbody tr:hover {
            background-color: #F9FAFB;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container-fluid px-3 px-lg-4">
    <!-- 頂部頁籤標題與操作按鈕 -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center py-2 mb-3 border-bottom gap-2">
        <div>
            <h4 class="mb-1 fw-bold text-dark">
                <i class="bi bi-people-fill text-primary me-2"></i>管理者與巡檢人員維護 (Administrators & Inspectors)
            </h4>
            <p class="text-muted small mb-0">全院停車管理系統權限帳號維護，可自行新增、編輯及控管總務後台管理員與現場巡檢警衛帳號。</p>
        </div>
        <div class="d-flex align-items-center gap-2">
            <button type="button" class="btn btn-primary shadow-sm" onclick="openAddUserModal();">
                <i class="bi bi-person-plus-fill me-1"></i>新增管理 / 巡檢人員
            </button>
            <button type="button" class="btn btn-outline-secondary" onclick="loadUserOverview();" title="重新整理">
                <i class="bi bi-arrow-clockwise me-1"></i>刷新
            </button>
        </div>
    </div>

    <!-- 4 大 KPI 統計指標卡片 -->
    <div class="row g-3 mb-4">
        <!-- 1. 全院帳號總數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-blue">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">系統帳號總數 (Total Users)</div>
                        <div class="kpi-value" id="kpiTotalUsers">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-person-vcard"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    全院後台與行動端人員帳號總計
                </div>
            </div>
        </div>

        <!-- 2. 後台系統管理員 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-indigo">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">系統管理者 (Admins)</div>
                        <div class="kpi-value" id="kpiAdminCount">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-shield-lock-fill"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    具後台主控台、審核與車籍維護權限
                </div>
            </div>
        </div>

        <!-- 3. 現場巡檢警衛人員 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-green">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">現場巡檢人員 (Inspectors)</div>
                        <div class="kpi-value" id="kpiSecurityCount">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-camera-fill"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    現場行動端車牌掃描、違規拍照稽核
                </div>
            </div>
        </div>

        <!-- 4. 正常啟用中帳號 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-amber">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">正常啟用中 (Active Accounts)</div>
                        <div class="kpi-value" id="kpiActiveUsers">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-check-circle-fill"></i>
                    </div>
                </div>
                <div class="kpi-footer text-muted">
                    目前授權可正常登入使用之帳號
                </div>
            </div>
        </div>
    </div>

    <!-- 複合篩選與搜尋列 -->
    <div class="card border-0 shadow-sm rounded-3 mb-4">
        <div class="card-body p-3">
            <div class="row g-2 align-items-center">
                <div class="col-12 col-md-4 col-lg-5">
                    <div class="input-group">
                        <span class="input-group-text bg-white border-end-0 text-muted">
                            <i class="bi bi-search"></i>
                        </span>
                        <input type="text" id="txtKeyword" class="form-control border-start-0" 
                               placeholder="搜尋帳號、姓名、部門或分機..." onkeyup="if(event.keyCode===13) loadUserOverview();" />
                    </div>
                </div>
                <div class="col-6 col-md-3 col-lg-2">
                    <select id="selRoleFilter" class="form-select" onchange="loadUserOverview();">
                        <option value="ALL">全部身分角色</option>
                        <option value="ADMIN_GROUP">系統管理者 (主管/專員)</option>
                        <option value="SECURITY">現場巡檢人員 (警衛)</option>
                    </select>
                </div>
                <div class="col-6 col-md-3 col-lg-2">
                    <select id="selStatusFilter" class="form-select" onchange="loadUserOverview();">
                        <option value="ALL">全部啟用狀態</option>
                        <option value="ACTIVE" selected>僅顯示啟用中</option>
                        <option value="INACTIVE">僅顯示已停用</option>
                    </select>
                </div>
                <div class="col-12 col-md-2 col-lg-3 text-md-end mt-2 mt-md-0">
                    <button type="button" class="btn btn-outline-secondary btn-sm px-3" onclick="clearFilters();">
                        <i class="bi bi-x-circle me-1"></i>清除條件
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 人員帳號清單表格 -->
    <div class="card border-0 shadow-sm rounded-3">
        <div class="card-header bg-white py-3 border-bottom d-flex justify-content-between align-items-center">
            <h6 class="mb-0 fw-bold text-dark">
                <i class="bi bi-card-list text-primary me-2"></i>系統人員帳號名冊
            </h6>
            <span class="badge bg-light text-secondary border px-2 py-1" id="lblResultCount">載入中...</span>
        </div>
        <div class="table-responsive">
            <table class="table table-hover table-users align-middle mb-0">
                <thead class="table-light text-muted small text-uppercase">
                    <tr>
                        <th class="ps-3" style="width: 60px;">#</th>
                        <th>登入帳號</th>
                        <th>人員姓名 / 稱謂</th>
                        <th>身分角色</th>
                        <th>所屬科室 / 部門</th>
                        <th>聯絡電話 / 分機</th>
                        <th>最後登入時間</th>
                        <th>帳號狀態</th>
                        <th class="text-end pe-3" style="min-width: 170px;">功能操作</th>
                    </tr>
                </thead>
                <tbody id="tblUserBody">
                    <tr>
                        <td colspan="9" class="text-center py-5 text-muted">
                            <div class="spinner-border text-primary spinner-border-sm me-2" role="status"></div>
                            正在載入人員帳號名冊...
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- ========================================== -->
<!-- 彈窗：新增 / 編輯管理員或巡檢人員 Modal -->
<!-- ========================================== -->
<div class="modal fade" id="userModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <div class="modal-header bg-primary text-white py-3">
                <h5 class="modal-title fw-bold" id="userModalTitle">
                    <i class="bi bi-person-fill-gear me-2"></i>新增管理 / 巡檢人員帳號
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <form id="formUser" onsubmit="return false;">
                    <input type="hidden" id="hdnAdminID" value="0" />

                    <!-- 角色類型選擇 (按鈕群組視覺切換) -->
                    <div class="mb-4">
                        <label class="form-label fw-bold text-dark mb-2">
                            人員角色類型 <span class="text-danger">*</span>
                        </label>
                        <div class="row g-2">
                            <div class="col-md-6">
                                <div class="form-check card p-3 border-2 role-choice-card" id="cardRoleAdmin" style="cursor: pointer;" onclick="selectRole('ADMIN');">
                                    <input class="form-check-input" type="radio" name="radRole" id="radRoleAdmin" value="ADMIN" checked>
                                    <label class="form-check-label w-100 ps-2" for="radRoleAdmin" style="cursor: pointer;">
                                        <div class="fw-bold text-primary">
                                            <i class="bi bi-shield-lock-fill me-1"></i>總務系統管理員 (ADMIN)
                                        </div>
                                        <div class="small text-muted mt-1">擁有管理看板、車籍維護、場域與科室配額設定、員工申請審核及帳號管理權限。</div>
                                    </label>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-check card p-3 border-2 role-choice-card" id="cardRoleSecurity" style="cursor: pointer;" onclick="selectRole('SECURITY');">
                                    <input class="form-check-input" type="radio" name="radRole" id="radRoleSecurity" value="SECURITY">
                                    <label class="form-check-label w-100 ps-2" for="radRoleSecurity" style="cursor: pointer;">
                                        <div class="fw-bold text-success">
                                            <i class="bi bi-camera-fill me-1"></i>現場巡檢查核人員 (SECURITY)
                                        </div>
                                        <div class="small text-muted mt-1">專用於警衛手機/平板行動巡檢模式，進行車牌 OCR 辨識、跨區逾期違規判定與拍照存證。</div>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row g-3">
                        <!-- 登入帳號 -->
                        <div class="col-md-6">
                            <label for="txtUsername" class="form-label fw-semibold text-dark">
                                登入帳號 (Username) <span class="text-danger">*</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-person"></i></span>
                                <input type="text" class="form-control" id="txtUsername" placeholder="例: admin02, sec_duty03" maxlength="30" required />
                            </div>
                            <div class="form-text small">英數字或底線，建立後具唯一性防呆驗證。</div>
                        </div>

                        <!-- 顯示姓名 / 稱謂 -->
                        <div class="col-md-6">
                            <label for="txtDisplayName" class="form-label fw-semibold text-dark">
                                人員姓名 / 稱謂 <span class="text-danger">*</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-card-text"></i></span>
                                <input type="text" class="form-control" id="txtDisplayName" placeholder="例: 林專員 (總務車管)、張警衛" maxlength="50" required />
                            </div>
                        </div>

                        <!-- 登入密碼 -->
                        <div class="col-md-6">
                            <label for="txtPassword" class="form-label fw-semibold text-dark">
                                登入密碼 <span class="text-danger" id="spanPwdRequired">*</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-key"></i></span>
                                <input type="password" class="form-control" id="txtPassword" placeholder="輸入 6 位以上密碼" maxlength="50" />
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePasswordVisibility('txtPassword', this);">
                                    <i class="bi bi-eye"></i>
                                </button>
                            </div>
                            <div class="form-text small" id="lblPwdHint">新增帳號時為必填欄位。</div>
                        </div>

                        <!-- 職務名稱稱謂 -->
                        <div class="col-md-6">
                            <label for="txtRoleName" class="form-label fw-semibold text-dark">
                                職稱稱謂 (Role Title) <span class="text-danger">*</span>
                            </label>
                            <input type="text" class="form-control" id="txtRoleName" placeholder="例: 總務行政主管、現場巡檢警衛" maxlength="50" />
                        </div>

                        <!-- 所屬部門科室 -->
                        <div class="col-md-6">
                            <label for="selDeptName" class="form-label fw-semibold text-dark">
                                所屬部門 / 課室
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-hospital"></i></span>
                                <select class="form-select" id="selDeptName">
                                    <option value="總務行政處">總務行政處</option>
                                    <option value="安全警衛課">安全警衛課</option>
                                    <option value="資訊室">資訊室</option>
                                    <option value="工務室">工務室</option>
                                </select>
                            </div>
                        </div>

                        <!-- 聯絡電話 / 分機 -->
                        <div class="col-md-6">
                            <label for="txtContactPhone" class="form-label fw-semibold text-dark">
                                聯絡分機 / 公務手機
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-telephone"></i></span>
                                <input type="text" class="form-control" id="txtContactPhone" placeholder="例: 分機 3108 或 0912-345678" maxlength="30" />
                            </div>
                        </div>

                        <!-- 電子郵件 (選填) -->
                        <div class="col-md-6">
                            <label for="txtEmail" class="form-label fw-semibold text-dark">
                                電子郵件 (Email)
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-envelope"></i></span>
                                <input type="email" class="form-control" id="txtEmail" placeholder="example@hospital.org.tw" maxlength="80" />
                            </div>
                        </div>

                        <!-- 帳號啟用狀態 -->
                        <div class="col-md-6 d-flex align-items-center pt-md-4">
                            <div class="form-check form-switch fs-5">
                                <input class="form-check-input" type="checkbox" id="chkIsActive" checked />
                                <label class="form-check-label fs-6 fw-semibold text-dark ms-2" for="chkIsActive">
                                    立即啟用此帳號權限
                                </label>
                            </div>
                        </div>

                        <!-- 備註說明 -->
                        <div class="col-12">
                            <label for="txtRemarks" class="form-label fw-semibold text-dark">
                                備註說明
                            </label>
                            <textarea class="form-control" id="txtRemarks" rows="2" placeholder="可填寫人員排班、發卡負責或權限異動說明..." maxlength="200"></textarea>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer bg-light py-2 px-4 border-top">
                <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary px-4 fw-semibold shadow-sm" onclick="submitUserForm();">
                    <i class="bi bi-check-circle-fill me-1"></i>儲存人員設定
                </button>
            </div>
        </div>
    </div>
</div>

<!-- ========================================== -->
<!-- 彈窗：重設密碼 Quick Modal -->
<!-- ========================================== -->
<div class="modal fade" id="pwdModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <div class="modal-header bg-warning text-dark py-2">
                <h6 class="modal-title fw-bold">
                    <i class="bi bi-key-fill me-2"></i>重設人員登入密碼
                </h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <input type="hidden" id="hdnPwdAdminID" value="0" />
                <div class="mb-2">
                    <label class="form-label small text-muted mb-1">目標帳號</label>
                    <div class="fw-bold text-dark" id="lblResetUsername">--</div>
                </div>
                <div class="mb-3">
                    <label for="txtNewPassword" class="form-label small fw-semibold text-dark mb-1">請輸入新密碼</label>
                    <div class="input-group">
                        <input type="password" class="form-control" id="txtNewPassword" placeholder="輸入 6 位以上新密碼" maxlength="50" />
                        <button class="btn btn-outline-secondary" type="button" onclick="togglePasswordVisibility('txtNewPassword', this);">
                            <i class="bi bi-eye"></i>
                        </button>
                    </div>
                </div>
            </div>
            <div class="modal-footer bg-light py-2">
                <button type="button" class="btn btn-sm btn-outline-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-sm btn-warning fw-semibold px-3" onclick="submitResetPassword();">
                    確認重設密碼
                </button>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<!-- 頁面專屬 JavaScript 互動控制 -->
<script>
    var gUsers = [];
    var gUserModal = null;
    var gPwdModal = null;

    $(document).ready(function () {
        try {
            var modalEl = document.getElementById('userModal');
            if (modalEl && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                gUserModal = new bootstrap.Modal(modalEl);
            }
            var pwdEl = document.getElementById('pwdModal');
            if (pwdEl && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                gPwdModal = new bootstrap.Modal(pwdEl);
            }
        } catch (e) {
            console.error('Modal init error:', e);
        }

        loadDeptOptions();
        loadUserOverview();
    });

    // 載入所屬部門下拉選項
    function loadDeptOptions() {
        $.ajax({
            type: "POST",
            url: "Admin_Management.aspx/GetDeptOptions",
            data: "{}",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                if (res.d && res.d.length > 0) {
                    var $sel = $('#selDeptName');
                    $sel.empty();
                    res.d.forEach(function (d) {
                        $sel.append($('<option></option>').val(d).text(d));
                    });
                }
            }
        });
    }

    // 載入人員總覽與清單
    function loadUserOverview() {
        var kw = $('#txtKeyword').val();
        var role = $('#selRoleFilter').val();
        var status = $('#selStatusFilter').val();

        $('#tblUserBody').html('<tr><td colspan="9" class="text-center py-4 text-muted"><div class="spinner-border text-primary spinner-border-sm me-2"></div>正在載入最新名冊...</td></tr>');

        $.ajax({
            type: "POST",
            url: "Admin_Management.aspx/GetOverview",
            data: JSON.stringify({ keyword: kw, roleFilter: role, statusFilter: status }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var data = res.d;
                if (!data) return;

                // 更新 4 大 KPI 卡片
                $('#kpiTotalUsers').text(data.TotalUsers);
                $('#kpiActiveUsers').text(data.ActiveUsers);
                $('#kpiAdminCount').text(data.AdminCount);
                $('#kpiSecurityCount').text(data.SecurityCount);

                gUsers = data.UserList || [];
                renderUserTable(gUsers);
            },
            error: function (xhr, status, err) {
                $('#tblUserBody').html('<tr><td colspan="9" class="text-center py-4 text-danger"><i class="bi bi-exclamation-triangle-fill me-2"></i>載入資料失敗，請確認資料庫連線！</td></tr>');
            }
        });
    }

    // 渲染人員清單表格
    function renderUserTable(list) {
        $('#lblResultCount').text('共 ' + list.length + ' 筆紀錄');

        if (!list || list.length === 0) {
            $('#tblUserBody').html('<tr><td colspan="9" class="text-center py-5 text-muted"><i class="bi bi-inbox fs-3 d-block mb-2 text-secondary"></i>查無符合條件的人員紀錄</td></tr>');
            return;
        }

        var html = '';
        list.forEach(function (u, idx) {
            var isSecurity = u.Role === 'SECURITY';
            var isSuper = u.Role === 'SUPER_ADMIN';

            var avatarClass = isSuper ? 'avatar-super' : (isSecurity ? 'avatar-security' : 'avatar-admin');
            var avatarIcon = isSuper ? 'bi-star-fill' : (isSecurity ? 'bi-camera-fill' : 'bi-shield-lock-fill');

            var badgeClass = isSuper ? 'role-badge-super' : (isSecurity ? 'role-badge-security' : 'role-badge-admin');
            var roleTitle = u.RoleName || (isSecurity ? '現場巡檢警衛' : '總務系統管理員');

            var statusBadge = u.IsActive
                ? '<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-check-circle-fill me-1"></i>啟用中</span>'
                : '<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-2 py-1"><i class="bi bi-dash-circle-fill me-1"></i>已停用</span>';

            html += '<tr>';
            html += '<td class="ps-3 text-muted fw-semibold">' + (idx + 1) + '</td>';
            html += '<td>';
            html += '  <div class="d-flex align-items-center gap-2">';
            html += '    <div class="avatar-box ' + avatarClass + '"><i class="bi ' + avatarIcon + '"></i></div>';
            html += '    <div>';
            html += '      <span class="badge bg-light text-dark border font-monospace px-2 py-1">' + escapeHtml(u.Username) + '</span>';
            if (isSuper) {
                html += '      <span class="badge bg-warning text-dark ms-1" style="font-size: 0.7rem;">最高主管</span>';
            }
            html += '    </div>';
            html += '  </div>';
            html += '</td>';
            html += '<td><div class="fw-bold text-dark">' + escapeHtml(u.DisplayName) + '</div><small class="text-muted">' + (escapeHtml(u.Remarks) || '') + '</small></td>';
            html += '<td><span class="badge ' + badgeClass + ' px-2 py-1">' + escapeHtml(roleTitle) + '</span></td>';
            html += '<td><span class="text-secondary"><i class="bi bi-building me-1"></i>' + escapeHtml(u.DeptName || '--') + '</span></td>';
            html += '<td>' + (u.ContactPhone ? '<i class="bi bi-telephone text-muted me-1"></i>' + escapeHtml(u.ContactPhone) : '<span class="text-muted">--</span>') + '</td>';
            html += '<td><small class="text-muted">' + escapeHtml(u.LastLoginTime || '從未登入') + '</small></td>';
            html += '<td>' + statusBadge + '</td>';
            html += '<td class="text-end pe-3">';
            html += '  <div class="btn-group btn-group-sm">';
            html += '    <button type="button" class="btn btn-outline-primary" onclick="editUser(' + u.AdminID + ');" title="編輯人員"><i class="bi bi-pencil-square"></i></button>';
            html += '    <button type="button" class="btn btn-outline-warning" onclick="openResetPasswordModal(' + u.AdminID + ', \'' + escapeHtml(u.Username) + '\', \'' + escapeHtml(u.DisplayName) + '\');" title="重設密碼"><i class="bi bi-key"></i></button>';
            if (u.IsActive) {
                html += '    <button type="button" class="btn btn-outline-secondary" onclick="toggleUserStatus(' + u.AdminID + ', false);" title="停用帳號"><i class="bi bi-slash-circle"></i></button>';
            } else {
                html += '    <button type="button" class="btn btn-outline-success" onclick="toggleUserStatus(' + u.AdminID + ', true);" title="啟用帳號"><i class="bi bi-check-circle"></i></button>';
            }
            html += '    <button type="button" class="btn btn-outline-danger" onclick="deleteUser(' + u.AdminID + ', \'' + escapeHtml(u.DisplayName) + '\');" title="刪除帳號"><i class="bi bi-trash"></i></button>';
            html += '  </div>';
            html += '</td>';
            html += '</tr>';
        });

        $('#tblUserBody').html(html);
    }

    // 選擇角色類型連動預設值
    function selectRole(role) {
        $('input[name="radRole"][value="' + role + '"]').prop('checked', true);

        if (role === 'SECURITY') {
            $('#cardRoleSecurity').addClass('border-success bg-success-subtle');
            $('#cardRoleAdmin').removeClass('border-primary bg-primary-subtle');
            if ($('#hdnAdminID').val() === '0') {
                $('#txtRoleName').val('現場巡檢人員');
                $('#selDeptName').val('安全警衛課');
            }
        } else {
            $('#cardRoleAdmin').addClass('border-primary bg-primary-subtle');
            $('#cardRoleSecurity').removeClass('border-success bg-success-subtle');
            if ($('#hdnAdminID').val() === '0') {
                $('#txtRoleName').val('總務系統管理員');
                $('#selDeptName').val('總務行政處');
            }
        }
    }

    // 開啟新增人員 Modal
    function openAddUserModal() {
        $('#hdnAdminID').val('0');
        $('#userModalTitle').html('<i class="bi bi-person-plus-fill me-2"></i>新增管理 / 巡檢人員帳號');
        $('#txtUsername').val('').prop('readonly', false);
        $('#txtDisplayName').val('');
        $('#txtPassword').val('');
        $('#txtContactPhone').val('');
        $('#txtEmail').val('');
        $('#txtRemarks').val('');
        $('#chkIsActive').prop('checked', true);

        $('#spanPwdRequired').show();
        $('#lblPwdHint').text('新增帳號時登入密碼為必填。');

        selectRole('ADMIN');
        gUserModal.show();
    }

    // 開啟編輯人員 Modal
    function editUser(adminId) {
        $.ajax({
            type: "POST",
            url: "Admin_Management.aspx/GetUser",
            data: JSON.stringify({ adminId: adminId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var u = res.d;
                if (!u) {
                    Swal.fire('錯誤', '查無此人員資料！', 'error');
                    return;
                }

                $('#hdnAdminID').val(u.AdminID);
                $('#userModalTitle').html('<i class="bi bi-pencil-square me-2"></i>編輯人員：' + escapeHtml(u.DisplayName));
                $('#txtUsername').val(u.Username).prop('readonly', true);
                $('#txtDisplayName').val(u.DisplayName);
                $('#txtPassword').val('');
                $('#txtRoleName').val(u.RoleName);
                $('#selDeptName').val(u.DeptName);
                $('#txtContactPhone').val(u.ContactPhone);
                $('#txtEmail').val(u.Email);
                $('#chkIsActive').prop('checked', u.IsActive);
                $('#txtRemarks').val(u.Remarks);

                $('#spanPwdRequired').hide();
                $('#lblPwdHint').text('編輯時留空代表「保持原密碼不變」。');

                selectRole(u.Role === 'SECURITY' ? 'SECURITY' : 'ADMIN');
                gUserModal.show();
            }
        });
    }

    // 提交儲存人員表單
    function submitUserForm() {
        var adminId = parseInt($('#hdnAdminID').val()) || 0;
        var role = $('input[name="radRole"]:checked').val() || 'ADMIN';
        var username = $.trim($('#txtUsername').val());
        var displayName = $.trim($('#txtDisplayName').val());
        var password = $.trim($('#txtPassword').val());
        var roleName = $.trim($('#txtRoleName').val());
        var deptName = $('#selDeptName').val();
        var phone = $.trim($('#txtContactPhone').val());
        var email = $.trim($('#txtEmail').val());
        var isActive = $('#chkIsActive').is(':checked');
        var remarks = $.trim($('#txtRemarks').val());

        if (!username) {
            Swal.fire('提醒', '請輸入登入帳號！', 'warning');
            $('#txtUsername').focus();
            return;
        }

        if (!displayName) {
            Swal.fire('提醒', '請輸入人員姓名或稱謂！', 'warning');
            $('#txtDisplayName').focus();
            return;
        }

        if (adminId === 0 && !password) {
            Swal.fire('提醒', '新增帳號時，登入密碼為必填！', 'warning');
            $('#txtPassword').focus();
            return;
        }

        var dto = {
            AdminID: adminId,
            Username: username,
            DisplayName: displayName,
            Password: password,
            Role: role,
            RoleName: roleName,
            DeptName: deptName,
            ContactPhone: phone,
            Email: email,
            IsActive: isActive,
            Remarks: remarks
        };

        $.ajax({
            type: "POST",
            url: "Admin_Management.aspx/SaveUser",
            data: JSON.stringify({ dto: dto }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var r = res.d;
                if (r.Success) {
                    gUserModal.hide();
                    Swal.fire({
                        icon: 'success',
                        title: '成功',
                        text: r.Message,
                        timer: 1600,
                        showConfirmButton: false
                    });
                    loadUserOverview();
                } else {
                    Swal.fire('操作失敗', r.Message, 'error');
                }
            },
            error: function () {
                Swal.fire('系統錯誤', '儲存過程發生異常，請重試！', 'error');
            }
        });
    }

    // 切換啟用 / 停用
    function toggleUserStatus(adminId, targetStatus) {
        var actionText = targetStatus ? '啟用' : '停用';
        Swal.fire({
            title: '確認' + actionText + '帳號？',
            text: '確定要將此帳號狀態設定為【' + (targetStatus ? '啟用中' : '已停用') + '】嗎？',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: '確定' + actionText,
            cancelButtonText: '取消'
        }).then(function (result) {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Admin_Management.aspx/ToggleStatus",
                    data: JSON.stringify({ adminId: adminId, targetStatus: targetStatus }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        var r = res.d;
                        if (r.Success) {
                            Swal.fire('已完成', r.Message, 'success');
                            loadUserOverview();
                        } else {
                            Swal.fire('無法執行', r.Message, 'warning');
                        }
                    }
                });
            }
        });
    }

    // 開啟快速重設密碼 Modal
    function openResetPasswordModal(adminId, username, displayName) {
        $('#hdnPwdAdminID').val(adminId);
        $('#lblResetUsername').text(displayName + ' (' + username + ')');
        $('#txtNewPassword').val('');
        gPwdModal.show();
    }

    // 提交重設密碼
    function submitResetPassword() {
        var adminId = parseInt($('#hdnPwdAdminID').val());
        var newPwd = $.trim($('#txtNewPassword').val());

        if (!newPwd) {
            Swal.fire('提醒', '請輸入新密碼！', 'warning');
            $('#txtNewPassword').focus();
            return;
        }

        $.ajax({
            type: "POST",
            url: "Admin_Management.aspx/ResetPassword",
            data: JSON.stringify({ adminId: adminId, newPassword: newPwd }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var r = res.d;
                if (r.Success) {
                    gPwdModal.hide();
                    Swal.fire('重設成功', r.Message, 'success');
                } else {
                    Swal.fire('失敗', r.Message, 'error');
                }
            }
        });
    }

    // 刪除人員帳號
    function deleteUser(adminId, displayName) {
        Swal.fire({
            title: '確定刪除【' + displayName + '】？',
            text: '刪除後該人員將無法登入系統。此操作無法復原，請確認是否繼續！',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#DC2626',
            confirmButtonText: '確定刪除',
            cancelButtonText: '取消'
        }).then(function (result) {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: "Admin_Management.aspx/DeleteUser",
                    data: JSON.stringify({ adminId: adminId }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        var r = res.d;
                        if (r.Success) {
                            Swal.fire('已刪除', r.Message, 'success');
                            loadUserOverview();
                        } else {
                            Swal.fire('無法刪除', r.Message, 'warning');
                        }
                    }
                });
            }
        });
    }

    // 清除篩選條件
    function clearFilters() {
        $('#txtKeyword').val('');
        $('#selRoleFilter').val('ALL');
        $('#selStatusFilter').val('ALL');
        loadUserOverview();
    }

    // 密碼顯示/隱藏切換
    function togglePasswordVisibility(inputId, btn) {
        var $input = $('#' + inputId);
        var $icon = $(btn).find('i');
        if ($input.attr('type') === 'password') {
            $input.attr('type', 'text');
            $icon.removeClass('bi-eye').addClass('bi-eye-slash');
        } else {
            $input.attr('type', 'password');
            $icon.removeClass('bi-eye-slash').addClass('bi-eye');
        }
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
</script>
</asp:Content>
