using System;
using System.IO;
using System.Web.UI;

namespace HospitalParking
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Init(object sender, EventArgs e)
        {
            // 檢查是否為管理員專屬頁面
            string currentPath = Request.AppRelativeCurrentExecutionFilePath ?? "";
            string currentFile = Path.GetFileNameWithoutExtension(currentPath);

            // 若非員工申請專區，且非登入頁面，則強制需要管理員身分
            bool isPublicPage = string.Equals(currentFile, "Employee_Portal", StringComparison.OrdinalIgnoreCase) ||
                                string.Equals(currentFile, "Login", StringComparison.OrdinalIgnoreCase) ||
                                string.Equals(currentFile, "Default", StringComparison.OrdinalIgnoreCase);

            if (!isPublicPage)
            {
                if (Session["AdminUser"] == null)
                {
                    // 未登入管理員，強制導向至登入畫面並保留原始請求路徑
                    string returnUrl = Request.RawUrl;
                    Response.Redirect("~/Login.aspx?returnUrl=" + Server.UrlEncode(returnUrl));
                }
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        public string IsActivePage(string pageName)
        {
            string currentPath = Request.AppRelativeCurrentExecutionFilePath ?? "";
            string currentFile = Path.GetFileNameWithoutExtension(currentPath);
            if (string.Equals(currentFile, pageName, StringComparison.OrdinalIgnoreCase))
            {
                return "active";
            }
            return "";
        }

        public bool IsEmployeePortal
        {
            get
            {
                string currentPath = Request.AppRelativeCurrentExecutionFilePath ?? "";
                string currentFile = Path.GetFileNameWithoutExtension(currentPath);
                return string.Equals(currentFile, "Employee_Portal", StringComparison.OrdinalIgnoreCase);
            }
        }

        public HospitalParking.DTOs.AdminUserDto CurrentAdmin
        {
            get
            {
                return Session["AdminUser"] as HospitalParking.DTOs.AdminUserDto;
            }
        }

        public string CurrentAdminName
        {
            get
            {
                return CurrentAdmin != null ? CurrentAdmin.DisplayName : "陳專員 (總務管理員)";
            }
        }

        public string CurrentAdminRoleName
        {
            get
            {
                return CurrentAdmin != null ? CurrentAdmin.RoleName : "總務行政主管";
            }
        }
    }
}
