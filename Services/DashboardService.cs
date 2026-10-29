using System;
using System.Collections.Generic;
using System.Data;
using Npgsql;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    public class DashboardService
    {
        public DashboardSummaryDto GetDashboardSummary(int? zoneFilter = null)
        {
            var summary = new DashboardSummaryDto();

            // 1. KPI 統計卡片
            string sqlValid = "SELECT COUNT(1) FROM ParkingPermits WHERE Status = 'ACTIVE'";
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                sqlValid += " AND ZoneID = " + zoneFilter.Value;
            }
            summary.ValidPermitCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlValid));

            string sqlPending = "SELECT COUNT(1) FROM ParkingEmployeeApplications WHERE ReviewStatus IN ('PENDING', 'PROCESSING', 'WAITLIST', 'APPROVED')";
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                sqlPending += " AND PreferredZoneID = " + zoneFilter.Value;
            }
            summary.PendingAppCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlPending));

            string sqlExpiring = @"
                SELECT COUNT(1) FROM ParkingPermits 
                WHERE Status = 'ACTIVE' 
                  AND ExpireDate >= CURRENT_DATE 
                  AND ExpireDate <= (CURRENT_DATE + INTERVAL '30 days')";
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                sqlExpiring += " AND ZoneID = " + zoneFilter.Value;
            }
            summary.ExpiringSoonCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlExpiring));

            string sqlInspectToday = @"
                SELECT COUNT(1) FROM ParkingInspectionLogs 
                WHERE CAST(InspectTime AS DATE) = CURRENT_DATE";
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                sqlInspectToday += " AND ZoneID = " + zoneFilter.Value;
            }
            summary.TodayInspectionCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlInspectToday));

            // 2. 各停車區域容量飽和度
            string sqlZones = @"
                SELECT z.ZoneID, z.ZoneCode, z.ZoneName, z.TotalCapacity, z.WarningThresholdPct,
                       (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID AND p.Status = 'ACTIVE') AS OccupiedCount
                FROM ParkingZones z
                WHERE z.IsActive = TRUE
                ORDER BY z.ZoneCode";

            var dtZones = DbHelper.ExecuteDataTable(sqlZones);
            foreach (DataRow row in dtZones.Rows)
            {
                int cap = Convert.ToInt32(row["TotalCapacity"]);
                int occ = Convert.ToInt32(row["OccupiedCount"]);
                int warnPct = Convert.ToInt32(row["WarningThresholdPct"]);
                int pct = cap > 0 ? (int)Math.Round((double)occ * 100 / cap) : 0;

                summary.ZoneCapacities.Add(new ZoneCapacityDto
                {
                    ZoneID = Convert.ToInt32(row["ZoneID"]),
                    ZoneCode = row["ZoneCode"].ToString(),
                    ZoneName = row["ZoneName"].ToString(),
                    TotalCapacity = cap,
                    OccupiedCount = occ,
                    OccupancyPct = pct,
                    WarningThresholdPct = warnPct,
                    IsWarning = pct >= warnPct
                });
            }

            // 3. 部門車位佔用排行 (前 6 大部門)
            string sqlDept = @"
                SELECT d.DeptName, d.QuotaLimit,
                       COUNT(p.PermitID) AS PermitCount
                FROM ParkingDepartments d
                LEFT JOIN ParkingPermits p ON d.DeptID = p.DeptID AND p.Status = 'ACTIVE'
                WHERE d.IsActive = TRUE
                GROUP BY d.DeptID, d.DeptName, d.QuotaLimit
                ORDER BY PermitCount DESC, d.DeptName
                LIMIT 6";

            var dtDept = DbHelper.ExecuteDataTable(sqlDept);
            foreach (DataRow row in dtDept.Rows)
            {
                summary.DeptOccupancies.Add(new DeptOccupancyDto
                {
                    DeptName = row["DeptName"].ToString(),
                    PermitCount = Convert.ToInt32(row["PermitCount"]),
                    QuotaLimit = Convert.ToInt32(row["QuotaLimit"])
                });
            }

            // 4. 巡檢違規分類統計
            string sqlStats = @"
                SELECT ResultStatus, COUNT(1) AS Cnt
                FROM ParkingInspectionLogs
                GROUP BY ResultStatus";

            var dtStats = DbHelper.ExecuteDataTable(sqlStats);
            var statMap = new Dictionary<string, int>();
            foreach (DataRow row in dtStats.Rows)
            {
                statMap[row["ResultStatus"].ToString()] = Convert.ToInt32(row["Cnt"]);
            }

            summary.InspectionStats.Add(new InspectionStatDto
            {
                Status = "VALID",
                StatusLabel = "查驗合格",
                Count = statMap.ContainsKey("VALID") ? statMap["VALID"] : 0,
                ColorHex = "#0E9F6E" // Success Green
            });
            summary.InspectionStats.Add(new InspectionStatDto
            {
                Status = "WRONG_ZONE",
                StatusLabel = "跨區違規",
                Count = statMap.ContainsKey("WRONG_ZONE") ? statMap["WRONG_ZONE"] : 0,
                ColorHex = "#E3A008" // Warning Amber
            });
            summary.InspectionStats.Add(new InspectionStatDto
            {
                Status = "EXPIRED",
                StatusLabel = "逾期停權",
                Count = statMap.ContainsKey("EXPIRED") ? statMap["EXPIRED"] : 0,
                ColorHex = "#F05252" // Danger Red
            });
            summary.InspectionStats.Add(new InspectionStatDto
            {
                Status = "NOT_FOUND",
                StatusLabel = "未登記車輛",
                Count = statMap.ContainsKey("NOT_FOUND") ? statMap["NOT_FOUND"] : 0,
                ColorHex = "#374151" // Dark Gray
            });

            // 5. 最新待辦審核案件 (包含待審核、已收案、待排序、待領證)
            var appService = new ApplicationWorkflowService();
            var allPending = appService.GetApplications("ACTIVE");
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                allPending = allPending.FindAll(a => a.PreferredZoneID == zoneFilter.Value);
            }
            for (int i = 0; i < Math.Min(10, allPending.Count); i++)
            {
                summary.RecentApplications.Add(allPending[i]);
            }

            return summary;
        }

        /// <summary>
        /// 取得特定部門之車位佔用與通行證明細 (下鑽檢視)
        /// </summary>
        public DeptDrilldownDto GetDeptPermitsDetail(string deptName)
        {
            var result = new DeptDrilldownDto { DeptName = deptName };
            if (string.IsNullOrWhiteSpace(deptName)) return result;

            // 1. 查詢部門基本資訊與配額
            string sqlDept = "SELECT DeptID, DeptName, QuotaLimit FROM ParkingDepartments WHERE DeptName = @DeptName";
            var dtDept = DbHelper.ExecuteDataTable(sqlDept, new NpgsqlParameter("@DeptName", deptName.Trim()));
            if (dtDept.Rows.Count > 0)
            {
                result.DeptID = Convert.ToInt32(dtDept.Rows[0]["DeptID"]);
                result.QuotaLimit = Convert.ToInt32(dtDept.Rows[0]["QuotaLimit"]);
            }

            // 2. 查詢該部門目前有效之車籍通行證
            string sqlPermits = @"
                SELECT p.PermitID, p.PermitNumber, p.DeptID, d.DeptName, p.CardNumber, p.OwnerName,
                       p.SensorTagNumber, p.RemoteControllerNo, p.VehicleColor, p.LicensePlate,
                       p.VehicleBrand, p.ZoneID, z.ZoneName,
                       TO_CHAR(p.RegisterDate, 'YYYY-MM-DD') AS RegisterDate,
                       TO_CHAR(p.StartDate, 'YYYY-MM-DD') AS StartDate,
                       TO_CHAR(p.ExpireDate, 'YYYY-MM-DD') AS ExpireDate,
                       p.ExpireDate AS ExpDateRaw,
                       p.Status, p.Remarks
                FROM ParkingPermits p
                INNER JOIN ParkingDepartments d ON p.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                WHERE d.DeptName = @DeptName AND p.Status = 'ACTIVE'
                ORDER BY p.PermitID DESC";

            var dtPermits = DbHelper.ExecuteDataTable(sqlPermits, new NpgsqlParameter("@DeptName", deptName.Trim()));
            DateTime today = DateTime.Today;
            foreach (DataRow dr in dtPermits.Rows)
            {
                DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);
                int daysRemaining = (expDate - today).Days;
                bool isExpiringSoon = daysRemaining >= 0 && daysRemaining <= 30;

                result.Permits.Add(new PermitItemDto
                {
                    PermitID = Convert.ToInt32(dr["PermitID"]),
                    PermitNumber = dr["PermitNumber"].ToString(),
                    DeptID = Convert.ToInt32(dr["DeptID"]),
                    DeptName = dr["DeptName"].ToString(),
                    CardNumber = dr["CardNumber"] != DBNull.Value ? dr["CardNumber"].ToString() : "",
                    OwnerName = dr["OwnerName"].ToString(),
                    SensorTagNumber = dr["SensorTagNumber"] != DBNull.Value ? dr["SensorTagNumber"].ToString() : "",
                    RemoteControllerNo = dr["RemoteControllerNo"] != DBNull.Value ? dr["RemoteControllerNo"].ToString() : "",
                    VehicleColor = dr["VehicleColor"].ToString(),
                    LicensePlate = dr["LicensePlate"].ToString(),
                    VehicleBrand = dr["VehicleBrand"].ToString(),
                    ZoneID = Convert.ToInt32(dr["ZoneID"]),
                    ZoneName = dr["ZoneName"].ToString(),
                    RegisterDate = dr["RegisterDate"].ToString(),
                    StartDate = dr["StartDate"].ToString(),
                    ExpireDate = dr["ExpireDate"].ToString(),
                    Status = dr["Status"].ToString(),
                    Remarks = dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "",
                    DaysRemaining = daysRemaining,
                    IsExpiringSoon = isExpiringSoon
                });
            }

            result.OccupiedCount = result.Permits.Count;
            result.OccupancyPct = result.QuotaLimit > 0 ? (int)Math.Round((double)result.OccupiedCount * 100 / result.QuotaLimit) : 0;
            return result;
        }

        /// <summary>
        /// 取得特定停車場域之容量與通行證名單 (下鑽檢視)
        /// </summary>
        public ZoneDrilldownDto GetZonePermitsDetail(int zoneId)
        {
            var result = new ZoneDrilldownDto { ZoneID = zoneId };

            // 1. 查詢該場域配置資訊
            string sqlZone = "SELECT ZoneID, ZoneCode, ZoneName, TotalCapacity, WarningThresholdPct FROM ParkingZones WHERE ZoneID = @ZoneID";
            var dtZone = DbHelper.ExecuteDataTable(sqlZone, new NpgsqlParameter("@ZoneID", zoneId));
            if (dtZone.Rows.Count > 0)
            {
                result.ZoneCode = dtZone.Rows[0]["ZoneCode"].ToString();
                result.ZoneName = dtZone.Rows[0]["ZoneName"].ToString();
                result.TotalCapacity = Convert.ToInt32(dtZone.Rows[0]["TotalCapacity"]);
                result.WarningThresholdPct = Convert.ToInt32(dtZone.Rows[0]["WarningThresholdPct"]);
            }

            // 2. 查詢該場域所有有效車籍
            string sqlPermits = @"
                SELECT p.PermitID, p.PermitNumber, p.DeptID, d.DeptName, p.CardNumber, p.OwnerName,
                       p.SensorTagNumber, p.RemoteControllerNo, p.VehicleColor, p.LicensePlate,
                       p.VehicleBrand, p.ZoneID, z.ZoneName,
                       TO_CHAR(p.RegisterDate, 'YYYY-MM-DD') AS RegisterDate,
                       TO_CHAR(p.StartDate, 'YYYY-MM-DD') AS StartDate,
                       TO_CHAR(p.ExpireDate, 'YYYY-MM-DD') AS ExpireDate,
                       p.ExpireDate AS ExpDateRaw,
                       p.Status, p.Remarks
                FROM ParkingPermits p
                INNER JOIN ParkingDepartments d ON p.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                WHERE p.ZoneID = @ZoneID AND p.Status = 'ACTIVE'
                ORDER BY p.PermitID DESC";

            var dtPermits = DbHelper.ExecuteDataTable(sqlPermits, new NpgsqlParameter("@ZoneID", zoneId));
            DateTime today = DateTime.Today;
            foreach (DataRow dr in dtPermits.Rows)
            {
                DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);
                int daysRemaining = (expDate - today).Days;
                bool isExpiringSoon = daysRemaining >= 0 && daysRemaining <= 30;

                result.Permits.Add(new PermitItemDto
                {
                    PermitID = Convert.ToInt32(dr["PermitID"]),
                    PermitNumber = dr["PermitNumber"].ToString(),
                    DeptID = Convert.ToInt32(dr["DeptID"]),
                    DeptName = dr["DeptName"].ToString(),
                    CardNumber = dr["CardNumber"] != DBNull.Value ? dr["CardNumber"].ToString() : "",
                    OwnerName = dr["OwnerName"].ToString(),
                    SensorTagNumber = dr["SensorTagNumber"] != DBNull.Value ? dr["SensorTagNumber"].ToString() : "",
                    RemoteControllerNo = dr["RemoteControllerNo"] != DBNull.Value ? dr["RemoteControllerNo"].ToString() : "",
                    VehicleColor = dr["VehicleColor"].ToString(),
                    LicensePlate = dr["LicensePlate"].ToString(),
                    VehicleBrand = dr["VehicleBrand"].ToString(),
                    ZoneID = Convert.ToInt32(dr["ZoneID"]),
                    ZoneName = dr["ZoneName"].ToString(),
                    RegisterDate = dr["RegisterDate"].ToString(),
                    StartDate = dr["StartDate"].ToString(),
                    ExpireDate = dr["ExpireDate"].ToString(),
                    Status = dr["Status"].ToString(),
                    Remarks = dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "",
                    DaysRemaining = daysRemaining,
                    IsExpiringSoon = isExpiringSoon
                });
            }

            result.OccupiedCount = result.Permits.Count;
            result.RemainingQuota = Math.Max(0, result.TotalCapacity - result.OccupiedCount);
            result.OccupancyPct = result.TotalCapacity > 0 ? (int)Math.Round((double)result.OccupiedCount * 100 / result.TotalCapacity) : 0;
            result.IsWarning = result.OccupancyPct >= result.WarningThresholdPct;
            return result;
        }

        /// <summary>
        /// 取得巡檢特定分類或態勢之稽核日誌明細 (下鑽檢視)
        /// </summary>
        public InspectionDrilldownDto GetInspectionLogsDetail(string resultStatus, int? zoneFilter)
        {
            var result = new InspectionDrilldownDto
            {
                Status = resultStatus ?? "ALL"
            };

            switch (result.Status)
            {
                case "VALID":
                    result.StatusLabel = "查驗合格";
                    result.ColorHex = "#0E9F6E";
                    break;
                case "WRONG_ZONE":
                    result.StatusLabel = "跨區違規";
                    result.ColorHex = "#E3A008";
                    break;
                case "EXPIRED":
                    result.StatusLabel = "逾期停權";
                    result.ColorHex = "#F05252";
                    break;
                case "NOT_FOUND":
                    result.StatusLabel = "未登記車輛";
                    result.ColorHex = "#374151";
                    break;
                default:
                    result.StatusLabel = "全部巡查紀錄";
                    result.ColorHex = "#1A56DB";
                    break;
            }

            string sql = @"
                SELECT l.LogID,
                       TO_CHAR(l.InspectTime, 'YYYY-MM-DD HH24:MI') AS InspectTime,
                       l.InspectorAccount,
                       l.ZoneID,
                       z.ZoneName,
                       l.PlateScanned,
                       l.ResultStatus,
                       p.OwnerName,
                       d.DeptName,
                       pz.ZoneName AS PermittedZoneName,
                       l.PhotoPath,
                       l.Remark
                FROM ParkingInspectionLogs l
                INNER JOIN ParkingZones z ON l.ZoneID = z.ZoneID
                LEFT JOIN ParkingPermits p ON l.PermitID = p.PermitID
                LEFT JOIN ParkingDepartments d ON p.DeptID = d.DeptID
                LEFT JOIN ParkingZones pz ON p.ZoneID = pz.ZoneID
                WHERE 1=1 ";

            var pars = new List<NpgsqlParameter>();
            if (!string.IsNullOrWhiteSpace(resultStatus) && resultStatus != "ALL")
            {
                sql += " AND l.ResultStatus = @Status ";
                pars.Add(new NpgsqlParameter("@Status", resultStatus));
            }
            if (zoneFilter.HasValue && zoneFilter.Value > 0)
            {
                sql += " AND l.ZoneID = @ZoneID ";
                pars.Add(new NpgsqlParameter("@ZoneID", zoneFilter.Value));
            }

            sql += " ORDER BY l.LogID DESC";

            var dt = DbHelper.ExecuteDataTable(sql, pars.ToArray());
            foreach (DataRow dr in dt.Rows)
            {
                string status = dr["ResultStatus"].ToString();
                string label = status;
                if (status == "VALID") label = "查驗合格";
                else if (status == "WRONG_ZONE") label = "跨區違規";
                else if (status == "EXPIRED") label = "逾期停權";
                else if (status == "NOT_FOUND") label = "未登記車輛";

                result.Logs.Add(new InspectionLogItemDto
                {
                    LogID = Convert.ToInt64(dr["LogID"]),
                    InspectTime = dr["InspectTime"].ToString(),
                    InspectorAccount = dr["InspectorAccount"].ToString(),
                    ZoneID = Convert.ToInt32(dr["ZoneID"]),
                    ZoneName = dr["ZoneName"].ToString(),
                    PlateScanned = dr["PlateScanned"].ToString(),
                    ResultStatus = status,
                    ResultStatusLabel = label,
                    OwnerName = dr["OwnerName"] != DBNull.Value ? dr["OwnerName"].ToString() : "(外來/未登記)",
                    DeptName = dr["DeptName"] != DBNull.Value ? dr["DeptName"].ToString() : "--",
                    PermittedZoneName = dr["PermittedZoneName"] != DBNull.Value ? dr["PermittedZoneName"].ToString() : "--",
                    PhotoPath = dr["PhotoPath"] != DBNull.Value ? dr["PhotoPath"].ToString() : "",
                    Remark = dr["Remark"] != DBNull.Value ? dr["Remark"].ToString() : ""
                });
            }

            result.TotalCount = result.Logs.Count;
            return result;
        }

        /// <summary>
        /// 取得 30 日內即將屆期之車籍名單 (下鑽檢視)
        /// </summary>
        public List<PermitItemDto> GetExpiringPermitsDetail(int? zoneFilter)
        {
            var permitService = new PermitService();
            return permitService.SearchPermits(new SearchCriteriaDto
            {
                ZoneID = zoneFilter,
                Status = "EXPIRING_SOON"
            });
        }
    }
}