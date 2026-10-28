using System;
using System.Collections.Generic;
using System.Web.Services;
using System.Web.UI;
using HospitalParking.DTOs;
using HospitalParking.Services;

namespace HospitalParking
{
    public partial class Permit_Management : Page
    {
        private static readonly PermitService permitService = new PermitService();

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        public static LookupDataDto GetLookupOptions()
        {
            return permitService.GetLookupOptions();
        }

        [WebMethod]
        public static List<PermitItemDto> SearchPermits(SearchCriteriaDto criteria)
        {
            return permitService.SearchPermits(criteria);
        }

        [WebMethod]
        public static PermitItemDto GetPermit(int permitId)
        {
            return permitService.GetPermitById(permitId);
        }

        [WebMethod]
        public static OperationResult SavePermit(PermitItemDto dto)
        {
            return permitService.SavePermit(dto);
        }

        [WebMethod]
        public static OperationResult BatchExtend(BatchExtendDto dto)
        {
            return permitService.BatchExtendPermits(dto);
        }

        [WebMethod]
        public static OperationResult DeletePermit(int permitId)
        {
            return permitService.DeletePermit(permitId);
        }

        [WebMethod]
        public static string ExportCsv(SearchCriteriaDto criteria)
        {
            return permitService.GeneratePermitCsv(criteria);
        }

        [WebMethod]
        public static string GetImportCsvTemplate()
        {
            return permitService.GetImportCsvTemplate();
        }

        [WebMethod]
        public static BatchImportResultDto BatchImport(List<BatchImportItemDto> items, bool skipDuplicates)
        {
            return permitService.BatchImportPermits(items, skipDuplicates);
        }
    }
}
