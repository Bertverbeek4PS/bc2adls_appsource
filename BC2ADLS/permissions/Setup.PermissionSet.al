// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344439 "AZD - Setup"
{
    /// <summary>
    /// The permission set to be used when administering the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Setup', MaxLength = 30;

    Permissions = table "AZD Deleted Table Filter" = x,
                  table "AZD Export Category Table" = x,
                  table "AZD Setup" = x,
                  table "AZD Table Last Timestamp" = x,
                  tabledata "AZD Setup" = RIMD,
                  tabledata "AZD Table" = RIMD,
                  tabledata "AZD Field" = RIMD,
                  tabledata "AZD Deleted Record" = RD,
                  tabledata "AZD Current Session" = R,
                  tabledata "AZD Table Last Timestamp" = RID,
                  tabledata "AZD Run" = RD,
                  tabledata "AZD Enum Translation" = RIMD,
                  tabledata "AZD Enum Translation Lang" = RIMD,
                  tabledata "AZD Deleted Table Filter" = RIMD,
                  tabledata "AZD Export Category Table" = RIMD,
                  codeunit "AZD Clear Tracked Deletions" = X,
                  codeunit "AZD Credentials" = X,
                  codeunit "AZD Setup" = X,
                  codeunit "AZD Installer" = X,
                  page "AZD Setup Tables" = X,
                  page "AZD Setup Fields" = X,
                  page "AZD Setup" = X,
                  page "AZD Run" = X,
                  page "AZD Enum Translations" = X,
                  page "AZD Enum Translations Lang" = X,
                  page "AZD Export Categories" = X,
                  page "AZD Assign Export Category" = X,
                  page "AZD Deleted Table Filter" = X,
                  report "AZD Schedule Task Assignment" = X,
                  xmlport "AZD BC2ADLS Import" = X;
}
