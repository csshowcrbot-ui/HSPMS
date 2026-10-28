using System;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Admin_Dashboard : Page
    {
        private static readonly ZoneService zoneService = new ZoneService();

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        public string RenderZoneFilterOptions()
        {
            var zones = zoneService.GetActiveZoneOptions();
            var sb = new System.Text.StringBuilder();
            sb.Append("<option value=\"\">全部停車區域 (總覽)</option>");
            if (zones != null)
            {
                foreach (var z in zones)
                {
                    sb.AppendFormat("<option value=\"{0}\">{1}</option>", z.ZoneID, System.Web.HttpUtility.HtmlEncode(z.ZoneName));
                }
            }
            return sb.ToString();
        }

        [WebMethod]
        public static DashboardSummaryDto GetDashboardData(int? zoneFilter)
        {
            var service = new DashboardService();
            return service.GetDashboardSummary(zoneFilter);
        }

        private static string GetCurrentReviewerName()
        {
            var session = System.Web.HttpContext.Current != null ? System.Web.HttpContext.Current.Session : null;
            if (session != null && session["AdminUser"] != null)
            {
                var admin = session["AdminUser"] as AdminUserDto;
                if (admin != null && !string.IsNullOrWhiteSpace(admin.DisplayName))
                {
                    return admin.DisplayName;
                }
            }
            return "總務行政處 陳專員";
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult ReviewAccept(int applicationId, int? assignedZoneId, string remarks)
        {
            var service = new ApplicationWorkflowService();
            return service.AcceptApplication(applicationId, assignedZoneId, remarks, GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult ReviewWaitlist(int applicationId, int? assignedZoneId, string remarks)
        {
            var service = new ApplicationWorkflowService();
            return service.WaitlistApplication(applicationId, assignedZoneId, remarks, GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult ReviewReadyPickup(int applicationId, int? assignedZoneId, string remarks)
        {
            var service = new ApplicationWorkflowService();
            return service.MarkReadyPickup(applicationId, assignedZoneId, remarks, GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult ReviewIssuePermit(int applicationId, int? assignedZoneId, string sensorTag, string remoteNo, string expireDate, string remarks)
        {
            var service = new ApplicationWorkflowService();
            DateTime? exp = null;
            DateTime parsedExp;
            if (DateTime.TryParse(expireDate, out parsedExp))
            {
                exp = parsedExp;
            }
            return service.IssuePermit(applicationId, assignedZoneId, sensorTag, remoteNo, exp, remarks, GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult UpdateAssignedZone(int applicationId, int zoneId)
        {
            var service = new ApplicationWorkflowService();
            return service.UpdateAssignedZone(applicationId, zoneId, GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult QuickApprove(int applicationId)
        {
            var service = new ApplicationWorkflowService();
            return service.MarkReadyPickup(applicationId, "線上審核核准待領證", GetCurrentReviewerName());
        }

        [WebMethod(EnableSession = true)]
        public static OperationResult QuickReject(int applicationId, string reason)
        {
            var service = new ApplicationWorkflowService();
            return service.RejectApplication(applicationId, reason, GetCurrentReviewerName());
        }

        [WebMethod]
        public static System.Collections.Generic.List<ApplicationDto> GetFilteredApplications(string status, string keyword)
        {
            var service = new ApplicationWorkflowService();
            return service.GetApplications(status, keyword);
        }

        [WebMethod]
        public static DeptDrilldownDto GetDeptPermitsDetail(string deptName)
        {
            var service = new DashboardService();
            return service.GetDeptPermitsDetail(deptName);
        }

        [WebMethod]
        public static ZoneDrilldownDto GetZonePermitsDetail(int zoneId)
        {
            var service = new DashboardService();
            return service.GetZonePermitsDetail(zoneId);
        }

        [WebMethod]
        public static InspectionDrilldownDto GetInspectionLogsDetail(string resultStatus, int? zoneFilter)
        {
            var service = new DashboardService();
            return service.GetInspectionLogsDetail(resultStatus, zoneFilter);
        }

        [WebMethod]
        public static System.Collections.Generic.List<PermitItemDto> GetExpiringPermitsDetail(int? zoneFilter)
        {
            var service = new DashboardService();
            return service.GetExpiringPermitsDetail(zoneFilter);
        }
    }
}
