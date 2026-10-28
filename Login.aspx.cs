using System;
using System.IO;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Login : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // 處理登出請求
            if (Request.QueryString["action"] == "logout")
            {
                Session.Remove("AdminUser");
                Session.Clear();
                Session.Abandon();
                Response.Redirect("~/Login.aspx?loggedout=1");
                return;
            }

            // 若已登入且造訪登入頁，直接導向管理看板
            if (!IsPostBack)
            {
                if (Session["AdminUser"] != null)
                {
                    string returnUrl = Request.QueryString["returnUrl"];
                    if (!string.IsNullOrWhiteSpace(returnUrl) && !returnUrl.Contains("Login.aspx"))
                    {
                        Response.Redirect(returnUrl);
                    }
                    else
                    {
                        Response.Redirect("~/Admin_Dashboard.aspx");
                    }
                }
            }
        }

        [WebMethod]
        public static OperationResult DoLogin(string username, string password, string returnUrl)
        {
            var authService = new AuthService();
            var result = authService.Authenticate(username, password);

            if (result.Success && result.Data != null)
            {
                var adminUser = result.Data as AdminUserDto;
                if (adminUser != null)
                {
                    // 登入成功寫入 Session
                    HttpContext.Current.Session["AdminUser"] = adminUser;

                    string targetUrl = "Admin_Dashboard.aspx";
                    if (!string.IsNullOrWhiteSpace(returnUrl) && !returnUrl.Contains("Login.aspx"))
                    {
                        targetUrl = returnUrl;
                    }

                    return OperationResult.Ok(result.Message, targetUrl);
                }
            }

            return result;
        }
    }
}
