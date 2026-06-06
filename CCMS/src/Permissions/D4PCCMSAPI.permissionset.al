namespace D4P.CCMS.Permissions;

using D4P.CCMS.API;
using D4P.CCMS.Auth;
using D4P.CCMS.Backup;
using D4P.CCMS.Capacity;
using D4P.CCMS.Customer;
using D4P.CCMS.Environment;
using D4P.CCMS.Extension;
using D4P.CCMS.Features;
using D4P.CCMS.General;
using D4P.CCMS.Operations;
using D4P.CCMS.Session;
using D4P.CCMS.Setup;
using D4P.CCMS.Telemetry;
using D4P.CCMS.Tenant;

permissionset 62004 "D4P CCMS API"
{
    Assignable = true;
    Caption = 'D4P CCMS API';
    Permissions =
        // Tabledata - read-only entities (R)
        tabledata "D4P BC Installed App" = R,
        tabledata "D4P BC Environment Feature" = R,
        tabledata "D4P BC Environment Backup" = R,
        tabledata "D4P BC Capacity Header" = R,
        tabledata "D4P BC Capacity Line" = R,
        tabledata "D4P BC Environment Session" = R,
        tabledata "D4P BC Environment Operation" = R,
        tabledata "D4P KQL Extension Lifecycle" = R,
        tabledata "D4P KQL Page Execution" = R,
        tabledata "D4P KQL Report Execution" = R,
        tabledata "D4P KQL Slow AL Method" = R,
        tabledata "D4P PTE Object Range" = R,
        tabledata "D4P AppInsights Connection" = R,
        tabledata "D4P BC Setup" = R,
        tabledata "D4P BC App Registration" = R,

        // Tabledata - Environment needs Modify (scheduleUpdate / GetEnvironmentUpdates) (RM)
        tabledata "D4P BC Environment" = RM,

        // Tabledata - temp table populated by listAvailableUpdates
        tabledata "D4P BC Available Update" = RIMD,

        // Tabledata - writable entities (RIMD)
        tabledata "D4P BC Customer" = RIMD,
        tabledata "D4P BC Tenant" = RIMD,
        tabledata "D4P KQL Query Store" = RIMD,

        // Pages - API pages execute (X)
        page "D4P Environment API" = X,
        page "D4P Installed App API" = X,
        page "D4P Environment Feature API" = X,
        page "D4P Environment Backup API" = X,
        page "D4P Environment Session API" = X,
        page "D4P Environment Operation API" = X,
        page "D4P KQL Ext Lifecycle API" = X,
        page "D4P KQL Page Execution API" = X,
        page "D4P KQL Report Execution API" = X,
        page "D4P KQL Slow AL Method API" = X,
        page "D4P AppInsights Conn API" = X,
        page "D4P Capacity Header API" = X,
        page "D4P Capacity Line API" = X,
        page "D4P PTE Object Range API" = X,
        page "D4P BC Setup API" = X,
        page "D4P App Registration API" = X,
        page "D4P Customer API" = X,
        page "D4P Tenant API" = X,
        page "D4P KQL Query Store API" = X,

        // Codeunits - action codeunits execute (X)
        codeunit "D4P BC Environment Mgt" = X,
        codeunit "D4P BC Operations Helper" = X,
        codeunit "D4P BC Backup Helper" = X,
        codeunit "D4P BC Features Helper" = X,
        codeunit "D4P BC Admin API Response" = X;
}
