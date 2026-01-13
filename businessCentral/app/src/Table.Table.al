// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.Reflection;

#pragma warning disable LC0015
table 11344450 "AZD Table"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADL Table';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Permissions = tabledata "AZD Field" = rd,
                  tabledata "AZD Table Last Timestamp" = d,
                  tabledata "AZD Deleted Record" = d;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            Editable = false;
            Caption = 'Table ID';
        }
        field(3; Enabled; Boolean)
        {
            Editable = false;
            Caption = 'Enabled';
            ToolTip = 'Specifies the state of the table. Set this checkmark to export this table, otherwise not.';

            trigger OnValidate()
            var
                ADLSEExternalEvents: Codeunit "AZD External Events";
                ADLSETableErr: Label 'The ADL Table table cannot be disabled.';
            begin
                if Rec."Table ID" = Database::"AZD Table" then
                    if xRec.Enabled = false then
                        Error(ADLSETableErr);

                if Rec.Enabled then
                    CheckExportingOnlyValidFields();

                ADLSEExternalEvents.OnEnableTableChanged(Rec);
            end;
        }
        field(10; ExportCategory; Code[50])
        {
            Caption = 'Export Category';
            TableRelation = "AZD Export Category Table";
            ToolTip = 'Specifies the Export Category which can be linked to tables which are part of the export to Azure Datalake. The Category can be used to schedule the export.';
        }
        field(15; ExportFileNumber; Integer)
        {
            Caption = 'Export File Number';
            AllowInCustomizations = AsReadOnly;
        }
        field(17; "Initial Load Start Date"; Date)
        {
            Caption = 'Initial Load Start Date';
            ToolTip = 'Specifies the starting date for the initial data load. Only records with SystemModifiedAt >= this date will be exported on the first export. Leave blank to export all historical data.';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Table ID")
        {
        }
        fieldgroup(Brick; "Table ID", Enabled, ExportCategory)
        {
        }
    }

    trigger OnInsert()
    var
        ADLSESetup: Record "AZD Setup";
    begin
        ADLSESetup.SchemaExported();

        CheckTableOfTypeNormal(Rec."Table ID");

        UpsertAllTableIds(0);
    end;

    trigger OnDelete()
    var
        ADLSESetup: Record "AZD Setup";
        ADLSETableField: Record "AZD Field";
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
        ADLSEDeletedRecord: Record "AZD Deleted Record";
        ADLSEExternalEvents: Codeunit "AZD External Events";
    begin
        ADLSESetup.SchemaExported();

        ADLSETableField.SetRange("Table ID", Rec."Table ID");
        ADLSETableField.DeleteAll(false);

        ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
        ADLSEDeletedRecord.DeleteAll(false);

        ADLSETableLastTimestamp.SetRange("Table ID", Rec."Table ID");
        ADLSETableLastTimestamp.DeleteAll(false);

        ADLSEExternalEvents.OnDeleteTable(Rec);
    end;

    trigger OnModify()
    var
        ADLSESetup: Record "AZD Setup";
    begin
        if (Rec."Table ID" <> xRec."Table ID") or (Rec.Enabled <> xRec.Enabled) then begin
            ADLSESetup.SchemaExported();
            CheckNotExporting();
        end;
    end;

    trigger OnRename()
    begin
        UpsertAllTableIds(8);
    end;

    var
        TableNotNormalErr: Label 'Table %1 is not a normal table.', Comment = '%1: caption of table';
        TableExportingDataErr: Label 'Data is being executed for table %1. Please wait for the export to finish before making changes.', Comment = '%1: table caption';
        TableCannotBeExportedErr: Label 'The table %1 cannot be exported because of the following error. \%2', Comment = '%1: Table ID, %2: error text';
        TablesResetTxt: Label '%1 table(s) were reset %2', Comment = '%1 = number of tables that were reset, %2 = message if tables are exported';
        TableResetExportedTxt: Label 'and are exported to the lakehouse. Please run the notebook first.';
        StoppedByUserLbl: Label 'Session stopped by user.';
        InvalidFieldNotificationSent: List of [Integer];
        InvalidFieldConfiguredMsg: Label 'The following fields have been incorrectly enabled for exports in the table %1: %2', Comment = '%1 = table name; %2 = List of invalid field names';
        WarnOfSchemaChangeQst: Label 'Data may have been exported from this table before. Changing the export schema now may cause unexpected side- effects. You may reset the table first so all the data shall be exported afresh. Do you still wish to continue?';

    procedure FieldsChosen(): Integer
    var
        ADLSEField: Record "AZD Field";
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        exit(ADLSEField.Count());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'i')]
    procedure Add(TableID: Integer)
    var
        ADLSEExternalEvents: Codeunit "AZD External Events";
    begin
        if not CheckTableCanBeExportedFrom(TableID) then
            Error(TableCannotBeExportedErr, TableID, GetLastErrorText());
        Rec.Init();
        Rec."Table ID" := TableID;
        Rec.Enabled := true;
        Rec.Insert(true);

        AddPrimaryKeyFields();
        ADLSEExternalEvents.OnAddTable(Rec);
    end;

    [TryFunction]
    local procedure CheckTableCanBeExportedFrom(TableID: Integer)
    var
        RecordRef: RecordRef;
    begin
        ClearLastError();
        RecordRef.Open(TableID); // proves the table exists and can be opened
    end;

    local procedure CheckTableOfTypeNormal(TableID: Integer)
    var
        TableMetadata: Record "Table Metadata";
        ADLSEUtil: Codeunit "AZD Util";
        TableCaption: Text;
    begin
        TableCaption := ADLSEUtil.GetTableCaption(TableID);

        TableMetadata.SetRange(ID, TableID);
        TableMetadata.FindFirst();

        if TableMetadata.TableType <> TableMetadata.TableType::Normal then
            Error(TableNotNormalErr, TableCaption);
    end;

    procedure CheckNotExporting()
    var
        ADLSEUtil: Codeunit "AZD Util";
    begin
        if GetLastRunState() = "AZD Run State"::InProcess then
            Error(TableExportingDataErr, ADLSEUtil.GetTableCaption(Rec."Table ID"));
    end;

    local procedure GetLastRunState(): Enum "AZD Run State"
    var
        ADLSERun: Record "AZD Run";
        LastState: Enum "AZD Run State";
        LastStarted: DateTime;
        LastErrorText: Text[2048];
    begin
        ADLSERun.GetLastRunDetails(Rec."Table ID", LastState, LastStarted, LastErrorText);
        exit(LastState);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'rm')]
    procedure ResetSelected()
    begin
        ResetSelected(false);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'rm')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table Last Timestamp", 'rm')]
    procedure ResetSelected(AllCompanies: Boolean)
    var
        ADLSEDeletedRecord: Record "AZD Deleted Record";
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
        ADLSESetup: Record "AZD Setup";
        ADLSECommunication: Codeunit "AZD Communication";
        Counter: Integer;
    begin
        if Rec.FindSet(true) then
            repeat
                if not Rec.Enabled then begin
                    Rec.Enabled := true;
                    Rec.Modify(true);
                end;
                ADLSESetup.GetSingleton();

                if not AllCompanies then begin
                    if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        if ADLSETableLastTimestamp.Get(CompanyName(), Rec."Table ID") then
                            ADLSETableLastTimestamp.Delete(true);
                    end
                    else begin
                        ADLSETableLastTimestamp.SaveUpdatedLastTimestamp(Rec."Table ID", 0);
                        ADLSETableLastTimestamp.SaveDeletedLastEntryNo(Rec."Table ID", 0);
                    end;
                end else
                    if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        ADLSETableLastTimestamp.SetRange("Table ID", Rec."Table ID");
                        ADLSETableLastTimestamp.DeleteAll();
                    end
                    else begin
                        ADLSETableLastTimestamp.SetRange("Table ID", Rec."Table ID");
                        ADLSETableLastTimestamp.ModifyAll("Updated Last Timestamp", 0, true);
                        ADLSETableLastTimestamp.ModifyAll("Deleted Last Entry No.", 0, true);
                        ADLSETableLastTimestamp.SetRange("Table ID");
                    end;
                ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
                ADLSEDeletedRecord.DeleteAll(false);

                if (ADLSESetup."Delete Table") then
                    ADLSECommunication.ResetTableExport(Rec."Table ID", AllCompanies);

                Rec.ExportFileNumber := 1;
                Rec.Modify(true);

                OnAfterResetSelected(Rec);

                Counter += 1;
            until Rec.Next() = 0;
        if (ADLSESetup."Delete Table") and (ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Microsoft Fabric") then
            Message(TablesResetTxt, Counter, TableResetExportedTxt)
        else
            Message(TablesResetTxt, Counter, '.');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'r')]
    local procedure CheckExportingOnlyValidFields()
    var
        ADLSEField: Record "AZD Field";
        Field: Record Field;
        ADLSESetup: Codeunit "AZD Setup";
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                Field.Get(ADLSEField."Table ID", ADLSEField."Field ID");
                ADLSESetup.CheckFieldCanBeExported(Field);
            until ADLSEField.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'r')]
    procedure ListInvalidFieldsBeingExported() FieldList: List of [Text]
    var
        ADLSEField: Record "AZD Field";
        ADLSESetup: Codeunit "AZD Setup";
        ADLSEUtil: Codeunit "AZD Util";
        ADLSEExecution: Codeunit "AZD Execution";
        CustomDimensions: Dictionary of [Text, Text];
        RemovedFieldNameLbl: Label '#[%1]', Locked = true;
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                if not ADLSESetup.CanFieldBeExported(ADLSEField."Table ID", ADLSEField."Field ID") then begin
                    ADLSEField.CalcFields(FieldCaption);
                    FieldList.Add(ADLSEField.FieldCaption <> '' ? ADLSEField.FieldCaption : StrSubstNo(RemovedFieldNameLbl, ADLSEField."Field ID"));
                end;
            until ADLSEField.Next() = 0;

        if FieldList.Count() > 0 then begin
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(Rec."Table ID"));
            CustomDimensions.Add('ListOfFields', ADLSEUtil.Concatenate(FieldList));
            ADLSEExecution.Log('ADLSE-029', 'The following invalid fields are configured to be exported from the table.',
                Verbosity::Warning, CustomDimensions);
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'rm')]
    procedure AddAllFields()
    var
        ADLSEFields: Record "AZD Field";
    begin
        ADLSEFields.InsertForTable(Rec);
        ADLSEFields.SetRange("Table ID", Rec."Table ID");
        if ADLSEFields.FindSet(true) then
            repeat
                if (ADLSEFields.CanFieldBeEnabled()) then begin
                    ADLSEFields.Enabled := true;
                    ADLSEFields.Modify(true);
                end;
            until ADLSEFields.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table Last Timestamp", 'r')]
    procedure GetLastHeartbeat(): DateTime
    var
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
    begin
        ADLSETableLastTimestamp.ReadIsolation(ReadIsolation::ReadUncommitted);
        if not ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(Rec."Table ID") then
            exit;
        exit(ADLSETableLastTimestamp.SystemModifiedAt)
    end;

    procedure GetActiveSessionId(): Integer
    var
        ExpSessionId: Integer;
    begin
        ExpSessionId := GetCurrentSessionId();
        if ExpSessionId = 0 then
            exit;
        if IsSessionActive(ExpSessionId) then
            exit(ExpSessionId);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Current Session", 'r')]
    procedure GetCurrentSessionId(): Integer
    var
        CurrentSession: Record "AZD Current Session";
    begin
        CurrentSession.ReadIsolation(ReadIsolation::ReadUncommitted);
        if CurrentSession.Get(Rec."Table ID", CompanyName()) then
            exit(CurrentSession."Session ID");
        exit(0);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Current Session", 'd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Run", 'm')]
    procedure StopActiveSession()
    var
        CurrentSession: Record "AZD Current Session";
        Run: Record "AZD Run";
        ADLSEUtil: Codeunit "AZD Util";
        ExpSessionId: Integer;
    begin
        ExpSessionId := GetActiveSessionId();
        if ExpSessionId <> 0 then
            if IsSessionActive(ExpSessionId) then
                Session.StopSession(ExpSessionId, StoppedByUserLbl);
        CurrentSession.Stop(Rec."Table ID", false, ADLSEUtil.GetTableCaption(Rec."Table ID"));
        Run.CancelRun(Rec."Table ID");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'ri')]
    local procedure AddPrimaryKeyFields()
    var
        Field: Record Field;
        ADLSEField: Record "AZD Field";
    begin
        Field.SetRange(TableNo, Rec."Table ID");
        Field.SetRange(IsPartOfPrimaryKey, true);
        if Field.Findset() then
            repeat
                if not ADLSEField.Get(Rec."Table ID", Field."No.") then begin
                    ADLSEField."Table ID" := Field.TableNo;
                    ADLSEField."Field ID" := Field."No.";
                    ADLSEField.Enabled := true;
                    ADLSEField.Insert();
                end;
            until Field.Next() = 0;
    end;

    local procedure UpsertAllTableIds(Rowmarker: Integer)
    var
        AZDCompaniesTable: Record "AZD Companies Table";
        AZDSyncCompanies: Record "AZD Sync Companies";
        SyncCompany: Text[30];
    begin
        // Rowmarker semantics used here:
        // 0 = Insert -> add missing rows for this Sync Company across ALL table IDs (do not update existing rows)
        // 1 = Modify -> update existing rows for this Sync Company across ALL table IDs (do not insert missing rows)
        // 2 = Delete -> remove ALL rows for this Sync Company across ALL table IDs (except current row already being deleted)

        SyncCompany := CopyStr(CompanyName(), 1, MaxStrLen(SyncCompany));
        if SyncCompany = '' then
            exit;

        case Rowmarker of
            2: // Delete: remove this company entry for all other tables (current one is already being deleted)
                begin
                    AZDCompaniesTable.SetRange("Table ID", Rec."Table ID");
                    AZDCompaniesTable.DeleteAll(false);
                end;

            0: // Insert: add missing rows only
                if AZDSyncCompanies.FindSet() then
                    repeat
                        AZDCompaniesTable.Init();
                        AZDCompaniesTable."Table ID" := Rec."Table ID";
                        AZDCompaniesTable."Sync Company" := AZDSyncCompanies."Sync Company";
                        if AZDCompaniesTable.Insert(false) then;
                    until AZDSyncCompanies.Next() = 0;
            8: // Rename:
                begin
                    UpsertAllTableIds(2);
                    UpsertAllTableIds(0);
                end;
        end;
    end;

    procedure DoChooseFields()
    var
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
        ADLSESetup: Codeunit "AZD Setup";
    begin
        if ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(Rec."Table ID") then
            if not Confirm(WarnOfSchemaChangeQst, false) then
                exit;
        ADLSESetup.ChooseFieldsToExport(Rec);
    end;

    procedure IssueNotificationIfInvalidFieldsConfiguredToBeExported()
    var
        ADLSEUtil: Codeunit "AZD Util";
        InvalidFieldNotification: Notification;
        InvalidFieldList: List of [Text];
    begin
        if InvalidFieldNotificationSent.Contains(Rec."Table ID") then
            exit;
        InvalidFieldList := Rec.ListInvalidFieldsBeingExported();
        if InvalidFieldList.Count() = 0 then
            exit;
        InvalidFieldNotification.Message := StrSubstNo(InvalidFieldConfiguredMsg, ADLSEUtil.GetTableCaption(Rec."Table ID"), ADLSEUtil.Concatenate(InvalidFieldList));
        InvalidFieldNotification.Scope := NotificationScope::LocalScope;
        InvalidFieldNotification.Send();
        InvalidFieldNotificationSent.Add(Rec."Table ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetSelected(ADLSETable: Record "AZD Table")
    begin

    end;
}
