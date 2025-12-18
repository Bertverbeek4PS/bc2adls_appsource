// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344439 "ADL - Setup"
{
    /// <summary>
    /// The permission set to be used when administering the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Setup', MaxLength = 30;

    Permissions = table "ADL Deleted Table Filter" = x,
                  table "ADL Export Category Table" = x,
                  table "ADL Setup" = x,
                  table "ADL Table Last Timestamp" = x,
                  tabledata "ADL Setup" = RIMD,
                  tabledata "ADL Table" = RIMD,
                  tabledata "ADL Field" = RIMD,
                  tabledata "ADL Deleted Record" = RD,
                  tabledata "ADL Current Session" = R,
                  tabledata "ADL Table Last Timestamp" = RID,
                  tabledata "ADL Run" = RD,
                  tabledata "ADL Enum Translation" = RIMD,
                  tabledata "ADL Enum Translation Lang" = RIMD,
                  tabledata "ADL Deleted Table Filter" = RIMD,
                  tabledata "ADL Export Category Table" = RIMD,
                  codeunit "ADL Clear Tracked Deletions" = X,
                  codeunit "ADL Credentials" = X,
                  codeunit "ADL Setup" = X,
                  codeunit "ADL Installer" = X,
                  page "ADL Setup Tables" = X,
                  page "ADL Setup Fields" = X,
                  page "ADL Setup" = X,
                  page "ADL Run" = X,
                  page "ADL Enum Translations" = X,
                  page "ADL Enum Translations Lang" = X,
                  page "ADL Export Categories" = X,
                  page "ADL Assign Export Category" = X,
                  page "ADL Deleted Table Filter" = X,
                  report "ADL Schedule Task Assignment" = X,
                  xmlport "ADL BC2ADLS Import" = X;
}
