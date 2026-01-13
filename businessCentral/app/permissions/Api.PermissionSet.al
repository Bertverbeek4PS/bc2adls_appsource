// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344437 "AZD - API"
{
    /// <summary>
    /// The permission set to be used when using the API.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Api', MaxLength = 30;

    Permissions = table "AZD Setup" = x,
                  tabledata "AZD Table" = RMI,
                  tabledata "AZD Setup" = R,
                  tabledata "AZD Current Session" = R,
                  tabledata "AZD Run" = R,
                  tabledata "AZD Field" = RI,
                  page "AZD Table API v12" = X,
                  page "AZD Setup API v12" = X,
                  page "AZD Field API v12" = X,
                  page "AZD CurrentSession API" = X,
                  page "AZD Run API v12" = X,
                  codeunit "AZD External Events Helper" = X,
                  codeunit "AZD External Events" = X;
}
