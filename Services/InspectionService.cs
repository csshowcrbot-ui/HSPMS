using System;
using System.Collections.Generic;
using System.Data;
using Npgsql;
using System.IO;
using System.Web;
using HospitalParking.Common;
using HospitalParking.DTOs;

namespace HospitalParking.Services
{
    public class InspectionService
    {
        public VerificationResultDto VerifyLicensePlate(string plate, int currentZoneId, string photoRef, string remark, string inspector)
        {
            if (string.IsNullOrWhiteSpace(plate))
            {
                var emptyResult = new VerificationResultDto();
                emptyResult.Status = "NOT_FOUND";
                emptyResult.Message = "請輸入車牌號碼進行查驗！";
                return emptyResult;
            }

            if (string.IsNullOrWhiteSpace(inspector)) inspector = "SEC_DUTY01";

            string originalPlate = plate.Trim().ToUpper();
            string cleanPlate = originalPlate.Replace("-", "").Replace(" ", "");

            var result = new VerificationResultDto();
            result.Plate = originalPlate;

            // 1. 取得當前巡檢區域名稱
            string zoneSql = "SELECT ZoneName FROM ParkingZones WHERE ZoneID = @ZoneID";
            var zoneObj = DbHelper.ExecuteScalar(zoneSql, new NpgsqlParameter("@ZoneID", currentZoneId));
            result.CurrentZoneName = zoneObj != null ? zoneObj.ToString() : "未知區域";

            // 2. 查詢車籍主檔
            string permitSql = @"
                SELECT p.PermitID, p.PermitNumber, p.OwnerName, d.DeptName, p.ZoneID, z.ZoneName, 
                       p.SensorTagNumber, p.RemoteControllerNo, p.VehicleColor, p.VehicleBrand, p.CardNumber,
                       TO_CHAR(p.ExpireDate, 'YYYY-MM-DD') AS ExpireDate,
                       p.ExpireDate AS ExpDateRaw, p.Status
                FROM ParkingPermits p
                INNER JOIN ParkingDepartments d ON p.DeptID = d.DeptID
                INNER JOIN ParkingZones z ON p.ZoneID = z.ZoneID
                WHERE p.CleanPlate = @CleanPlate";

            var dt = DbHelper.ExecuteDataTable(permitSql, new NpgsqlParameter("@CleanPlate", cleanPlate));

            if (dt.Rows.Count > 0)
            {
                var dr = dt.Rows[0];
                int permitId = Convert.ToInt32(dr["PermitID"]);
                result.OwnerName = dr["OwnerName"].ToString();
                result.DeptName = dr["DeptName"].ToString();
                int permittedZoneId = Convert.ToInt32(dr["ZoneID"]);
                result.PermittedZoneName = dr["ZoneName"].ToString();
                result.ExpireDate = dr["ExpireDate"].ToString();
                result.SensorTagNumber = dr["SensorTagNumber"] != DBNull.Value ? dr["SensorTagNumber"].ToString() : "--";
                result.RemoteControllerNo = dr["RemoteControllerNo"] != DBNull.Value ? dr["RemoteControllerNo"].ToString() : "--";
                result.VehicleColor = dr["VehicleColor"].ToString();
                result.VehicleBrand = dr["VehicleBrand"].ToString();
                result.CardNumber = dr["CardNumber"] != DBNull.Value ? dr["CardNumber"].ToString() : "--";

                DateTime expDate = Convert.ToDateTime(dr["ExpDateRaw"]);
                string permitStatus = dr["Status"].ToString();

                if (permitStatus == "REVOKED")
                {
                    result.Status = "EXPIRED";
                    result.Message = "該車輛之通行證已遭【註銷停權】，禁止停放於本院任何車位！";
                }
                else if (permitStatus == "EXPIRED" || expDate < DateTime.Today)
                {
                    result.Status = "EXPIRED";
                    result.Message = string.Format("該車輛之通行證已逾期屆滿（效期至 {0}），尚未完成展期繳費手續！", result.ExpireDate);
                }
                else if (permittedZoneId != currentZoneId)
                {
                    result.Status = "WRONG_ZONE";
                    result.Message = string.Format("警告：跨區停放違規！該車核准停放於【{0}】，不得停放於【{1}】。", result.PermittedZoneName, result.CurrentZoneName);
                }
                else
                {
                    result.Status = "VALID";
                    result.Message = "該車輛具備本區域有效停放授權，資格查對合格。";
                }

                // 紀錄稽核日誌
                LogInspection(permitId, originalPlate, currentZoneId, result.Status, photoRef, remark ?? result.Message, inspector);
            }
            else
            {
                result.Status = "NOT_FOUND";
                result.Message = "系統查無此車牌之登記資訊，疑為外來未登記車輛，請巡檢警衛留意外來臨停！";
                LogInspection(null, originalPlate, currentZoneId, result.Status, photoRef, remark ?? result.Message, inspector);
            }

            return result;
        }

