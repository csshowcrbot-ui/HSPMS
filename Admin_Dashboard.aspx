<%@ Page Title="管理者戰情看板" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Admin_Dashboard.aspx.cs" Inherits="HospitalParking.Admin_Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .zone-progress-item {
            padding: 0.75rem;
            border-radius: 8px;
            background: #F9FAFB;
            margin-bottom: 0.75rem;
            border-left: 4px solid var(--hsp-primary);
            cursor: pointer;
            transition: all 0.2s ease-in-out;
        }
        .zone-progress-item:hover {
            background: #EFF6FF;
            box-shadow: 0 4px 10px rgba(26, 86, 219, 0.12);
            transform: translateY(-2px);
        }
        .zone-progress-item.warning {
            border-left-color: var(--hsp-danger);
            background: #FFF5F5;
        }
        .zone-progress-item.warning:hover {
            background: #FEE2E2;
        }
        .inspection-stat-row {
            cursor: pointer;
            padding: 0.5rem 0.6rem;
            border-radius: 6px;
            transition: all 0.2s ease-in-out;
        }
        .inspection-stat-row:hover {
            background: #F3F4F6;
            transform: translateX(4px);
        }
        .kpi-card.interactive {
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .kpi-card.interactive:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.08);
        }
        .chart-hint-badge {
            font-size: 0.75rem;
            background: #EEF2FF;
            color: #1A56DB;
            border: 1px solid #C7D2FE;
            border-radius: 20px;
            padding: 0.25rem 0.6rem;
            font-weight: 500;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container-fluid px-3 px-lg-4">
    <!-- 頂部標題與分區快選工具列 -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center py-2 mb-3 border-bottom gap-2">
        <div>
            <h4 class="mb-1 fw-bold text-dark">
                <i class="bi bi-speedometer2 text-primary me-2"></i>總覽戰情看板 (Executive Dashboard)
            </h4>
            <p class="text-muted small mb-0">全院 3 大停車區域、各科室車位配額、審核流程與即時巡檢態勢監控。點擊各圖表或卡片可直接檢視細項名單。</p>
        </div>
        <div class="d-flex align-items-center gap-2">
            <div class="input-group input-group-sm" style="width: 220px;">
                <span class="input-group-text bg-white text-muted"><i class="bi bi-funnel"></i></span>
                <select id="ddlZoneFilter" class="form-select fw-semibold" onchange="loadDashboard();">
                    <%= RenderZoneFilterOptions() %>
                </select>
            </div>
            <button type="button" class="btn btn-sm btn-outline-primary" onclick="loadDashboard();" title="重新整理">
                <i class="bi bi-arrow-clockwise me-1"></i>刷新
            </button>
            <span class="badge bg-light text-muted border small d-none d-sm-inline-block py-2 px-2" id="lblLastUpdate">
                更新於: --:--:--
            </span>
        </div>
    </div>

    <!-- 關鍵指標卡片區 (KPI 4 Blocks) -->
    <div class="row g-3 mb-4">
        <!-- 1. 有效停車證總數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-blue interactive" onclick="openZoneDrilldown(0, '全院所有停車區域');" title="點擊檢視全院有效車證細項名單">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">有效停車證總數 (Active)</div>
                        <div class="kpi-value" id="kpiValidPermits">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-shield-check"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-success me-1"><i class="bi bi-check-circle-fill"></i></span>
                        <span>全院通行證授權在案</span>
                    </div>
                    <span class="badge bg-white text-primary border"><i class="bi bi-search me-1"></i>看細項</span>
                </div>
            </div>
        </div>

        <!-- 2. 待審核申請單 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-amber interactive" onclick="scrollToPendingApps();" title="點擊平滑捲動至待審核申請清單">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">待審核員工申請 (Pending)</div>
                        <div class="kpi-value" id="kpiPendingApps">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-hourglass-split"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-warning me-1"><i class="bi bi-exclamation-circle-fill"></i></span>
                        <span>需總務管理單位審核</span>
                    </div>
                    <span class="badge bg-white text-warning border"><i class="bi bi-arrow-down-short me-1"></i>看清單</span>
                </div>
            </div>
        </div>

        <!-- 3. 30日內即將到期 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-rose interactive" onclick="openExpiringDrilldown();" title="點擊檢視 30 日內即將屆期車籍名單">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">30日內即將屆期 (Expiring)</div>
                        <div class="kpi-value" id="kpiExpiringSoon">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-calendar-event"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-danger me-1"><i class="bi bi-clock-history"></i></span>
                        <span>可通知同仁線上申辦展期</span>
                    </div>
                    <span class="badge bg-white text-danger border"><i class="bi bi-search me-1"></i>看名單</span>
                </div>
            </div>
        </div>

        <!-- 4. 今日現場巡檢次數 -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="kpi-card kpi-teal interactive" onclick="openInspectionDrilldown('ALL', '全部現場巡檢查核');" title="點擊檢視巡檢查核稽核日誌">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="kpi-label">今日現場巡檢次數 (Inspections)</div>
                        <div class="kpi-value" id="kpiTodayInspections">--</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="bi bi-qr-code-scan"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-success me-1"><i class="bi bi-camera-fill"></i></span>
                        <span>警衛行動查核即時累計</span>
                    </div>
                    <span class="badge bg-white text-success border"><i class="bi bi-search me-1"></i>看日誌</span>
                </div>
            </div>
        </div>
    </div>

    <!-- 圖表分析區 (Charts Grid) -->
    <div class="row g-3 mb-4">
        <!-- 區域容量飽和度 (Doughnut & Progress) -->
        <div class="col-12 col-lg-5">
            <div class="hsp-card h-100">
                <div class="hsp-card-header d-flex justify-content-between align-items-center">
                    <span class="fw-bold"><i class="bi bi-pie-chart-fill text-primary me-2"></i>各停車區域容量飽和度</span>
                    <span class="chart-hint-badge" onclick="openZoneDrilldown(0, '全院所有停車區域');" role="button" title="點擊檢視全院各區域車籍明細">
                        <i class="bi bi-cursor-fill me-1"></i>點擊圖表看細項
                    </span>
                </div>
                <div class="card-body p-3">
                    <div style="height: 200px; position: relative;" class="mb-3" title="點擊圖表扇區可查看細項">
                        <canvas id="chartZoneCapacity"></canvas>
                    </div>
                    <div id="zoneProgressContainer">
                        <!-- 動態進度條 -->
                    </div>
                </div>
            </div>
        </div>

        <!-- 部門車位佔用排行 (Bar Chart) -->
        <div class="col-12 col-lg-4">
            <div class="hsp-card h-100 d-flex flex-column justify-content-between">
                <div>
                    <div class="hsp-card-header d-flex justify-content-between align-items-center">
                        <span class="fw-bold"><i class="bi bi-bar-chart-fill text-primary me-2"></i>部門科室車位佔用排行</span>
                        <span class="chart-hint-badge" onclick="if(cachedDeptList&&cachedDeptList.length>0) openDeptDrilldown(cachedDeptList[0].DeptName);" role="button" title="點擊檢視第 1 名科室車籍明細">
                            <i class="bi bi-cursor-fill me-1"></i>點擊長條看細項
                        </span>
                    </div>
                    <div class="card-body p-3">
                        <div style="height: 240px; position: relative;" title="點擊部門柱狀條或下方科室標籤可查看細項">
                            <canvas id="chartDeptOccupancy"></canvas>
                        </div>
                        <div class="mt-2 pt-2 border-top">
                            <small class="text-muted d-block mb-1"><i class="bi bi-hand-index-thumb me-1"></i>快捷科室明細：</small>
                            <div id="deptQuickPills" class="d-flex flex-wrap gap-1">
                                <!-- 動態生成各科室快捷標籤 -->
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 巡檢稽核違規分類 (Pie Chart) -->
        <div class="col-12 col-lg-3">
            <div class="hsp-card h-100">
                <div class="hsp-card-header d-flex justify-content-between align-items-center">
                    <span class="fw-bold"><i class="bi bi-shield-exclamation text-primary me-2"></i>巡檢查驗態勢分佈</span>
                    <span class="chart-hint-badge" onclick="openInspectionDrilldown('ALL', '全部現場巡檢查核');" role="button" title="點擊檢視全部現場巡檢日誌明細">
                        <i class="bi bi-cursor-fill me-1"></i>點擊圓餅看細項
                    </span>
                </div>
                <div class="card-body p-3 d-flex flex-column justify-content-between">
                    <div style="height: 200px; position: relative;" class="mb-2" title="點擊圖表扇區或下方列表可查看稽核日誌">
                        <canvas id="chartInspectionStats"></canvas>
                    </div>
                    <div id="inspectionStatBadges" class="d-flex flex-column gap-2 small">
                        <!-- 統計徽章 -->
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 最新待辦審核清單 (Applications Table) -->
    <div class="hsp-card mb-4">
        <div class="hsp-card-header d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
            <div class="d-flex align-items-center">
                <span class="h6 mb-0 fw-bold"><i class="bi bi-inbox-fill text-primary me-2"></i>員工停車證申請審核與案件管理</span>
                <span class="badge bg-danger ms-2" id="badgePendingCount">0</span>
            </div>
            
            <!-- 狀態篩選標籤頁按鈕 -->
            <div class="d-flex flex-wrap align-items-center gap-2">
                <div class="btn-group btn-group-sm" role="group" id="btnGroupAppFilter">
                    <button type="button" class="btn btn-outline-primary active" onclick="filterAppStatus('ACTIVE', this);">全部待辦</button>
                    <button type="button" class="btn btn-outline-primary" onclick="filterAppStatus('PENDING', this);">待審核</button>
                    <button type="button" class="btn btn-outline-primary" onclick="filterAppStatus('PROCESSING', this);">已收案</button>
                    <button type="button" class="btn btn-outline-primary" onclick="filterAppStatus('WAITLIST', this);">待排序</button>
                    <button type="button" class="btn btn-outline-primary" onclick="filterAppStatus('APPROVED', this);">待領證</button>
                    <button type="button" class="btn btn-outline-secondary" onclick="filterAppStatus('COMPLETED', this);">已發證</button>
                    <button type="button" class="btn btn-outline-danger" onclick="filterAppStatus('REJECTED', this);">已駁回</button>
                </div>
                <div class="input-group input-group-sm" style="max-width: 220px;">
                    <input type="text" id="txtAppKeyword" class="form-control" placeholder="關鍵字 (車牌/姓名/單號)..." onkeydown="if(event.key==='Enter') searchApps();" />
                    <button class="btn btn-outline-secondary" type="button" onclick="searchApps();"><i class="bi bi-search"></i></button>
                </div>
            </div>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table hsp-table align-middle mb-0" id="tblRecentApplications">
                    <thead>
                        <tr>
                            <th>申請單號</th>
                            <th>工號</th>
                            <th>姓名</th>
                            <th>科室</th>
                            <th>車牌號碼</th>
                            <th>車輛廠牌/顏色</th>
                            <th>志願停放區</th>
                            <th>申請時間</th>
                            <th class="text-center">當前狀態</th>
                            <th class="text-center">審核作業</th>
                        </tr>
                    </thead>
                    <tbody id="tbodyPendingApps">
                        <tr>
                            <td colspan="10" class="text-center py-4 text-muted">
                                <span class="spinner-border spinner-border-sm me-2"></span>載入審核案件中...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- 快速審核彈窗 (Review Modal) -->
<div class="modal fade" id="modalReview" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header bg-primary text-white py-3">
                <div class="d-flex align-items-center">
                    <i class="bi bi-patch-check-fill fs-5 me-2"></i>
                    <div>
                        <h5 class="modal-title fw-bold mb-0 text-white">員工停車證申請審核與狀態作業</h5>
                        <small class="text-white-50">支援駁回申請、收案、待排序、待領證與發證作業</small>
                    </div>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <input type="hidden" id="hidReviewAppId" />
                <input type="hidden" id="hidCurrentAppStatus" />

                <!-- 申請單基本資料卡片 -->
                <div class="alert alert-light border shadow-sm mb-3">
                    <div class="row g-2">
                        <div class="col-sm-6"><strong>單號：</strong><span id="revAppNo" class="font-monospace fw-bold text-primary">--</span></div>
                        <div class="col-sm-6"><strong>工號：</strong><span id="revEmpNo" class="font-monospace">--</span></div>
                        <div class="col-sm-6"><strong>申請人：</strong><span id="revApplicantName" class="fw-bold">--</span></div>
                        <div class="col-sm-6"><strong>部門：</strong><span id="revDeptName">--</span></div>
                        <div class="col-sm-6"><strong>車牌：</strong><span class="license-plate-badge" id="revPlate">--</span></div>
                        <div class="col-sm-6"><strong>車型：</strong><span id="revVehicle">--</span></div>
                        <div class="col-sm-6"><strong>志願區域：</strong><span class="badge bg-info text-dark" id="revZone">--</span></div>
                        <div class="col-sm-6"><strong>當前狀態：</strong><span id="revCurrentStatusBadge">--</span></div>
                    </div>
                    <div id="revPriorRemarksRow" class="mt-2 pt-2 border-top small text-muted d-none">
                        <i class="bi bi-clock-history me-1"></i><strong>前次處理紀錄：</strong><span id="revPriorRemarks">--</span>
                    </div>
                </div>

                <!-- 5 大審核作業方式選擇器 (Reject, Accept, Waitlist, Ready, Issue) -->
                <div class="card border mb-3">
                    <div class="card-header bg-white py-2 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-dark small"><i class="bi bi-sliders text-primary me-1"></i>請選擇審核作業方式：</span>
                        <span class="badge bg-light text-secondary border font-monospace" id="lblTargetAction">目前選定：收案受理</span>
                    </div>
                    <div class="card-body p-3">
                        <div class="btn-group w-100 mb-3" role="group" aria-label="審核作業選項">
                            <button type="button" class="btn btn-outline-danger btn-action-tab fw-bold py-2" id="btnTabReject" onclick="switchReviewAction('REJECT');" title="不予核准並載明駁回原因">
                                <i class="bi bi-x-circle d-block mb-1 fs-5"></i>駁回申請
                            </button>
                            <button type="button" class="btn btn-outline-primary btn-action-tab fw-bold py-2 active" id="btnTabAccept" onclick="switchReviewAction('ACCEPT');" title="正式收件立案審查">
                                <i class="bi bi-inbox-fill d-block mb-1 fs-5"></i>收案
                            </button>
                            <button type="button" class="btn btn-outline-warning btn-action-tab fw-bold py-2 text-dark" id="btnTabWaitlist" onclick="switchReviewAction('WAITLIST');" title="配額額滿時列入候補排序">
                                <i class="bi bi-clock-history d-block mb-1 fs-5"></i>待排序
                            </button>
                            <button type="button" class="btn btn-outline-info btn-action-tab fw-bold py-2" id="btnTabReady" onclick="switchReviewAction('READY');" title="審核通過，通知同仁領卡">
                                <i class="bi bi-card-checklist d-block mb-1 fs-5"></i>待領證
                            </button>
                            <button type="button" class="btn btn-outline-success btn-action-tab fw-bold py-2" id="btnTabIssue" onclick="switchReviewAction('ISSUE');" title="臨櫃交付感應卡並建立車籍生效">
                                <i class="bi bi-credit-card-2-front-fill d-block mb-1 fs-5"></i>發證
                            </button>
                        </div>

                        <!-- 1. 駁回申請面板 -->
                        <div id="panelReject" class="action-panel d-none">
                            <div class="alert alert-danger py-2 px-3 small mb-2">
                                <i class="bi bi-exclamation-triangle-fill me-1"></i><strong>【駁回申請】</strong>：案件審查未通過，將更新狀態為「已駁回」，系統將通知申請同仁補正或重新申辦。
                            </div>
                            <div class="mb-2">
                                <label class="form-label font-weight-bold text-danger small">駁回原因說明 (必填)：</label>
                                <textarea id="txtRejectReason" class="form-control form-control-sm" rows="3" placeholder="例: 該科室車位配額已額滿，或上傳行照非本人所有且未檢附直系親屬證明..."></textarea>
                            </div>
                        </div>

                        <!-- 2. 收案面板 -->
                        <div id="panelAccept" class="action-panel">
                            <div class="alert alert-primary py-2 px-3 small mb-2">
                                <i class="bi bi-info-circle-fill me-1"></i><strong>【收案受理】</strong>：確認同仁車籍與初審資格符合，正式立案審理中（狀態流轉為「已收案」）。
                            </div>
                            <div class="mb-2">
                                <label class="form-label font-weight-bold small">收案審理備註 (選填)：</label>
                                <input type="text" id="txtAcceptRemarks" class="form-control form-control-sm" placeholder="例: 初審資料無誤，進行科室配額比對中" value="已受理收案，資料查驗審核中" />
                            </div>
                        </div>

                        <!-- 3. 待排序面板 -->
                        <div id="panelWaitlist" class="action-panel d-none">
                            <div class="alert alert-warning py-2 px-3 small mb-2">
                                <i class="bi bi-hourglass-split me-1"></i><strong>【待排序】</strong>：志願停車區域或科室配額暫時額滿，將案件列入輪候候補名冊，等候釋出。
                            </div>
                            <div class="mb-2">
                                <label class="form-label font-weight-bold small">待排序 / 輪候備註 (選填)：</label>
                                <input type="text" id="txtWaitlistRemarks" class="form-control form-control-sm" placeholder="例: 露天B區已額滿，列入候補第 2 順位" value="目前配額額滿，已列入排序輪候名單" />
                            </div>
                        </div>

                        <!-- 4. 待領證面板 -->
                        <div id="panelReady" class="action-panel d-none">
                            <div class="alert alert-info py-2 px-3 small mb-2">
                                <i class="bi bi-bell-fill me-1"></i><strong>【待領證】</strong>：審核通過！已為同仁保留車位額度，標記為「待領證」，通知攜帶識別證至總務處領取 RFID 感應卡與鐵捲門遙控器。
                            </div>
                            <div class="mb-2">
                                <label class="form-label font-weight-bold small">領證通知備註 (選填)：</label>
                                <input type="text" id="txtReadyRemarks" class="form-control form-control-sm" placeholder="例: 審核通過，請於本週五前至總務處領取卡片" value="審核通過，請攜帶識別證至總務處領取感應卡與遙控器" />
                            </div>
                        </div>

                        <!-- 5. 發證面板 -->
                        <div id="panelIssue" class="action-panel d-none">
                            <div class="alert alert-success py-2 px-3 small mb-2">
                                <i class="bi bi-check-circle-fill me-1"></i><strong>【發證結案】</strong>：同仁已至總務處臨櫃領證，填入實體 RFID 感應卡號與遙控器序號，正式寫入車籍通行證主檔並啟用！
                            </div>
                            <div class="row g-2">
                                <div class="col-12">
                                    <div class="p-2 bg-light border border-success-subtle rounded mb-1">
                                        <div class="d-flex justify-content-between align-items-center mb-1">
                                            <label class="form-label small fw-bold text-success mb-0">
                                                <i class="bi bi-geo-alt-fill text-danger me-1"></i>實際停放區域 (管理者可調整)：
                                            </label>
                                            <small class="text-muted" style="font-size:0.75rem;">
                                                <i class="bi bi-info-circle me-1"></i>依院區現況配置安排為主，預設帶入同仁原志願
                                            </small>
                                        </div>
                                        <select id="selIssueZone" class="form-select form-select-sm fw-bold border-success">
                                        </select>
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <label class="form-label small fw-bold">RFID 感應卡號 (Sensor Tag) <span class="text-danger">*</span>：</label>
                                    <div class="input-group input-group-sm">
                                        <span class="input-group-text"><i class="bi bi-upc-scan"></i></span>
                                        <input type="text" id="txtIssueTag" class="form-control" placeholder="例: TAG-80123" />
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <label class="form-label small fw-bold">鐵捲門遙控器號 (選填)：</label>
                                    <div class="input-group input-group-sm">
                                        <span class="input-group-text"><i class="bi bi-controller"></i></span>
                                        <input type="text" id="txtIssueRemote" class="form-control" placeholder="例: RC-80123" />
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <label class="form-label small fw-bold">通行證有效迄日：</label>
                                    <input type="date" id="txtIssueExpireDate" class="form-control form-control-sm" />
                                </div>
                                <div class="col-sm-6">
                                    <label class="form-label small fw-bold">發證結案備註：</label>
                                    <input type="text" id="txtIssueRemarks" class="form-control form-control-sm" value="同仁已完成臨櫃領證並啟用通行證" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer bg-light d-flex justify-content-between">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                    <i class="bi bi-x me-1"></i>取消關閉
                </button>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-primary px-4 fw-bold shadow-sm" id="btnExecuteReviewAction" onclick="submitExecuteAction();">
                        <i class="bi bi-inbox-fill me-1" id="iconExecuteAction"></i>
                        <span id="textExecuteAction">確認收案受理</span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 圖表細項內容下鑽視窗 (Chart Drilldown Modal) -->
<div class="modal fade" id="modalChartDrilldown" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header bg-primary text-white py-3" id="drilldownHeader">
                <div class="d-flex align-items-center">
                    <div class="rounded-circle bg-white text-primary p-2 me-3 d-flex align-items-center justify-content-center shadow-sm" style="width: 42px; height: 42px;">
                        <i class="bi bi-diagram-3-fill fs-5" id="drilldownIcon"></i>
                    </div>
                    <div>
                        <h5 class="modal-title fw-bold mb-0 text-white" id="drilldownTitle">明細內容檢視</h5>
                        <small class="text-white-50" id="drilldownSubtitle">點選圖表項目即時下鑽分析</small>
                    </div>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4 bg-light">
                <!-- 頂部即時統計指標條 (動態生成) -->
                <div class="row g-3 mb-3" id="drilldownMetricsRow">
                </div>

                <!-- 搜尋過濾工具列 -->
                <div class="card border-0 shadow-sm mb-3">
                    <div class="card-body p-3 d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-2">
                        <div class="input-group input-group-sm" style="max-width: 420px;">
                            <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                            <input type="text" id="txtDrilldownSearch" class="form-control" placeholder="輸入關鍵字 (車牌/姓名/工號/科室/說明) 即時篩選..." oninput="filterDrilldownTable();">
                            <button type="button" class="btn btn-outline-secondary" onclick="$('#txtDrilldownSearch').val(''); filterDrilldownTable();" title="清除搜尋">
                                <i class="bi bi-x-lg"></i>
                            </button>
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            <span class="badge bg-primary-subtle text-primary border border-primary-subtle py-2 px-3 fw-bold" id="drilldownRecordCount">
                                共 0 筆明細
                            </span>
                            <a href="Permit_Management.aspx" class="btn btn-sm btn-outline-primary" target="_blank" title="前往車籍維護主檔完整管理">
                                <i class="bi bi-box-arrow-up-right me-1"></i>前往車籍維護主檔
                            </a>
                        </div>
                    </div>
                </div>

                <!-- 載入中 Spinner -->
                <div id="drilldownLoading" class="text-center py-5 bg-white rounded shadow-sm">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="visually-hidden">載入中...</span>
                    </div>
                    <div class="text-muted mt-2 fw-semibold">正在撈取細項資料，請稍候...</div>
                </div>

                <!-- 資料展示表格 (車籍通行證模式) -->
                <div class="card border-0 shadow-sm d-none" id="drilldownPermitTableWrapper">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tblDrilldownPermits">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 140px;">通行證號</th>
                                    <th style="width: 130px;">車牌號碼</th>
                                    <th style="width: 120px;">車主姓名</th>
                                    <th>科室部門</th>
                                    <th>核准停放區域</th>
                                    <th>車輛廠牌 / 車色</th>
                                    <th>感應卡號 / RFID</th>
                                    <th style="width: 130px;">有效期限</th>
                                    <th style="width: 90px;" class="text-center">狀態</th>
                                </tr>
                            </thead>
                            <tbody id="tbodyDrilldownPermits">
                                <!-- 動態生成 -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- 資料展示表格 (巡檢查驗日誌模式) -->
                <div class="card border-0 shadow-sm d-none" id="drilldownInspectionTableWrapper">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tblDrilldownInspections">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 150px;">查核時間</th>
                                    <th style="width: 120px;">巡檢地點</th>
                                    <th style="width: 130px;">查核車牌</th>
                                    <th style="width: 120px;">登記車主</th>
                                    <th>所屬部門</th>
                                    <th>核准區域</th>
                                    <th style="width: 120px;" class="text-center">查驗態勢</th>
                                    <th style="width: 100px;">巡檢員</th>
                                    <th>查核判定與處置說明</th>
                                </tr>
                            </thead>
                            <tbody id="tbodyDrilldownInspections">
                                <!-- 動態生成 -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- 無資料提示區 -->
                <div id="drilldownEmptyState" class="text-center py-5 bg-white rounded shadow-sm d-none">
                    <i class="bi bi-inbox text-muted" style="font-size: 3.5rem;"></i>
                    <div class="text-muted fw-bold mt-2 fs-6" id="drilldownEmptyText">暫無相關明細資料</div>
                </div>
            </div>
            <div class="modal-footer bg-light py-2">
                <button type="button" class="btn btn-secondary btn-sm px-3" data-bs-dismiss="modal">
                    <i class="bi bi-x-circle me-1"></i>關閉
                </button>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script>
    var zoneCapacityChart = null;
    var deptChart = null;
    var inspectionChart = null;
    var pendingAppsList = [];

    // 圖表下鑽相關全域快取狀態
    var currentDrilldownMode = ''; // 'PERMIT' 或 'INSPECTION'
    var currentDrilldownRawList = []; // 原始列表供即時過濾
    var cachedZoneList = [];
    var cachedDeptList = [];
    var cachedStatList = [];

    $(document).ready(function () {
        loadDashboard();
        // 每 30 秒自動靜默更新看板
        setInterval(function() {
            loadDashboard(true);
        }, 30000);
    });

    function loadDashboard(silent) {
        var zoneFilterVal = $('#ddlZoneFilter').val();
        var zoneParam = zoneFilterVal ? parseInt(zoneFilterVal) : null;

        if (!silent) {
            $('#kpiValidPermits, #kpiPendingApps, #kpiExpiringSoon, #kpiTodayInspections').html('<span class="spinner-border spinner-border-sm"></span>');
        }

        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetDashboardData",
            data: JSON.stringify({ zoneFilter: zoneParam }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                renderKpis(d);
                renderZoneCapacities(d.ZoneCapacities);
                renderDeptChart(d.DeptOccupancies);
                renderInspectionChart(d.InspectionStats);
                renderPendingApplications(d.RecentApplications);
                
                var now = new Date();
                $('#lblLastUpdate').text('更新於: ' + now.toLocaleTimeString());
            },
            error: function () {
                if (!silent) Swal.fire('錯誤', '無法載入看板數據，請確認資料庫服務運作正常。', 'error');
            }
        });
    }

    function renderKpis(d) {
        $('#kpiValidPermits').text(d.ValidPermitCount.toLocaleString());
        $('#kpiPendingApps').text(d.PendingAppCount.toLocaleString());
        $('#kpiExpiringSoon').text(d.ExpiringSoonCount.toLocaleString());
        $('#kpiTodayInspections').text(d.TodayInspectionCount.toLocaleString());
        $('#badgePendingCount').text(d.PendingAppCount);
    }

    function renderZoneCapacities(zones) {
        cachedZoneList = zones || [];
        var labels = [];
        var dataOccupied = [];
        var bgColors = [];
        var progressHtml = '';

        // 動態同步分區快選下拉選單
        var currentFilterVal = $('#ddlZoneFilter').val();
        var filterOpts = '<option value="">全部停車區域 (總覽)</option>';
        cachedZoneList.forEach(z => {
            filterOpts += `<option value="${z.ZoneID}">${z.ZoneName}</option>`;
        });
        $('#ddlZoneFilter').html(filterOpts);
        if (currentFilterVal) {
            $('#ddlZoneFilter').val(currentFilterVal);
        }

        cachedZoneList.forEach((z, idx) => {
            labels.push(z.ZoneName);
            dataOccupied.push(z.OccupiedCount);
            
            var isWarn = z.IsWarning;
            var barColor = isWarn ? 'bg-danger' : (z.OccupancyPct > 70 ? 'bg-warning' : 'bg-primary');
            bgColors.push(isWarn ? '#F05252' : (z.OccupancyPct > 70 ? '#E3A008' : '#1A56DB'));

            progressHtml += `
                <div class="zone-progress-item ${isWarn ? 'warning' : ''}" onclick="openZoneDrilldown(${z.ZoneID}, '${escapeHtml(z.ZoneName)}');" title="點擊檢視 ${escapeHtml(z.ZoneName)} 車籍細項">
                    <div class="d-flex justify-content-between align-items-center mb-1">
                        <span class="fw-bold small text-dark"><i class="bi bi-geo-alt-fill text-primary me-1"></i>${z.ZoneName}</span>
                        <span class="small ${isWarn ? 'text-danger fw-bold' : 'text-muted'}">
                            ${z.OccupiedCount} / ${z.TotalCapacity} 位 (${z.OccupancyPct}%)
                            ${isWarn ? ' <span class="badge bg-danger ms-1">飽和告警</span>' : ''}
                            <i class="bi bi-chevron-right text-muted ms-1"></i>
                        </span>
                    </div>
                    <div class="progress" style="height: 8px;">
                        <div class="progress-bar ${barColor}" style="width: ${Math.min(100, z.OccupancyPct)}%"></div>
                    </div>
                </div>`;
        });

        $('#zoneProgressContainer').html(progressHtml);

        var ctx = document.getElementById('chartZoneCapacity').getContext('2d');
        if (zoneCapacityChart) zoneCapacityChart.destroy();

        zoneCapacityChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{
                    data: dataOccupied,
                    backgroundColor: bgColors,
                    borderWidth: 2,
                    borderColor: '#FFFFFF'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } },
                    tooltip: {
                        callbacks: {
                            afterLabel: function() { return '👆 點選此扇區可查看車輛清單'; }
                        }
                    }
                },
                cutout: '65%',
                onHover: function(e, elements) {
                    e.native.target.style.cursor = elements && elements.length > 0 ? 'pointer' : 'default';
                },
                onClick: function(e, elements) {
                    var idx = -1;
                    if (elements && elements.length > 0) {
                        idx = elements[0].index;
                    } else if (zoneCapacityChart) {
                        var points = zoneCapacityChart.getElementsAtEventForMode(e, 'nearest', { intersect: false }, false);
                        if (points && points.length > 0) idx = points[0].index;
                    }
                    if (idx >= 0 && idx < cachedZoneList.length) {
                        var z = cachedZoneList[idx];
                        if (z) {
                            openZoneDrilldown(z.ZoneID, z.ZoneName);
                        }
                    }
                }
            }
        });
    }

    function renderDeptChart(deptList) {
        cachedDeptList = deptList || [];
        var labels = cachedDeptList.map(d => d.DeptName);
        var counts = cachedDeptList.map(d => d.PermitCount);

        // 動態生成科室快捷按鈕
        var pillsHtml = '';
        cachedDeptList.forEach(d => {
            pillsHtml += `<button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" style="font-size: 0.75rem;" onclick="openDeptDrilldown('${escapeHtml(d.DeptName)}');" title="點擊檢視 ${escapeHtml(d.DeptName)} 車位明細"><i class="bi bi-tag-fill me-1"></i>${escapeHtml(d.DeptName)} (${d.PermitCount})</button>`;
        });
        $('#deptQuickPills').html(pillsHtml);

        var ctx = document.getElementById('chartDeptOccupancy').getContext('2d');
        if (deptChart) deptChart.destroy();

        deptChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: '有效車位數',
                    data: counts,
                    backgroundColor: '#1A56DB',
                    hoverBackgroundColor: '#1E40AF',
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: 'y',
                scales: {
                    x: { beginAtZero: true, grid: { color: '#F3F4F6' } },
                    y: { grid: { display: false }, ticks: { font: { size: 11 } } }
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            afterLabel: function() { return '👆 點選此長條可查看該科室車籍明細'; }
                        }
                    }
                },
                onHover: function(e, elements) {
                    e.native.target.style.cursor = elements && elements.length > 0 ? 'pointer' : 'default';
                },
                onClick: function(e, elements) {
                    var idx = -1;
                    if (elements && elements.length > 0) {
                        idx = elements[0].index;
                    } else if (deptChart) {
                        var points = deptChart.getElementsAtEventForMode(e, 'index', { axis: 'y', intersect: false }, false);
                        if (points && points.length > 0) idx = points[0].index;
                    }
                    if (idx >= 0 && idx < cachedDeptList.length) {
                        var dept = cachedDeptList[idx];
                        if (dept) {
                            openDeptDrilldown(dept.DeptName);
                        }
                    }
                }
            }
        });
    }

    function renderInspectionChart(statList) {
        cachedStatList = statList || [];
        var labels = cachedStatList.map(s => s.StatusLabel);
        var data = cachedStatList.map(s => s.Count);
        var colors = cachedStatList.map(s => s.ColorHex);

        var ctx = document.getElementById('chartInspectionStats').getContext('2d');
        if (inspectionChart) inspectionChart.destroy();

        inspectionChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{
                    data: data,
                    backgroundColor: colors,
                    borderWidth: 2,
                    borderColor: '#FFFFFF'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            afterLabel: function() { return '👆 點選此態勢可查看查驗日誌明細'; }
                        }
                    }
                },
                cutout: '60%',
                onHover: function(e, elements) {
                    e.native.target.style.cursor = elements && elements.length > 0 ? 'pointer' : 'default';
                },
                onClick: function(e, elements) {
                    var idx = -1;
                    if (elements && elements.length > 0) {
                        idx = elements[0].index;
                    } else if (inspectionChart) {
                        var points = inspectionChart.getElementsAtEventForMode(e, 'nearest', { intersect: false }, false);
                        if (points && points.length > 0) idx = points[0].index;
                    }
                    if (idx >= 0 && idx < cachedStatList.length) {
                        var s = cachedStatList[idx];
                        if (s) {
                            openInspectionDrilldown(s.Status, s.StatusLabel);
                        }
                    }
                }
            }
        });

        var badgeHtml = '';
        cachedStatList.forEach(s => {
            badgeHtml += `
                <div class="inspection-stat-row d-flex justify-content-between align-items-center py-2 border-bottom" onclick="openInspectionDrilldown('${s.Status}', '${escapeHtml(s.StatusLabel)}');" title="點擊檢視【${escapeHtml(s.StatusLabel)}】巡檢日誌">
                    <span><span class="d-inline-block rounded-circle me-2" style="width:10px;height:10px;background-color:${s.ColorHex};"></span><strong class="text-dark">${s.StatusLabel}</strong></span>
                    <span class="badge bg-light text-dark border font-monospace px-2 py-1">${s.Count} 件 <i class="bi bi-chevron-right text-muted ms-1"></i></span>
                </div>`;
        });
        $('#inspectionStatBadges').html(badgeHtml);
    }

    var currentAppFilter = 'ACTIVE';

    function getStatusBadgeHtml(status) {
        switch (status) {
            case 'PENDING':
                return '<span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i>待審核</span>';
            case 'PROCESSING':
                return '<span class="badge bg-primary"><i class="bi bi-inbox-fill me-1"></i>已收案</span>';
            case 'WAITLIST':
                return '<span class="badge bg-secondary"><i class="bi bi-clock-history me-1"></i>待排序</span>';
            case 'APPROVED':
                return '<span class="badge bg-info text-dark"><i class="bi bi-card-checklist me-1"></i>待領證</span>';
            case 'COMPLETED':
                return '<span class="badge bg-success"><i class="bi bi-check2-circle me-1"></i>已發證</span>';
            case 'REJECTED':
                return '<span class="badge bg-danger"><i class="bi bi-x-circle me-1"></i>已駁回</span>';
            default:
                return `<span class="badge bg-light text-dark border">${status || '--'}</span>`;
        }
    }

    function renderPendingApplications(apps) {
        pendingAppsList = apps || [];
        var html = '';
        if (pendingAppsList.length === 0) {
            html = '<tr><td colspan="10" class="text-center py-4 text-muted"><i class="bi bi-emoji-smile text-success me-1"></i>目前暫無符合條件之申請單！</td></tr>';
        } else {
            pendingAppsList.forEach((a, idx) => {
                var badge = getStatusBadgeHtml(a.ReviewStatus);
                var zoneDisplay = '';
                if (a.AssignedZoneName && a.AssignedZoneID && a.AssignedZoneID !== a.PreferredZoneID) {
                    zoneDisplay = `<span class="badge bg-primary text-white" title="管理者依現況調整">${a.AssignedZoneName}</span><br><small class="text-muted" style="font-size:0.75rem;">(原志願: ${a.PreferredZoneName})</small>`;
                } else {
                    zoneDisplay = `<span class="badge bg-info text-dark">${a.PreferredZoneName}</span>`;
                }
                html += `
                    <tr>
                        <td><strong class="text-primary font-monospace">${a.ApplicationNo}</strong></td>
                        <td><span class="badge bg-secondary font-monospace">${a.EmpNo}</span></td>
                        <td><strong>${a.ApplicantName}</strong></td>
                        <td>${a.DeptName}</td>
                        <td><span class="license-plate-badge">${a.LicensePlate}</span></td>
                        <td>${a.VehicleBrand} / ${a.VehicleColor}</td>
                        <td>${zoneDisplay}</td>
                        <td><small class="text-muted">${a.ApplyDate}</small></td>
                        <td class="text-center">${badge}</td>
                        <td class="text-center">
                            <button type="button" class="btn btn-outline-primary btn-sm px-2 py-1 shadow-sm" onclick="openReviewModal(${idx});" title="開啟審核流程作業彈窗">
                                <i class="bi bi-pencil-square me-1"></i>審核/處理
                            </button>
                        </td>
                    </tr>`;
            });
        }
        $('#tbodyPendingApps').html(html);
    }

    function filterAppStatus(status, btnEl) {
        currentAppFilter = status;
        $('#btnGroupAppFilter button').removeClass('active');
        if (btnEl) $(btnEl).addClass('active');

        var kw = $('#txtAppKeyword').val().trim();
        loadFilteredApps(status, kw);
    }

    function searchApps() {
        var kw = $('#txtAppKeyword').val().trim();
        loadFilteredApps(currentAppFilter, kw);
    }

    function loadFilteredApps(status, kw) {
        $('#tbodyPendingApps').html('<tr><td colspan="10" class="text-center py-3 text-muted"><span class="spinner-border spinner-border-sm me-2"></span>載入案件中...</td></tr>');
        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetFilteredApplications",
            data: JSON.stringify({ status: status, keyword: kw || "" }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                renderPendingApplications(res.d);
            },
            error: function () {
                $('#tbodyPendingApps').html('<tr><td colspan="10" class="text-center py-3 text-danger">載入案件失敗，請重試！</td></tr>');
            }
        });
    }

    // ==========================================
    // 圖表點選下鑽檢視 (Chart Drill-down Handlers)
    // ==========================================

    function resetDrilldownModal(iconClass, titleText, subtitleText) {
        $('#drilldownIcon').attr('class', 'fs-5 ' + iconClass);
        $('#drilldownTitle').text(titleText);
        $('#drilldownSubtitle').text(subtitleText);
        $('#drilldownMetricsRow').empty();
        $('#txtDrilldownSearch').val('');
        $('#drilldownRecordCount').text('共 0 筆明細');
        $('#drilldownLoading').removeClass('d-none');
        $('#drilldownPermitTableWrapper').addClass('d-none');
        $('#drilldownInspectionTableWrapper').addClass('d-none');
        $('#drilldownEmptyState').addClass('d-none');
        
        var modalEl = document.getElementById('modalChartDrilldown');
        var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
        modal.show();
    }

    // 1. 部門科室車位佔用細項
    function openDeptDrilldown(deptName) {
        if (!deptName) return;
        resetDrilldownModal('bi-building text-primary', `【${deptName}】車位佔用與通行證明細`, '科室車位配額管制、佔用比例與已核發車籍');

        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetDeptPermitsDetail",
            data: JSON.stringify({ deptName: deptName }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                $('#drilldownLoading').addClass('d-none');

                var isOver = d.OccupiedCount > d.QuotaLimit;
                var metricsHtml = `
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">科室名稱</div>
                            <div class="fw-bold fs-6 text-dark text-truncate">${d.DeptName}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">配額上限</div>
                            <div class="fw-bold fs-5 text-secondary">${d.QuotaLimit} 位</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">目前有效佔用</div>
                            <div class="fw-bold fs-5 ${isOver ? 'text-danger' : 'text-primary'}">${d.OccupiedCount} 位</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">配額佔用率</div>
                            <div class="fw-bold fs-5 ${isOver ? 'text-danger' : (d.OccupancyPct > 85 ? 'text-warning' : 'text-success')}">
                                ${d.OccupancyPct}%
                                ${isOver ? '<span class="badge bg-danger ms-1 small">超額</span>' : ''}
                            </div>
                        </div>
                    </div>`;
                $('#drilldownMetricsRow').html(metricsHtml);

                currentDrilldownMode = 'PERMIT';
                currentDrilldownRawList = d.Permits || [];
                renderDrilldownPermits(currentDrilldownRawList);
            },
            error: function () {
                $('#drilldownLoading').addClass('d-none');
                Swal.fire('載入失敗', '無法撈取部門車位明細，請稍後重試。', 'error');
            }
        });
    }

    // 2. 停車區域容量與車籍名單
    function openZoneDrilldown(zoneId, zoneName) {
        resetDrilldownModal('bi-p-square-fill text-primary', `【${zoneName}】場域停放名單與容量`, '停車場域即時容納飽和度與目前有效通行證清單');

        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetZonePermitsDetail",
            data: JSON.stringify({ zoneId: zoneId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                $('#drilldownLoading').addClass('d-none');

                var metricsHtml = `
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">場域名稱</div>
                            <div class="fw-bold fs-6 text-dark text-truncate">${d.ZoneName || zoneName}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">總車位容量</div>
                            <div class="fw-bold fs-5 text-secondary">${d.TotalCapacity} 位</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">有效停放數 / 空位</div>
                            <div class="fw-bold fs-5 text-primary">${d.OccupiedCount} <span class="text-muted fs-6">/ 剩 ${d.RemainingQuota}</span></div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">飽和度 (警戒: ${d.WarningThresholdPct}%)</div>
                            <div class="fw-bold fs-5 ${d.IsWarning ? 'text-danger' : 'text-success'}">
                                ${d.OccupancyPct}%
                                ${d.IsWarning ? '<span class="badge bg-danger ms-1 small">警戒</span>' : ''}
                            </div>
                        </div>
                    </div>`;
                $('#drilldownMetricsRow').html(metricsHtml);

                currentDrilldownMode = 'PERMIT';
                currentDrilldownRawList = d.Permits || [];
                renderDrilldownPermits(currentDrilldownRawList);
            },
            error: function () {
                $('#drilldownLoading').addClass('d-none');
                Swal.fire('載入失敗', '無法撈取場域車位明細，請稍後重試。', 'error');
            }
        });
    }

    // 3. 巡檢查核態勢稽核日誌
    function openInspectionDrilldown(status, statusLabel) {
        var zoneFilterVal = $('#ddlZoneFilter').val();
        var zoneParam = zoneFilterVal ? parseInt(zoneFilterVal) : null;

        resetDrilldownModal('bi-shield-check text-primary', `【${statusLabel}】現場巡查稽核日誌明細`, '警衛行動查核即時掃描紀錄與違規態勢清單');

        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetInspectionLogsDetail",
            data: JSON.stringify({ resultStatus: status, zoneFilter: zoneParam }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var d = res.d;
                $('#drilldownLoading').addClass('d-none');

                var metricsHtml = `
                    <div class="col-6 col-md-4">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">查核態勢類別</div>
                            <div class="fw-bold fs-6" style="color: ${d.ColorHex};">${d.StatusLabel}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-4">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">累計查核紀錄筆數</div>
                            <div class="fw-bold fs-5 text-dark">${d.TotalCount} 筆</div>
                        </div>
                    </div>
                    <div class="col-12 col-md-4">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">當前分區過濾</div>
                            <div class="fw-bold fs-6 text-primary">${zoneParam ? $('#ddlZoneFilter option:selected').text() : '全院所有區域'}</div>
                        </div>
                    </div>`;
                $('#drilldownMetricsRow').html(metricsHtml);

                currentDrilldownMode = 'INSPECTION';
                currentDrilldownRawList = d.Logs || [];
                renderDrilldownInspections(currentDrilldownRawList);
            },
            error: function () {
                $('#drilldownLoading').addClass('d-none');
                Swal.fire('載入失敗', '無法撈取巡檢查核日誌，請稍後重試。', 'error');
            }
        });
    }

    // 4. 30 日內即將屆期車籍名單
    function openExpiringDrilldown() {
        var zoneFilterVal = $('#ddlZoneFilter').val();
        var zoneParam = zoneFilterVal ? parseInt(zoneFilterVal) : null;

        resetDrilldownModal('bi-alarm-fill text-danger', '【30 日內即將屆期】車籍通行證明細', '掌握即將屆期同仁車證，可提早發送展期繳費提醒通知');

        $.ajax({
            type: "POST",
            url: "Admin_Dashboard.aspx/GetExpiringPermitsDetail",
            data: JSON.stringify({ zoneFilter: zoneParam }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var list = res.d || [];
                $('#drilldownLoading').addClass('d-none');

                var metricsHtml = `
                    <div class="col-12 col-md-6">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">30 日內即將屆期車輛總數</div>
                            <div class="fw-bold fs-4 text-danger">${list.length} 輛</div>
                        </div>
                    </div>
                    <div class="col-12 col-md-6">
                        <div class="bg-white p-3 rounded border text-center">
                            <div class="text-muted small">管理建議處置</div>
                            <div class="fw-bold fs-6 text-primary">可通知同仁線上申辦展期或批次展期作業</div>
                        </div>
                    </div>`;
                $('#drilldownMetricsRow').html(metricsHtml);

                currentDrilldownMode = 'PERMIT';
                currentDrilldownRawList = list;
                renderDrilldownPermits(currentDrilldownRawList);
            },
            error: function () {
                $('#drilldownLoading').addClass('d-none');
                Swal.fire('載入失敗', '無法撈取即將屆期車籍名單，請稍後重試。', 'error');
            }
        });
    }

    // 5. 滾動至待審核申請區塊
    function scrollToPendingApps() {
        $('html, body').animate({
            scrollTop: $('#tblRecentApplications').offset().top - 100
        }, 400);
    }

    // 渲染車籍通行證列表表格
    function renderDrilldownPermits(list) {
        $('#drilldownInspectionTableWrapper').addClass('d-none');
        $('#drilldownRecordCount').text(`共 ${list.length} 筆車證`);

        if (list.length === 0) {
            $('#drilldownPermitTableWrapper').addClass('d-none');
            $('#drilldownEmptyText').text('查無符合條件的車籍通行證明細！');
            $('#drilldownEmptyState').removeClass('d-none');
            return;
        }

        $('#drilldownEmptyState').addClass('d-none');
        $('#drilldownPermitTableWrapper').removeClass('d-none');

        var tbodyHtml = '';
        list.forEach(p => {
            var expBadge = p.IsExpiringSoon ? `<span class="badge bg-danger ms-1">剩 ${p.DaysRemaining} 天</span>` : '';
            var statusBadge = p.Status === 'ACTIVE' 
                ? '<span class="badge bg-success">有效通行</span>' 
                : '<span class="badge bg-secondary">停權</span>';

            tbodyHtml += `
                <tr>
                    <td><strong>${p.PermitNumber}</strong></td>
                    <td><span class="license-plate-badge">${p.LicensePlate}</span></td>
                    <td><strong>${p.OwnerName}</strong></td>
                    <td><span class="badge bg-light text-dark border">${p.DeptName}</span></td>
                    <td><span class="badge bg-info text-dark">${p.ZoneName}</span></td>
                    <td>${escapeHtml(p.VehicleBrand || '--')} / ${escapeHtml(p.VehicleColor || '--')}</td>
                    <td><small class="text-muted font-monospace">${escapeHtml(p.SensorTagNumber || p.CardNumber || '--')}</small></td>
                    <td><small class="font-monospace text-dark">${p.ExpireDate}</small>${expBadge}</td>
                    <td class="text-center">${statusBadge}</td>
                </tr>`;
        });

        $('#tbodyDrilldownPermits').html(tbodyHtml);
    }

    // 渲染巡檢查核日誌表格
    function renderDrilldownInspections(logs) {
        $('#drilldownPermitTableWrapper').addClass('d-none');
        $('#drilldownRecordCount').text(`共 ${logs.length} 筆日誌`);

        if (logs.length === 0) {
            $('#drilldownInspectionTableWrapper').addClass('d-none');
            $('#drilldownEmptyText').text('暫無符合條件之巡查稽核日誌紀錄！');
            $('#drilldownEmptyState').removeClass('d-none');
            return;
        }

        $('#drilldownEmptyState').addClass('d-none');
        $('#drilldownInspectionTableWrapper').removeClass('d-none');

        var tbodyHtml = '';
        logs.forEach(l => {
            var statusBadge = '';
            if (l.ResultStatus === 'VALID') {
                statusBadge = '<span class="badge bg-success">合格</span>';
            } else if (l.ResultStatus === 'WRONG_ZONE') {
                statusBadge = '<span class="badge bg-warning text-dark">跨區違規</span>';
            } else if (l.ResultStatus === 'EXPIRED') {
                statusBadge = '<span class="badge bg-danger">逾期停權</span>';
            } else {
                statusBadge = '<span class="badge bg-dark">未登記車輛</span>';
            }

            tbodyHtml += `
                <tr>
                    <td><small class="font-monospace text-muted">${l.InspectTime}</small></td>
                    <td><span class="badge bg-light text-dark border">${l.ZoneName}</span></td>
                    <td><span class="license-plate-badge">${l.PlateScanned}</span></td>
                    <td><strong>${l.OwnerName}</strong></td>
                    <td>${l.DeptName || '--'}</td>
                    <td>${l.PermittedZoneName || '--'}</td>
                    <td class="text-center">${statusBadge}</td>
                    <td><small class="badge bg-secondary font-monospace">${l.InspectorAccount}</small></td>
                    <td><small class="text-muted">${escapeHtml(l.Remark || '--')}</small></td>
                </tr>`;
        });

        $('#tbodyDrilldownInspections').html(tbodyHtml);
    }

    // 即時關鍵字搜尋篩選
    function filterDrilldownTable() {
        var kw = $('#txtDrilldownSearch').val().trim().toLowerCase();
        if (!kw) {
            if (currentDrilldownMode === 'PERMIT') {
                renderDrilldownPermits(currentDrilldownRawList);
            } else if (currentDrilldownMode === 'INSPECTION') {
                renderDrilldownInspections(currentDrilldownRawList);
            }
            return;
        }

        if (currentDrilldownMode === 'PERMIT') {
            var filtered = currentDrilldownRawList.filter(p => {
                return (p.LicensePlate && p.LicensePlate.toLowerCase().includes(kw)) ||
                       (p.OwnerName && p.OwnerName.toLowerCase().includes(kw)) ||
                       (p.DeptName && p.DeptName.toLowerCase().includes(kw)) ||
                       (p.PermitNumber && p.PermitNumber.toLowerCase().includes(kw)) ||
                       (p.ZoneName && p.ZoneName.toLowerCase().includes(kw)) ||
                       (p.VehicleBrand && p.VehicleBrand.toLowerCase().includes(kw));
            });
            renderDrilldownPermits(filtered);
        } else if (currentDrilldownMode === 'INSPECTION') {
            var filtered = currentDrilldownRawList.filter(l => {
                return (l.PlateScanned && l.PlateScanned.toLowerCase().includes(kw)) ||
                       (l.OwnerName && l.OwnerName.toLowerCase().includes(kw)) ||
                       (l.DeptName && l.DeptName.toLowerCase().includes(kw)) ||
                       (l.ZoneName && l.ZoneName.toLowerCase().includes(kw)) ||
                       (l.InspectorAccount && l.InspectorAccount.toLowerCase().includes(kw)) ||
                       (l.Remark && l.Remark.toLowerCase().includes(kw));
            });
            renderDrilldownInspections(filtered);
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

    // ==========================================
    // 快速審核彈窗邏輯
    // ==========================================

    // ==========================================
    // 5 大審核作業模式與彈窗邏輯 (Reject, Accept, Waitlist, Ready, Issue)
    // ==========================================

    var currentReviewAction = 'ACCEPT';
    var currentSelectedApp = null;

    function switchReviewAction(action) {
        currentReviewAction = action;
        
        // 切換按鈕 active 樣式
        $('.btn-action-tab').removeClass('active');
        $('.action-panel').addClass('d-none');

        var actionLabel = '收案受理';
        var btnClass = 'btn-primary';
        var btnIcon = 'bi-inbox-fill';
        var btnText = '確認收案受理';

        if (action === 'REJECT') {
            $('#btnTabReject').addClass('active');
            $('#panelReject').removeClass('d-none');
            actionLabel = '駁回申請';
            btnClass = 'btn-danger';
            btnIcon = 'bi-x-circle-fill';
            btnText = '確認駁回此申請';
            setTimeout(() => { $('#txtRejectReason').focus(); }, 150);
        } else if (action === 'ACCEPT') {
            $('#btnTabAccept').addClass('active');
            $('#panelAccept').removeClass('d-none');
            actionLabel = '收案受理';
            btnClass = 'btn-primary';
            btnIcon = 'bi-inbox-fill';
            btnText = '確認收案受理';
        } else if (action === 'WAITLIST') {
            $('#btnTabWaitlist').addClass('active');
            $('#panelWaitlist').removeClass('d-none');
            actionLabel = '待排序';
            btnClass = 'btn-warning text-dark';
            btnIcon = 'bi-clock-history';
            btnText = '確認列入待排序';
        } else if (action === 'READY') {
            $('#btnTabReady').addClass('active');
            $('#panelReady').removeClass('d-none');
            actionLabel = '待領證';
            btnClass = 'btn-info text-white';
            btnIcon = 'bi-card-checklist';
            btnText = '確認核准待領證';
        } else if (action === 'ISSUE') {
            $('#btnTabIssue').addClass('active');
            $('#panelIssue').removeClass('d-none');
            actionLabel = '發證結案';
            btnClass = 'btn-success';
            btnIcon = 'bi-credit-card-2-front-fill';
            btnText = '確認發證生效結案';
        }

        $('#lblTargetAction').text('目前選定：' + actionLabel);
        $('#btnExecuteReviewAction')
            .removeClass('btn-primary btn-danger btn-warning btn-info btn-success text-dark text-white')
            .addClass(btnClass);
        $('#iconExecuteAction').attr('class', 'bi ' + btnIcon + ' me-1');
        $('#textExecuteAction').text(btnText);
    }

    function openReviewModal(idx) {
        var app = pendingAppsList[idx];
        if (!app) return;

        currentSelectedApp = app;
        $('#hidReviewAppId').val(app.ApplicationID);
        $('#hidCurrentAppStatus').val(app.ReviewStatus);
        $('#revAppNo').text(app.ApplicationNo);
        $('#revEmpNo').text(app.EmpNo);
        $('#revApplicantName').text(app.ApplicantName);
        $('#revDeptName').text(app.DeptName);
        $('#revPlate').text(app.LicensePlate);
        $('#revVehicle').text(app.VehicleBrand + ' ' + app.VehicleColor);
        $('#revZone').text(app.PreferredZoneName);
        $('#revCurrentStatusBadge').html(getStatusBadgeHtml(app.ReviewStatus));

        // 載入發證面板專用之實際停放區域下拉選單 (勾選發證時供管理者彈性調配)
        var zoneOptionsHtml = '';
        var selectedZoneId = (app.AssignedZoneID && app.AssignedZoneID > 0) ? app.AssignedZoneID : app.PreferredZoneID;
        (cachedZoneList || []).forEach(z => {
            var isSel = (z.ZoneID === selectedZoneId) ? 'selected' : '';
            var isPref = (z.ZoneID === app.PreferredZoneID) ? ' (同仁原志願)' : '';
            zoneOptionsHtml += `<option value="${z.ZoneID}" ${isSel}>${z.ZoneName}${isPref}</option>`;
        });
        $('#selIssueZone').html(zoneOptionsHtml);

        // 歷史備註紀錄
        if (app.ReviewRemarks || app.RejectReason) {
            var note = app.RejectReason ? ('駁回原因：' + app.RejectReason) : app.ReviewRemarks;
            var who = app.ReviewerName ? ` (${app.ReviewerName} ${app.ReviewDate || ''})` : '';
            $('#revPriorRemarks').text(note + who);
            $('#revPriorRemarksRow').removeClass('d-none');
        } else {
            $('#revPriorRemarksRow').addClass('d-none');
        }

        // 清空重置輸入欄位
        $('#txtRejectReason').val(app.RejectReason || '');
        $('#txtAcceptRemarks').val('已受理收案，資料查驗審核中');
        $('#txtWaitlistRemarks').val('目前配額額滿，已列入排序輪候名單');
        $('#txtReadyRemarks').val('審核通過，請攜帶識別證至總務處領取感應卡與遙控器');
        
        // 預填發證資訊
        var randomNum = Math.floor(1000 + Math.random() * 9000);
        $('#txtIssueTag').val('TAG-' + randomNum);
        $('#txtIssueRemote').val('RC-' + randomNum);

        var today = new Date();
        var nextYear = new Date(today.getFullYear() + 1, today.getMonth(), today.getDate());
        var expStr = nextYear.toISOString().split('T')[0];
        $('#txtIssueExpireDate').val(expStr);
        $('#txtIssueRemarks').val('同仁已完成臨櫃領證並啟用通行證');

        // 依據案件當前狀態，智慧預設作業選項
        if (app.ReviewStatus === 'PENDING') {
            switchReviewAction('ACCEPT');
        } else if (app.ReviewStatus === 'PROCESSING') {
            switchReviewAction('READY');
        } else if (app.ReviewStatus === 'WAITLIST') {
            switchReviewAction('READY');
        } else if (app.ReviewStatus === 'APPROVED') {
            switchReviewAction('ISSUE');
        } else if (app.ReviewStatus === 'COMPLETED') {
            switchReviewAction('ISSUE');
        } else if (app.ReviewStatus === 'REJECTED') {
            switchReviewAction('REJECT');
        } else {
            switchReviewAction('ACCEPT');
        }

        var modalEl = document.getElementById('modalReview');
        var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
        modal.show();
    }

    function submitExecuteAction() {
        var appId = parseInt($('#hidReviewAppId').val());
        if (!appId) return;

        if (currentReviewAction === 'REJECT') {
            var reason = $('#txtRejectReason').val().trim();
            if (!reason) {
                Swal.fire('請填寫原因', '選擇【駁回申請】時必須填寫駁回原因，以利員工了解補正！', 'warning');
                $('#txtRejectReason').focus();
                return;
            }

            Swal.fire({
                title: '確認駁回此申請？',
                text: '該單號狀態將更新為【已駁回】，並註記原因。',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: '確定駁回',
                cancelButtonText: '取消',
                confirmButtonColor: '#F05252'
            }).then(result => {
                if (result.isConfirmed) {
                    $.ajax({
                        type: "POST",
                        url: "Admin_Dashboard.aspx/QuickReject",
                        data: JSON.stringify({ applicationId: appId, reason: reason }),
                        contentType: "application/json; charset=utf-8",
                        dataType: "json",
                        success: function (res) {
                            handleActionResult(res.d, '已駁回');
                        }
                    });
                }
            });
        } else if (currentReviewAction === 'ACCEPT') {
            var remarks = $('#txtAcceptRemarks').val().trim();
            $.ajax({
                type: "POST",
                url: "Admin_Dashboard.aspx/ReviewAccept",
                data: JSON.stringify({ applicationId: appId, assignedZoneId: null, remarks: remarks }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    handleActionResult(res.d, '收案成功');
                }
            });
        } else if (currentReviewAction === 'WAITLIST') {
            var remarks = $('#txtWaitlistRemarks').val().trim();
            $.ajax({
                type: "POST",
                url: "Admin_Dashboard.aspx/ReviewWaitlist",
                data: JSON.stringify({ applicationId: appId, assignedZoneId: null, remarks: remarks }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    handleActionResult(res.d, '已列入待排序');
                }
            });
        } else if (currentReviewAction === 'READY') {
            var remarks = $('#txtReadyRemarks').val().trim();
            $.ajax({
                type: "POST",
                url: "Admin_Dashboard.aspx/ReviewReadyPickup",
                data: JSON.stringify({ applicationId: appId, assignedZoneId: null, remarks: remarks }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    handleActionResult(res.d, '已標記待領證');
                }
            });
        } else if (currentReviewAction === 'ISSUE') {
            var issueZoneId = parseInt($('#selIssueZone').val()) || null;
            var tag = $('#txtIssueTag').val().trim();
            var remote = $('#txtIssueRemote').val().trim();
            var expDate = $('#txtIssueExpireDate').val();
            var remarks = $('#txtIssueRemarks').val().trim();

            if (!tag) {
                Swal.fire('請填寫卡號', '發證時必須填寫實體 RFID 感應卡號！', 'warning');
                return;
            }

            Swal.fire({
                title: '確認發證？',
                text: `將為此車輛建立正式通行證主檔，並配發感應卡【${tag}】。`,
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: '確定發證',
                cancelButtonText: '取消',
                confirmButtonColor: '#0E9F6E'
            }).then(result => {
                if (result.isConfirmed) {
                    $.ajax({
                        type: "POST",
                        url: "Admin_Dashboard.aspx/ReviewIssuePermit",
                        data: JSON.stringify({ applicationId: appId, assignedZoneId: issueZoneId, sensorTag: tag, remoteNo: remote, expireDate: expDate, remarks: remarks }),
                        contentType: "application/json; charset=utf-8",
                        dataType: "json",
                        success: function (res) {
                            handleActionResult(res.d, '發證成功');
                        }
                    });
                }
            });
        }
    }

    function handleActionResult(result, title) {
        if (result.Success) {
            var modalEl = document.getElementById('modalReview');
            var modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            Swal.fire(title, result.Message, 'success');
            loadDashboard();
            if (currentAppFilter) {
                loadFilteredApps(currentAppFilter, $('#txtAppKeyword').val().trim());
            }
        } else {
            Swal.fire('作業失敗', result.Message, 'error');
        }
    }

    function submitApprove() {
        switchReviewAction('READY');
        submitExecuteAction();
    }

    function submitReject() {
        switchReviewAction('REJECT');
        submitExecuteAction();
    }
</script>
</asp:Content>
