using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    /// <summary>
    /// 管理者與現場巡檢人員維護服務 (Admin User Management Service)
    /// </summary>
    public class AdminUserService
    {
        public AdminUserService()
        {
            var auth = new AuthService();
            auth.EnsureAdminTableInitialized();
        }

        /// <summary>
        /// 取得管理者與巡檢人員總覽統計及清單 (支援關鍵字、身分角色與啟用狀態篩選)
        /// </summary>
        public AdminUserOverviewDto GetAdminUserOverview(string keyword = null, string roleFilter = null, string statusFilter = null)
        {
            var overview = new AdminUserOverviewDto();

            // 1. 全局 KPI 統計
            string kpiSql = @"
                SELECT 
                    COUNT(1) AS TotalUsers,
                    SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveUsers,
                    SUM(CASE WHEN Role IN ('SUPER_ADMIN', 'ADMIN') THEN 1 ELSE 0 END) AS AdminCount,
                    SUM(CASE WHEN Role = 'SECURITY' THEN 1 ELSE 0 END) AS SecurityCount
                FROM ParkingSystemAdmins";

            var dtKpi = DbHelper.ExecuteDataTable(kpiSql);
            if (dtKpi.Rows.Count > 0)
            {
                var r = dtKpi.Rows[0];
                overview.TotalUsers = r["TotalUsers"] != DBNull.Value ? Convert.ToInt32(r["TotalUsers"]) : 0;
                overview.ActiveUsers = r["ActiveUsers"] != DBNull.Value ? Convert.ToInt32(r["ActiveUsers"]) : 0;
                overview.AdminCount = r["AdminCount"] != DBNull.Value ? Convert.ToInt32(r["AdminCount"]) : 0;
                overview.SecurityCount = r["SecurityCount"] != DBNull.Value ? Convert.ToInt32(r["SecurityCount"]) : 0;
            }

            // 2. 帳號明細清單
            string sql = @"
                SELECT 
                    AdminID,
                    Username,
                    DisplayName,
                    Role,
                    RoleName,
                    DeptName,
                    ContactPhone,
                    Email,
                    CONVERT(VARCHAR(19), LastLoginTime, 120) AS LastLoginTime,
                    IsActive,
                    CONVERT(VARCHAR(19), CreatedDate, 120) AS CreatedDate,
                    Remarks
                FROM ParkingSystemAdmins
                WHERE 1=1 ";

            var pars = new List<SqlParameter>();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                sql += @" AND (
                    Username LIKE @Kw OR 
                    DisplayName LIKE @Kw OR 
                    DeptName LIKE @Kw OR 
                    ContactPhone LIKE @Kw OR 
                    RoleName LIKE @Kw
                )";
                pars.Add(new SqlParameter("@Kw", "%" + keyword.Trim() + "%"));
            }

            if (!string.IsNullOrWhiteSpace(roleFilter) && roleFilter != "ALL")
            {
                if (roleFilter == "ADMIN_GROUP")
                {
                    sql += " AND Role IN ('SUPER_ADMIN', 'ADMIN') ";
                }
                else
                {
                    sql += " AND Role = @Role ";
                    pars.Add(new SqlParameter("@Role", roleFilter.Trim()));
                }
            }

            if (!string.IsNullOrWhiteSpace(statusFilter) && statusFilter != "ALL")
            {
                if (statusFilter == "ACTIVE")
                {
                    sql += " AND IsActive = 1 ";
                }
                else if (statusFilter == "INACTIVE")
                {
                    sql += " AND IsActive = 0 ";
                }
            }

            sql += " ORDER BY IsActive DESC, Role ASC, AdminID ASC";

            var dtList = DbHelper.ExecuteDataTable(sql, pars.ToArray());
            foreach (DataRow row in dtList.Rows)
            {
                overview.UserList.Add(new AdminUserManageDto
                {
                    AdminID = Convert.ToInt32(row["AdminID"]),
                    Username = row["Username"].ToString().Trim(),
                    DisplayName = row["DisplayName"].ToString().Trim(),
                    Role = row["Role"].ToString().Trim(),
                    RoleName = row["RoleName"].ToString().Trim(),
                    DeptName = row["DeptName"].ToString().Trim(),
                    ContactPhone = row["ContactPhone"] != DBNull.Value ? row["ContactPhone"].ToString().Trim() : "",
                    Email = row["Email"] != DBNull.Value ? row["Email"].ToString().Trim() : "",
                    LastLoginTime = row["LastLoginTime"] != DBNull.Value ? row["LastLoginTime"].ToString() : "從未登入",
                    IsActive = Convert.ToBoolean(row["IsActive"]),
                    CreatedDate = row["CreatedDate"].ToString(),
                    Remarks = row["Remarks"] != DBNull.Value ? row["Remarks"].ToString().Trim() : ""
                });
            }

            return overview;
        }

        /// <summary>
        /// 依據 ID 取得特定帳號詳細資料
        /// </summary>
        public AdminUserManageDto GetAdminUserById(int adminId)
        {
            string sql = @"
                SELECT 
                    AdminID,
                    Username,
                    DisplayName,
                    Role,
                    RoleName,
                    DeptName,
                    ContactPhone,
                    Email,
                    CONVERT(VARCHAR(19), LastLoginTime, 120) AS LastLoginTime,
                    IsActive,
                    CONVERT(VARCHAR(19), CreatedDate, 120) AS CreatedDate,
                    Remarks
                FROM ParkingSystemAdmins
                WHERE AdminID = @AdminID";

            var dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@AdminID", adminId));
            if (dt.Rows.Count == 0) return null;

            var r = dt.Rows[0];
            return new AdminUserManageDto
            {
                AdminID = Convert.ToInt32(r["AdminID"]),
                Username = r["Username"].ToString().Trim(),
                DisplayName = r["DisplayName"].ToString().Trim(),
                Role = r["Role"].ToString().Trim(),
                RoleName = r["RoleName"].ToString().Trim(),
                DeptName = r["DeptName"].ToString().Trim(),
                ContactPhone = r["ContactPhone"] != DBNull.Value ? r["ContactPhone"].ToString().Trim() : "",
                Email = r["Email"] != DBNull.Value ? r["Email"].ToString().Trim() : "",
                LastLoginTime = r["LastLoginTime"] != DBNull.Value ? r["LastLoginTime"].ToString() : "",
                IsActive = Convert.ToBoolean(r["IsActive"]),
                CreatedDate = r["CreatedDate"].ToString(),
                Remarks = r["Remarks"] != DBNull.Value ? r["Remarks"].ToString().Trim() : ""
            };
        }

        /// <summary>
        /// 新增或儲存管理者 / 巡檢人員帳號資訊 (支援重複帳號防呆與密碼彈性處理)
        /// </summary>
        public OperationResult SaveAdminUser(AdminUserManageDto dto)
        {
            if (dto == null) return OperationResult.Fail("無效的資料傳入！");

            string username = (dto.Username ?? "").Trim();
            string displayName = (dto.DisplayName ?? "").Trim();
            string role = (dto.Role ?? "ADMIN").Trim().ToUpper();
            string deptName = (dto.DeptName ?? "").Trim();
            string phone = (dto.ContactPhone ?? "").Trim();
            string email = (dto.Email ?? "").Trim();
            string remarks = (dto.Remarks ?? "").Trim();

            if (string.IsNullOrWhiteSpace(username)) return OperationResult.Fail("登入帳號為必填欄位！");
            if (string.IsNullOrWhiteSpace(displayName)) return OperationResult.Fail("人員姓名 / 稱謂為必填欄位！");
            if (string.IsNullOrWhiteSpace(deptName)) deptName = role == "SECURITY" ? "安全警衛課" : "總務行政處";

            // 計算預設角色名稱
            string roleName = dto.RoleName;
            if (string.IsNullOrWhiteSpace(roleName))
            {
                if (role == "SUPER_ADMIN") roleName = "總務最高管理員";
                else if (role == "SECURITY") roleName = "現場巡檢人員";
                else roleName = "總務系統管理員";
            }

            // 檢查帳號唯一性防呆
            string chkSql = "SELECT COUNT(1) FROM ParkingSystemAdmins WHERE Username = @Username AND AdminID <> @AdminID";
            int count = Convert.ToInt32(DbHelper.ExecuteScalar(chkSql,
                new SqlParameter("@Username", username),
                new SqlParameter("@AdminID", dto.AdminID)));

            if (count > 0)
            {
                return OperationResult.Fail(string.Format("登入帳號【{0}】已被其他同仁使用，請選擇不同帳號！", username));
            }

            if (dto.AdminID == 0) // 新增
            {
                string pwd = (dto.Password ?? "").Trim();
                if (string.IsNullOrWhiteSpace(pwd))
                {
                    return OperationResult.Fail("新增人員帳號時，登入密碼為必填！");
                }

                string insertSql = @"
                    INSERT INTO ParkingSystemAdmins (
                        Username, Password, DisplayName, Role, RoleName, DeptName,
                        ContactPhone, Email, IsActive, CreatedDate, Remarks
                    ) VALUES (
                        @Username, @Password, @DisplayName, @Role, @RoleName, @DeptName,
                        @ContactPhone, @Email, @IsActive, GETDATE(), @Remarks
                    )";

                DbHelper.ExecuteNonQuery(insertSql,
                    new SqlParameter("@Username", username),
                    new SqlParameter("@Password", pwd),
                    new SqlParameter("@DisplayName", displayName),
                    new SqlParameter("@Role", role),
                    new SqlParameter("@RoleName", roleName),
                    new SqlParameter("@DeptName", deptName),
                    new SqlParameter("@ContactPhone", (object)phone ?? DBNull.Value),
                    new SqlParameter("@Email", (object)email ?? DBNull.Value),
                    new SqlParameter("@IsActive", dto.IsActive),
                    new SqlParameter("@Remarks", (object)remarks ?? DBNull.Value));

                return OperationResult.Ok(string.Format("已成功新增【{0}】({1}) 權限帳號！", displayName, roleName));
            }
            else // 修改
            {
                string pwd = (dto.Password ?? "").Trim();
                string updateSql;

                if (!string.IsNullOrWhiteSpace(pwd))
                {
                    updateSql = @"
                        UPDATE ParkingSystemAdmins
                        SET Username = @Username,
                            Password = @Password,
                            DisplayName = @DisplayName,
                            Role = @Role,
                            RoleName = @RoleName,
                            DeptName = @DeptName,
                            ContactPhone = @ContactPhone,
                            Email = @Email,
                            IsActive = @IsActive,
                            Remarks = @Remarks
                        WHERE AdminID = @AdminID";

                    DbHelper.ExecuteNonQuery(updateSql,
                        new SqlParameter("@Username", username),
                        new SqlParameter("@Password", pwd),
                        new SqlParameter("@DisplayName", displayName),
                        new SqlParameter("@Role", role),
                        new SqlParameter("@RoleName", roleName),
                        new SqlParameter("@DeptName", deptName),
                        new SqlParameter("@ContactPhone", (object)phone ?? DBNull.Value),
                        new SqlParameter("@Email", (object)email ?? DBNull.Value),
                        new SqlParameter("@IsActive", dto.IsActive),
                        new SqlParameter("@Remarks", (object)remarks ?? DBNull.Value),
                        new SqlParameter("@AdminID", dto.AdminID));
                }
                else
                {
                    updateSql = @"
                        UPDATE ParkingSystemAdmins
                        SET Username = @Username,
                            DisplayName = @DisplayName,
                            Role = @Role,
                            RoleName = @RoleName,
                            DeptName = @DeptName,
                            ContactPhone = @ContactPhone,
                            Email = @Email,
                            IsActive = @IsActive,
                            Remarks = @Remarks
                        WHERE AdminID = @AdminID";

                    DbHelper.ExecuteNonQuery(updateSql,
                        new SqlParameter("@Username", username),
                        new SqlParameter("@DisplayName", displayName),
                        new SqlParameter("@Role", role),
                        new SqlParameter("@RoleName", roleName),
                        new SqlParameter("@DeptName", deptName),
                        new SqlParameter("@ContactPhone", (object)phone ?? DBNull.Value),
                        new SqlParameter("@Email", (object)email ?? DBNull.Value),
                        new SqlParameter("@IsActive", dto.IsActive),
                        new SqlParameter("@Remarks", (object)remarks ?? DBNull.Value),
                        new SqlParameter("@AdminID", dto.AdminID));
                }

                return OperationResult.Ok(string.Format("【{0}】帳號資料已成功更新！", displayName));
            }
        }

        /// <summary>
        /// 快速切換帳號啟用 / 停用狀態 (含自身與超級管理者安全保護)
        /// </summary>
        public OperationResult ToggleStatus(int adminId, bool targetStatus, string currentOperatorUsername)
        {
            var user = GetAdminUserById(adminId);
            if (user == null) return OperationResult.Fail("查無此人員帳號！");

            // 安全防呆：不可停用自己
            if (!targetStatus && !string.IsNullOrWhiteSpace(currentOperatorUsername) &&
                string.Equals(user.Username, currentOperatorUsername, StringComparison.OrdinalIgnoreCase))
            {
                return OperationResult.Fail("系統安全限制：無法將目前正在操作之登入帳號設為停用！");
            }

            // 安全防呆：若欲停用 SUPER_ADMIN，檢查全系統是否至少還有一位啟用中的 SUPER_ADMIN
            if (!targetStatus && user.Role == "SUPER_ADMIN")
            {
                int superCount = Convert.ToInt32(DbHelper.ExecuteScalar(
                    "SELECT COUNT(1) FROM ParkingSystemAdmins WHERE Role = 'SUPER_ADMIN' AND IsActive = 1 AND AdminID <> @AdminID",
                    new SqlParameter("@AdminID", adminId)));
                if (superCount == 0)
                {
                    return OperationResult.Fail("系統安全限制：全院系統必須至少保留一位啟用中之最高管理員，無法停用該帳號！");
                }
            }

            string sql = "UPDATE ParkingSystemAdmins SET IsActive = @IsActive WHERE AdminID = @AdminID";
            DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@IsActive", targetStatus),
                new SqlParameter("@AdminID", adminId));

            return OperationResult.Ok(string.Format("帳號【{0}】已成功設為【{1}】！", user.DisplayName, targetStatus ? "啟用中" : "已停用"));
        }

        /// <summary>
        /// 快速重設特定人員密碼
        /// </summary>
        public OperationResult ResetPassword(int adminId, string newPassword)
        {
            if (string.IsNullOrWhiteSpace(newPassword)) return OperationResult.Fail("新密碼不可為空！");

            var user = GetAdminUserById(adminId);
            if (user == null) return OperationResult.Fail("查無此人員帳號！");

            string sql = "UPDATE ParkingSystemAdmins SET Password = @Password WHERE AdminID = @AdminID";
            DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@Password", newPassword.Trim()),
                new SqlParameter("@AdminID", adminId));

            return OperationResult.Ok(string.Format("人員【{0}】之密碼已順利重設！", user.DisplayName));
        }

        /// <summary>
        /// 刪除人員帳號 (含安全檢核防呆)
        /// </summary>
        public OperationResult DeleteAdminUser(int adminId, string currentOperatorUsername)
        {
            var user = GetAdminUserById(adminId);
            if (user == null) return OperationResult.Fail("查無此人員帳號！");

            // 安全防呆：不可刪除當前登入者
            if (!string.IsNullOrWhiteSpace(currentOperatorUsername) &&
                string.Equals(user.Username, currentOperatorUsername, StringComparison.OrdinalIgnoreCase))
            {
                return OperationResult.Fail("系統安全限制：無法刪除目前正在操作之登入帳號！");
            }

            // 安全防呆：不可刪除最後一位 SUPER_ADMIN
            if (user.Role == "SUPER_ADMIN")
            {
                int superCount = Convert.ToInt32(DbHelper.ExecuteScalar(
                    "SELECT COUNT(1) FROM ParkingSystemAdmins WHERE Role = 'SUPER_ADMIN' AND AdminID <> @AdminID",
                    new SqlParameter("@AdminID", adminId)));
                if (superCount == 0)
                {
                    return OperationResult.Fail("系統安全限制：全院系統必須至少保留一位最高管理員帳號，不可刪除！");
                }
            }

            string sql = "DELETE FROM ParkingSystemAdmins WHERE AdminID = @AdminID";
            int rows = DbHelper.ExecuteNonQuery(sql, new SqlParameter("@AdminID", adminId));

            if (rows > 0)
            {
                return OperationResult.Ok(string.Format("人員帳號【{0}】已成功刪除！", user.DisplayName));
            }
            return OperationResult.Fail("刪除失敗，查無紀錄！");
        }
    }
}
