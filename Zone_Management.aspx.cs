using System;
using System.Collections.Generic;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Zone_Management : Page
    {
        private static readonly ZoneService zoneService = new ZoneService();

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static ZoneOverviewSummaryDto GetZoneOverview()
        {
            return zoneService.GetZoneOverviewSummary();
        }

        [WebMethod]
        public static ZoneManageDto GetZoneDetail(int zoneId)
        {
            return zoneService.GetZoneById(zoneId);
        }

        [WebMethod]
        public static OperationResult SaveZone(ZoneManageDto dto)
        {
            return zoneService.SaveZone(dto);
        }

        [WebMethod]
        public static OperationResult ToggleZoneStatus(int zoneId, bool targetStatus)
        {
            return zoneService.ToggleStatus(zoneId, targetStatus);
        }

        [WebMethod]
        public static OperationResult DeleteZone(int zoneId)
        {
            return zoneService.DeleteZone(zoneId);
        }
    }
}
