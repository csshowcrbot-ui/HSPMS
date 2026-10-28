using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Admin_Management : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static AdminUserOverviewDto GetOverview(string keyword, string roleFilter, string statusFilter)
        {
            var service = new AdminUserService();
            return service.GetAdminUserOverview(keyword, roleFilter, statusFilter);
        }

        [WebMethod]
        public static AdminUserManageDto GetUser(int adminId)
        {
            var service = new AdminUserService();
            return service.GetAdminUserById(adminId);
        }

        [WebMethod]
        public static OperationResult SaveUser(AdminUserManageDto dto)
        {
            var service = new AdminUserService();
            return service.SaveAdminUser(dto);
        }

        [WebMethod]
        public static OperationResult ToggleStatus(int adminId, bool targetStatus)
        {
            var service = new AdminUserService();
            string currentOperator = GetCurrentOperatorUsername();
            return service.ToggleStatus(adminId, targetStatus, currentOperator);
        }

        [WebMethod]
        public static OperationResult ResetPassword(int adminId, string newPassword)
        {
            var service = new AdminUserService();
            return service.ResetPassword(adminId, newPassword);
        }

        [WebMethod]
        public static OperationResult DeleteUser(int adminId)
        {
            var service = new AdminUserService();
            string currentOperator = GetCurrentOperatorUsername();
            return service.DeleteAdminUser(adminId, currentOperator);
        }

        [WebMethod]
        public static List<string> GetDeptOptions()
        {
            var deptService = new DepartmentService();
            var overview = deptService.GetDepartmentOverview();
            var depts = new List<string> { "總務行政處", "安全警衛課", "資訊室", "工務室" };
            if (overview != null && overview.DeptList != null)
            {
                foreach (var d in overview.DeptList)
                {
                    if (!depts.Contains(d.DeptName))
                    {
                        depts.Add(d.DeptName);
                    }
                }
            }
            return depts;
        }

        private static string GetCurrentOperatorUsername()
        {
            if (HttpContext.Current != null && HttpContext.Current.Session != null)
            {
                var admin = HttpContext.Current.Session["AdminUser"] as AdminUserDto;
                if (admin != null) return admin.Username;
            }
            return "admin";
        }
    }
}
