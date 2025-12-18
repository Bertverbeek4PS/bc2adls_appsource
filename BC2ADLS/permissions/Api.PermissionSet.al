// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344437 "ADL - API"
{
    /// <summary>
    /// The permission set to be used when using the API.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Api', MaxLength = 30;

    Permissions = table "ADL Setup" = x,
                  tabledata "ADL Table" = RMI,
                  tabledata "ADL Setup" = R,
                  tabledata "ADL Current Session" = R,
                  tabledata "ADL Run" = R,
                  tabledata "ADL Field" = RI,
                  page "ADL Table API v12" = X,
                  page "ADL Setup API v12" = X,
                  page "ADL Field API v12" = X,
                  page "ADL CurrentSession API" = X,
                  page "ADL Run API v12" = X,
                  codeunit "ADL External Events Helper" = X,
                  codeunit "ADL External Events" = X;
}