        public VerificationResultDto VerifyLicensePlate(string plate, int currentZoneId, string photoRef)
        {
            return VerifyLicensePlate(plate, currentZoneId, photoRef, null, "SEC_DUTY01");
        }

        public void LogInspection(int? permitId, string plate, int zoneId, string status, string photoPath, string remark, string inspector)
        {
            if (string.IsNullOrWhiteSpace(inspector)) inspector = "SEC_DUTY01";

            string sql = @"
                INSERT INTO ParkingInspectionLogs (InspectTime, InspectorAccount, ZoneID, PlateScanned, PermitID, ResultStatus, PhotoPath, Remark)
                VALUES (CURRENT_TIMESTAMP, @Inspector, @ZoneID, @Plate, @PermitID, @Status, @PhotoPath, @Remark)";

            DbHelper.ExecuteNonQuery(sql,
                new NpgsqlParameter("@Inspector", inspector),
                new NpgsqlParameter("@ZoneID", zoneId),
                new NpgsqlParameter("@Plate", plate),
                new NpgsqlParameter("@PermitID", (object)permitId ?? DBNull.Value),
                new NpgsqlParameter("@Status", status),
                new NpgsqlParameter("@PhotoPath", (object)photoPath ?? DBNull.Value),
                new NpgsqlParameter("@Remark", (object)remark ?? DBNull.Value)
            );
        }

        public List<InspectionLogDto> GetRecentInspectionLogs(int zoneId, int count)
        {
            var list = new List<InspectionLogDto>();
            string sql = @"
                SELECT 
                    l.LogID,
                    TO_CHAR(l.InspectTime, 'YYYY-MM-DD HH24:MI') AS InspectTime,
                    l.InspectorAccount,
                    l.ZoneID,
                    z.ZoneName,
                    l.PlateScanned,
                    l.ResultStatus,
                    p.OwnerName,
                    l.PhotoPath,
                    l.Remark
                FROM ParkingInspectionLogs l
                INNER JOIN ParkingZones z ON l.ZoneID = z.ZoneID
                LEFT JOIN ParkingPermits p ON l.PermitID = p.PermitID
                WHERE 1=1 ";

            var pars = new List<NpgsqlParameter>();
            pars.Add(new NpgsqlParameter("@Count", count <= 0 ? 10 : count));

            if (zoneId > 0)
            {
                sql += " AND l.ZoneID = @ZoneID ";
                pars.Add(new NpgsqlParameter("@ZoneID", zoneId));
            }
            sql += " ORDER BY l.LogID DESC LIMIT @Count";

            var dt = DbHelper.ExecuteDataTable(sql, pars.ToArray());
            foreach (DataRow dr in dt.Rows)
            {
                string status = dr["ResultStatus"].ToString();
                string statusLabel = "合格";
                if (status == "WRONG_ZONE") statusLabel = "跨區違規";
                else if (status == "EXPIRED") statusLabel = "證件過期";
                else if (status == "NOT_FOUND") statusLabel = "無證車輛";

                list.Add(new InspectionLogDto
                {
                    LogID = Convert.ToInt64(dr["LogID"]),
                    InspectTime = dr["InspectTime"].ToString(),
                    InspectorAccount = dr["InspectorAccount"].ToString(),
                    ZoneID = Convert.ToInt32(dr["ZoneID"]),
                    ZoneName = dr["ZoneName"].ToString(),
                    PlateScanned = dr["PlateScanned"].ToString(),
                    ResultStatus = status,
                    ResultStatusLabel = statusLabel,
                    OwnerName = dr["OwnerName"] != DBNull.Value ? dr["OwnerName"].ToString() : "未登記",
                    PhotoPath = dr["PhotoPath"] != DBNull.Value ? dr["PhotoPath"].ToString() : "",
                    Remark = dr["Remark"] != DBNull.Value ? dr["Remark"].ToString() : ""
                });
            }

            return list;
        }

