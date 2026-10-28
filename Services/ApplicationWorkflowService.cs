using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    public class ApplicationWorkflowService
    {
        public OperationResult SubmitApplication(ApplicationDto dto)
        {
            if (dto == null) return OperationResult.Fail("無效的申請資料！");

            dto.ApplicantName = dto.ApplicantName != null ? dto.ApplicantName.Trim() : null;
            dto.EmpNo = dto.EmpNo != null ? dto.EmpNo.Trim().ToUpper() : null;
            dto.LicensePlate = dto.LicensePlate != null ? dto.LicensePlate.Trim().ToUpper() : null;

            if (string.IsNullOrWhiteSpace(dto.ApplicantName)) return OperationResult.Fail("請填寫申請人姓名！");
            if (string.IsNullOrWhiteSpace(dto.EmpNo)) return OperationResult.Fail("請填寫員工工號！");
            if (dto.DeptID <= 0) return OperationResult.Fail("請選擇服務部門！");
            if (string.IsNullOrWhiteSpace(dto.LicensePlate)) return OperationResult.Fail("請填寫車牌號碼！");
            if (dto.PreferredZoneID <= 0) return OperationResult.Fail("請選擇志願停放區域！");

            // 車牌標準化處理 (去空白、連字號與強制大寫)
            string cleanPlate = dto.LicensePlate.Replace("-", "").Replace(" ", "");

            // 1. 檢查該車牌是否已被登記有效停車證 (一車一證，不可重複由同一人或第二人申請)
            string chkPermit = @"
                SELECT TOP 1 p.OwnerName, p.CardNumber, p.PermitNumber, d.DeptName
                FROM ParkingPermits p
                LEFT JOIN ParkingDepartments d ON p.DeptID = d.DeptID
                WHERE p.CleanPlate = @CleanPlate AND p.Status = 'ACTIVE'";
            var dtPermit = DbHelper.ExecuteDataTable(chkPermit, new SqlParameter("@CleanPlate", cleanPlate));
            if (dtPermit.Rows.Count > 0)
            {
                var row = dtPermit.Rows[0];
                string owner = row["OwnerName"].ToString();
                string card = row["CardNumber"].ToString();
                string pNo = row["PermitNumber"].ToString();
                return OperationResult.Fail(string.Format("車牌【{0}】目前已被【{1} (工號: {2})】登記有效通行證【{3}】，同一車輛不可重複申請！若有過戶或異動需求請洽總務處。", dto.LicensePlate, owner, card, pNo));
            }

            // 2. 檢查是否有該車牌之審核中申請單 (PENDING, PROCESSING, WAITLIST, APPROVED)
            // 規則：一人可申請多台車輛，但同一車輛不可讓二人申請 (依車牌唯一防呆)
            string chkPending = @"
                SELECT TOP 1 ApplicationNo, ApplicantName, EmpNo, ReviewStatus 
                FROM ParkingEmployeeApplications 
                WHERE REPLACE(REPLACE(LicensePlate, '-', ''), ' ', '') = @CleanPlate 
                  AND ReviewStatus IN ('PENDING', 'PROCESSING', 'WAITLIST', 'APPROVED')";
            var dtPending = DbHelper.ExecuteDataTable(chkPending, new SqlParameter("@CleanPlate", cleanPlate));
            if (dtPending.Rows.Count > 0)
            {
                var row = dtPending.Rows[0];
                string pendingAppNo = row["ApplicationNo"].ToString();
                string pendingApplicant = row["ApplicantName"].ToString();
                string pendingEmpNo = row["EmpNo"].ToString();

                if (!string.Equals(pendingEmpNo, dto.EmpNo, StringComparison.OrdinalIgnoreCase))
                {
                    return OperationResult.Fail(string.Format("此車牌【{0}】目前已由同仁【{1} (工號: {2})】於申請單【{3}】申辦審理中，同一車輛不可由二人重複申請！", dto.LicensePlate, pendingApplicant, pendingEmpNo, pendingAppNo));
                }
                else
                {
                    return OperationResult.Fail(string.Format("您已為此車輛【{0}】送出過申請單【{1}】（審核中），同一車輛請勿重複送件！若欲申請第二台車輛，請填寫不同車牌號碼。", dto.LicensePlate, pendingAppNo));
                }
            }

            // 產生申請單號 APP-YYYYMMDD-XXX
            string todayStr = DateTime.Now.ToString("yyyyMMdd");
            string countSql = "SELECT COUNT(1) + 1 FROM ParkingEmployeeApplications WHERE CONVERT(VARCHAR(8), ApplyDate, 112) = @Today";
            int dailySeq = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, new SqlParameter("@Today", todayStr)));
            string appNo = string.Format("APP-{0}-{1:D3}", todayStr, dailySeq);

            string insertSql = @"
                INSERT INTO ParkingEmployeeApplications (
                    ApplicationNo, EmpNo, ApplicantName, DeptID, ContactPhone,
                    LicensePlate, VehicleBrand, VehicleColor, PreferredZoneID, ApplyDate, ReviewStatus
                ) VALUES (
                    @ApplicationNo, @EmpNo, @ApplicantName, @DeptID, @ContactPhone,
                    @LicensePlate, @VehicleBrand, @VehicleColor, @PreferredZoneID, GETDATE(), 'PENDING'
                )";

            DbHelper.ExecuteNonQuery(insertSql,
                new SqlParameter("@ApplicationNo", appNo),
                new SqlParameter("@EmpNo", dto.EmpNo),
                new SqlParameter("@ApplicantName", dto.ApplicantName),
                new SqlParameter("@DeptID", dto.DeptID),
                new SqlParameter("@ContactPhone", (object)dto.ContactPhone ?? DBNull.Value),
                new SqlParameter("@LicensePlate", dto.LicensePlate),
                new SqlParameter("@VehicleBrand", dto.VehicleBrand ?? ""),
                new SqlParameter("@VehicleColor", dto.VehicleColor ?? ""),
                new SqlParameter("@PreferredZoneID", dto.PreferredZoneID)
            );

            return OperationResult.Ok("申請單已順利送出！請妥善保存申請單號以利追蹤進度。", appNo);
        }

        public List<ApplicationDto> GetApplications(string reviewStatus, string keyword)
        {
            var list = new List<ApplicationDto>();
            string sql = @"
                SELECT a.ApplicationID, a.ApplicationNo, a.EmpNo, a.ApplicantName, a.DeptID, d.DeptName,
                       a.ContactPhone, a.LicensePlate, a.VehicleBrand, a.VehicleColor,
                       a.PreferredZoneID, z.ZoneName AS PreferredZoneName,
                       a.AssignedZoneID, az.ZoneName AS AssignedZoneName,
                       CONVERT(VARCHAR(16), a.ApplyDate, 120) AS ApplyDate,
                       a.ReviewStatus, a.ReviewerName,
                       CONVERT(VARCHAR(16), a.ReviewDate, 120) AS ReviewDate,
                       a.RejectReason, a.ReviewRemarks
                FROM ParkingEmployeeApplications a
                INNER JOIN ParkingDepartments d ON a.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON a.PreferredZoneID = z.ZoneID
                LEFT JOIN ParkingZones az ON a.AssignedZoneID = az.ZoneID
                WHERE 1=1 ";

            var pars = new List<SqlParameter>();

            if (!string.IsNullOrWhiteSpace(reviewStatus))
            {
                if (reviewStatus.Equals("ACTIVE", StringComparison.OrdinalIgnoreCase) ||
                    reviewStatus.Equals("PENDING_ALL", StringComparison.OrdinalIgnoreCase))
                {
                    sql += " AND a.ReviewStatus IN ('PENDING', 'PROCESSING', 'WAITLIST', 'APPROVED') ";
                }
                else
                {
                    sql += " AND a.ReviewStatus = @Status ";
                    pars.Add(new SqlParameter("@Status", reviewStatus));
                }
            }

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                sql += " AND (a.EmpNo LIKE @Kw OR a.ApplicantName LIKE @Kw OR a.LicensePlate LIKE @Kw OR a.ApplicationNo LIKE @Kw) ";
                pars.Add(new SqlParameter("@Kw", "%" + keyword.Trim() + "%"));
            }

            sql += " ORDER BY a.ApplicationID DESC";

            var dt = DbHelper.ExecuteDataTable(sql, pars.ToArray());
            foreach (DataRow dr in dt.Rows)
            {
                list.Add(new ApplicationDto
                {
                    ApplicationID = Convert.ToInt32(dr["ApplicationID"]),
                    ApplicationNo = dr["ApplicationNo"].ToString(),
                    EmpNo = dr["EmpNo"].ToString(),
                    ApplicantName = dr["ApplicantName"].ToString(),
                    DeptID = Convert.ToInt32(dr["DeptID"]),
                    DeptName = dr["DeptName"].ToString(),
                    ContactPhone = dr["ContactPhone"] != DBNull.Value ? dr["ContactPhone"].ToString() : "",
                    LicensePlate = dr["LicensePlate"].ToString(),
                    VehicleBrand = dr["VehicleBrand"].ToString(),
                    VehicleColor = dr["VehicleColor"].ToString(),
                    PreferredZoneID = Convert.ToInt32(dr["PreferredZoneID"]),
                    PreferredZoneName = dr["PreferredZoneName"].ToString(),
                    AssignedZoneID = dr["AssignedZoneID"] != DBNull.Value ? (int?)Convert.ToInt32(dr["AssignedZoneID"]) : null,
                    AssignedZoneName = dr["AssignedZoneName"] != DBNull.Value ? dr["AssignedZoneName"].ToString() : null,
                    ApplyDate = dr["ApplyDate"].ToString(),
                    ReviewStatus = dr["ReviewStatus"].ToString(),
                    ReviewerName = dr["ReviewerName"] != DBNull.Value ? dr["ReviewerName"].ToString() : "",
                    ReviewDate = dr["ReviewDate"] != DBNull.Value ? dr["ReviewDate"].ToString() : "",
                    RejectReason = dr["RejectReason"] != DBNull.Value ? dr["RejectReason"].ToString() : "",
                    ReviewRemarks = dr["ReviewRemarks"] != DBNull.Value ? dr["ReviewRemarks"].ToString() : ""
                });
            }

            return list;
        }

        public List<ApplicationDto> GetApplications(string reviewStatus)
        {
            return GetApplications(reviewStatus, null);
        }

        public List<ApplicationDto> SearchEmployeeApplications(string query)
        {
            if (string.IsNullOrWhiteSpace(query)) return new List<ApplicationDto>();
            query = query.Trim().ToUpper();

            string sql = @"
                SELECT a.ApplicationID, a.ApplicationNo, a.EmpNo, a.ApplicantName, a.DeptID, d.DeptName,
                       a.ContactPhone, a.LicensePlate, a.VehicleBrand, a.VehicleColor,
                       a.PreferredZoneID, z.ZoneName AS PreferredZoneName,
                       a.AssignedZoneID, az.ZoneName AS AssignedZoneName,
                       CONVERT(VARCHAR(16), a.ApplyDate, 120) AS ApplyDate,
                       a.ReviewStatus, a.ReviewerName,
                       CONVERT(VARCHAR(16), a.ReviewDate, 120) AS ReviewDate,
                       a.RejectReason, a.ReviewRemarks
                FROM ParkingEmployeeApplications a
                INNER JOIN ParkingDepartments d ON a.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON a.PreferredZoneID = z.ZoneID
                LEFT JOIN ParkingZones az ON a.AssignedZoneID = az.ZoneID
                WHERE a.EmpNo = @Query OR a.ApplicationNo = @Query OR a.LicensePlate = @Query
                ORDER BY a.ApplicationID DESC";

            var dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@Query", query));
            var list = new List<ApplicationDto>();

            foreach (DataRow dr in dt.Rows)
            {
                list.Add(new ApplicationDto
                {
                    ApplicationID = Convert.ToInt32(dr["ApplicationID"]),
                    ApplicationNo = dr["ApplicationNo"].ToString(),
                    EmpNo = dr["EmpNo"].ToString(),
                    ApplicantName = dr["ApplicantName"].ToString(),
                    DeptID = Convert.ToInt32(dr["DeptID"]),
                    DeptName = dr["DeptName"].ToString(),
                    ContactPhone = dr["ContactPhone"] != DBNull.Value ? dr["ContactPhone"].ToString() : "",
                    LicensePlate = dr["LicensePlate"].ToString(),
                    VehicleBrand = dr["VehicleBrand"].ToString(),
                    VehicleColor = dr["VehicleColor"].ToString(),
                    PreferredZoneID = Convert.ToInt32(dr["PreferredZoneID"]),
                    PreferredZoneName = dr["PreferredZoneName"].ToString(),
                    AssignedZoneID = dr["AssignedZoneID"] != DBNull.Value ? (int?)Convert.ToInt32(dr["AssignedZoneID"]) : null,
                    AssignedZoneName = dr["AssignedZoneName"] != DBNull.Value ? dr["AssignedZoneName"].ToString() : null,
                    ApplyDate = dr["ApplyDate"].ToString(),
                    ReviewStatus = dr["ReviewStatus"].ToString(),
                    ReviewerName = dr["ReviewerName"] != DBNull.Value ? dr["ReviewerName"].ToString() : "",
                    ReviewDate = dr["ReviewDate"] != DBNull.Value ? dr["ReviewDate"].ToString() : "",
                    RejectReason = dr["RejectReason"] != DBNull.Value ? dr["RejectReason"].ToString() : "",
                    ReviewRemarks = dr["ReviewRemarks"] != DBNull.Value ? dr["ReviewRemarks"].ToString() : ""
                });
            }

            return list;
        }

        /// <summary>
        /// 1. 收案 (Accept / Intake)：正式受理審核案件
        /// </summary>
        public OperationResult AcceptApplication(int applicationId, int? assignedZoneId, string remarks, string reviewerName)
        {
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            string fetchSql = "SELECT ReviewStatus FROM ParkingEmployeeApplications WHERE ApplicationID = @AppID";
            object currentStatusObj = DbHelper.ExecuteScalar(fetchSql, new SqlParameter("@AppID", applicationId));
            if (currentStatusObj == null) return OperationResult.Fail("查無此申請單！");
            string currentStatus = currentStatusObj.ToString();

            if (currentStatus == "COMPLETED" || currentStatus == "REJECTED")
            {
                return OperationResult.Fail(string.Format("該案件目前已為【{0}】，不可再進行收案操作！", currentStatus));
            }

            string updateSql = @"
                UPDATE ParkingEmployeeApplications SET
                    ReviewStatus = 'PROCESSING',
                    AssignedZoneID = CASE WHEN @AssignedZoneID > 0 THEN @AssignedZoneID ELSE AssignedZoneID END,
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE(),
                    ReviewRemarks = @Remarks
                WHERE ApplicationID = @AppID";

            int rows = DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@AssignedZoneID", (object)(assignedZoneId.HasValue ? assignedZoneId.Value : (object)DBNull.Value)),
                new SqlParameter("@Remarks", (object)(remarks ?? "已受理收案，資料查驗審核中") ?? DBNull.Value),
                new SqlParameter("@AppID", applicationId));

            if (rows > 0) return OperationResult.Ok("已完成【收案】！案件進入審查中程序。");
            return OperationResult.Fail("收案操作失敗！");
        }

        public OperationResult AcceptApplication(int applicationId, string remarks, string reviewerName)
        {
            return AcceptApplication(applicationId, null, remarks, reviewerName);
        }

        /// <summary>
        /// 2. 待排序 (Waitlist / Queue)：配額額滿或依資格輪候待排
        /// </summary>
        public OperationResult WaitlistApplication(int applicationId, int? assignedZoneId, string remarks, string reviewerName)
        {
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            string fetchSql = "SELECT ReviewStatus FROM ParkingEmployeeApplications WHERE ApplicationID = @AppID";
            object currentStatusObj = DbHelper.ExecuteScalar(fetchSql, new SqlParameter("@AppID", applicationId));
            if (currentStatusObj == null) return OperationResult.Fail("查無此申請單！");
            string currentStatus = currentStatusObj.ToString();

            if (currentStatus == "COMPLETED" || currentStatus == "REJECTED")
            {
                return OperationResult.Fail(string.Format("該案件目前已為【{0}】，不可再進行待排序操作！", currentStatus));
            }

            string updateSql = @"
                UPDATE ParkingEmployeeApplications SET
                    ReviewStatus = 'WAITLIST',
                    AssignedZoneID = CASE WHEN @AssignedZoneID > 0 THEN @AssignedZoneID ELSE AssignedZoneID END,
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE(),
                    ReviewRemarks = @Remarks
                WHERE ApplicationID = @AppID";

            int rows = DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@AssignedZoneID", (object)(assignedZoneId.HasValue ? assignedZoneId.Value : (object)DBNull.Value)),
                new SqlParameter("@Remarks", (object)(remarks ?? "目前配額額滿，已列入排序輪候名單") ?? DBNull.Value),
                new SqlParameter("@AppID", applicationId));

            if (rows > 0) return OperationResult.Ok("已將案件設為【待排序】！等待車位配額釋出或排序評比。");
            return OperationResult.Fail("設定待排序操作失敗！");
        }

        public OperationResult WaitlistApplication(int applicationId, string remarks, string reviewerName)
        {
            return WaitlistApplication(applicationId, null, remarks, reviewerName);
        }

        /// <summary>
        /// 3. 待領證 (Ready For Pickup / Approved)：審核通過，通知同仁領卡
        /// </summary>
        public OperationResult MarkReadyPickup(int applicationId, int? assignedZoneId, string remarks, string reviewerName)
        {
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            string fetchSql = "SELECT ReviewStatus FROM ParkingEmployeeApplications WHERE ApplicationID = @AppID";
            object currentStatusObj = DbHelper.ExecuteScalar(fetchSql, new SqlParameter("@AppID", applicationId));
            if (currentStatusObj == null) return OperationResult.Fail("查無此申請單！");
            string currentStatus = currentStatusObj.ToString();

            if (currentStatus == "COMPLETED" || currentStatus == "REJECTED")
            {
                return OperationResult.Fail(string.Format("該案件目前已為【{0}】，不可再標記待領證！", currentStatus));
            }

            string updateSql = @"
                UPDATE ParkingEmployeeApplications SET
                    ReviewStatus = 'APPROVED',
                    AssignedZoneID = CASE WHEN @AssignedZoneID > 0 THEN @AssignedZoneID ELSE AssignedZoneID END,
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE(),
                    ReviewRemarks = @Remarks
                WHERE ApplicationID = @AppID";

            int rows = DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@AssignedZoneID", (object)(assignedZoneId.HasValue ? assignedZoneId.Value : (object)DBNull.Value)),
                new SqlParameter("@Remarks", (object)(remarks ?? "審核通過，請攜帶識別證至總務處領取感應卡與遙控器") ?? DBNull.Value),
                new SqlParameter("@AppID", applicationId));

            if (rows > 0) return OperationResult.Ok("審核通過！案件已標記為【待領證】，請通知同仁攜證前來總務處領取通行證。");
            return OperationResult.Fail("標記待領證操作失敗！");
        }

        public OperationResult MarkReadyPickup(int applicationId, string remarks, string reviewerName)
        {
            return MarkReadyPickup(applicationId, null, remarks, reviewerName);
        }

        /// <summary>
        /// 4. 發證 (Issue Permit & Finalize)：臨櫃領證並綁定硬體卡號，建立車籍通行證主檔 (管理者可指定或調整實際停放區域)
        /// </summary>
        public OperationResult IssuePermit(int applicationId, int? assignedZoneId, string sensorTag, string remoteNo, DateTime? expireDate, string remarks, string reviewerName)
        {
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            string fetchSql = "SELECT * FROM ParkingEmployeeApplications WHERE ApplicationID = @AppID";
            var dt = DbHelper.ExecuteDataTable(fetchSql, new SqlParameter("@AppID", applicationId));
            if (dt.Rows.Count == 0) return OperationResult.Fail("查無此申請單！");

            var row = dt.Rows[0];
            string currentStatus = row["ReviewStatus"].ToString();
            if (currentStatus == "COMPLETED")
            {
                return OperationResult.Fail("該案件已發證結案，不可重複發證！");
            }
            if (currentStatus == "REJECTED")
            {
                return OperationResult.Fail("該案件已被駁回，無法直接發證！");
            }

            int deptId = Convert.ToInt32(row["DeptID"]);

            // 實際停放區域：優先採用管理者當前指定之 assignedZoneId，其次為歷史 AssignedZoneID，最後回退至志願 PreferredZoneID
            int zoneId = (assignedZoneId.HasValue && assignedZoneId.Value > 0)
                ? assignedZoneId.Value
                : (row["AssignedZoneID"] != DBNull.Value && Convert.ToInt32(row["AssignedZoneID"]) > 0 
                    ? Convert.ToInt32(row["AssignedZoneID"]) 
                    : Convert.ToInt32(row["PreferredZoneID"]));

            string plate = row["LicensePlate"].ToString();
            string owner = row["ApplicantName"].ToString();
            string empNo = row["EmpNo"].ToString();
            string brand = row["VehicleBrand"].ToString();
            string color = row["VehicleColor"].ToString();

            // 檢查車牌是否已在 Permits 主檔有 ACTIVE 記錄
            string chkSql = "SELECT COUNT(1) FROM ParkingPermits WHERE CleanPlate = REPLACE(REPLACE(@Plate, '-', ''), ' ', '') AND Status = 'ACTIVE'";
            int dup = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql, new SqlParameter("@Plate", plate)));
            if (dup > 0)
            {
                return OperationResult.Fail("該車牌目前已有院區有效通行證，無法重複發證！");
            }

            // 產生通行證號 PRK-YYYYMM-XXX
            string prefix = "PRK-" + DateTime.Now.ToString("yyyyMM");
            string countPermitSql = "SELECT COUNT(1) + 1 FROM ParkingPermits WHERE PermitNumber LIKE @Prefix";
            int seq = Convert.ToInt32(DbHelper.ExecuteScalar(countPermitSql, new SqlParameter("@Prefix", prefix + "%")));
            string permitNo = string.Format("{0}-{1:D3}", prefix, seq);

            DateTime start = DateTime.Today;
            DateTime expire = expireDate.HasValue ? expireDate.Value : DateTime.Today.AddYears(1);
            string finalTag = !string.IsNullOrWhiteSpace(sensorTag) ? sensorTag.Trim() : ("TAG-" + DateTime.Now.ToString("fff") + new Random().Next(10, 99));
            string finalRemote = !string.IsNullOrWhiteSpace(remoteNo) ? remoteNo.Trim() : ("RC-" + DateTime.Now.ToString("fff") + new Random().Next(10, 99));

            string insertPermitSql = @"
                INSERT INTO ParkingPermits (
                    PermitNumber, DeptID, CardNumber, OwnerName, SensorTagNumber,
                    RemoteControllerNo, VehicleColor, LicensePlate, VehicleBrand,
                    ZoneID, RegisterDate, StartDate, ExpireDate, Status, Remarks
                ) VALUES (
                    @PermitNumber, @DeptID, @CardNumber, @OwnerName, @SensorTagNumber,
                    @RemoteControllerNo, @VehicleColor, @LicensePlate, @VehicleBrand,
                    @ZoneID, @RegisterDate, @StartDate, @ExpireDate, 'ACTIVE', @Remarks
                )";

            DbHelper.ExecuteNonQuery(insertPermitSql,
                new SqlParameter("@PermitNumber", permitNo),
                new SqlParameter("@DeptID", deptId),
                new SqlParameter("@CardNumber", empNo),
                new SqlParameter("@OwnerName", owner),
                new SqlParameter("@SensorTagNumber", finalTag),
                new SqlParameter("@RemoteControllerNo", finalRemote),
                new SqlParameter("@VehicleColor", color),
                new SqlParameter("@LicensePlate", plate),
                new SqlParameter("@VehicleBrand", brand),
                new SqlParameter("@ZoneID", zoneId),
                new SqlParameter("@RegisterDate", start),
                new SqlParameter("@StartDate", start),
                new SqlParameter("@ExpireDate", expire),
                new SqlParameter("@Remarks", (object)(remarks ?? "員工線上申請審核通過發證") ?? DBNull.Value)
            );

            // 更新申請單狀態為 COMPLETED 並寫入最終實際核定停放區域 AssignedZoneID
            string updateAppSql = @"
                UPDATE ParkingEmployeeApplications SET
                    ReviewStatus = 'COMPLETED',
                    AssignedZoneID = @ZoneID,
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE(),
                    ReviewRemarks = @Remarks
                WHERE ApplicationID = @AppID";

            DbHelper.ExecuteNonQuery(updateAppSql,
                new SqlParameter("@ZoneID", zoneId),
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@Remarks", (object)(remarks ?? string.Format("已核發通行證【{0}】，卡號：{1}", permitNo, finalTag)) ?? DBNull.Value),
                new SqlParameter("@AppID", applicationId));

            return OperationResult.Ok(string.Format("發證成功！已建立車籍通行證【{0}】（感應卡：{1}，有效至 {2:yyyy-MM-dd}），申請單已結案啟用。", permitNo, finalTag, expire), permitNo);
        }

        public OperationResult IssuePermit(int applicationId, string sensorTag, string remoteNo, DateTime? expireDate, string remarks, string reviewerName)
        {
            return IssuePermit(applicationId, null, sensorTag, remoteNo, expireDate, remarks, reviewerName);
        }

        /// <summary>
        /// 單獨更新實際停放區域 (管理者隨時可彈性調整)
        /// </summary>
        public OperationResult UpdateAssignedZone(int applicationId, int zoneId, string reviewerName)
        {
            if (zoneId <= 0) return OperationResult.Fail("請選擇正確的停放區域！");
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            string sql = @"
                UPDATE ParkingEmployeeApplications SET
                    AssignedZoneID = @ZoneID,
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE()
                WHERE ApplicationID = @AppID";

            int rows = DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@ZoneID", zoneId),
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@AppID", applicationId));

            if (rows > 0) return OperationResult.Ok("實際安排停放區域已更新成功！");
            return OperationResult.Fail("更新停放區域失敗，查無此案件！");
        }

        /// <summary>
        /// 5. 駁回申請 (Reject Application)：不予核准並載明駁回原因
        /// </summary>
        public OperationResult RejectApplication(int applicationId, string rejectReason, string reviewerName)
        {
            if (string.IsNullOrWhiteSpace(reviewerName)) reviewerName = "總務處 審核專員";

            if (string.IsNullOrWhiteSpace(rejectReason))
            {
                return OperationResult.Fail("請填寫駁回原因！");
            }

            string updateSql = @"
                UPDATE ParkingEmployeeApplications SET
                    ReviewStatus = 'REJECTED',
                    ReviewerName = @Reviewer,
                    ReviewDate = GETDATE(),
                    RejectReason = @Reason
                WHERE ApplicationID = @AppID AND ReviewStatus NOT IN ('COMPLETED', 'REJECTED')";

            int rows = DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@Reviewer", reviewerName),
                new SqlParameter("@Reason", rejectReason.Trim()),
                new SqlParameter("@AppID", applicationId));

            if (rows > 0) return OperationResult.Ok("申請單已駁回！");
            return OperationResult.Fail("駁回失敗，該單可能已結案或不存在。");
        }

        /// <summary>
        /// 快速核准相容介面 (預設進行待領證通知)
        /// </summary>
        public OperationResult ApproveApplication(int applicationId, string reviewerName)
        {
            return MarkReadyPickup(applicationId, "線上審核核准，待領證", reviewerName);
        }
    }
}
