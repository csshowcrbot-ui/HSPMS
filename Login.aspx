<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="HospitalParking.Login" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>管理主控台登入 - 醫療院區智慧停車場管理系統 (HSPMS)</title>
    
    <!-- Bootstrap 5.3 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet" />
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet" />

    <style>
        :root {
            --hsp-primary: #1A56DB;
            --hsp-dark: #0B192C;
            --hsp-accent: #0E9F6E;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #0B192C 0%, #1E3A8A 50%, #1A56DB 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            position: relative;
            overflow-x: hidden;
        }
        /* 背景科技光斑裝飾 */
        .bg-glow-1 {
            position: absolute;
            width: 450px;
            height: 450px;
            background: radial-gradient(circle, rgba(30, 64, 175, 0.45) 0%, rgba(11, 25, 44, 0) 70%);
            top: -100px;
            left: -100px;
            border-radius: 50%;
            z-index: 1;
            pointer-events: none;
        }
        .bg-glow-2 {
            position: absolute;
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, rgba(14, 159, 110, 0.25) 0%, rgba(11, 25, 44, 0) 70%);
            bottom: -150px;
            right: -100px;
            border-radius: 50%;
            z-index: 1;
            pointer-events: none;
        }
        .login-card {
            position: relative;
            z-index: 10;
            background: #FFFFFF;
            border-radius: 20px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.45), 0 0 0 1px rgba(255, 255, 255, 0.1);
            max-width: 460px;
            width: 100%;
            overflow: hidden;
        }
        .login-header {
            background: linear-gradient(135deg, #1A56DB 0%, #1E40AF 100%);
            padding: 2.25rem 2rem 1.75rem;
            color: #FFFFFF;
            text-align: center;
            position: relative;
        }
        .login-body {
            padding: 2rem 2.25rem 2.25rem;
        }
        .brand-icon-box {
            width: 58px;
            height: 58px;
            background: #FFFFFF;
            color: #1A56DB;
            border-radius: 16px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1rem;
            box-shadow: 0 8px 16px rgba(0,0,0,0.15);
        }
        .form-floating > .form-control:focus ~ label,
        .form-floating > .form-control:not(:placeholder-shown) ~ label {
            color: var(--hsp-primary);
        }
        .btn-login {
            background: linear-gradient(135deg, #1A56DB 0%, #1E40AF 100%);
            color: #FFFFFF;
            font-weight: 600;
            padding: 0.85rem;
            border-radius: 10px;
            border: none;
            transition: all 0.2s;
            box-shadow: 0 4px 12px rgba(26, 86, 219, 0.35);
        }
        .btn-login:hover {
            background: linear-gradient(135deg, #1E40AF 0%, #172554 100%);
            color: #FFFFFF;
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(26, 86, 219, 0.45);
        }
    </style>
</head>
<body>
    <div class="bg-glow-1"></div>
    <div class="bg-glow-2"></div>

    <div class="login-card animate-fade-in">
        <!-- 頂部品牌 Banner -->
        <div class="login-header">
            <div class="brand-icon-box">
                <i class="bi bi-shield-lock-fill fs-2"></i>
            </div>
            <h4 class="fw-bold mb-1">醫療院區車輛管理系統</h4>
            <div class="small opacity-75 mb-2">HSPMS Executive Administration Portal</div>
            <span class="badge bg-white bg-opacity-20 text-white rounded-pill px-3 py-1 font-monospace small">
                <i class="bi bi-person-fill-lock me-1"></i>總務管理單位主控台身分驗證
            </span>
        </div>

        <!-- 登入表單主體 -->
        <div class="login-body">
            <form id="frmLogin" onsubmit="return false;">
                <!-- 帳號輸入框 -->
                <div class="mb-3">
                    <label class="form-label fw-bold text-dark small">
                        <i class="bi bi-person-circle text-primary me-1"></i>管理員帳號 (Username)：
                    </label>
                    <div class="input-group">
                        <span class="input-group-text bg-light border-end-0 text-muted">
                            <i class="bi bi-person"></i>
                        </span>
                        <input type="text" id="txtUsername" class="form-control border-start-0 ps-0" placeholder="請輸入管理員帳號 (例: admin)" autocomplete="username" />
                    </div>
                </div>

                <!-- 密碼輸入框 -->
                <div class="mb-4">
                    <label class="form-label fw-bold text-dark small d-flex justify-content-between align-items-center">
                        <span><i class="bi bi-key-fill text-primary me-1"></i>管理密碼 (Password)：</span>
                    </label>
                    <div class="input-group">
                        <span class="input-group-text bg-light border-end-0 text-muted">
                            <i class="bi bi-lock"></i>
                        </span>
                        <input type="password" id="txtPassword" class="form-control border-start-0 border-end-0 ps-0" placeholder="請輸入管理密碼" autocomplete="current-password" />
                        <button type="button" class="btn btn-outline-secondary border-start-0" id="btnTogglePassword" onclick="togglePasswordVisibility();" title="切換密碼顯示">
                            <i class="bi bi-eye" id="iconEye"></i>
                        </button>
                    </div>
                </div>

                <!-- 登入按鈕 -->
                <button type="button" class="btn btn-login w-100 d-flex align-items-center justify-content-center" id="btnLogin" onclick="performLogin();">
                    <span id="btnText"><i class="bi bi-box-arrow-in-right me-2 fs-5"></i>登入管理主控台</span>
                    <span id="btnSpinner" class="spinner-border spinner-border-sm ms-2 d-none" role="status"></span>
                </button>
            </form>

            <!-- 返回員工申請專區 -->
            <div class="mt-4 pt-3 border-top text-center">
                <a href="Employee_Portal.aspx" class="text-decoration-none small text-muted d-inline-flex align-items-center">
                    <i class="bi bi-arrow-left-circle me-1 text-primary"></i>
                    <span>非管理人員？返回【員工停車證自助申辦專區】</span>
                </a>
            </div>
        </div>
    </div>

    <!-- 頁尾版權 -->
    <div class="position-absolute bottom-0 text-white-50 small mb-3 text-center w-100" style="z-index: 10;">
        醫療院區智慧停車場管理系統 (HSPMS) &copy; <%= DateTime.Now.Year %> 總務處車籍管理中心. All rights reserved.
    </div>

    <!-- jQuery 3.7.1 -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <script>
        $(document).ready(function () {
            // 檢查是否為登出後跳轉
            var urlParams = new URLSearchParams(window.location.search);
            if (urlParams.get('loggedout') === '1') {
                Swal.fire({
                    icon: 'success',
                    title: '已安全登出',
                    text: '您已成功登出管理系統，如需使用請重新登入。',
                    timer: 2000,
                    showConfirmButton: false
                });
            }

            // 預設將游標置於帳號輸入框
            $('#txtUsername').focus();

            // 支援鍵盤 Enter 觸發登入
            $('#txtUsername, #txtPassword').on('keypress', function (e) {
                if (e.which === 13) {
                    performLogin();
                }
            });
        });

        // 切換密碼顯示/隱藏
        function togglePasswordVisibility() {
            var pwdInput = document.getElementById('txtPassword');
            var eyeIcon = document.getElementById('iconEye');
            if (pwdInput.type === 'password') {
                pwdInput.type = 'text';
                eyeIcon.className = 'bi bi-eye-slash text-primary';
            } else {
                pwdInput.type = 'password';
                eyeIcon.className = 'bi bi-eye';
            }
        }

        // 執行登入身分驗證
        function performLogin() {
            var username = $('#txtUsername').val().trim();
            var password = $('#txtPassword').val().trim();

            if (!username) {
                Swal.fire({
                    icon: 'warning',
                    title: '請輸入帳號',
                    text: '請輸入管理員登入帳號！',
                    confirmButtonColor: '#1A56DB'
                });
                $('#txtUsername').focus();
                return;
            }

            if (!password) {
                Swal.fire({
                    icon: 'warning',
                    title: '請輸入密碼',
                    text: '請輸入管理員登入密碼！',
                    confirmButtonColor: '#1A56DB'
                });
                $('#txtPassword').focus();
                return;
            }

            // 取得 URL 中的 returnUrl 參數
            var urlParams = new URLSearchParams(window.location.search);
            var returnUrl = urlParams.get('returnUrl') || 'Admin_Dashboard.aspx';

            // 視覺狀態切換 (載入中)
            $('#btnLogin').prop('disabled', true);
            $('#btnText').text('身分驗證中...');
            $('#btnSpinner').removeClass('d-none');

            $.ajax({
                type: "POST",
                url: "Login.aspx/DoLogin",
                data: JSON.stringify({
                    username: username,
                    password: password,
                    returnUrl: returnUrl
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var r = res.d;
                    if (r.Success) {
                        Swal.fire({
                            icon: 'success',
                            title: '登入成功',
                            text: r.Message,
                            showConfirmButton: false,
                            timer: 1000
                        }).then(function () {
                            window.location.href = r.Data || returnUrl;
                        });
                    } else {
                        $('#btnLogin').prop('disabled', false);
                        $('#btnText').html('<i class="bi bi-box-arrow-in-right me-2 fs-5"></i>登入管理主控台');
                        $('#btnSpinner').addClass('d-none');
                        Swal.fire({
                            icon: 'error',
                            title: '驗證失敗',
                            text: r.Message,
                            confirmButtonColor: '#1A56DB'
                        });
                        $('#txtPassword').focus();
                    }
                },
                error: function () {
                    $('#btnLogin').prop('disabled', false);
                    $('#btnText').html('<i class="bi bi-box-arrow-in-right me-2 fs-5"></i>登入管理主控台');
                    $('#btnSpinner').addClass('d-none');
                    Swal.fire({
                        icon: 'error',
                        title: '通訊異常',
                        text: '無法連線至身分驗證服務，請確認伺服器運作正常！',
                        confirmButtonColor: '#1A56DB'
                    });
                }
            });
        }
    </script>
</body>
</html>
