using System;
using System.Collections.Generic;
using System.Data;
using Npgsql;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    /// <summary>
    /// 醫療院區部門科室與車位配額管理服務 (Department Management Service - PostgreSQL)
    /// </summary>
    public class DepartmentService
    {
        /// <summary>
        /// 取得全院部門科室統計與清單
        /// </summary>
        public DepartmentOverviewDto GetDepartmentOverview()
        {
            var summary = new DepartmentOverviewDto();

            string sql = @"
                SELECT 
                    d.DeptID,
                    d.DeptCode,
                    d.DeptName,
                    d.QuotaLimit,
                    d.IsActive,
                    TO_CHAR(d.CreatedDate, 'YYYY-MM-DD HH24:MI:SS') AS CreatedDate,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.DeptID = d.DeptID AND p.Status = 'ACTIVE') AS ActivePermitCount,
                    (SELECT COUNT(1) FROM ParkingPermits p WHERE p.DeptID = d.DeptID) AS TotalPermitCount,
                    (SELECT COUNT(1) FROM ParkingEmployeeApplications a WHERE a.DeptID = d.DeptID AND a.ReviewStatus IN ('PENDING', 'PROCESSING', 'WAITLIST', 'APPROVED')) AS PendingAppCount
                FROM ParkingDepartments d
                ORDER BY d.IsActive DESC, d.DeptCode ASC";

            var dt = DbHelper.ExecuteDataTable(sql);

            int totalQuota = 0;
            int totalActivePermits = 0;
            int overQuotaCount = 0;
            int activeCount = 0;

            foreach (DataRow row in dt.Rows)
            {
                int quota = Convert.ToInt32(row["QuotaLimit"]);
                int activePermits = Convert.ToInt32(row["ActivePermitCount"]);
                bool isActive = Convert.ToBoolean(row["IsActive"]);
                int pct = quota > 0 ? (int)Math.Round((double)activePermits * 100 / quota) : (activePermits > 0 ? 100 : 0);
                bool isOverQuota = isActive && quota > 0 && activePermits >= quota;

                if (isActive)
                {
                    activeCount++;
                    totalQuota += quota;
                    totalActivePermits += activePermits;
                    if (isOverQuota)
                    {
                        overQuotaCount++;
                    }
                }

                summary.DeptList.Add(new DepartmentManageDto
                {
                    DeptID = Convert.ToInt32(row["DeptID"]),
                    DeptCode = row["DeptCode"].ToString().Trim(),
                    DeptName = row["DeptName"].ToString().Trim(),
                    QuotaLimit = quota,
                    IsActive = isActive,
                    CreatedDate = row["CreatedDate"].ToString(),
                    ActivePermitCount = activePermits,
                    TotalPermitCount = Convert.ToInt32(row["TotalPermitCount"]),
                    RemainingQuota = Math.Max(0, quota - activePermits),
                    UtilizationPct = pct,
                    IsOverQuota = isOverQuota,
                    PendingAppCount = Convert.ToInt32(row["PendingAppCount"])
                });
            }

            summary.TotalDepts = dt.Rows.Count;
            summary.ActiveDepts = activeCount;
            summary.TotalQuotaLimit = totalQuota;
            summary.TotalActivePermits = totalActivePermits;
            summary.OverQuotaDeptCount = overQuotaCount;

            return summary;
        }

        /// <summary>
        /// 依據 ID 取得特定部門詳細資訊
        /// </summary>
        public DepartmentManageDto GetDepartmentById(int deptId)
        {
            string sql = "SELECT DeptID, DeptCode, DeptName, QuotaLimit, IsActive FROM ParkingDepartments WHERE DeptID = @DeptID";
            var dt = DbHelper.ExecuteDataTable(sql, new NpgsqlParameter("@DeptID", deptId));
            if (dt.Rows.Count == 0) return null;

            var r = dt.Rows[0];
            return new DepartmentManageDto
            {
                DeptID = Convert.ToInt32(r["DeptID"]),
                DeptCode = r["DeptCode"].ToString().Trim(),
                DeptName = r["DeptName"].ToString().Trim(),
                QuotaLimit = Convert.ToInt32(r["QuotaLimit"]),
                IsActive = Convert.ToBoolean(r["IsActive"])
            };
        }

        /// <summary>
        /// 新增或儲存部門科室資訊 (包含防呆唯一性檢查)
        /// </summary>
        public OperationResult SaveDepartment(DepartmentManageDto dto)
        {
            if (dto == null) return OperationResult.Fail("無效之資料物件！");

            string code = (dto.DeptCode ?? "").Trim().ToUpper();
            string name = (dto.DeptName ?? "").Trim();

            if (string.IsNullOrWhiteSpace(code)) return OperationResult.Fail("部門科室代碼為必填！");
            if (string.IsNullOrWhiteSpace(name)) return OperationResult.Fail("部門科室名稱為必填！");
            if (dto.QuotaLimit < 0) return OperationResult.Fail("車位配額上限不可小於 0！");

            // 檢查代碼或名稱是否與其他部門衝突
            string chkSql = "SELECT COUNT(1) FROM ParkingDepartments WHERE (DeptCode = @Code OR DeptName = @Name) AND DeptID <> @DeptID";
            int count = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql,
                new NpgsqlParameter("@Code", code),
                new NpgsqlParameter("@Name", name),
                new NpgsqlParameter("@DeptID", dto.DeptID)));

            if (count > 0)
            {
                return OperationResult.Fail(string.Format("科室代碼【{0}】或科室名稱【{1}】已存在，不可重複！", code, name));
            }

            if (dto.DeptID == 0)
            {
                string insertSql = @"
                    INSERT INTO ParkingDepartments (DeptCode, DeptName, QuotaLimit, IsActive, CreatedDate)
                    VALUES (@DeptCode, @DeptName, @QuotaLimit, @IsActive, CURRENT_TIMESTAMP)";

                DbHelper.ExecuteNonQuery(insertSql,
                    new NpgsqlParameter("@DeptCode", code),
                    new NpgsqlParameter("@DeptName", name),
                    new NpgsqlParameter("@QuotaLimit", dto.QuotaLimit),
                    new NpgsqlParameter("@IsActive", dto.IsActive));

                return OperationResult.Ok("部門科室已成功建立！");
            }
            else
            {
                string updateSql = @"
                    UPDATE ParkingDepartments
                    SET DeptCode = @DeptCode,
                        DeptName = @DeptName,
                        QuotaLimit = @QuotaLimit,
                        IsActive = @IsActive
                    WHERE DeptID = @DeptID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new NpgsqlParameter("@DeptCode", code),
                    new NpgsqlParameter("@DeptName", name),
                    new NpgsqlParameter("@QuotaLimit", dto.QuotaLimit),
                    new NpgsqlParameter("@IsActive", dto.IsActive),
                    new NpgsqlParameter("@DeptID", dto.DeptID));

                return OperationResult.Ok("部門科室資料已成功更新！");
            }
        }

        /// <summary>
        /// 切換科室啟用狀態
        /// </summary>
        public OperationResult ToggleStatus(int deptId, bool targetStatus)
        {
            string sql = "UPDATE ParkingDepartments SET IsActive = @IsActive WHERE DeptID = @DeptID";
            DbHelper.ExecuteNonQuery(sql,
                new NpgsqlParameter("@IsActive", targetStatus),
                new NpgsqlParameter("@DeptID", deptId));

            return OperationResult.Ok(string.Format("科室狀態已切換為【{0}】！", targetStatus ? "啟用中" : "已停用"));
        }

        /// <summary>
        /// 刪除部門科室 (包含通行證與申請單安全防呆檢核)
        /// </summary>
        public OperationResult DeleteDepartment(int deptId)
        {
            int permitCount = Convert.ToInt32(DbHelper.ExecuteScalar(
                "SELECT COUNT(1) FROM ParkingPermits WHERE DeptID = @DeptID", new NpgsqlParameter("@DeptID", deptId)));
            if (permitCount > 0)
            {
                return OperationResult.Fail(string.Format("該部門尚有 {0} 筆車輛通行證關聯，無法直接刪除！建議將該部門設為【已停用】。", permitCount));
            }

            int appCount = Convert.ToInt32(DbHelper.ExecuteScalar(
                "SELECT COUNT(1) FROM ParkingEmployeeApplications WHERE DeptID = @DeptID", new NpgsqlParameter("@DeptID", deptId)));
            if (appCount > 0)
            {
                return OperationResult.Fail(string.Format("該部門尚有 {0} 筆線上申請紀錄關聯，無法直接刪除！建議將該部門設為【已停用】。", appCount));
            }

            string sql = "DELETE FROM ParkingDepartments WHERE DeptID = @DeptID";
            DbHelper.ExecuteNonQuery(sql, new NpgsqlParameter("@DeptID", deptId));
            return OperationResult.Ok("部門科室已成功刪除！");
        }

        /// <summary>
        /// 取得該部門所屬之所有車輛通行證清單
        /// </summary>
        public List<DepartmentPermitItemDto> GetDepartmentPermits(int deptId)
        {
            var list = new List<DepartmentPermitItemDto>();
            string sql = @"
                SELECT 
                    p.PermitID,
                    p.PermitNumber,
                    p.OwnerName,
                    p.CardNumber,
                    p.LicensePlate,
                    p.VehicleBrand,
                    p.VehicleColor,
                    z.ZoneName,
                    TO_CHAR(p.StartDate, 'YYYY-MM-DD') AS StartDate,
                    TO_CHAR(p.ExpireDate, 'YYYY-MM-DD') AS ExpireDate,
                    p.Status
                FROM ParkingPermits p
                LEFT JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                WHERE p.DeptID = @DeptID
                ORDER BY p.Status ASC, p.PermitID DESC";

            var dt = DbHelper.ExecuteDataTable(sql, new NpgsqlParameter("@DeptID", deptId));
            foreach (DataRow r in dt.Rows)
            {
                list.Add(new DepartmentPermitItemDto
                {
                    PermitID = Convert.ToInt32(r["PermitID"]),
                    PermitNumber = r["PermitNumber"].ToString(),
                    OwnerName = r["OwnerName"].ToString(),
                    CardNumber = r["CardNumber"] != DBNull.Value ? r["CardNumber"].ToString() : "",
                    LicensePlate = r["LicensePlate"].ToString(),
                    VehicleBrand = r["VehicleBrand"].ToString(),
                    VehicleColor = r["VehicleColor"].ToString(),
                    ZoneName = r["ZoneName"] != DBNull.Value ? r["ZoneName"].ToString() : "",
                    StartDate = r["StartDate"].ToString(),
                    ExpireDate = r["ExpireDate"].ToString(),
                    Status = r["Status"].ToString()
                });
            }
            return list;
        }
    }
}