        public VerificationResultDto RecognizeAndVerify(string base64Image, int currentZoneId, string manualPlateHint)
        {
            string savedPath = null;
            string localFilePath = null;
            if (!string.IsNullOrWhiteSpace(base64Image))
            {
                try
                {
                    string uploadsDir = HttpContext.Current != null
                        ? HttpContext.Current.Server.MapPath("~/Uploads")
                        : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Uploads");

                    if (!Directory.Exists(uploadsDir))
                    {
                        Directory.CreateDirectory(uploadsDir);
                    }

                    string fileName = string.Format("inspect_{0:yyyyMMdd_HHmmss}_{1}.jpg", DateTime.Now, Guid.NewGuid().ToString().Substring(0, 4));
                    string filePath = Path.Combine(uploadsDir, fileName);

                    string cleanBase64 = base64Image;
                    if (cleanBase64.Contains(","))
                    {
                        cleanBase64 = cleanBase64.Substring(cleanBase64.IndexOf(",") + 1);
                    }

                    byte[] imageBytes = Convert.FromBase64String(cleanBase64);
                    File.WriteAllBytes(filePath, imageBytes);
                    savedPath = "/Uploads/" + fileName;
                    localFilePath = filePath;
                }
                catch
                {
                    // Ignore photo save error, fallback to memory
                }
            }

            string plateToVerify = NormalizeTaiwanPlate(manualPlateHint);
            if (string.IsNullOrWhiteSpace(plateToVerify) && !string.IsNullOrWhiteSpace(localFilePath) && File.Exists(localFilePath))
            {
                plateToVerify = RecognizePlateFromFile(localFilePath);
            }

            if (string.IsNullOrWhiteSpace(plateToVerify))
            {
                var pendingResult = new VerificationResultDto();
                pendingResult.Status = "PHOTO_SAVED";
                pendingResult.Plate = "";
                pendingResult.Message = "照片已成功取格存檔，未能自動辨識出車牌，請確認或輸入車牌號碼進行查驗！";
                pendingResult.PhotoPath = savedPath;
                return pendingResult;
            }

            var result = VerifyLicensePlate(plateToVerify, currentZoneId, savedPath, "相機拍照辨識查核", "SEC_DUTY01");
            result.PhotoPath = savedPath;
            return result;
        }

