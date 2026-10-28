using System;
using System.Collections.Generic;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Employee_Portal : Page
    {
        private static readonly ApplicationWorkflowService workflowService = new ApplicationWorkflowService();
        private static readonly PermitService permitService = new PermitService();

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static LookupDataDto GetLookupOptions()
        {
            return permitService.GetLookupOptions();
        }

        [WebMethod]
        public static OperationResult SubmitApplication(ApplicationDto dto)
        {
            return workflowService.SubmitApplication(dto);
        }

        [WebMethod]
        public static List<ApplicationDto> SearchApplications(string query)
        {
            return workflowService.SearchEmployeeApplications(query);
        }
    }
}
