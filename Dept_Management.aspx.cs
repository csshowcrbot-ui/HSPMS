using System;
using System.Collections.Generic;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Dept_Management : Page
    {
        private static readonly DepartmentService deptService = new DepartmentService();

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static DepartmentOverviewDto GetDepartmentOverview()
        {
            return deptService.GetDepartmentOverview();
        }

        [WebMethod]
        public static DepartmentManageDto GetDepartmentDetail(int deptId)
        {
            return deptService.GetDepartmentById(deptId);
        }

        [WebMethod]
        public static OperationResult SaveDepartment(DepartmentManageDto dto)
        {
            return deptService.SaveDepartment(dto);
        }

        [WebMethod]
        public static OperationResult ToggleDepartmentStatus(int deptId, bool targetStatus)
        {
            return deptService.ToggleStatus(deptId, targetStatus);
        }

        [WebMethod]
        public static OperationResult DeleteDepartment(int deptId)
        {
            return deptService.DeleteDepartment(deptId);
        }

        [WebMethod]
        public static List<DepartmentPermitItemDto> GetDepartmentPermits(int deptId)
        {
            return deptService.GetDepartmentPermits(deptId);
        }
    }
}