        public static string RecognizePlateFromFile(string imagePath)
        {
            if (string.IsNullOrWhiteSpace(imagePath) || !File.Exists(imagePath))
                return null;

            try
            {
                string scriptPath = HttpContext.Current != null
                    ? HttpContext.Current.Server.MapPath("~/App_Data/RecognizePlate.ps1")
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "RecognizePlate.ps1");

                if (!File.Exists(scriptPath))
                    return null;

                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = string.Format("-ExecutionPolicy Bypass -NoProfile -NonInteractive -File \"{0}\" -ImagePath \"{1}\"", scriptPath, imagePath),
                    RedirectStandardOutput = true,
                    RedirectStandardError = false,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var proc = System.Diagnostics.Process.Start(psi))
                {
                    if (proc != null)
                    {
                        string output = proc.StandardOutput.ReadToEnd();
                        proc.WaitForExit(10000);
                        if (!string.IsNullOrWhiteSpace(output))
                        {
                            var lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                            foreach (var line in lines)
                            {
                                string candidate = line.Trim();
                                if (!string.IsNullOrEmpty(candidate))
                                {
                                    string normalized = NormalizeTaiwanPlate(candidate);
                                    LogOcr(string.Format("Image: {0} => OCR: {1} => Norm: {2}", Path.GetFileName(imagePath), candidate, normalized));
                                    return normalized;
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogOcr("RecognizePlateFromFile Exception: " + ex.Message);
            }
            return null;
        }

        public string RecognizePlateFromBase64(string base64Image)
        {
            if (string.IsNullOrWhiteSpace(base64Image)) return null;

            string tempFile = null;
            try
            {
                string uploadsDir = HttpContext.Current != null
                    ? HttpContext.Current.Server.MapPath("~/Uploads")
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Uploads");

                if (!Directory.Exists(uploadsDir))
                {
                    Directory.CreateDirectory(uploadsDir);
                }

                string fileName = string.Format("ocr_temp_{0:yyyyMMdd_HHmmss}_{1}.jpg", DateTime.Now, Guid.NewGuid().ToString().Substring(0, 4));
                tempFile = Path.Combine(uploadsDir, fileName);

                string cleanBase64 = base64Image.Trim();
                if (cleanBase64.Contains(","))
                {
                    cleanBase64 = cleanBase64.Substring(cleanBase64.IndexOf(",") + 1);
                }
                cleanBase64 = cleanBase64.Replace(" ", "+").Replace("\r", "").Replace("\n", "");

                byte[] imageBytes = Convert.FromBase64String(cleanBase64);
                File.WriteAllBytes(tempFile, imageBytes);

                return RecognizePlateFromFile(tempFile);
            }
            catch (Exception ex)
            {
                LogOcr("RecognizePlateFromBase64 Exception: " + ex.Message);
                return null;
            }
            finally
            {
                if (tempFile != null && File.Exists(tempFile))
                {
                    try { File.Delete(tempFile); } catch { }
                }
            }
        }

        private static void LogOcr(string message)
        {
            try
            {
                string logDir = HttpContext.Current != null
                    ? HttpContext.Current.Server.MapPath("~/App_Data")
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data");
                string logFile = Path.Combine(logDir, "ocr.log");
                File.AppendAllText(logFile, string.Format("[{0:yyyy-MM-dd HH:mm:ss}] {1}\r\n", DateTime.Now, message));
            }
            catch { }
        }

        public static string NormalizeTaiwanPlate(string plate)
        {
            if (string.IsNullOrWhiteSpace(plate)) return null;

            string s = plate.Trim().ToUpper()
                .Replace("Ä", "A").Replace("À", "A").Replace("Á", "A")
                .Replace("·", "-").Replace("•", "-").Replace(".", "-")
                .Replace(" ", "-").Replace("_", "-");

            s = s.Trim('-');

            if (s.Contains("-"))
            {
                var parts = s.Split(new[] { '-' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length == 2)
                {
                    string p1 = parts[0];
                    string p2 = parts[1];

                    // 3英文 + 4數字 (常見新式汽機車)
                    if (p1.Length == 3 && p2.Length == 4)
                    {
                        p1 = p1.Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                        p2 = p2.Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                        return p1 + "-" + p2;
                    }

                    // 4數字 + 2英文 (舊式汽車)
                    if (p1.Length == 4 && p2.Length == 2)
                    {
                        p1 = p1.Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                        p2 = p2.Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                        return p1 + "-" + p2;
                    }

                    // 2英文 + 4數字 (舊式汽車)
                    if (p1.Length == 2 && p2.Length == 4)
                    {
                        p1 = p1.Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                        p2 = p2.Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                        return p1 + "-" + p2;
                    }
                }
            }
            else if (s.Length == 7)
            {
                string p1 = s.Substring(0, 3).Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                string p2 = s.Substring(3).Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                return p1 + "-" + p2;
            }
            else if (s.Length == 6)
            {
                if (char.IsDigit(s[0]) || char.IsDigit(s[1]))
                {
                    string p1 = s.Substring(0, 4).Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                    string p2 = s.Substring(4).Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                    return p1 + "-" + p2;
                }
                else
                {
                    string p1 = s.Substring(0, 2).Replace("0", "O").Replace("1", "I").Replace("5", "S").Replace("8", "B");
                    string p2 = s.Substring(2).Replace("O", "0").Replace("D", "0").Replace("Q", "0").Replace("I", "1").Replace("L", "1").Replace("Z", "2").Replace("S", "3").Replace("B", "8").Replace("G", "6");
                    return p1 + "-" + p2;
                }
            }

            return s;
        }
    }
}
