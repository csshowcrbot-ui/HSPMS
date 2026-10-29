using System;
using System.Collections.Generic;
using System.Data;
using Npgsql;
using System.Text;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    public class PermitService
    {
        public LookupDataDto GetLookupOptions()
        {
            var result = new LookupDataDto();

            string sqlDept = @"
                SELECT d.DeptID, d.DeptCode, d.DeptName, d.QuotaLimit,
                       (SELECT COUNT(1) FROM ParkingPermits p WHERE p.DeptID = d.DeptID AND p.Status = 'ACTIVE') AS CurrentUsed
                FROM ParkingDepartments d
                WHERE d.IsActive = TRUE
                ORDER BY d.DeptName";

            var dtDept = DbHelper.ExecuteDataTable(sqlDept);
            foreach (DataRow row in dtDept.Rows)
            {
                result.Departments.Add(new DeptItem
                {
                    DeptID = Convert.ToInt32(row["DeptID"]),
                    DeptCode = row["DeptCode"].ToString(),
                    DeptName = row["DeptName"].ToString(),
                    QuotaLimit = Convert.ToInt32(row["QuotaLimit"]),
                    CurrentUsed = Convert.ToInt32(row["CurrentUsed"])
                });
            }

            string sqlZone = @"
                SELECT z.ZoneID, z.ZoneCode, z.ZoneName, z.TotalCapacity, z.WarningThresholdPct,
                       (SELECT COUNT(1) FROM ParkingPermits p WHERE p.ZoneID = z.ZoneID AND p.Status = 'ACTIVE') AS CurrentOccupied
                FROM ParkingZones z
                WHERE z.IsActive = TRUE
                ORDER BY z.ZoneCode";

            var dtZone = DbHelper.ExecuteDataTable(sqlZone);
            foreach (DataRow row in dtZone.Rows)
            {
                int cap = Convert.ToInt32(row["TotalCapacity"]);
                int occ = Convert.ToInt32(row["CurrentOccupied"]);
                int pct = cap > 0 ? (int)Math.Round((double)occ * 100 / cap) : 0;
                result.Zones.Add(new ZoneItem
                {
                    ZoneID = Convert.ToInt32(row["ZoneID"]),
                    ZoneCode = row["ZoneCode"].ToString(),
                    ZoneName = row["ZoneName"].ToString(),
                    TotalCapacity = cap,
                    CurrentOccupied = occ,
                    RemainingQuota = Math.Max(0, cap - occ),
                    OccupancyPct = pct,
                    WarningThresholdPct = Convert.ToInt32(row["WarningThresholdPct"])
                });
            }

            return result;
        }

        public List<PermitItemDto> SearchPermits(SearchCriteriaDto criteria)
        {
            var list = new List<PermitItemDto>();
            string sql = @"
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
                WHERE 1=1 ";

            var pars = new List<NpgsqlParameter>();

            if (criteria != null)
            {
                if (criteria.DeptID.HasValue && criteria.DeptID.Value > 0)
                {
                    sql += " AND p.DeptID = @DeptID ";
                    pars.Add(new NpgsqlParameter("@DeptID", criteria.DeptID.Value));
                }

                if (criteria.ZoneID.HasValue && criteria.ZoneID.Value > 0)
                {
                    sql += " AND p.ZoneID = @ZoneID ";
                    pars.Add(new NpgsqlParameter("@ZoneID", criteria.ZoneID.Value));
                }

                if (!string.IsNullOrWhiteSpace(criteria.Status))
                {
                    if (criteria.Status == "EXPIRING_SOON")
                    {
                        sql += " AND p.Status = 'ACTIVE' AND p.ExpireDate >= CURRENT_DATE AND p.ExpireDate <= (CURRENT_DATE + INTERVAL '30 days') ";
                    }
                    else
                    {
                        sql += " AND p.Status = @Status ";
                        pars.Add(new NpgsqlParameter("@Status", criteria.Status));
                    }
                }

                if (!string.IsNullOrWhiteSpace(criteria.Keyword))
                {
                    string kw = criteria.Keyword.Trim();
                    string cleanKw = kw.Replace("-", "").Replace(" ", "");
                    sql += " AND (p.LicensePlate ILIKE @Kw OR p.CleanPlate ILIKE @CleanKw OR p.OwnerName ILIKE @Kw OR p.CardNumber ILIKE @Kw OR p.PermitNumber ILIKE @Kw OR p.SensorTagNumber ILIKE @Kw) ";
                    pars.Add(new NpgsqlParameter("@Kw", "%" + kw + "%"));
                    pars.Add(new NpgsqlParameter("@CleanKw", "%" + cleanKw + "%"));
                }
            }

            sql += " ORDER BY p.PermitID DESC";

            var dt = DbHelper.ExecuteDataTable(sql, pars.ToArray());
            DateTime today = DateTime.Today;

            foreach (DataRow dr in dt.Rows)
            {
                DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);
                int daysRemaining = (expDate - today).Days;
                bool isExpiringSoon = daysRemaining >= 0 && daysRemaining <= 30;

                list.Add(new PermitItemDto
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

            return list;
        }

        public PermitItemDto GetPermitById(int permitId)
        {
            string sql = @"
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
                WHERE p.PermitID = @PermitID";

            var dt = DbHelper.ExecuteDataTable(sql, new NpgsqlParameter("@PermitID", permitId));
            if (dt.Rows.Count == 0) return null;

            var dr = dt.Rows[0];
            DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);
            int daysRemaining = (expDate - DateTime.Today).Days;

            return new PermitItemDto
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
                IsExpiringSoon = daysRemaining >= 0 && daysRemaining <= 30
            };
        }

        public OperationResult SavePermit(PermitItemDto dto)
        {
            if (dto == null) return OperationResult.Fail("無效的資料傳入");

            dto.LicensePlate = dto.LicensePlate != null ? dto.LicensePlate.Trim().ToUpper() : null;
            dto.PermitNumber = dto.PermitNumber != null ? dto.PermitNumber.Trim().ToUpper() : null;

            if (string.IsNullOrWhiteSpace(dto.LicensePlate)) return OperationResult.Fail("車牌號碼為必填！");
            if (string.IsNullOrWhiteSpace(dto.PermitNumber)) return OperationResult.Fail("停車證號為必填！");
            if (string.IsNullOrWhiteSpace(dto.OwnerName)) return OperationResult.Fail("車主姓名為必填！");
            if (dto.DeptID <= 0) return OperationResult.Fail("請選擇所屬部門！");
            if (dto.ZoneID <= 0) return OperationResult.Fail("請選擇停車區域！");

            DateTime startDate, expireDate, registerDate;
            if (!DateTime.TryParse(dto.StartDate, out startDate)) return OperationResult.Fail("開始日期格式不正確！");
            if (!DateTime.TryParse(dto.ExpireDate, out expireDate)) return OperationResult.Fail("到期日期格式不正確！");
            if (!DateTime.TryParse(dto.RegisterDate, out registerDate)) registerDate = DateTime.Today;

            if (expireDate < startDate)
            {
                return OperationResult.Fail("到期日期不得早於開始日期！");
            }

            // 檢查車牌或停車證號是否重複
            string chkSql = @"
                SELECT COUNT(1) FROM ParkingPermits 
                WHERE (CleanPlate = REPLACE(REPLACE(@Plate, '-', ''), ' ', '') OR PermitNumber = @PermitNum)
                  AND PermitID <> @PermitID";

            int count = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql,
                new NpgsqlParameter("@Plate", dto.LicensePlate),
                new NpgsqlParameter("@PermitNum", dto.PermitNumber),
                new NpgsqlParameter("@PermitID", dto.PermitID)));

            if (count > 0)
            {
                return OperationResult.Fail("該車牌號碼或通行證號已存在，不得重複新增！");
            }

            string status = string.IsNullOrWhiteSpace(dto.Status) ? "ACTIVE" : dto.Status;
            if (expireDate < DateTime.Today && status == "ACTIVE")
            {
                status = "EXPIRED";
            }

            if (dto.PermitID == 0) // 新增
            {
                string insertSql = @"
                    INSERT INTO ParkingPermits (
                        PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber,
                        RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand,
                        ZoneID, RegisterDate, StartDate, ExpireDate, Status, Remarks
                    ) VALUES (
                        @PermitNumber, @DeptID, @CardNumber, @OwnerName, @SensorTagNumber,
                        @RemoteControllerNo, @VehicleColor, @LicensePlate, @VehicleBrand,
                        @ZoneID, @RegisterDate, @StartDate, @ExpireDate, @Status, @Remarks
                    )";

                DbHelper.ExecuteNonQuery(insertSql,
                    new NpgsqlParameter("@PermitNumber", dto.PermitNumber),
                    new NpgsqlParameter("@DeptID", dto.DeptID),
                    new NpgsqlParameter("@CardNumber", (object)dto.CardNumber ?? DBNull.Value),
                    new NpgsqlParameter("@OwnerName", dto.OwnerName),
                    new NpgsqlParameter("@SensorTagNumber", (object)dto.SensorTagNumber ?? DBNull.Value),
                    new NpgsqlParameter("@RemoteControllerNo", (object)dto.RemoteControllerNo ?? DBNull.Value),
                    new NpgsqlParameter("@VehicleColor", dto.VehicleColor ?? ""),
                    new NpgsqlParameter("@LicensePlate", dto.LicensePlate),
                    new NpgsqlParameter("@VehicleBrand", dto.VehicleBrand ?? ""),
                    new NpgsqlParameter("@ZoneID", dto.ZoneID),
                    new NpgsqlParameter("@RegisterDate", registerDate),
                    new NpgsqlParameter("@StartDate", startDate),
                    new NpgsqlParameter("@ExpireDate", expireDate),
                    new NpgsqlParameter("@Status", status),
                    new NpgsqlParameter("@Remarks", (object)dto.Remarks ?? DBNull.Value)
                );

                return OperationResult.Ok("通行證新增成功！");
            }
            else // 修改
            {
                string updateSql = @"
                    UPDATE ParkingPermits SET
                        PermitNumber = @PermitNumber,
                        DeptID = @DeptID,
                        CardNumber = @CardNumber,
                        OwnerName = @OwnerName,
                        SensorTagNumber = @SensorTagNumber,
                        RemoteControllerNo = @RemoteControllerNo,
                        VehicleColor = @VehicleColor,
                        LicensePlate = @LicensePlate,
                        VehicleBrand = @VehicleBrand,
                        ZoneID = @ZoneID,
                        StartDate = @StartDate,
                        ExpireDate = @ExpireDate,
                        Status = @Status,
                        Remarks = @Remarks,
                        UpdatedDate = CURRENT_TIMESTAMP
                    WHERE PermitID = @PermitID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new NpgsqlParameter("@PermitID", dto.PermitID),
                    new NpgsqlParameter("@PermitNumber", dto.PermitNumber),
                    new NpgsqlParameter("@DeptID", dto.DeptID),
                    new NpgsqlParameter("@CardNumber", (object)dto.CardNumber ?? DBNull.Value),
                    new NpgsqlParameter("@OwnerName", dto.OwnerName),
                    new NpgsqlParameter("@SensorTagNumber", (object)dto.SensorTagNumber ?? DBNull.Value),
                    new NpgsqlParameter("@RemoteControllerNo", (object)dto.RemoteControllerNo ?? DBNull.Value),
                    new NpgsqlParameter("@VehicleColor", dto.VehicleColor ?? ""),
                    new NpgsqlParameter("@LicensePlate", dto.LicensePlate),
                    new NpgsqlParameter("@VehicleBrand", dto.VehicleBrand ?? ""),
                    new NpgsqlParameter("@ZoneID", dto.ZoneID),
                    new NpgsqlParameter("@StartDate", startDate),
                    new NpgsqlParameter("@ExpireDate", expireDate),
                    new NpgsqlParameter("@Status", status),
                    new NpgsqlParameter("@Remarks", (object)dto.Remarks ?? DBNull.Value)
                );

                return OperationResult.Ok("通行證已成功更新！");
            }
        }

        public OperationResult BatchExtendPermits(BatchExtendDto dto)
        {
            if (dto == null || dto.PermitIDs == null || dto.PermitIDs.Count == 0)
            {
                return OperationResult.Fail("請至少勾選一筆欲展期的車輛通行證！");
            }
            if (dto.ExtendMonths <= 0) dto.ExtendMonths = 12;

            int updated = 0;
            foreach (int id in dto.PermitIDs)
            {
                string sql = @"
                    UPDATE ParkingPermits SET
                        ExpireDate = (CASE WHEN ExpireDate < CURRENT_DATE THEN CURRENT_DATE ELSE ExpireDate END) + (@Months || ' month')::interval,
                        Status = 'ACTIVE',
                        UpdatedDate = CURRENT_TIMESTAMP
                    WHERE PermitID = @PermitID";

                updated += DbHelper.ExecuteNonQuery(sql,
                    new NpgsqlParameter("@Months", dto.ExtendMonths),
                    new NpgsqlParameter("@PermitID", id));
            }

            return OperationResult.Ok(string.Format("成功完成 {0} 筆車籍通行證展期 (+{1} 個月)！", updated, dto.ExtendMonths));
        }

        public OperationResult RevokePermit(int permitId, string reason)
        {
            string sql = @"
                UPDATE ParkingPermits SET 
                    Status = 'REVOKED',
                    Remarks = COALESCE(Remarks || ' | ', '') || @Reason,
                    UpdatedDate = CURRENT_TIMESTAMP
                WHERE PermitID = @PermitID";

            int rows = DbHelper.ExecuteNonQuery(sql,
                new NpgsqlParameter("@PermitID", permitId),
                new NpgsqlParameter("@Reason", "【註銷: " + DateTime.Now.ToString("yyyy-MM-dd") + " " + reason + "】"));

            if (rows > 0) return OperationResult.Ok("通行證已成功註銷停權！");
            return OperationResult.Fail("查無此通行證！");
        }

        public OperationResult DeletePermit(int permitId)
        {
            // 檢查巡檢紀錄外鍵
            string chkSql = "SELECT COUNT(1) FROM ParkingInspectionLogs WHERE PermitID = @PermitID";
            int refLogs = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql, new NpgsqlParameter("@PermitID", permitId)));
            if (refLogs > 0)
            {
                // 若有外鍵關聯，轉為註銷
                return RevokePermit(permitId, "關聯巡檢紀錄，系統轉為註銷歸檔");
            }

            string sql = "DELETE FROM ParkingPermits WHERE PermitID = @PermitID";
            int rows = DbHelper.ExecuteNonQuery(sql, new NpgsqlParameter("@PermitID", permitId));
            if (rows > 0) return OperationResult.Ok("通行證已刪除！");
            return OperationResult.Fail("刪除失敗，查無紀錄！");
        }

        public string GeneratePermitCsv(SearchCriteriaDto criteria)
        {
            var permits = SearchPermits(criteria);
            var sb = new StringBuilder();
            // UTF-8 BOM for Excel
            sb.Append('\uFEFF');
            sb.AppendLine("停車證號,部門名稱,員工姓名,員工卡號,車牌號碼,廠牌,車輛顏色,停車區域,感應卡號,遙控器編號,開始日期,到期日期,目前狀態,備註說明");

            foreach (var p in permits)
            {
                string statusText = p.Status == "ACTIVE" ? "正常有效" : (p.Status == "EXPIRED" ? "逾期" : "已註銷");
                string safeRemarks = p.Remarks != null ? p.Remarks.Replace("\"", "\"\"") : "";
                sb.AppendFormat("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\",\"{5}\",\"{6}\",\"{7}\",\"{8}\",\"{9}\",\"{10}\",\"{11}\",\"{12}\",\"{13}\"\r\n",
                    p.PermitNumber, p.DeptName, p.OwnerName, p.CardNumber, p.LicensePlate, p.VehicleBrand, p.VehicleColor,
                    p.ZoneName, p.SensorTagNumber, p.RemoteControllerNo, p.StartDate, p.ExpireDate, statusText, safeRemarks);
            }

            return sb.ToString();
        }

        public string GetImportCsvTemplate()
        {
            var sb = new StringBuilder();
            sb.Append('\uFEFF'); // UTF-8 BOM
            sb.AppendLine("部門科室 (代碼或全稱皆可),員工姓名,員工卡號,車牌號碼,車輛廠牌,車輛顏色,停放區域 (代碼或名稱皆可),感應卡號,遙控器編號,開始日期,到期日期,備註說明");

            var dtDepts = DbHelper.ExecuteDataTable("SELECT DeptCode, DeptName FROM ParkingDepartments WHERE IsActive = TRUE ORDER BY DeptID");
            var dtZones = DbHelper.ExecuteDataTable("SELECT ZoneCode, ZoneName FROM ParkingZones WHERE IsActive = TRUE ORDER BY ZoneID");

            string d1 = dtDepts.Rows.Count > 0 ? dtDepts.Rows[0]["DeptCode"].ToString() : "DEPT01";
            string d2 = dtDepts.Rows.Count > 1 ? dtDepts.Rows[1]["DeptName"].ToString() : (dtDepts.Rows.Count > 0 ? dtDepts.Rows[0]["DeptName"].ToString() : "醫護部");

            string z1 = dtZones.Rows.Count > 0 ? dtZones.Rows[0]["ZoneCode"].ToString() : "";
            string z2 = dtZones.Rows.Count > 1 ? dtZones.Rows[1]["ZoneName"].ToString() : (dtZones.Rows.Count > 0 ? dtZones.Rows[0]["ZoneName"].ToString() : "");

            string today = DateTime.Today.ToString("yyyy-MM-dd");
            string nextYear = DateTime.Today.AddYears(1).ToString("yyyy-MM-dd");

            sb.AppendLine(string.Format("{0},王大明,EMP2001,BPK-8899,Toyota RAV4,極光銀,{1},TAG-8821,RC-8821,{2},{3},填寫科室代碼與區域代碼範例", d1, z1, today, nextYear));
            sb.AppendLine(string.Format("{0},周雅婷,EMP9999,TES-8888,Toyota Yaris,極光白,{1},,,{2},{3},填寫科室全稱與區域名稱範例", d2, z2, today, nextYear));
            return sb.ToString();
        }

        public BatchImportResultDto BatchImportPermits(List<BatchImportItemDto> items, bool skipDuplicates)
        {
            var result = new BatchImportResultDto();
            if (items == null || items.Count == 0)
            {
                result.Success = false;
                result.Message = "未提供匯入資料或資料格式為空！";
                return result;
            }

            result.TotalCount = items.Count;

            // 快取所有有效的部門與停車區域字典
            var dtDepts = DbHelper.ExecuteDataTable("SELECT DeptID, DeptCode, DeptName FROM ParkingDepartments WHERE IsActive = TRUE");
            var dtZones = DbHelper.ExecuteDataTable("SELECT ZoneID, ZoneCode, ZoneName FROM ParkingZones WHERE IsActive = TRUE");

            var deptDict = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (DataRow r in dtDepts.Rows)
            {
                int id = Convert.ToInt32(r["DeptID"]);
                string name = r["DeptName"].ToString();
                string code = r["DeptCode"].ToString();
                deptDict[name] = id;
                deptDict[code] = id;
            }

            var zoneDict = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (DataRow r in dtZones.Rows)
            {
                int id = Convert.ToInt32(r["ZoneID"]);
                string name = r["ZoneName"].ToString();
                string code = r["ZoneCode"].ToString();
                zoneDict[name] = id;
                zoneDict[code] = id;
            }

            var processedPlatesInBatch = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < items.Count; i++)
            {
                int rowNum = i + 1;
                var item = items[i];

                if (item == null)
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 資料為空行", rowNum));
                    continue;
                }

                string plate = (item.LicensePlate ?? "").Trim().ToUpper();
                string cleanPlate = plate.Replace("-", "").Replace(" ", "");

                if (string.IsNullOrWhiteSpace(cleanPlate))
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌號碼不可為空", rowNum));
                    continue;
                }

                if (processedPlatesInBatch.Contains(cleanPlate))
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】在本次匯入清單中重複出現", rowNum, plate));
                    continue;
                }

                // 檢查資料庫車牌是否已存在且 ACTIVE
                string chkSql = "SELECT COUNT(1) FROM ParkingPermits WHERE CleanPlate = @CleanPlate AND Status = 'ACTIVE'";
                int existingCount = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql, new NpgsqlParameter("@CleanPlate", cleanPlate)));
                if (existingCount > 0)
                {
                    if (skipDuplicates)
                    {
                        result.FailCount++;
                        result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】已存在有效通行證，已略過匯入", rowNum, plate));
                        continue;
                    }
                    else
                    {
                        result.FailCount++;
                        result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】已存在有效通行證，同一車輛不可重複建立", rowNum, plate));
                        continue;
                    }
                }

                // 解析部門
                string deptInput = (item.DeptName ?? "").Trim();
                int deptId = 0;
                if (!string.IsNullOrWhiteSpace(deptInput))
                {
                    if (deptDict.ContainsKey(deptInput))
                    {
                        deptId = deptDict[deptInput];
                    }
                    else
                    {
                        // 模糊匹配 (例如: "心臟超音波" 符合 "心臟超音波室")
                        foreach (var kvp in deptDict)
                        {
                            if (kvp.Key.IndexOf(deptInput, StringComparison.OrdinalIgnoreCase) >= 0 ||
                                deptInput.IndexOf(kvp.Key, StringComparison.OrdinalIgnoreCase) >= 0)
                            {
                                deptId = kvp.Value;
                                break;
                            }
                        }
                    }
                }

                if (deptId <= 0)
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】所填部門【{2}】在系統字典中查無對應紀錄", rowNum, plate, deptInput));
                    continue;
                }

                // 解析停車區域
                string zoneInput = (item.ZoneName ?? "").Trim();
                int zoneId = 0;
                if (!string.IsNullOrWhiteSpace(zoneInput))
                {
                    if (zoneDict.ContainsKey(zoneInput))
                    {
                        zoneId = zoneDict[zoneInput];
                    }
                    else
                    {
                        // 模糊匹配 (例如: "A區" 符合 "地下A區")
                        foreach (var kvp in zoneDict)
                        {
                            if (kvp.Key.IndexOf(zoneInput, StringComparison.OrdinalIgnoreCase) >= 0 ||
                                zoneInput.IndexOf(kvp.Key, StringComparison.OrdinalIgnoreCase) >= 0)
                            {
                                zoneId = kvp.Value;
                                break;
                            }
                        }
                    }
                }

                if (zoneId <= 0)
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】所填區域【{2}】在系統中查無對應紀錄", rowNum, plate, zoneInput));
                    continue;
                }

                string owner = !string.IsNullOrWhiteSpace(item.OwnerName) ? item.OwnerName.Trim() : "院區同仁";
                string card = !string.IsNullOrWhiteSpace(item.CardNumber) ? item.CardNumber.Trim().ToUpper() : "EMP" + new Random().Next(1000, 9999);
                string brand = !string.IsNullOrWhiteSpace(item.VehicleBrand) ? item.VehicleBrand.Trim() : "自用車";
                string color = !string.IsNullOrWhiteSpace(item.VehicleColor) ? item.VehicleColor.Trim() : "白色";

                DateTime start = DateTime.Today;
                DateTime parsedStart;
                if (!string.IsNullOrWhiteSpace(item.StartDate) && DateTime.TryParse(item.StartDate, out parsedStart))
                {
                    start = parsedStart;
                }

                DateTime expire = start.AddYears(1);
                DateTime parsedExpire;
                if (!string.IsNullOrWhiteSpace(item.ExpireDate) && DateTime.TryParse(item.ExpireDate, out parsedExpire))
                {
                    expire = parsedExpire;
                }

                if (expire < start)
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】到期日不得早於起始日", rowNum, plate));
                    continue;
                }

                // 產生通行證號 PRK-YYYYMM-XXX
                string prefix = "PRK-" + DateTime.Now.ToString("yyyyMM") + "-";
                int nextSeq = 1;
                string maxSql = "SELECT PermitNumber FROM ParkingPermits WHERE PermitNumber LIKE @Prefix ORDER BY PermitNumber DESC LIMIT 1";
                object maxObj = DbHelper.ExecuteScalar(maxSql, new NpgsqlParameter("@Prefix", prefix + "%"));
                if (maxObj != null && maxObj != DBNull.Value)
                {
                    string maxStr = maxObj.ToString();
                    if (maxStr.StartsWith(prefix))
                    {
                        string seqPart = maxStr.Substring(prefix.Length);
                        int parsedSeq;
                        if (int.TryParse(seqPart, out parsedSeq))
                        {
                            nextSeq = parsedSeq + 1;
                        }
                    }
                }
                string permitNo = string.Format("{0}{1:D3}", prefix, nextSeq);
                while (Convert.ToInt32(DbHelper.ExecuteScalar("SELECT COUNT(1) FROM ParkingPermits WHERE PermitNumber = @PermitNo", new NpgsqlParameter("@PermitNo", permitNo))) > 0)
                {
                    nextSeq++;
                    permitNo = string.Format("{0}{1:D3}", prefix, nextSeq);
                }

                string tag = !string.IsNullOrWhiteSpace(item.SensorTagNumber) ? item.SensorTagNumber.Trim() : ("TAG-" + DateTime.Now.ToString("fff") + new Random().Next(10, 99));
                string remote = !string.IsNullOrWhiteSpace(item.RemoteControllerNo) ? item.RemoteControllerNo.Trim() : ("RC-" + DateTime.Now.ToString("fff") + new Random().Next(10, 99));
                string remarks = !string.IsNullOrWhiteSpace(item.Remarks) ? item.Remarks.Trim() : "批次匯入建立";

                string insertSql = @"
                    INSERT INTO ParkingPermits (
                        PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber,
                        RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand,
                        ZoneID, RegisterDate, StartDate, ExpireDate, Status, Remarks
                    ) VALUES (
                        @PermitNumber, @DeptID, @CardNumber, @OwnerName, @SensorTagNumber,
                        @RemoteControllerNo, @VehicleColor, @LicensePlate, @VehicleBrand,
                        @ZoneID, @RegisterDate, @StartDate, @ExpireDate, 'ACTIVE', @Remarks
                    )";

                try
                {
                    DbHelper.ExecuteNonQuery(insertSql,
                        new NpgsqlParameter("@PermitNumber", permitNo),
                        new NpgsqlParameter("@DeptID", deptId),
                        new NpgsqlParameter("@CardNumber", card),
                        new NpgsqlParameter("@OwnerName", owner),
                        new NpgsqlParameter("@SensorTagNumber", tag),
                        new NpgsqlParameter("@RemoteControllerNo", remote),
                        new NpgsqlParameter("@VehicleColor", color),
                        new NpgsqlParameter("@LicensePlate", plate),
                        new NpgsqlParameter("@VehicleBrand", brand),
                        new NpgsqlParameter("@ZoneID", zoneId),
                        new NpgsqlParameter("@RegisterDate", DateTime.Today),
                        new NpgsqlParameter("@StartDate", start),
                        new NpgsqlParameter("@ExpireDate", expire),
                        new NpgsqlParameter("@Remarks", remarks)
                    );

                    processedPlatesInBatch.Add(cleanPlate);
                    result.SuccessCount++;
                    result.SuccessPermitNumbers.Add(string.Format("{0} ({1})", permitNo, plate));
                }
                catch (Exception ex)
                {
                    result.FailCount++;
                    result.ErrorMessages.Add(string.Format("第 {0} 列: 車牌【{1}】寫入資料庫失敗: {2}", rowNum, plate, ex.Message));
                }
            }

            result.Success = result.SuccessCount > 0;
            result.Message = string.Format("批次匯入處理完成：總筆數 {0} 筆，成功 {1} 筆，失敗 {2} 筆。", result.TotalCount, result.SuccessCount, result.FailCount);
            return result;
        }
    }
}