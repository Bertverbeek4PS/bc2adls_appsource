// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344438 "ADL - Execute"
{
    /// <summary>
    /// The permission set to be used when running the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Execute', MaxLength = 30;

    Permissions = table "ADL Setup" = x,
                  table "ADL Table Last Timestamp" = x,
                  tabledata "ADL Setup" = RM,
                  tabledata "ADL Table" = RM,
                  tabledata "ADL Field" = R,
                  tabledata "ADL Deleted Record" = R,
                  tabledata "ADL Current Session" = RIMD,
                  tabledata "ADL Table Last Timestamp" = RIMD,
                  tabledata "ADL Run" = RIMD,
                  tabledata "ADL Enum Translation" = RIMD,
                  tabledata "ADL Enum Translation Lang" = RIMD,
                  tabledata "ADL Deleted Table Filter" = R,
                  tabledata "ADL Export Category Table" = R,
                  codeunit "ADL UpgradeTagNewCompanySubs" = X,
                  codeunit "ADL Upgrade" = X,
                  codeunit "ADL Util" = X,
                  codeunit ADL = X,
                  codeunit "ADL CDM Util" = X,
                  codeunit "ADL Communication" = X,
                  codeunit "ADL Session Manager" = X,
                  codeunit "ADL Http" = X,
                  codeunit "ADL Gen 2 Util" = X,
                  codeunit "ADL Execute" = X,
                  codeunit "ADL Execution" = X,
                  codeunit "ADL Wrapper Execute" = X,
                  report "ADL Seek Data" = X,
                  xmlport "ADL BC2ADLS Export" = X;
}
