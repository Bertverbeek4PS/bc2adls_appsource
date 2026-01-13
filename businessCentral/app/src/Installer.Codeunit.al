// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.DataAdministration;

codeunit 11344448 "AZD Installer"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        DisableTablesExportingInvalidFields();
    end;

    trigger OnInstallAppPerCompany()
    begin
        AddAllowedTables();
    end;

    procedure AddAllowedTables()
    var
        ADLSERun: Record "AZD Run";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"AZD Run", ADLSERun.FieldNo(SystemModifiedAt));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'r')]
    procedure ListInvalidFieldsBeingExported() InvalidFieldsMap: Dictionary of [Integer, List of [Text]]
    var
        ADLSETable: Record "AZD Table";
        InvalidFields: List of [Text];
    begin
        // find the tables which export fields that have now been obsoleted or are invalid
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet() then
            repeat
                InvalidFields := ADLSETable.ListInvalidFieldsBeingExported();
                if InvalidFields.Count() > 0 then
                    InvalidFieldsMap.Add(ADLSETable."Table ID", InvalidFields);
            until ADLSETable.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'rm')]
    local procedure DisableTablesExportingInvalidFields()
    var
        ADLSETable: Record "AZD Table";
        ADLSEUtil: Codeunit "AZD Util";
        ADLSEExecution: Codeunit "AZD Execution";
        InvalidFieldsMap: Dictionary of [Integer, List of [Text]];
        CustomDimensions: Dictionary of [Text, Text];
        TableID: Integer;
    begin
        InvalidFieldsMap := ListInvalidFieldsBeingExported();
        foreach TableID in InvalidFieldsMap.Keys() do begin
            ADLSETable.Get(TableID);
            ADLSETable.Enabled := false;
            ADLSETable.Modify(true);

            Clear(CustomDimensions);
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(TableID));
            CustomDimensions.Add('ListOfInvalidFields', ADLSEUtil.Concatenate(InvalidFieldsMap.Get(TableID)));
            ADLSEExecution.Log('ADLSE-31', 'Table is disabled for export because it exports invalid fields.', Verbosity::Warning, CustomDimensions);
        end;
    end;
}
