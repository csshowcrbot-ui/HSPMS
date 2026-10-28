using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    /// <summary>
    /// 停車場場域維護與容量管理服務 (Zone Management Service)
    /// </summary>
    public class ZoneService
    {
        /// <summary>
        /// 取得全院停車場域總覽統計與詳細清單
        /// </summary>
        public ZoneOverviewSummaryDto GetZoneOverviewSummary()
        {
            var summary = new ZoneOverviewSummaryDto();

            string sql = @"
                SELECT 
                    z.ZoneID,
                    z.ZoneCode,
                    z.ZoneName,
                    z.TotalCapacity,
                    z.WarningThresholdPct,
                    z.IsActive,
                    CONVERT(VARCHAR(19), z.CreatedDate, 120) AS CreatedDate,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID AND p.Status = 'ACTIVE') AS CurrentOccupied,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID) AS PermitCount,
                    (SELECT COUNT(1) FROM ParkingEmployeeApplications a WHERE a.PreferredZoneID = z.ZoneID AND a.ReviewStatus = 'PENDING') AS PendingAppCount,
                    (SELECT COUNT(1) FROM ParkingInspectionLogs i WHERE i.ZoneID = z.ZoneID) AS InspectionCount
                FROM ParkingZones z
                ORDER BY z.IsActive DESC, z.ZoneCode ASC";

            var dt = DbHelper.ExecuteDataTable(sql);

            int totalCap = 0;
            int totalOcc = 0;
            int warnCount = 0;
            int activeCount = 0;

            foreach (DataRow row in dt.Rows)
            {
                int cap = Convert.ToInt32(row["TotalCapacity"]);
                int occ = Convert.ToInt32(row["CurrentOccupied"]);
                int warnPct = Convert.ToInt32(row["WarningThresholdPct"]);
                bool isActive = Convert.ToBoolean(row["IsActive"]);
                int pct = cap > 0 ? (int)Math.Round((double)occ * 100 / cap) : 0;
                bool isWarning = isActive && (pct >= warnPct);

                if (isActive)
                {
                    activeCount++;
                    totalCap += cap;
                    totalOcc += occ;
                    if (isWarning)
                    {
                        warnCount++;
                    }
                }

                summary.ZoneList.Add(new ZoneManageDto
                {
                    ZoneID = Convert.ToInt32(row["ZoneID"]),
                    ZoneCode = row["ZoneCode"].ToString().Trim(),
                    ZoneName = row["ZoneName"].ToString().Trim(),
                    TotalCapacity = cap,
                    WarningThresholdPct = warnPct,
                    IsActive = isActive,
                    CreatedDate = row["CreatedDate"].ToString(),
                    CurrentOccupied = occ,
                    RemainingQuota = Math.Max(0, cap - occ),
                    OccupancyPct = pct,
                    IsWarning = isWarning,
                    PermitCount = Convert.ToInt32(row["PermitCount"]),
                    PendingAppCount = Convert.ToInt32(row["PendingAppCount"]),
                    InspectionCount = Convert.ToInt32(row["InspectionCount"])
                });
            }

            summary.TotalZones = dt.Rows.Count;
            summary.ActiveZones = activeCount;
            summary.TotalCapacity = totalCap;
            summary.TotalOccupied = totalOcc;
            summary.WarningZoneCount = warnCount;

            return summary;
        }

        /// <summary>
        /// 依 ZoneID 取得單筆場域詳細資料
        /// </summary>
        public ZoneManageDto GetZoneById(int zoneId)
        {
            string sql = @"
                SELECT 
                    z.ZoneID,
                    z.ZoneCode,
                    z.ZoneName,
                    z.TotalCapacity,
                    z.WarningThresholdPct,
                    z.IsActive,
                    CONVERT(VARCHAR(19), z.CreatedDate, 120) AS CreatedDate,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID AND p.Status = 'ACTIVE') AS CurrentOccupied,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID) AS PermitCount,
                    (SELECT COUNT(1) FROM ParkingEmployeeApplications a WHERE a.PreferredZoneID = z.ZoneID AND a.ReviewStatus = 'PENDING') AS PendingAppCount,
                    (SELECT COUNT(1) FROM ParkingInspectionLogs i WHERE i.ZoneID = z.ZoneID) AS InspectionCount
                FROM ParkingZones z
                WHERE z.ZoneID = @ZoneID";

            var dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@ZoneID", zoneId));
            if (dt.Rows.Count == 0)
            {
                return null;
            }

            var row = dt.Rows[0];
            int cap = Convert.ToInt32(row["TotalCapacity"]);
            int occ = Convert.ToInt32(row["CurrentOccupied"]);
            int warnPct = Convert.ToInt32(row["WarningThresholdPct"]);
            int pct = cap > 0 ? (int)Math.Round((double)occ * 100 / cap) : 0;

            return new ZoneManageDto
            {
                ZoneID = Convert.ToInt32(row["ZoneID"]),
                ZoneCode = row["ZoneCode"].ToString().Trim(),
                ZoneName = row["ZoneName"].ToString().Trim(),
                TotalCapacity = cap,
                WarningThresholdPct = warnPct,
                IsActive = Convert.ToBoolean(row["IsActive"]),
                CreatedDate = row["CreatedDate"].ToString(),
                CurrentOccupied = occ,
                RemainingQuota = Math.Max(0, cap - occ),
                OccupancyPct = pct,
                IsWarning = pct >= warnPct,
                PermitCount = Convert.ToInt32(row["PermitCount"]),
                PendingAppCount = Convert.ToInt32(row["PendingAppCount"]),
                InspectionCount = Convert.ToInt32(row["InspectionCount"])
            };
        }

        /// <summary>
        /// 儲存場域 (包含新增與更新，含代碼防呆與容量校驗)
        /// </summary>
        public OperationResult SaveZone(ZoneManageDto dto)
        {
            if (dto == null)
            {
                return OperationResult.Fail("傳入之場域資料為空！");
            }

            dto.ZoneCode = (dto.ZoneCode ?? "").Trim().ToUpper();
            dto.ZoneName = (dto.ZoneName ?? "").Trim();

            if (string.IsNullOrWhiteSpace(dto.ZoneCode))
            {
                return OperationResult.Fail("請填寫場域代碼 (如 A, B, C, P1, VIP 等)！");
            }
            if (dto.ZoneCode.Length > 10)
            {
                return OperationResult.Fail("場域代碼長度不得超過 10 個字元！");
            }

            if (string.IsNullOrWhiteSpace(dto.ZoneName))
            {
                return OperationResult.Fail("請填寫場域名稱 (如: 地下A區、立體二館等)！");
            }
            if (dto.ZoneName.Length > 50)
            {
                return OperationResult.Fail("場域名稱長度不得超過 50 個字元！");
            }

            if (dto.TotalCapacity <= 0)
            {
                return OperationResult.Fail("場域總格位容量必須大於 0！");
            }

            if (dto.WarningThresholdPct <= 0 || dto.WarningThresholdPct > 100)
            {
                dto.WarningThresholdPct = 85; // 預設 85%
            }

            // 新增場域
            if (dto.ZoneID <= 0)
            {
                string checkSql = "SELECT COUNT(1) FROM ParkingZones WHERE UPPER(ZoneCode) = @ZoneCode";
                int exists = Convert.ToInt32(DbHelper.ExecuteScalar(checkSql, new SqlParameter("@ZoneCode", dto.ZoneCode)));
                if (exists > 0)
                {
                    return OperationResult.Fail(string.Format("場域代碼【{0}】已存在，請使用其他代碼！", dto.ZoneCode));
                }

                string insertSql = @"
                    INSERT INTO ParkingZones (ZoneCode, ZoneName, TotalCapacity, WarningThresholdPct, IsActive, CreatedDate)
                    VALUES (@ZoneCode, @ZoneName, @TotalCapacity, @WarningThresholdPct, @IsActive, GETDATE());
                    SELECT SCOPE_IDENTITY();";

                var newIdObj = DbHelper.ExecuteScalar(insertSql,
                    new SqlParameter("@ZoneCode", dto.ZoneCode),
                    new SqlParameter("@ZoneName", dto.ZoneName),
                    new SqlParameter("@TotalCapacity", dto.TotalCapacity),
                    new SqlParameter("@WarningThresholdPct", dto.WarningThresholdPct),
                    new SqlParameter("@IsActive", dto.IsActive)
                );

                int newId = Convert.ToInt32(newIdObj);
                return OperationResult.Ok(string.Format("成功新增停車場域【{0} - {1}】！", dto.ZoneCode, dto.ZoneName), newId);
            }
            // 更新既有場域
            else
            {
                string checkSql = "SELECT COUNT(1) FROM ParkingZones WHERE UPPER(ZoneCode) = @ZoneCode AND ZoneID <> @ZoneID";
                int exists = Convert.ToInt32(DbHelper.ExecuteScalar(checkSql,
                    new SqlParameter("@ZoneCode", dto.ZoneCode),
                    new SqlParameter("@ZoneID", dto.ZoneID)
                ));
                if (exists > 0)
                {
                    return OperationResult.Fail(string.Format("場域代碼【{0}】已被其他場域使用，不可重複！", dto.ZoneCode));
                }

                string updateSql = @"
                    UPDATE ParkingZones 
                    SET ZoneCode = @ZoneCode,
                        ZoneName = @ZoneName,
                        TotalCapacity = @TotalCapacity,
                        WarningThresholdPct = @WarningThresholdPct,
                        IsActive = @IsActive
                    WHERE ZoneID = @ZoneID";

                int affected = DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@ZoneCode", dto.ZoneCode),
                    new SqlParameter("@ZoneName", dto.ZoneName),
                    new SqlParameter("@TotalCapacity", dto.TotalCapacity),
                    new SqlParameter("@WarningThresholdPct", dto.WarningThresholdPct),
                    new SqlParameter("@IsActive", dto.IsActive),
                    new SqlParameter("@ZoneID", dto.ZoneID)
                );

                if (affected > 0)
                {
                    return OperationResult.Ok(string.Format("已成功更新停車場域【{0}】資訊！", dto.ZoneName));
                }
                return OperationResult.Fail("更新失敗，查無該場域紀錄！");
            }
        }

        /// <summary>
        /// 快速切換場域啟用 / 停用狀態
        /// </summary>
        public OperationResult ToggleStatus(int zoneId, bool targetStatus)
        {
            string sql = "UPDATE ParkingZones SET IsActive = @IsActive WHERE ZoneID = @ZoneID";
            int affected = DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@IsActive", targetStatus),
                new SqlParameter("@ZoneID", zoneId)
            );

            if (affected > 0)
            {
                return OperationResult.Ok(string.Format("已成功將場域狀態設為【{0}】！", targetStatus ? "啟用" : "停用"));
            }
            return OperationResult.Fail("操作失敗，查無該場域！");
        }

        /// <summary>
        /// 安全刪除場域 (含外鍵依賴關聯防呆)
        /// </summary>
        public OperationResult DeleteZone(int zoneId)
        {
            // 1. 檢查通行證關聯
            string sqlPermits = "SELECT COUNT(1) FROM ParkingPermits WHERE ZoneID = @ZoneID";
            int permitCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlPermits, new SqlParameter("@ZoneID", zoneId)));

            // 2. 檢查申請單關聯
            string sqlApps = "SELECT COUNT(1) FROM ParkingEmployeeApplications WHERE PreferredZoneID = @ZoneID";
            int appCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlApps, new SqlParameter("@ZoneID", zoneId)));

            // 3. 檢查巡檢紀錄關聯
            string sqlLogs = "SELECT COUNT(1) FROM ParkingInspectionLogs WHERE ZoneID = @ZoneID";
            int logCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlLogs, new SqlParameter("@ZoneID", zoneId)));

            if (permitCount > 0 || appCount > 0 || logCount > 0)
            {
                return OperationResult.Fail(string.Format(
                    "無法直接刪除該場域！系統偵測該場域已關聯：通行證 {0} 筆、員工申請單 {1} 筆、現場巡檢日誌 {2} 筆。為確保醫療院區管理與審計紀錄完整，請將狀態改為「停用」即可停止新車核發。",
                    permitCount, appCount, logCount));
            }

            // 4. 無任何關聯則允許刪除
            string deleteSql = "DELETE FROM ParkingZones WHERE ZoneID = @ZoneID";
            int affected = DbHelper.ExecuteNonQuery(deleteSql, new SqlParameter("@ZoneID", zoneId));

            if (affected > 0)
            {
                return OperationResult.Ok("該停車場域已成功移除！");
            }
            return OperationResult.Fail("刪除失敗，查無該場域！");
        }

        /// <summary>
        /// 取得所有啟用中場域的下拉選項
        /// </summary>
        public List<ZoneItem> GetActiveZoneOptions()
        {
            var list = new List<ZoneItem>();
            string sql = @"
                SELECT z.ZoneID, z.ZoneCode, z.ZoneName, z.TotalCapacity, z.WarningThresholdPct,
                       (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID AND p.Status = 'ACTIVE') AS CurrentOccupied
                FROM ParkingZones z
                WHERE z.IsActive = 1
                ORDER BY z.ZoneCode";

            var dt = DbHelper.ExecuteDataTable(sql);
            foreach (DataRow row in dt.Rows)
            {
                int cap = Convert.ToInt32(row["TotalCapacity"]);
                int occ = Convert.ToInt32(row["CurrentOccupied"]);
                int pct = cap > 0 ? (int)Math.Round((double)occ * 100 / cap) : 0;

                list.Add(new ZoneItem
                {
                    ZoneID = Convert.ToInt32(row["ZoneID"]),
                    ZoneCode = row["ZoneCode"].ToString().Trim(),
                    ZoneName = row["ZoneName"].ToString().Trim(),
                    TotalCapacity = cap,
                    CurrentOccupied = occ,
                    RemainingQuota = Math.Max(0, cap - occ),
                    OccupancyPct = pct,
                    WarningThresholdPct = Convert.ToInt32(row["WarningThresholdPct"])
                });
            }
            return list;
        }
    }
}
