<%@ Page Title="現場行動巡檢查核" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Mobile_Check.aspx.cs" Inherits="HospitalParking.Mobile_Check" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .quick-test-btn {
            font-size: 0.8rem;
            padding: 0.3rem 0.6rem;
            border-radius: 8px;
            font-family: monospace;
        }
        .captured-preview-box {
            position: relative;
            max-height: 180px;
            overflow: hidden;
            border-radius: 12px;
            margin-bottom: 1rem;
            background: #000;
        }
        .captured-preview-box img {
            width: 100%;
            height: 180px;
            object-fit: cover;
        }
        .captured-preview-badge {
            position: absolute;
            top: 10px;
            right: 10px;
            background: rgba(0,0,0,0.7);
            color: #fff;
            padding: 2px 8px;
            border-radius: 6px;
            font-size: 0.75rem;
        }
        /* 車牌取景框與近拍裁切樣式 */
        .crop-hint-badge {
            position: absolute;
            top: 12px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(15, 23, 42, 0.88);
            color: #00E676;
            padding: 5px 16px;
            border-radius: 20px;
            font-size: 0.82rem;
            font-weight: 600;
            border: 1px solid rgba(0, 230, 118, 0.4);
            z-index: 20;
            pointer-events: none;
            box-shadow: 0 4px 12px rgba(0,0,0,0.5);
            white-space: nowrap;
        }
        .crop-canvas-wrapper {
            position: relative;
            width: 100%;
            height: 60vh;
            min-height: 320px;
            max-height: 440px;
            background: #090d16;
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
            user-select: none;
            touch-action: none;
        }
        #cropSourceCanvas, #cropOverlayCanvas {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            display: block;
        }
        #cropOverlayCanvas {
            cursor: move;
            z-index: 10;
        }
        .live-viewfinder-box {
            position: relative;
            width: 100%;
            height: 420px;
            background: #000;
            overflow: hidden;
        }
        #videoLiveStream {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .live-camera-overlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .live-plate-target {
            width: 80%;
            max-width: 320px;
            height: 135px;
            border: 2px dashed #00E676;
            border-radius: 8px;
            box-shadow: 0 0 20px rgba(0,230,118,0.5), inset 0 0 15px rgba(0,230,118,0.2);
            position: relative;
        }
        .live-plate-target::before, .live-plate-target::after {
            content: '';
            position: absolute;
            width: 20px; height: 20px;
            border-color: #00E676;
            border-style: solid;
        }
        .live-plate-target::before {
            top: -2px; left: -2px;
            border-width: 4px 0 0 4px;
        }
        .live-plate-target::after {
            bottom: -2px; right: -2px;
            border-width: 0 4px 4px 0;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
<div class="container mobile-check-container py-2">
    <!-- 頂部當前巡檢分區選擇列 -->
    <div class="hsp-card mb-3 p-3 border-primary border-opacity-25 shadow-sm">
        <label class="form-label fw-bold text-primary mb-1">
            <i class="bi bi-geo-alt-fill text-danger me-1 fs-5"></i>當前巡檢位置 (分區定位)：
        </label>
        <select id="ddlCurrentZone" class="form-select form-select-lg fw-bold border-2 border-primary" onchange="onZoneChanged();">
            <%= RenderZoneOptions() %>
        </select>
    </div>

    <!-- 查驗操作面板 (相機拍攝 + 手動輸入) -->
    <div class="hsp-card mb-3 p-4 shadow-sm text-center">
        <!-- 隱藏原生 File Input，利用 capture="environment" 直接調用手機後置鏡頭 -->
        <input type="file" id="cameraInput" accept="image/*" capture="environment" style="display:none;" onchange="handleImageCaptured(this);" />
        
        <!-- 相機拍照預覽 -->
        <div id="previewContainer" class="captured-preview-box" style="display:none;">
            <img id="imgCapturePreview" src="" alt="拍攝預覽" />
            <div class="captured-preview-badge"><i class="bi bi-camera me-1"></i>車牌影像取格完成</div>
        </div>

        <!-- 大尺寸拍攝操作區 (支援原生相機取景與即時視訊對焦) -->
        <div class="row g-2 mb-2">
            <div class="col-8 col-sm-9">
                <button type="button" class="btn btn-primary w-100 btn-mobile-camera shadow-sm" onclick="$('#txtCheckPlate').val(''); $('#cameraInput').click();">
                    <i class="bi bi-camera-fill fs-3"></i>
                    <span>拍攝車牌 / 對焦裁切</span>
                </button>
            </div>
            <div class="col-4 col-sm-3">
                <button type="button" class="btn btn-outline-primary w-100 h-100 d-flex flex-column justify-content-center align-items-center shadow-sm" onclick="openLiveCameraStream();" title="開啟即時相機動態取景">
                    <i class="bi bi-camera-video fs-4"></i>
                    <span style="font-size: 0.75rem;">即時對焦</span>
                </button>
            </div>
        </div>
        <div class="text-muted small mb-3">
            <i class="bi bi-magic text-primary me-1"></i>智慧取景：拍攝後自動鎖定保險桿車牌位置，支援拖曳微調與近拍自動裁切。
        </div>

        <div class="d-flex align-items-center my-3">
            <hr class="flex-grow-1"><span class="px-3 text-muted small fw-bold">或 手動輸入車牌查驗</span><hr class="flex-grow-1">
        </div>

        <!-- 車牌手動輸入框 -->
        <div class="input-group mb-2">
            <input type="text" id="txtCheckPlate" class="form-control mobile-plate-input text-center font-monospace" placeholder="例: ABC-1234" maxlength="10" />
            <button class="btn btn-dark px-4 fw-bold" type="button" onclick="verifyPlateManual();" style="min-width: 90px;">
                <i class="bi bi-search me-1"></i>查驗
            </button>
        </div>

    </div>

    <!-- 查驗結果動態呈現卡片 (高對比 WCAG 2.1 AA) -->
    <div id="checkResultContainer" style="display:none;" class="mb-3">
        <!-- 動態填入查核結果 -->
    </div>

    <!-- 即時巡檢日誌記錄區 -->
    <div class="hsp-card p-3 shadow-sm">
        <div class="d-flex justify-content-between align-items-center mb-2">
            <span class="fw-bold small text-muted"><i class="bi bi-clock-history me-1"></i>當班巡檢查核紀錄 (Inspection Logs)</span>
            <button type="button" class="btn btn-link btn-sm p-0 text-decoration-none" onclick="loadRecentLogs();">
                <i class="bi bi-arrow-clockwise"></i> 刷新
            </button>
        </div>
        <div id="recentLogsContainer" class="d-flex flex-column gap-2 small">
            <div class="text-center py-3 text-muted">載入巡檢紀錄中...</div>
        </div>
    </div>
</div>

<!-- 違規舉證拍照或備註彈窗 -->
<div class="modal fade" id="modalRecordViolation" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-danger text-white">
                <h5 class="modal-title"><i class="bi bi-exclamation-triangle-fill me-2"></i>現場違規舉證登錄</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <div class="mb-3">
                    <label class="form-label fw-bold">違規車牌：</label>
                    <input type="text" id="txtViolatePlate" class="form-control font-monospace fw-bold" readonly />
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">違規類型：</label>
                    <input type="text" id="txtViolateType" class="form-control" readonly />
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">巡檢員現場處理備註：</label>
                    <textarea id="txtViolateRemark" class="form-control" rows="3" placeholder="例: 已於車窗夾放黃色跨區違停勸導單，並通報總務處協尋車主移車..."></textarea>
                </div>
            </div>
            <div class="modal-footer bg-light">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-danger px-4" onclick="submitViolationRecord();">
                    <i class="bi bi-check-lg me-1"></i>確認送出舉證紀錄
                </button>
            </div>
        </div>
    </div>
</div>

<!-- 車牌取景對焦框與近拍裁切彈窗 (License Plate Viewfinder & Auto-Crop) -->
<div class="modal fade" id="modalPlateCrop" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg text-white" style="background: #0f172a; border-radius: 16px; overflow: hidden;">
            <div class="modal-header border-bottom border-secondary border-opacity-25 py-2 px-3" style="background: #1e293b;">
                <div class="d-flex align-items-center">
                    <span class="badge bg-success bg-gradient me-2 px-2 py-1"><i class="bi bi-camera-fill me-1"></i>AI 取景</span>
                    <h6 class="modal-title mb-0 fw-bold text-white">車牌對焦取景與近拍裁切</h6>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-0 position-relative" style="background: #090d16;">
                <!-- 提示浮水印標籤 -->
                <div class="crop-hint-badge">
                    <i class="bi bi-arrows-move me-1"></i>滑動綠框對準車牌｜可拖曳與縮放
                </div>

                <!-- 畫布容器 -->
                <div class="crop-canvas-wrapper" id="cropCanvasWrapper">
                    <canvas id="cropSourceCanvas"></canvas>
                    <canvas id="cropOverlayCanvas"></canvas>
                </div>

                <!-- 浮動快捷微調控制列 -->
                <div class="d-flex justify-content-between align-items-center px-3 py-2" style="background: rgba(15, 23, 42, 0.95); border-top: 1px solid rgba(255,255,255,0.08);">
                    <div class="d-flex align-items-center gap-2">
                        <span class="small text-muted d-none d-sm-inline">框線縮放：</span>
                        <button type="button" class="btn btn-outline-light btn-sm rounded-pill px-2 py-1" onclick="adjustCropSize(-30);" title="縮小取景框">
                            <i class="bi bi-dash-lg"></i>
                        </button>
                        <button type="button" class="btn btn-outline-light btn-sm rounded-pill px-2 py-1" onclick="adjustCropSize(30);" title="放大取景框">
                            <i class="bi bi-plus-lg"></i>
                        </button>
                        <button type="button" class="btn btn-outline-secondary btn-sm rounded-pill px-2 py-1 ms-1 text-white" onclick="resetCropBox();" title="重設取景框位置">
                            <i class="bi bi-arrow-counterclockwise me-1"></i>置中
                        </button>
                    </div>
                    <div class="small text-success fw-bold font-monospace">
                        <i class="bi bi-aspect-ratio me-1"></i>標準車牌比例 (2.38:1)
                    </div>
                </div>
            </div>
            <div class="modal-footer border-top border-secondary border-opacity-25 py-2 px-3 d-flex justify-content-between" style="background: #1e293b;">
                <button type="button" class="btn btn-outline-secondary btn-sm text-light" onclick="performFullImageRecognition();">
                    <i class="bi bi-image me-1"></i>全圖辨識 (不裁切)
                </button>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-secondary btn-sm px-3" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-success fw-bold px-4 shadow-sm" id="btnConfirmCrop" onclick="confirmAndRecognizeCrop();">
                        <i class="bi bi-check-circle-fill me-1"></i>確認裁切並辨識
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 即時視訊相機對焦拍攝彈窗 (Live Camera Stream Viewfinder) -->
<div class="modal fade" id="modalLiveCamera" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg text-white" style="background: #0f172a; border-radius: 16px; overflow: hidden;">
            <div class="modal-header border-bottom border-secondary border-opacity-25 py-2 px-3" style="background: #1e293b;">
                <div class="d-flex align-items-center">
                    <span class="badge bg-primary bg-gradient me-2 px-2 py-1"><i class="bi bi-camera-video me-1"></i>即時動態</span>
                    <h6 class="modal-title mb-0 fw-bold text-white">即時相機取景對焦</h6>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" onclick="stopLiveCameraStream();"></button>
            </div>
            <div class="modal-body p-0 position-relative" style="background: #000;">
                <div class="live-viewfinder-box">
                    <video id="videoLiveStream" playsinline autoplay muted></video>
                    <div class="live-camera-overlay">
                        <div class="crop-hint-badge" style="top: 15px;">
                            <i class="bi bi-bullseye me-1"></i>請將車牌對準中央綠色框線
                        </div>
                        <div class="live-plate-target"></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer border-top border-secondary border-opacity-25 py-2 px-3 d-flex justify-content-between" style="background: #1e293b;">
                <button type="button" class="btn btn-secondary btn-sm px-3" data-bs-dismiss="modal" onclick="stopLiveCameraStream();">關閉</button>
                <button type="button" class="btn btn-success fw-bold px-4 shadow-sm" onclick="captureLiveCameraFrame();">
                    <i class="bi bi-camera-fill me-1"></i>立即定格對焦
                </button>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<!-- Tesseract.js 離線/CDN OCR 字元辨識引擎 -->
<script src="<%= ResolveUrl("~/Content/tesseract.min.js") %>"></script>
<script>
    if (typeof Tesseract === 'undefined') {
        document.write('<script src="https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js"><\/script>');
    }
</script>

<script>
    var lastVerifiedPlate = '';
    var lastResultStatus = '';
    var capturedPhotoBase64 = null;

    // 前端取景框與裁切狀態變數
    var cropImage = null;
    var cropRect = null; // { x, y, width, height }
    var cropDisplayScale = 1;
    var isDragging = false;
    var dragOffset = { x: 0, y: 0 };
    var initialPinchDist = 0;
    var initialCropWidth = 0;
    var overlayEventsBound = false;
    var activeMediaStream = null;

    $(document).ready(function () {
        loadZoneOptions();

        $('#txtCheckPlate').keypress(function (e) {
            if (e.which === 13) {
                verifyPlateManual();
                return false;
            }
        });

        $('#modalPlateCrop').on('shown.bs.modal', function () {
            initCropCanvas();
        });

        $('#modalLiveCamera').on('hidden.bs.modal', function () {
            stopLiveCameraStream();
        });

        $(window).on('resize', function () {
            if ($('#modalPlateCrop').is(':visible') && cropImage) {
                initCropCanvas();
            }
        });
    });

    function loadZoneOptions() {
        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/GetActiveZones",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var zones = res.d || [];
                var $ddl = $('#ddlCurrentZone');
                var cur = $ddl.val();
                if (zones && zones.length > 0) {
                    var html = '';
                    zones.forEach(function (z) {
                        html += `<option value="${z.ZoneID}">${z.ZoneName}</option>`;
                    });
                    $ddl.html(html);
                    if (cur && $ddl.find('option[value="' + cur + '"]').length > 0) {
                        $ddl.val(cur);
                    } else {
                        $ddl.val(zones[0].ZoneID);
                    }
                    $ddl.prop('disabled', false);
                    loadRecentLogs();
                } else {
                    $ddl.html('<option value="">-- 資料表目前無啟用中之停車分區 (請先至場域維護建立) --</option>');
                    $ddl.prop('disabled', true);
                    $('#recentLogsContainer').html('<div class="text-center py-2 text-muted">目前尚未建立停車場分區（請至【場域維護】建立）</div>');
                }
            },
            error: function () {
                var $ddl = $('#ddlCurrentZone');
                if (!$ddl.val()) {
                    $ddl.html('<option value="">-- 連線異常無法取得分區 --</option>');
                }
            }
        });
    }

    function onZoneChanged() {
        var zoneVal = $('#ddlCurrentZone').val();
        if (zoneVal) {
            loadRecentLogs();
            if ($('#txtCheckPlate').val().trim()) {
                verifyPlateManual();
            }
        }
    }

    function verifyPlateManual() {
        var plate = $('#txtCheckPlate').val().trim().toUpperCase();
        var zoneVal = $('#ddlCurrentZone').val();
        var zoneId = parseInt(zoneVal);

        if (!zoneVal || isNaN(zoneId) || zoneId <= 0) {
            Swal.fire('提醒', '目前無有效的巡檢分區！請先至【場域維護】建立停車分區後再行查驗。', 'warning');
            return;
        }

        if (!plate) {
            Swal.fire('提醒', '請輸入車牌號碼！', 'warning');
            return;
        }

        executeVerification(plate, zoneId, capturedPhotoBase64);
    }

    // 前端 Canvas 輕量化壓縮：將手機相機 8MB 原始高畫素照片壓縮為 ~150KB 銳利照片，徹底避免傳輸超限
    function compressAndResizeImage(file, maxDimension, quality, callback) {
        var reader = new FileReader();
        reader.onload = function (e) {
            var img = new Image();
            img.onload = function () {
                var width = img.width;
                var height = img.height;
                if (width > maxDimension || height > maxDimension) {
                    if (width > height) {
                        height = Math.round((height * maxDimension) / width);
                        width = maxDimension;
                    } else {
                        width = Math.round((width * maxDimension) / height);
                        height = maxDimension;
                    }
                }
                var canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                var ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                var compressed = canvas.toDataURL('image/jpeg', quality);
                callback(compressed, canvas);
            };
            img.onerror = function () {
                callback(e.target.result, null);
            };
            img.src = e.target.result;
        };
        reader.onerror = function () {
            Swal.fire('讀取錯誤', '無法讀取相機拍攝之照片，請重試！', 'error');
        };
        reader.readAsDataURL(file);
    }

    // 影像對比強化處理器：加強黑白對比，壓制水箱護罩陰影，突顯車牌清晰黑字
    function createEnhancedPlateCanvas(sourceCanvas) {
        var enhanced = document.createElement('canvas');
        enhanced.width = sourceCanvas.width;
        enhanced.height = sourceCanvas.height;
        var ctx = enhanced.getContext('2d');
        ctx.drawImage(sourceCanvas, 0, 0);

        try {
            var imgData = ctx.getImageData(0, 0, enhanced.width, enhanced.height);
            var data = imgData.data;
            for (var i = 0; i < data.length; i += 4) {
                var r = data[i], g = data[i + 1], b = data[i + 2];
                var gray = 0.299 * r + 0.587 * g + 0.114 * b;
                // 對比強化：壓暗黑色車牌字元，提亮白色車牌底色
                if (gray < 120) {
                    gray = Math.max(0, gray * 0.4);
                } else if (gray > 140) {
                    gray = Math.min(255, gray * 1.3);
                }
                data[i] = gray;
                data[i + 1] = gray;
                data[i + 2] = gray;
            }
            ctx.putImageData(imgData, 0, 0);
            return enhanced;
        } catch (e) {
            return sourceCanvas;
        }
    }

    // 台灣車牌格式智慧剖析與萃取演算法 (支援字元位置校對、排除車頭進氣格柵噪聲如 FII-HIT)
    function extractLicensePlate(text) {
        if (!text) return null;

        var cleaned = text.toUpperCase()
            .replace(/[ÄÀÁÂÃÅ]/g, 'A')
            .replace(/[ÈÉÊË]/g, 'E')
            .replace(/[ÌÍÎÏ]/g, 'I')
            .replace(/[ÒÓÔÕÖ]/g, 'O')
            .replace(/[ÙÚÛÜ]/g, 'U')
            .replace(/[·•.。:_]/g, '-')
            .replace(/[\r\n\t]/g, ' ');

        var candidates = [];

        // 規則 1: 3 碼 (英數混雜) + 連字號/空白/無間隔 + 4 碼 (英數混雜) -> 如 ASU-7635, NSF-3620, ABC-1234
        var reg1 = /([A-Z0-9]{3})[\s\-]*([A-Z0-9]{4})/g;
        var m;
        while ((m = reg1.exec(cleaned)) !== null) {
            var p1 = m[1];
            var p2 = m[2];

            // 嚴格排除純英文單字或車頭格柵/標誌陰影 (例如 FII-HIT, HYUNDAI 等)
            if (/^[A-Z]+$/.test(p1) && /^[A-Z]+$/.test(p2) && !/[0-9]/.test(p2)) {
                continue;
            }

            // 前 3 碼必定為英文字母：進行易混淆字元自動校準 (0->O, 1->I, 5->S, 8->B, 4->A)
            var norm1 = p1.replace(/0/g, 'O').replace(/1/g, 'I').replace(/5/g, 'S').replace(/8/g, 'B');

            // 後 4 碼必定為阿拉伯數字：進行字元位置校準 (S->3, B->8, O/D/Q->0, I/L->1, Z->2, G->6)
            var norm2 = p2.replace(/[ODQ]/g, '0').replace(/[IL]/g, '1').replace(/Z/g, '2').replace(/S/g, '3').replace(/B/g, '8').replace(/G/g, '6');

            var score = 0;
            if (/^[A-Z]{3}$/.test(norm1)) score += 45;
            if (/^\d{4}$/.test(norm2)) score += 55;

            if (score >= 60) {
                candidates.push({ plate: norm1 + '-' + norm2, score: score });
            }
        }

        // 規則 2: 4 碼數字 + 2 碼英文 (舊式汽車如 5678-EF)
        var reg2 = /([A-Z0-9]{4})[\s\-]+([A-Z0-9]{2})/g;
        while ((m = reg2.exec(cleaned)) !== null) {
            var p1 = m[1];
            var p2 = m[2];
            var norm1 = p1.replace(/[ODQ]/g, '0').replace(/[IL]/g, '1').replace(/Z/g, '2').replace(/S/g, '3').replace(/B/g, '8').replace(/G/g, '6');
            var norm2 = p2.replace(/0/g, 'O').replace(/1/g, 'I').replace(/5/g, 'S').replace(/8/g, 'B');
            if (/^\d{4}$/.test(norm1) && /^[A-Z]{2}$/.test(norm2)) {
                candidates.push({ plate: norm1 + '-' + norm2, score: 95 });
            }
        }

        // 規則 3: 2 碼英文 + 4 碼數字 (舊式汽車如 AB-1234)
        var reg3 = /([A-Z0-9]{2})[\s\-]+([A-Z0-9]{4})/g;
        while ((m = reg3.exec(cleaned)) !== null) {
            var p1 = m[1];
            var p2 = m[2];
            var norm1 = p1.replace(/0/g, 'O').replace(/1/g, 'I').replace(/5/g, 'S').replace(/8/g, 'B');
            var norm2 = p2.replace(/[ODQ]/g, '0').replace(/[IL]/g, '1').replace(/Z/g, '2').replace(/S/g, '3').replace(/B/g, '8').replace(/G/g, '6');
            if (/^[A-Z]{2}$/.test(norm1) && /^\d{4}$/.test(norm2)) {
                candidates.push({ plate: norm1 + '-' + norm2, score: 95 });
            }
        }

        // 規則 4: 3 碼數字 + 3 碼英文 或 3 碼英文 + 3 碼數字 (機車重機)
        var reg4 = /([A-Z0-9]{3})[\s\-]+([A-Z0-9]{3})/g;
        while ((m = reg4.exec(cleaned)) !== null) {
            var p1 = m[1];
            var p2 = m[2];
            // 排除純英文雜訊如 FII-HIT
            if (!(/[0-9]/.test(p1) || /[0-9]/.test(p2))) {
                continue;
            }
            candidates.push({ plate: p1 + '-' + p2, score: 80 });
        }

        if (candidates.length === 0) return null;

        // 依據相符度評分排序，優先選取標準度最高者
        candidates.sort(function (a, b) { return b.score - a.score; });
        return candidates[0].plate;
    }

    // 拍攝照片完成後之完整處理流程 (開啟前端智慧對焦取景框與自動裁切)
    function handleImageCaptured(input) {
        if (!input.files || !input.files[0]) return;
        var file = input.files[0];

        // 徹底清空前次輸入值
        $('#txtCheckPlate').val('');

        // 讀取檔案並開啟取景對焦彈窗
        openPlateCropModal(file);

        // 清空 input 讓同檔名相片可重複選取拍照
        $(input).val('');
    }

    // 開啟車牌對焦取景彈窗
    function openPlateCropModal(file) {
        var reader = new FileReader();
        reader.onload = function (e) {
            var img = new Image();
            img.onload = function () {
                cropImage = img;
                var modalEl = document.getElementById('modalPlateCrop');
                var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
                modal.show();

                setTimeout(function () {
                    initCropCanvas();
                }, 250);
            };
            img.onerror = function () {
                Swal.fire('讀取錯誤', '無法載入照片，請重試！', 'error');
            };
            img.src = e.target.result;
        };
        reader.onerror = function () {
            Swal.fire('讀取錯誤', '無法讀取相機拍攝之照片，請重試！', 'error');
        };
        reader.readAsDataURL(file);
    }

    // 初始化對焦裁切畫布尺寸與預設車牌框位置
    function initCropCanvas() {
        if (!cropImage) return;

        var wrapper = document.getElementById('cropCanvasWrapper');
        if (!wrapper) return;
        var wrapW = wrapper.clientWidth || 360;
        var wrapH = wrapper.clientHeight || 360;

        var imgW = cropImage.naturalWidth || cropImage.width;
        var imgH = cropImage.naturalHeight || cropImage.height;
        if (!imgW || !imgH) return;

        // 計算等比例縮放以適應視窗
        cropDisplayScale = Math.min(wrapW / imgW, wrapH / imgH);
        var dispW = Math.round(imgW * cropDisplayScale);
        var dispH = Math.round(imgH * cropDisplayScale);

        var srcCanvas = document.getElementById('cropSourceCanvas');
        var ovrCanvas = document.getElementById('cropOverlayCanvas');
        if (!srcCanvas || !ovrCanvas) return;

        srcCanvas.width = dispW;
        srcCanvas.height = dispH;
        srcCanvas.style.width = dispW + 'px';
        srcCanvas.style.height = dispH + 'px';

        ovrCanvas.width = dispW;
        ovrCanvas.height = dispH;
        ovrCanvas.style.width = dispW + 'px';
        ovrCanvas.style.height = dispH + 'px';

        var srcCtx = srcCanvas.getContext('2d');
        srcCtx.drawImage(cropImage, 0, 0, dispW, dispH);

        // 初始預設車牌框：寬度約為相片寬度的 62%，比例約 2.38:1 (38cm x 16cm)
        var boxW = Math.round(dispW * 0.62);
        boxW = Math.max(140, Math.min(dispW * 0.94, boxW));
        var boxH = Math.round(boxW / 2.375);

        // 置於畫面水平置中、垂直中偏下 (車輛保險桿/車牌絕佳位置)
        var boxX = Math.round((dispW - boxW) / 2);
        var boxY = Math.round((dispH - boxH) * 0.62);
        boxY = Math.max(0, Math.min(dispH - boxH, boxY));

        cropRect = { x: boxX, y: boxY, width: boxW, height: boxH };
        drawCropOverlay();
        bindCropOverlayEvents();
    }

    // 綁定取景框拖曳與手勢縮放事件
    function bindCropOverlayEvents() {
        var ovrCanvas = document.getElementById('cropOverlayCanvas');
        if (!ovrCanvas || overlayEventsBound) return;
        overlayEventsBound = true;

        ovrCanvas.addEventListener('pointerdown', function (e) {
            if (!cropRect) return;
            var rect = ovrCanvas.getBoundingClientRect();
            var x = (e.clientX - rect.left) * (ovrCanvas.width / rect.width);
            var y = (e.clientY - rect.top) * (ovrCanvas.height / rect.height);

            isDragging = true;
            try { ovrCanvas.setPointerCapture(e.pointerId); } catch (ex) { }

            // 若點擊在框線外，平滑將取景框中心移至該點
            if (x < cropRect.x || x > cropRect.x + cropRect.width || y < cropRect.y || y > cropRect.y + cropRect.height) {
                cropRect.x = Math.max(0, Math.min(ovrCanvas.width - cropRect.width, x - cropRect.width / 2));
                cropRect.y = Math.max(0, Math.min(ovrCanvas.height - cropRect.height, y - cropRect.height / 2));
                dragOffset = { x: cropRect.width / 2, y: cropRect.height / 2 };
                drawCropOverlay();
            } else {
                dragOffset = { x: x - cropRect.x, y: y - cropRect.y };
            }
        });

        ovrCanvas.addEventListener('pointermove', function (e) {
            if (!isDragging || !cropRect) return;
            var rect = ovrCanvas.getBoundingClientRect();
            var x = (e.clientX - rect.left) * (ovrCanvas.width / rect.width);
            var y = (e.clientY - rect.top) * (ovrCanvas.height / rect.height);

            cropRect.x = Math.max(0, Math.min(ovrCanvas.width - cropRect.width, x - dragOffset.x));
            cropRect.y = Math.max(0, Math.min(ovrCanvas.height - cropRect.height, y - dragOffset.y));
            drawCropOverlay();
        });

        function stopDrag(e) {
            if (isDragging) {
                isDragging = false;
                try { ovrCanvas.releasePointerCapture(e.pointerId); } catch (ex) { }
            }
        }

        ovrCanvas.addEventListener('pointerup', stopDrag);
        ovrCanvas.addEventListener('pointercancel', stopDrag);

        // 手機雙指手勢縮放 (Pinch-to-zoom)
        ovrCanvas.addEventListener('touchstart', function (e) {
            if (e.touches.length === 2 && cropRect) {
                isDragging = false;
                var t1 = e.touches[0];
                var t2 = e.touches[1];
                initialPinchDist = Math.hypot(t1.clientX - t2.clientX, t1.clientY - t2.clientY);
                initialCropWidth = cropRect.width;
            }
        }, { passive: false });

        ovrCanvas.addEventListener('touchmove', function (e) {
            if (e.touches.length === 2 && initialPinchDist > 0 && cropRect) {
                e.preventDefault();
                var t1 = e.touches[0];
                var t2 = e.touches[1];
                var curDist = Math.hypot(t1.clientX - t2.clientX, t1.clientY - t2.clientY);
                var ratio = curDist / initialPinchDist;
                var newW = Math.round(initialCropWidth * ratio);
                setCropBoxWidth(newW);
            }
        }, { passive: false });

        ovrCanvas.addEventListener('touchend', function (e) {
            if (e.touches.length < 2) {
                initialPinchDist = 0;
            }
        });
    }

    // 繪製高科技取景框與暗角遮罩
    function drawCropOverlay() {
        var ovrCanvas = document.getElementById('cropOverlayCanvas');
        if (!ovrCanvas || !cropRect) return;
        var ctx = ovrCanvas.getContext('2d');
        var w = ovrCanvas.width;
        var h = ovrCanvas.height;

        ctx.clearRect(0, 0, w, h);

        // 1. 半透明暗色遮罩 (壓暗非車牌雜訊區域)
        ctx.fillStyle = 'rgba(5, 10, 20, 0.68)';
        ctx.fillRect(0, 0, w, h);

        // 2. 挖空取景核心區域
        ctx.clearRect(cropRect.x, cropRect.y, cropRect.width, cropRect.height);

        ctx.save();

        // 3. 綠色高科技對焦邊框
        ctx.strokeStyle = 'rgba(0, 230, 118, 0.75)';
        ctx.lineWidth = 2;
        ctx.strokeRect(cropRect.x, cropRect.y, cropRect.width, cropRect.height);

        // 4. 四角科技強化 L 型標記
        var cornerLen = Math.min(26, Math.floor(cropRect.width * 0.12));
        ctx.strokeStyle = '#00E676';
        ctx.lineWidth = 4;
        ctx.lineCap = 'round';
        ctx.shadowColor = '#00E676';
        ctx.shadowBlur = 10;

        // 左上
        ctx.beginPath();
        ctx.moveTo(cropRect.x, cropRect.y + cornerLen);
        ctx.lineTo(cropRect.x, cropRect.y);
        ctx.lineTo(cropRect.x + cornerLen, cropRect.y);
        ctx.stroke();

        // 右上
        ctx.beginPath();
        ctx.moveTo(cropRect.x + cropRect.width - cornerLen, cropRect.y);
        ctx.lineTo(cropRect.x + cropRect.width, cropRect.y);
        ctx.lineTo(cropRect.x + cropRect.width, cropRect.y + cornerLen);
        ctx.stroke();

        // 左下
        ctx.beginPath();
        ctx.moveTo(cropRect.x, cropRect.y + cropRect.height - cornerLen);
        ctx.lineTo(cropRect.x, cropRect.y + cropRect.height);
        ctx.lineTo(cropRect.x + cornerLen, cropRect.y + cropRect.height);
        ctx.stroke();

        // 右下
        ctx.beginPath();
        ctx.moveTo(cropRect.x + cropRect.width - cornerLen, cropRect.y + cropRect.height);
        ctx.lineTo(cropRect.x + cropRect.width, cropRect.y + cropRect.height);
        ctx.lineTo(cropRect.x + cropRect.width, cropRect.y + cropRect.height - cornerLen);
        ctx.stroke();

        // 5. 中央十字瞄準線 (微距對準車牌中線)
        var cx = cropRect.x + cropRect.width / 2;
        var cy = cropRect.y + cropRect.height / 2;
        ctx.shadowBlur = 0;
        ctx.strokeStyle = 'rgba(0, 230, 118, 0.5)';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(cx - 12, cy);
        ctx.lineTo(cx + 12, cy);
        ctx.moveTo(cx, cy - 9);
        ctx.lineTo(cx, cy + 9);
        ctx.stroke();

        // 6. 對焦標籤 (Badge)
        var labelText = "PLATE ALIGN [車牌取景區]";
        ctx.font = "bold 11px monospace";
        ctx.fillStyle = "#00E676";
        ctx.shadowColor = "rgba(0,0,0,0.8)";
        ctx.shadowBlur = 4;
        var tw = ctx.measureText(labelText).width;
        ctx.fillText(labelText, cropRect.x + (cropRect.width - tw) / 2, Math.max(14, cropRect.y - 7));

        ctx.restore();
    }

    // 縮放微調取景框大小
    function adjustCropSize(delta) {
        if (!cropRect) return;
        setCropBoxWidth(cropRect.width + delta);
    }

    function setCropBoxWidth(newW) {
        var ovrCanvas = document.getElementById('cropOverlayCanvas');
        if (!ovrCanvas || !cropRect) return;

        var minW = Math.round(ovrCanvas.width * 0.22);
        var maxW = Math.round(ovrCanvas.width * 0.96);
        newW = Math.max(minW, Math.min(maxW, newW));

        var cx = cropRect.x + cropRect.width / 2;
        var cy = cropRect.y + cropRect.height / 2;

        var newH = Math.round(newW / 2.375);
        newH = Math.min(ovrCanvas.height, newH);

        cropRect.width = newW;
        cropRect.height = newH;
        cropRect.x = Math.max(0, Math.min(ovrCanvas.width - newW, cx - newW / 2));
        cropRect.y = Math.max(0, Math.min(ovrCanvas.height - newH, cy - newH / 2));

        drawCropOverlay();
    }

    // 重設取景框至畫面中央下方
    function resetCropBox() {
        var ovrCanvas = document.getElementById('cropOverlayCanvas');
        if (!ovrCanvas) return;

        var boxW = Math.round(ovrCanvas.width * 0.62);
        boxW = Math.max(140, Math.min(ovrCanvas.width * 0.94, boxW));
        var boxH = Math.round(boxW / 2.375);

        var boxX = Math.round((ovrCanvas.width - boxW) / 2);
        var boxY = Math.round((ovrCanvas.height - boxH) * 0.62);
        boxY = Math.max(0, Math.min(ovrCanvas.height - boxH, boxY));

        cropRect = { x: boxX, y: boxY, width: boxW, height: boxH };
        drawCropOverlay();
    }

    // 確認裁切並送出近拍辨識
    function confirmAndRecognizeCrop() {
        if (!cropImage || !cropRect) return;

        var scale = cropDisplayScale || 1;
        var origX = Math.round(cropRect.x / scale);
        var origY = Math.round(cropRect.y / scale);
        var origW = Math.round(cropRect.width / scale);
        var origH = Math.round(cropRect.height / scale);

        // 邊緣微幅擴展 4% ~ 6%，確保車牌邊框及英數字完整保留無裁切殘缺
        var padX = Math.round(origW * 0.04);
        var padY = Math.round(origH * 0.06);
        origX = Math.max(0, origX - padX);
        origY = Math.max(0, origY - padY);
        origW = Math.min(cropImage.naturalWidth - origX, origW + padX * 2);
        origH = Math.min(cropImage.naturalHeight - origY, origH + padY * 2);

        // 在離屏 Canvas 裁切車牌清晰子區域
        var cutCanvas = document.createElement('canvas');
        cutCanvas.width = origW;
        cutCanvas.height = origH;
        var cutCtx = cutCanvas.getContext('2d');
        cutCtx.drawImage(cropImage, origX, origY, origW, origH, 0, 0, origW, origH);

        // 產出近拍裁切後的優質影像 Base64
        var croppedBase64 = cutCanvas.toDataURL('image/jpeg', 0.92);
        capturedPhotoBase64 = croppedBase64;
        $('#imgCapturePreview').attr('src', capturedPhotoBase64);
        $('#previewContainer').show();

        // 關閉裁切對焦彈窗
        var modalEl = document.getElementById('modalPlateCrop');
        var modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();

        // 送往伺服端高精度車牌辨識引擎
        sendImageForRecognition(capturedPhotoBase64, cutCanvas);
    }

    // 1 鍵跳過裁切，直接全圖辨識
    function performFullImageRecognition() {
        if (!cropImage) return;

        var modalEl = document.getElementById('modalPlateCrop');
        var modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();

        // 使用全圖進行壓縮與辨識
        var canvas = document.createElement('canvas');
        var maxDim = 1280;
        var w = cropImage.naturalWidth;
        var h = cropImage.naturalHeight;
        if (w > maxDim || h > maxDim) {
            if (w > h) { h = Math.round((h * maxDim) / w); w = maxDim; }
            else { w = Math.round((w * maxDim) / h); h = maxDim; }
        }
        canvas.width = w;
        canvas.height = h;
        var ctx = canvas.getContext('2d');
        ctx.drawImage(cropImage, 0, 0, w, h);
        var fullBase64 = canvas.toDataURL('image/jpeg', 0.85);

        capturedPhotoBase64 = fullBase64;
        $('#imgCapturePreview').attr('src', capturedPhotoBase64);
        $('#previewContainer').show();

        sendImageForRecognition(capturedPhotoBase64, canvas);
    }

    // 送交影像進行辨識 (優先調用伺服端原生 Windows Media OCR)
    function sendImageForRecognition(base64Image, canvas) {
        Swal.fire({
            title: '車牌高速辨識中...',
            html: '<div class="spinner-border text-primary my-2" role="status"></div><div class="small text-muted mt-2">正在透過系統高精度 OCR 引擎辨識車牌號碼...</div>',
            allowOutsideClick: false,
            showConfirmButton: false
        });

        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/RecognizePlateOnly",
            data: JSON.stringify({ base64Image: base64Image }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            timeout: 15000,
            success: function (res) {
                var recognized = res && res.d ? res.d.trim() : '';
                if (recognized) {
                    promptConfirmPlate(recognized);
                } else {
                    fallbackClientOcrOrPrompt(canvas);
                }
            },
            error: function (xhr, status, err) {
                console.warn('Server OCR API warning:', status, err);
                fallbackClientOcrOrPrompt(canvas);
            }
        });
    }

    // 即時動態相機串流功能
    function openLiveCameraStream() {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            Swal.fire({
                title: '瀏覽器安全限制',
                text: '當前連線環境未啟用 HTTPS 或瀏覽器不支援即時視訊串流，系統將自動開啟原生高畫素相機取景模式！',
                icon: 'info',
                confirmButtonText: '開啟相機'
            }).then(function () {
                $('#cameraInput').click();
            });
            return;
        }

        var modalEl = document.getElementById('modalLiveCamera');
        var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
        modal.show();

        var constraints = {
            video: {
                facingMode: { ideal: "environment" },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
            },
            audio: false
        };

        navigator.mediaDevices.getUserMedia(constraints)
            .then(function (stream) {
                activeMediaStream = stream;
                var video = document.getElementById('videoLiveStream');
                video.srcObject = stream;
                video.play();
            })
            .catch(function (err) {
                console.warn('getUserMedia error:', err);
                modal.hide();
                Swal.fire({
                    title: '相機啟動提醒',
                    text: '無法直接存取即時鏡頭串流（可能未獲相機授權或非 HTTPS），請使用原生拍照模式！',
                    icon: 'warning',
                    confirmButtonText: '切換原生拍照'
                }).then(function () {
                    $('#cameraInput').click();
                });
            });
    }

    function stopLiveCameraStream() {
        if (activeMediaStream) {
            activeMediaStream.getTracks().forEach(function (track) {
                track.stop();
            });
            activeMediaStream = null;
        }
        var video = document.getElementById('videoLiveStream');
        if (video) video.srcObject = null;
    }

    function captureLiveCameraFrame() {
        var video = document.getElementById('videoLiveStream');
        if (!video || !video.videoWidth) {
            Swal.fire('提醒', '鏡頭尚未就緒，請稍候重試！', 'warning');
            return;
        }

        var canvas = document.createElement('canvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        var ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

        stopLiveCameraStream();
        var modalLiveEl = document.getElementById('modalLiveCamera');
        var modalLive = bootstrap.Modal.getInstance(modalLiveEl);
        if (modalLive) modalLive.hide();

        // 將擷取到的畫面載入裁切取景框
        var img = new Image();
        img.onload = function () {
            cropImage = img;
            var modalCropEl = document.getElementById('modalPlateCrop');
            var modalCrop = bootstrap.Modal.getOrCreateInstance(modalCropEl);
            modalCrop.show();
            setTimeout(function () {
                initCropCanvas();
            }, 250);
        };
        img.src = canvas.toDataURL('image/jpeg', 0.95);
    }

    // 前端備援 OCR 辨識 (若伺服器未辨識到時)
    function fallbackClientOcrOrPrompt(canvas) {
        if (typeof Tesseract !== 'undefined' && canvas) {
            var ocrFinished = false;
            var ocrTimer = setTimeout(function () {
                if (!ocrFinished) {
                    ocrFinished = true;
                    promptConfirmPlate(null);
                }
            }, 4000);

            try {
                var ocrCanvas = createEnhancedPlateCanvas(canvas);
                Tesseract.recognize(ocrCanvas, 'eng', {
                    tessedit_char_whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- '
                }).then(function (result) {
                    if (ocrFinished) return;
                    ocrFinished = true;
                    clearTimeout(ocrTimer);
                    var rawText = (result && result.data) ? result.data.text : '';
                    var detectedPlate = extractLicensePlate(rawText);
                    promptConfirmPlate(detectedPlate);
                }).catch(function () {
                    if (ocrFinished) return;
                    ocrFinished = true;
                    clearTimeout(ocrTimer);
                    promptConfirmPlate(null);
                });
            } catch (e) {
                if (ocrFinished) return;
                ocrFinished = true;
                clearTimeout(ocrTimer);
                promptConfirmPlate(null);
            }
        } else {
            promptConfirmPlate(null);
        }
    }

    // 彈出確認/校正車牌對話框，提供巡檢人員 1 鍵快速確認或直接送出
    function promptConfirmPlate(detectedPlate) {
        Swal.close();

        // 嚴格判定：只認可實際辨識出來的車牌，絕不可拿舊的 manualHint 充當辨識成功結果！
        if (detectedPlate && detectedPlate.trim()) {
            var candidatePlate = detectedPlate.trim().toUpperCase();
            $('#txtCheckPlate').val(candidatePlate);

            Swal.fire({
                icon: 'success',
                title: '車牌辨識完成',
                html: `
                    <div class="mb-2 text-muted small">辨識到之車輛號牌為：</div>
                    <div class="my-3 py-2 px-3 bg-light rounded border border-primary border-2">
                        <span class="fs-2 fw-bold text-primary font-monospace">${escapeHtml(candidatePlate)}</span>
                    </div>
                    <div class="small text-muted mb-1">若辨識字元需微調，可直接於下方修改：</div>
                    <input type="text" id="swalEditPlate" class="form-control text-center font-monospace fw-bold" 
                           value="${escapeHtml(candidatePlate)}" maxlength="10" style="letter-spacing: 2px; font-size: 1.25rem;" />
                `,
                showCancelButton: true,
                confirmButtonText: '<i class="bi bi-shield-check me-1"></i>確認查驗',
                confirmButtonColor: '#1A56DB',
                cancelButtonText: '重新拍攝',
                didOpen: function () {
                    $('#swalEditPlate').focus().select();
                    $('#swalEditPlate').on('keypress', function (e) {
                        if (e.which === 13) {
                            Swal.clickConfirm();
                        }
                    });
                },
                preConfirm: function () {
                    var val = $('#swalEditPlate').val().trim().toUpperCase();
                    if (!val) {
                        Swal.showValidationMessage('車牌號碼不可為空！');
                        return false;
                    }
                    return val;
                }
            }).then(function (res) {
                if (res.isConfirmed && res.value) {
                    var finalPlate = res.value;
                    $('#txtCheckPlate').val(finalPlate);
                    var zoneId = parseInt($('#ddlCurrentZone').val());
                    uploadAndVerify(capturedPhotoBase64, zoneId, finalPlate);
                }
            });
        } else {
            // 未能直接解析出明確車牌格式時，照片已妥善存證，提供純淨空白輸入框供巡檢員確認輸入
            Swal.fire({
                icon: 'info',
                title: '照片取格存證完成',
                html: `
                    <div class="mb-2 text-muted small">未能自動辨識出清晰車牌，請輸入車牌號碼進行查驗：</div>
                    <input type="text" id="swalEditPlate" class="form-control text-center font-monospace fw-bold my-2" 
                           placeholder="例如: ABC-1234" maxlength="10" style="letter-spacing: 2px; font-size: 1.25rem;" />
                `,
                showCancelButton: true,
                confirmButtonText: '<i class="bi bi-search me-1"></i>立即查驗',
                confirmButtonColor: '#1A56DB',
                cancelButtonText: '重新拍攝',
                didOpen: function () {
                    $('#swalEditPlate').focus();
                    $('#swalEditPlate').on('keypress', function (e) {
                        if (e.which === 13) {
                            Swal.clickConfirm();
                        }
                    });
                },
                preConfirm: function () {
                    var val = $('#swalEditPlate').val().trim().toUpperCase();
                    if (!val) {
                        Swal.showValidationMessage('請輸入車牌號碼！');
                        return false;
                    }
                    return val;
                }
            }).then(function (res) {
                if (res.isConfirmed && res.value) {
                    var finalPlate = res.value;
                    $('#txtCheckPlate').val(finalPlate);
                    var zoneId = parseInt($('#ddlCurrentZone').val());
                    uploadAndVerify(capturedPhotoBase64, zoneId, finalPlate);
                }
            });
        }
    }

    // 上傳存證照片並執行車籍授權比對
    function uploadAndVerify(base64, zoneId, plate) {
        Swal.fire({
            title: '車籍資格查核中...',
            html: '<div class="spinner-border text-primary my-2" role="status"></div><div class="small text-muted mt-2">比對院區授權停車主檔中...</div>',
            allowOutsideClick: false,
            showConfirmButton: false
        });

        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/RecognizeAndVerify",
            data: JSON.stringify({
                base64Image: base64,
                currentZoneId: zoneId,
                manualPlateHint: plate
            }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                Swal.close();
                renderResultCard(res.d);
                $('#txtCheckPlate').val(res.d.Plate);
                loadRecentLogs();
            },
            error: function (xhr, status, error) {
                Swal.close();
                Swal.fire('連線逾時', '伺服器或資料庫連線逾時，請確認網路連線正常。', 'error');
            }
        });
    }

    function executeVerification(plate, zoneId, photoPath) {
        Swal.fire({
            title: '查核中...',
            allowOutsideClick: false,
            didOpen: () => { Swal.showLoading(); }
        });

        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/VerifyLicensePlate",
            data: JSON.stringify({ plate: plate, currentZoneId: zoneId, photoRef: photoPath }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                Swal.close();
                renderResultCard(res.d);
                loadRecentLogs();
            },
            error: function () {
                Swal.close();
                Swal.fire('查驗失敗', '資料庫連線超時，請檢查連線狀態。', 'error');
            }
        });
    }

    function renderResultCard(data) {
        lastVerifiedPlate = data.Plate;
        lastResultStatus = data.Status;

        var cardClass = "verify-card-valid";
        var badgeHtml = '<span class="badge bg-white text-success fs-6"><i class="bi bi-check-circle-fill me-1"></i>合格 - 准予停放</span>';
        var actionButtonsHtml = '';

        if (data.Status === 'WRONG_ZONE') {
            cardClass = "verify-card-wrong";
            badgeHtml = '<span class="badge bg-white text-warning fs-6"><i class="bi bi-exclamation-triangle-fill me-1"></i>違規 - 跨區停放</span>';
            actionButtonsHtml = `
                <div class="mt-3 pt-3 border-top border-warning border-opacity-25 d-flex gap-2">
                    <button type="button" class="btn btn-warning flex-grow-1 fw-bold text-dark" onclick="openViolationModal('跨區停放');">
                        <i class="bi bi-camera me-1"></i>登記跨區違規並拍照
                    </button>
                    <button type="button" class="btn btn-outline-dark" onclick="notifyMoveCar('${data.Plate}');">
                        <i class="bi bi-megaphone me-1"></i>通報移車
                    </button>
                </div>`;
        } else if (data.Status === 'EXPIRED') {
            cardClass = "verify-card-expired";
            badgeHtml = '<span class="badge bg-white text-danger fs-6"><i class="bi bi-x-octagon-fill me-1"></i>違規 - 證件已過期</span>';
            actionButtonsHtml = `
                <div class="mt-3 pt-3 border-top border-danger border-opacity-25 d-flex gap-2">
                    <button type="button" class="btn btn-danger flex-grow-1 fw-bold" onclick="openViolationModal('證件逾期停放');">
                        <i class="bi bi-file-earmark-text me-1"></i>登記開立逾期勸導單
                    </button>
                </div>`;
        } else if (data.Status === 'NOT_FOUND') {
            cardClass = "verify-card-unknown";
            badgeHtml = '<span class="badge bg-white text-dark fs-6"><i class="bi bi-question-diamond-fill me-1"></i>警告 - 無通行證紀錄</span>';
            actionButtonsHtml = `
                <div class="mt-3 pt-3 border-top border-secondary border-opacity-25 d-flex gap-2">
                    <button type="button" class="btn btn-dark flex-grow-1" onclick="openViolationModal('無通行證外來車輛');">
                        <i class="bi bi-camera me-1"></i>現場拍照留存通報
                    </button>
                </div>`;
        }

        var html = `
            <div class="card verify-card ${cardClass}">
                <div class="verify-header p-3 d-flex justify-content-between align-items-center">
                    <span class="font-monospace fs-3 fw-bold">${data.Plate}</span>
                    ${badgeHtml}
                </div>
                <div class="card-body p-3">
                    <div class="row g-2 small mb-2">
                        <div class="col-6"><strong>車主姓名：</strong>${data.OwnerName || '<span class="text-muted">未登記</span>'}</div>
                        <div class="col-6"><strong>所屬科室：</strong>${data.DeptName || '<span class="text-muted">未登記</span>'}</div>
                        <div class="col-12">
                            <strong>授權停放區域：</strong>
                            ${data.PermittedZoneName ? `<span class="badge bg-primary">${data.PermittedZoneName}</span>` : '<span class="text-muted">無授權分區</span>'}
                            <small class="text-muted ms-1">(目前所在: ${data.CurrentZoneName})</small>
                        </div>
                        <div class="col-6"><strong>有效到期日：</strong>${data.ExpireDate || '--'}</div>
                        <div class="col-6"><strong>車輛廠牌顏色：</strong>${data.VehicleBrand || '--'} / ${data.VehicleColor || '--'}</div>
                        <div class="col-6"><strong>門禁卡號：</strong>${data.CardNumber || '--'}</div>
                        <div class="col-6"><strong>RFID 感應卡：</strong>${data.SensorTagNumber || '--'}</div>
                    </div>

                    <div class="alert alert-light border small mb-0 py-2">
                        <strong>判定依據：</strong>${data.Message}
                    </div>

                    ${actionButtonsHtml}
                </div>
            </div>`;

        $('#checkResultContainer').html(html).show();
    }

    function openViolationModal(type) {
        $('#txtViolatePlate').val(lastVerifiedPlate);
        $('#txtViolateType').val(type);
        $('#txtViolateRemark').val('');
        $('#modalRecordViolation').modal('show');
    }

    function submitViolationRecord() {
        var plate = $('#txtViolatePlate').val();
        var type = $('#txtViolateType').val();
        var remark = $('#txtViolateRemark').val().trim();
        var zoneId = parseInt($('#ddlCurrentZone').val());

        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/RecordViolation",
            data: JSON.stringify({ plate: plate, zoneId: zoneId, violationType: type, remark: remark }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                if (res.d.Success) {
                    $('#modalRecordViolation').modal('hide');
                    Swal.fire('舉證完成', '違規稽核紀錄已寫入系統資料庫！', 'success');
                    loadRecentLogs();
                } else {
                    Swal.fire('失敗', res.d.Message, 'error');
                }
            }
        });
    }

    function notifyMoveCar(plate) {
        Swal.fire({
            title: '通報移車通知',
            text: `已向車主發送院內簡訊/推播通知，請車主儘速將車輛 【${plate}】 移至正確之核准停車區域。`,
            icon: 'info',
            confirmButtonText: '確定'
        });
    }

    function loadRecentLogs() {
        var zoneVal = $('#ddlCurrentZone').val();
        if (!zoneVal) {
            $('#recentLogsContainer').html('<div class="text-center py-2 text-muted">目前尚未選擇巡檢分區或尚未建立場域</div>');
            return;
        }
        var zoneId = parseInt(zoneVal);
        if (isNaN(zoneId) || zoneId <= 0) {
            $('#recentLogsContainer').html('<div class="text-center py-2 text-muted">目前尚未選擇巡檢分區</div>');
            return;
        }
        $.ajax({
            type: "POST",
            url: "Mobile_Check.aspx/GetRecentLogs",
            data: JSON.stringify({ zoneId: zoneId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var logs = res.d || [];
                if (logs.length === 0) {
                    $('#recentLogsContainer').html('<div class="text-center py-2 text-muted">今日尚無巡檢紀錄</div>');
                    return;
                }
                var html = '';
                logs.forEach(l => {
                    var badge = '<span class="badge bg-success">合格</span>';
                    if (l.ResultStatus === 'WRONG_ZONE') badge = '<span class="badge bg-warning text-dark">跨區</span>';
                    else if (l.ResultStatus === 'EXPIRED') badge = '<span class="badge bg-danger">過期</span>';
                    else if (l.ResultStatus === 'NOT_FOUND') badge = '<span class="badge bg-dark">未登記</span>';

                    html += `
                        <div class="d-flex justify-content-between align-items-center p-2 rounded bg-light border-bottom">
                            <div>
                                <span class="font-monospace fw-bold me-1">${l.PlateScanned}</span>
                                <small class="text-muted">${l.OwnerName || ''}</small>
                                <small class="d-block text-muted" style="font-size:0.75rem;">${l.InspectTime}</small>
                            </div>
                            <div class="text-end">
                                ${badge}
                            </div>
                        </div>`;
                });
                $('#recentLogsContainer').html(html);
            },
            error: function () {
                $('#recentLogsContainer').html('<div class="text-center py-2 text-muted">讀取紀錄失敗</div>');
            }
        });
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
