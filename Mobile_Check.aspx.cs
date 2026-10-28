using System;
using System.Collections.Generic;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Mobile_Check : Page
    {
        private static readonly InspectionService inspectionService = new InspectionService();
        private static readonly ZoneService zoneService = new ZoneService();

        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
        }

        public string RenderZoneOptions()
        {
            var zones = zoneService.GetActiveZoneOptions();
            if (zones == null || zones.Count == 0)
            {
                return "<option value=\"\">-- 資料表目前無啟用中之停車分區 (請先至場域維護建立) --</option>";
            }
            var sb = new System.Text.StringBuilder();
            foreach (var z in zones)
            {
                sb.AppendFormat("<option value=\"{0}\">{1}</option>", z.ZoneID, System.Web.HttpUtility.HtmlEncode(z.ZoneName));
            }
            return sb.ToString();
        }

        [WebMethod]
        public static List<ZoneItem> GetActiveZones()
        {
            return zoneService.GetActiveZoneOptions();
        }

        [WebMethod]
        public static VerificationResultDto VerifyLicensePlate(string plate, int currentZoneId, string photoRef)
        {
            return inspectionService.VerifyLicensePlate(plate, currentZoneId, photoRef);
        }

        [WebMethod]
        public static VerificationResultDto RecognizeAndVerify(string base64Image, int currentZoneId, string manualPlateHint)
        {
            return inspectionService.RecognizeAndVerify(base64Image, currentZoneId, manualPlateHint);
        }

        [WebMethod]
        public static string RecognizePlateOnly(string base64Image)
        {
            return inspectionService.RecognizePlateFromBase64(base64Image) ?? "";
        }

        [WebMethod]
        public static List<InspectionLogDto> GetRecentLogs(int zoneId)
        {
            return inspectionService.GetRecentInspectionLogs(zoneId, 10);
        }

        [WebMethod]
        public static OperationResult RecordViolation(string plate, int zoneId, string violationType, string remark)
        {
            try
            {
                inspectionService.LogInspection(null, plate, zoneId, "WRONG_ZONE", null, string.Format("【舉證登錄: {0}】{1}", violationType, remark), "SEC_DUTY01");
                return OperationResult.Ok("舉證紀錄登錄成功！");
            }
            catch (Exception ex)
            {
                return OperationResult.Fail("登錄異常：" + ex.Message);
            }
        }
    }
}
