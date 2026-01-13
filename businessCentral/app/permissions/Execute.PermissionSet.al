// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344438 "AZD - Execute"
{
    /// <summary>
    /// The permission set to be used when running the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Execute', MaxLength = 30;

    Permissions = table "AZD Setup" = x,
                  table "AZD Table Last Timestamp" = x,
                  tabledata "AZD Setup" = RM,
                  tabledata "AZD Table" = RM,
                  tabledata "AZD Field" = R,
                  tabledata "AZD Deleted Record" = R,
                  tabledata "AZD Current Session" = RIMD,
                  tabledata "AZD Table Last Timestamp" = RIMD,
                  tabledata "AZD Run" = RIMD,
                  tabledata "AZD Enum Translation" = RIMD,
                  tabledata "AZD Enum Translation Lang" = RIMD,
                  tabledata "AZD Deleted Table Filter" = R,
                  tabledata "AZD Export Category Table" = R,
                  tabledata "AZD Companies Table" = R,
                  tabledata "AZD Sync Companies" = R,
                  codeunit "AZD UpgradeTagNewCompanySubs" = X,
                  codeunit "AZD Upgrade" = X,
                  codeunit "AZD Util" = X,
                  codeunit AZD = X,
                  codeunit "AZD CDM Util" = X,
                  codeunit "AZD Communication" = X,
                  codeunit "AZD Session Manager" = X,
                  codeunit "AZD Http" = X,
                  codeunit "AZD Gen 2 Util" = X,
                  codeunit "AZD Execute" = X,
                  codeunit "AZD Execution" = X,
                  codeunit "AZD Wrapper Execute" = X,
                  codeunit "AZD Company Run" = X,
                  codeunit "AZD Multi Company Export" = X,
                  report "AZD Seek Data" = X,
                  report "AZDScheduleMultiTaskAssign" = X,
                  xmlport "AZD BC2ADLS Export" = X;
}
