// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.Reflection;
using System.Threading;
using System.Environment;

codeunit 11344443 "AZD Execution"
{
    trigger OnRun()
    begin
        StartExport();
    end;

    var
        EmitTelemetry: Boolean;
        ExportStartedTxt: Label 'Data export started for %1 out of %2 tables. Please refresh this page to see the latest export state for the tables. Only those tables that either have had changes since the last export or failed to export last time have been included. The tables for which the exports could not be started have been queued up for later.', Comment = '%1 = number of tables to start the export for. %2 = total number of tables enabled for export.';
        SuccessfulStopMsg: Label 'The export process was stopped successfully.';
        ClearSchemaExportedOnMsg: Label 'The schema export date has been cleared.';


    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'r')]
    internal procedure StartExport()
    var
        ADLSETable: Record "AZD Table";
    begin
        StartExport(ADLSETable);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Field", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Sync Companies", 'r')]
    internal procedure StartExport(var ADLSETable: Record "AZD Table")
    var
        ADLSESetupRec: Record "AZD Setup";
        ADLSEField: Record "AZD Field";
        ADLSECurrentSession: Record "AZD Current Session";
        AZDSyncCompanies: Record "AZD Sync Companies";
        ADLSESetup: Codeunit "AZD Setup";
        ADLSECommunication: Codeunit "AZD Communication";
        ADLSESessionManager: Codeunit "AZD Session Manager";
        ADLSEExternalEvents: Codeunit "AZD External Events";
        Counter: Integer;
        Started: Integer;
    begin
        ADLSESetup.CheckSetup(ADLSESetupRec);
        EmitTelemetry := ADLSESetupRec."Emit telemetry";
        ADLSECurrentSession.CleanupSessions();

        if AZDSyncCompanies.Get(CompanyName()) then begin// Possible Multi Company export Create session So that is can be stopped.
            ADLSECurrentSession.Start(AZDSyncCompanies.RecordId.TableNo);
            Commit(); //To make sure session is stored before starting exports
        end;

        if ADLSESetupRec.GetStorageType() = ADLSESetupRec."Storage Type"::"Azure Data Lake" then //Because Fabric doesn't have do create a container
            ADLSECommunication.SetupBlobStorage();
        ADLSESessionManager.Init();

        ADLSEExternalEvents.OnExport(ADLSESetupRec);

        if EmitTelemetry then
            Log('ADLSE-022', 'Starting export for all tables', Verbosity::Normal);
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet(false) then
            repeat
                Counter += 1;
                ADLSEField.SetRange("Table ID", ADLSETable."Table ID");
                ADLSEField.SetRange(Enabled, true);
                if not ADLSEField.IsEmpty() then
                    if ADLSESessionManager.StartExport(ADLSETable."Table ID", EmitTelemetry) then
                        Started += 1;
            until ADLSETable.Next() = 0;

        Message(ExportStartedTxt, Started, Counter);
        if EmitTelemetry then
            Log('ADLSE-001', StrSubstNo(ExportStartedTxt, Started, Counter), Verbosity::Normal);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Setup", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Current Session", 'rd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Run", 'm')]
    internal procedure StopExport()
    var
        ADLSESetup: Record "AZD Setup";
        ADLSERun: Record "AZD Run";
        ADLSECurrentSession: Record "AZD Current Session";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Emit telemetry" then
            Log('ADLSE-003', 'Stopping export sessions', Verbosity::Normal);

        ADLSECurrentSession.CancelAll();

        ADLSERun.CancelAllRuns();

        Message(SuccessfulStopMsg);
        if ADLSESetup."Emit telemetry" then
            Log('ADLSE-019', 'Stopped export sessions', Verbosity::Normal);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Setup", 'm')]
    internal procedure SchemaExport()
    var
        ADLSESetup: Record "AZD Setup";
        ADLSETable: Record "AZD Table";
        ADLSECurrentSession: Record "AZD Current Session";
        AllObjWithCaption: Record AllObjWithCaption;
        ADLSEExecute: Codeunit "AZD Execute";
        ADLSEExternalEvents: Codeunit "AZD External Events";
        ProgressWindowDialog: Dialog;
        Progress1Msg: Label 'Current Table:           #1##########\', Comment = '#1: table caption';
    begin
        // ensure that no current export sessions running
        ADLSECurrentSession.CheckForNoActiveSessions();

        ADLSETable.Reset();
        ADLSETable.SetRange(Enabled, true);
        if not ADLSETable.FindSet(false) then
            exit;

        if GuiAllowed() then
            ProgressWindowDialog.Open(Progress1Msg);

        repeat
            if GuiAllowed() then begin
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                AllObjWithCaption.SetRange("Object ID", ADLSETable."Table ID");
                if AllObjWithCaption.FindFirst() then
                    if GuiAllowed() then
                        ProgressWindowDialog.Update(1, AllObjWithCaption."Object Caption");
            end;

            ADLSEExecute.ExportSchema(ADLSETable."Table ID");
        until ADLSETable.Next() = 0;

        if GuiAllowed() then
            ProgressWindowDialog.Close();

        ADLSESetup.GetSingleton();
        ADLSESetup."Schema Exported On" := CurrentDateTime();
        ADLSESetup.Modify(true);

        ADLSEExternalEvents.OnExportSchema(ADLSESetup);
    end;

    internal procedure ClearSchemaExportedOn(ErrInfo: ErrorInfo)
    begin
        ClearSchemaExportedOn();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Setup", 'm')]
    internal procedure ClearSchemaExportedOn()
    var
        ADLSESetup: Record "AZD Setup";
        ADLSEExternalEvents: Codeunit "AZD External Events";
    begin
        ADLSESetup.GetSingleton();
        ADLSESetup."Schema Exported On" := 0DT;
        ADLSESetup.Modify(true);
        if GuiAllowed() then
            Message(ClearSchemaExportedOnMsg);

        ADLSEExternalEvents.OnClearSchemaExportedOn(ADLSESetup);
    end;

    internal procedure ScheduleExport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ADLSEScheduleTaskAssignment: Report "AZD Schedule Task Assignment";
        SavedData: Text;
        xmldata: Text;
        Handled: Boolean;
    begin
        OnBeforeScheduleExport(Handled);
        if Handled then
            exit;

        JobQueueEntry.SetFilter("User ID", UserId());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"AZD Schedule Task Assignment");
        JobQueueEntry.SetCurrentKey(SystemCreatedAt);
        JobQueueEntry.SetAscending(SystemCreatedAt, false);

        if JobQueueEntry.FindFirst() then
            SavedData := JobQueueEntry.GetReportParameters();

        xmldata := ADLSEScheduleTaskAssignment.RunRequestPage(SavedData);

        if xmldata <> '' then begin
            ADLSEScheduleTaskAssignment.CreateJobQueueEntry(JobQueueEntry);
            JobQueueEntry.SetReportParameters(xmldata);
            JobQueueEntry.Modify();
        end;
    end;

    internal procedure ScheduleMultiExport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        AZDScheduleMultiTaskAssign: Report AZDScheduleMultiTaskAssign;
        SavedData: Text;
        xmldata: Text;
        Handled: Boolean;
    begin
        OnBeforeScheduleExport(Handled);
        if Handled then
            exit;

        JobQueueEntry.SetFilter("User ID", UserId());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::AZDScheduleMultiTaskAssign);
        JobQueueEntry.SetCurrentKey(SystemCreatedAt);
        JobQueueEntry.SetAscending(SystemCreatedAt, false);

        if JobQueueEntry.FindFirst() then
            SavedData := JobQueueEntry.GetReportParameters();

        xmldata := AZDScheduleMultiTaskAssign.RunRequestPage(SavedData);

        if xmldata <> '' then begin
            AZDScheduleMultiTaskAssign.CreateJobQueueEntry(JobQueueEntry);
            JobQueueEntry.SetReportParameters(xmldata);
            JobQueueEntry.Modify();
        end;
    end;

    internal procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Log(EventId, Message, Verbosity, CustomDimensions);
    end;

    internal procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [InherentPermissions(PermissionObjectType::Table, Database::"AZD Table Last Timestamp", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table Last Timestamp", 'R')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterGetDatabaseTableTriggerSetup, '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
    begin
        if CompanyName() = '' then
            exit;

        // track deletes only if at least one export has been made for that table
        if ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(TableId) then
            OnDatabaseDelete := true;
    end;

    [InherentPermissions(PermissionObjectType::Table, Database::"AZD Table Last Timestamp", 'X')]
    [InherentPermissions(PermissionObjectType::Table, Database::"AZD Deleted Record", 'X')]
    [InherentPermissions(PermissionObjectType::Table, Database::"AZD Deleted Table Filter", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Table Last Timestamp", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Deleted Record", 'RI')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Deleted Table Filter", 'r')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseDelete, '', false, false)]
    local procedure OnAfterOnDatabaseDelete(RecRef: RecordRef)
    var
        ADLSETableLastTimestamp: Record "AZD Table Last Timestamp";
        ADLSEDeletedRecord: Record "AZD Deleted Record";
        DeletedTablesNottoSync: Record "AZD Deleted Table Filter";
    begin
        if RecRef.Number() = Database::"AZD Deleted Record" then
            exit;

        if RecRef.CurrentCompany() <> CompanyName() then //workarround for records which are deleted usings changecompany
            ADLSETableLastTimestamp.ChangeCompany(RecRef.CurrentCompany());

        if DeletedTablesNottoSync.Get(RecRef.Number()) then
            exit;

        // check if table is to be tracked.
        if not ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(RecRef.Number()) then
            exit;

        ADLSEDeletedRecord.TrackDeletedRecord(RecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleExport(var Handled: Boolean)
    begin

    end;
}
