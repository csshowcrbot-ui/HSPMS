using System;
using System.Web.UI;

namespace HospitalParking
{
    public partial class DefaultPage : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // 預設以員工申請專區為主，已登入管理員才轉導至後台戰情看板
            if (Session["AdminUser"] != null)
            {
                Response.Redirect("~/Admin_Dashboard.aspx");
            }
            else
            {
                Response.Redirect("~/Employee_Portal.aspx");
            }
        }
    }
}
