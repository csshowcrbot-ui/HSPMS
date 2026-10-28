using System;
using System.Collections.Generic;

namespace HospitalParking.DTOs
{
    public class OperationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public object Data { get; set; }

        public static OperationResult Ok(string message, object data)
        {
            return new OperationResult { Success = true, Message = message, Data = data };
        }

        public static OperationResult Ok(string message)
        {
            return new OperationResult { Success = true, Message = message, Data = null };
        }

        public static OperationResult Fail(string message, object data)
        {
            return new OperationResult { Success = false, Message = message, Data = data };
        }

        public static OperationResult Fail(string message)
        {
            return new OperationResult { Success = false, Message = message, Data = null };
        }
    }

    public class DeptItem
    {
        public int DeptID { get; set; }
        public string DeptCode { get; set; }
        public string DeptName { get; set; }
        public int QuotaLimit { get; set; }
        public int CurrentUsed { get; set; }
    }

    public class ZoneItem
    {
        public int ZoneID { get; set; }
        public string ZoneCode { get; set; }
        public string ZoneName { get; set; }
        public int TotalCapacity { get; set; }
        public int CurrentOccupied { get; set; }
        public int RemainingQuota { get; set; }
        public int OccupancyPct { get; set; }
        public int WarningThresholdPct { get; set; }
    }

    public class ZoneManageDto
    {
        public int ZoneID { get; set; }
        public string ZoneCode { get; set; }
        public string ZoneName { get; set; }
        public int TotalCapacity { get; set; }
        public int WarningThresholdPct { get; set; }
        public bool IsActive { get; set; }
        public string CreatedDate { get; set; }

        public int CurrentOccupied { get; set; }
        public int RemainingQuota { get; set; }
        public int OccupancyPct { get; set; }
        public bool IsWarning { get; set; }
        public int PermitCount { get; set; }
        public int PendingAppCount { get; set; }
        public int InspectionCount { get; set; }
    }

    public class ZoneOverviewSummaryDto
    {
        public int TotalZones { get; set; }
        public int ActiveZones { get; set; }
        public int TotalCapacity { get; set; }
        public int TotalOccupied { get; set; }
        public int WarningZoneCount { get; set; }
        public List<ZoneManageDto> ZoneList { get; set; }

        public ZoneOverviewSummaryDto()
        {
            ZoneList = new List<ZoneManageDto>();
        }
    }

    public class LookupDataDto
    {
        public List<DeptItem> Departments { get; set; }
        public List<ZoneItem> Zones { get; set; }

        public LookupDataDto()
        {
            Departments = new List<DeptItem>();
            Zones = new List<ZoneItem>();
        }
    }

    public class SearchCriteriaDto
    {
        public int? DeptID { get; set; }
        public int? ZoneID { get; set; }
        public string Status { get; set; }
        public string Keyword { get; set; }
    }

    public class PermitItemDto
    {
        public int PermitID { get; set; }
        public string PermitNumber { get; set; }
        public int DeptID { get; set; }
        public string DeptName { get; set; }
        public string CardNumber { get; set; }
        public string OwnerName { get; set; }
        public string SensorTagNumber { get; set; }
        public string RemoteControllerNo { get; set; }
        public string VehicleColor { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public int ZoneID { get; set; }
        public string ZoneName { get; set; }
        public string RegisterDate { get; set; }
        public string StartDate { get; set; }
        public string ExpireDate { get; set; }
        public string Status { get; set; }
        public string Remarks { get; set; }
        public int DaysRemaining { get; set; }
        public bool IsExpiringSoon { get; set; }
    }

    public class BatchExtendDto
    {
        public List<int> PermitIDs { get; set; }
        public int ExtendMonths { get; set; }

        public BatchExtendDto()
        {
            PermitIDs = new List<int>();
        }
    }

    public class ApplicationDto
    {
        public int ApplicationID { get; set; }
        public string ApplicationNo { get; set; }
        public string EmpNo { get; set; }
        public string ApplicantName { get; set; }
        public int DeptID { get; set; }
        public string DeptName { get; set; }
        public string ContactPhone { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public string VehicleColor { get; set; }
        public int PreferredZoneID { get; set; }
        public string PreferredZoneName { get; set; }
        public int? AssignedZoneID { get; set; }
        public string AssignedZoneName { get; set; }
        public int EffectiveZoneID
        {
            get { return (AssignedZoneID.HasValue && AssignedZoneID.Value > 0) ? AssignedZoneID.Value : PreferredZoneID; }
        }
        public string EffectiveZoneName
        {
            get { return !string.IsNullOrEmpty(AssignedZoneName) ? AssignedZoneName : PreferredZoneName; }
        }
        public string ApplyDate { get; set; }
        public string ReviewStatus { get; set; }
        public string ReviewStatusName
        {
            get
            {
                switch (ReviewStatus)
                {
                    case "PENDING": return "待審核";
                    case "PROCESSING": return "已收案";
                    case "WAITLIST": return "待排序";
                    case "APPROVED": return "待領證";
                    case "COMPLETED": return "已發證";
                    case "REJECTED": return "已駁回";
                    default: return ReviewStatus ?? "未知";
                }
            }
        }
        public string ReviewerName { get; set; }
        public string ReviewDate { get; set; }
        public string RejectReason { get; set; }
        public string ReviewRemarks { get; set; }
    }

    public class VerificationResultDto
    {
        public string Plate { get; set; }
        public string Status { get; set; }
        public string OwnerName { get; set; }
        public string DeptName { get; set; }
        public string PermittedZoneName { get; set; }
        public string CurrentZoneName { get; set; }
        public string ExpireDate { get; set; }
        public string Message { get; set; }
        public string SensorTagNumber { get; set; }
        public string RemoteControllerNo { get; set; }
        public string VehicleColor { get; set; }
        public string VehicleBrand { get; set; }
        public string PhotoPath { get; set; }
        public string CardNumber { get; set; }
    }

    public class DashboardSummaryDto
    {
        public int ValidPermitCount { get; set; }
        public int PendingAppCount { get; set; }
        public int ExpiringSoonCount { get; set; }
        public int TodayInspectionCount { get; set; }
        public List<ZoneCapacityDto> ZoneCapacities { get; set; }
        public List<DeptOccupancyDto> DeptOccupancies { get; set; }
        public List<InspectionStatDto> InspectionStats { get; set; }
        public List<ApplicationDto> RecentApplications { get; set; }

        public DashboardSummaryDto()
        {
            ZoneCapacities = new List<ZoneCapacityDto>();
            DeptOccupancies = new List<DeptOccupancyDto>();
            InspectionStats = new List<InspectionStatDto>();
            RecentApplications = new List<ApplicationDto>();
        }
    }

    public class ZoneCapacityDto
    {
        public int ZoneID { get; set; }
        public string ZoneCode { get; set; }
        public string ZoneName { get; set; }
        public int TotalCapacity { get; set; }
        public int OccupiedCount { get; set; }
        public int OccupancyPct { get; set; }
        public int WarningThresholdPct { get; set; }
        public bool IsWarning { get; set; }
    }

    public class DeptOccupancyDto
    {
        public string DeptName { get; set; }
        public int PermitCount { get; set; }
        public int QuotaLimit { get; set; }
    }

    public class InspectionStatDto
    {
        public string Status { get; set; }
        public string StatusLabel { get; set; }
        public int Count { get; set; }
        public string ColorHex { get; set; }
    }

    public class InspectionLogDto
    {
        public long LogID { get; set; }
        public string InspectTime { get; set; }
        public string InspectorAccount { get; set; }
        public int ZoneID { get; set; }
        public string ZoneName { get; set; }
        public string PlateScanned { get; set; }
        public string ResultStatus { get; set; }
        public string ResultStatusLabel { get; set; }
        public string OwnerName { get; set; }
        public string PhotoPath { get; set; }
        public string Remark { get; set; }
    }

    public class DeptDrilldownDto
    {
        public int DeptID { get; set; }
        public string DeptName { get; set; }
        public int QuotaLimit { get; set; }
        public int OccupiedCount { get; set; }
        public int OccupancyPct { get; set; }
        public List<PermitItemDto> Permits { get; set; }

        public DeptDrilldownDto()
        {
            Permits = new List<PermitItemDto>();
        }
    }

    public class ZoneDrilldownDto
    {
        public int ZoneID { get; set; }
        public string ZoneCode { get; set; }
        public string ZoneName { get; set; }
        public int TotalCapacity { get; set; }
        public int OccupiedCount { get; set; }
        public int RemainingQuota { get; set; }
        public int OccupancyPct { get; set; }
        public int WarningThresholdPct { get; set; }
        public bool IsWarning { get; set; }
        public List<PermitItemDto> Permits { get; set; }

        public ZoneDrilldownDto()
        {
            Permits = new List<PermitItemDto>();
        }
    }

    public class InspectionLogItemDto
    {
        public long LogID { get; set; }
        public string InspectTime { get; set; }
        public string InspectorAccount { get; set; }
        public int ZoneID { get; set; }
        public string ZoneName { get; set; }
        public string PlateScanned { get; set; }
        public string ResultStatus { get; set; }
        public string ResultStatusLabel { get; set; }
        public string OwnerName { get; set; }
        public string DeptName { get; set; }
        public string PermittedZoneName { get; set; }
        public string PhotoPath { get; set; }
        public string Remark { get; set; }
    }

    public class InspectionDrilldownDto
    {
        public string Status { get; set; }
        public string StatusLabel { get; set; }
        public string ColorHex { get; set; }
        public int TotalCount { get; set; }
        public List<InspectionLogItemDto> Logs { get; set; }

        public InspectionDrilldownDto()
        {
            Logs = new List<InspectionLogItemDto>();
        }
    }

    public class AdminUserDto
    {
        public int AdminID { get; set; }
        public string Username { get; set; }
        public string DisplayName { get; set; }
        public string Role { get; set; }
        public string RoleName { get; set; }
        public string DeptName { get; set; }
        public string LoginTime { get; set; }
    }

    /// <summary>
    /// 管理者與巡檢人員維護資料傳遞物件
    /// </summary>
    public class AdminUserManageDto
    {
        public int AdminID { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string DisplayName { get; set; }
        public string Role { get; set; }         // SUPER_ADMIN, ADMIN, SECURITY
        public string RoleName { get; set; }     // 總務行政主管, 系統管理員, 現場巡檢警衛
        public string DeptName { get; set; }     // 總務行政處, 安全警衛課...
        public string ContactPhone { get; set; }
        public string Email { get; set; }
        public string LastLoginTime { get; set; }
        public bool IsActive { get; set; }
        public string CreatedDate { get; set; }
        public string Remarks { get; set; }
    }

    /// <summary>
    /// 管理者與巡檢人員總覽統計物件
    /// </summary>
    public class AdminUserOverviewDto
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int AdminCount { get; set; }
        public int SecurityCount { get; set; }
        public List<AdminUserManageDto> UserList { get; set; }

        public AdminUserOverviewDto()
        {
            UserList = new List<AdminUserManageDto>();
        }
    }

    public class LoginRequestDto
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public string ReturnUrl { get; set; }
    }

    public class BatchImportItemDto
    {
        public string DeptName { get; set; }
        public string OwnerName { get; set; }
        public string CardNumber { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public string VehicleColor { get; set; }
        public string ZoneName { get; set; }
        public string SensorTagNumber { get; set; }
        public string RemoteControllerNo { get; set; }
        public string StartDate { get; set; }
        public string ExpireDate { get; set; }
        public string Remarks { get; set; }
    }

    public class BatchImportResultDto
    {
        public bool Success { get; set; }
        public int TotalCount { get; set; }
        public int SuccessCount { get; set; }
        public int FailCount { get; set; }
        public string Message { get; set; }
        public List<string> ErrorMessages { get; set; }
        public List<string> SuccessPermitNumbers { get; set; }

        public BatchImportResultDto()
        {
            ErrorMessages = new List<string>();
            SuccessPermitNumbers = new List<string>();
        }
    }

    public class DepartmentManageDto
    {
        public int DeptID { get; set; }
        public string DeptCode { get; set; }
        public string DeptName { get; set; }
        public int QuotaLimit { get; set; }
        public bool IsActive { get; set; }
        public string CreatedDate { get; set; }

        public int ActivePermitCount { get; set; }
        public int TotalPermitCount { get; set; }
        public int RemainingQuota { get; set; }
        public int UtilizationPct { get; set; }
        public bool IsOverQuota { get; set; }
        public int PendingAppCount { get; set; }
    }

    public class DepartmentOverviewDto
    {
        public int TotalDepts { get; set; }
        public int ActiveDepts { get; set; }
        public int TotalQuotaLimit { get; set; }
        public int TotalActivePermits { get; set; }
        public int OverQuotaDeptCount { get; set; }
        public List<DepartmentManageDto> DeptList { get; set; }

        public DepartmentOverviewDto()
        {
            DeptList = new List<DepartmentManageDto>();
        }
    }

    public class DepartmentPermitItemDto
    {
        public int PermitID { get; set; }
        public string PermitNumber { get; set; }
        public string OwnerName { get; set; }
        public string CardNumber { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public string VehicleColor { get; set; }
        public string ZoneName { get; set; }
        public string StartDate { get; set; }
        public string ExpireDate { get; set; }
        public string Status { get; set; }
    }
}


