using System;

namespace HospitalParking.Models
{
    public class Department
    {
        public int DeptID { get; set; }
        public string DeptCode { get; set; }
        public string DeptName { get; set; }
        public int QuotaLimit { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    public class ParkingZone
    {
        public int ZoneID { get; set; }
        public string ZoneCode { get; set; }
        public string ZoneName { get; set; }
        public int TotalCapacity { get; set; }
        public int WarningThresholdPct { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    public class Permit
    {
        public int PermitID { get; set; }
        public string PermitNumber { get; set; }
        public int DeptID { get; set; }
        public string CardNumber { get; set; }
        public string OwnerName { get; set; }
        public string SensorTagNumber { get; set; }
        public string RemoteControllerNo { get; set; }
        public string VehicleColor { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public int ZoneID { get; set; }
        public DateTime RegisterDate { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime ExpireDate { get; set; }
        public string Status { get; set; }
        public string Remarks { get; set; }
        public DateTime UpdatedDate { get; set; }
    }

    public class EmployeeApplication
    {
        public int ApplicationID { get; set; }
        public string ApplicationNo { get; set; }
        public string EmpNo { get; set; }
        public string ApplicantName { get; set; }
        public int DeptID { get; set; }
        public string ContactPhone { get; set; }
        public string LicensePlate { get; set; }
        public string VehicleBrand { get; set; }
        public string VehicleColor { get; set; }
        public int PreferredZoneID { get; set; }
        public DateTime ApplyDate { get; set; }
        public string ReviewStatus { get; set; } // PENDING, PROCESSING, WAITLIST, APPROVED, COMPLETED, REJECTED
        public string ReviewerName { get; set; }
        public DateTime? ReviewDate { get; set; }
        public string RejectReason { get; set; }
        public string ReviewRemarks { get; set; }
    }

    public class InspectionLog
    {
        public long LogID { get; set; }
        public DateTime InspectTime { get; set; }
        public string InspectorAccount { get; set; }
        public int ZoneID { get; set; }
        public string PlateScanned { get; set; }
        public int? PermitID { get; set; }
        public string ResultStatus { get; set; } // VALID, WRONG_ZONE, EXPIRED, NOT_FOUND
        public string PhotoPath { get; set; }
        public string Remark { get; set; }
    }
}
