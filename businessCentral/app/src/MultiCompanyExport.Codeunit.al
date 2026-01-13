namespace bc2adls;

using System.Threading;
using System.Environment;
codeunit 11344455 "AZD Multi Company Export"
{
    Permissions = tabledata "AZD Companies Table" = RIMD;
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var
        AZDTable: Record "AZD Table";
        AZDSyncCompanies: Record "AZD Sync Companies";
        AZDCurrentSession: Record "AZD Current Session";
        NewSessionID: Integer;
    begin
        AZDSyncCompanies.Reset();
        if CompanyFilters <> '' then
            AZDSyncCompanies.SetFilter("Sync Company", '%1', this.CompanyFilters);
        if GuiAllowed() then
            Message(this.ExportStartedTxt, AZDTable.Count(), AZDSyncCompanies.Count());
        if AZDSyncCompanies.FindSet(false) then
            repeat
                Clear(NewSessionID);
                if session.StartSession(NewSessionID, Codeunit::"AZD Execution", AZDSyncCompanies."Sync Company") then begin
                    AZDCurrentSession.ChangeCompany(AZDSyncCompanies."Sync Company");
                    repeat
                        Sleep(10000);
                    until (not Session.IsSessionActive(NewSessionID) and (not CheckAnyActiveSession(AZDSyncCompanies."Sync Company")) and (not AZDCurrentSession.AreAnySessionsActive()));
                    Commit();// Commit after each company is done. To prevent rollback of everything
                end;
            until AZDSyncCompanies.Next() = 0;
    end;


    var
        CompanyFilters: Text;
        ExportStartedTxt: Label 'Data export started for %1 tables in %2 Companies. Please refresh this page to see the latest export state for the tables. Only those tables that either have had changes since the last export or failed to export last time have been included. The tables for which the exports could not be started have been queued up for later.', Comment = '%1 = Total number of tables to start the export for. %2 = Total number of companies to export for.';

    [InherentPermissions(PermissionObjectType::TableData, Database::"AZD Current Session", 'rd')]

    local procedure CheckAnyActiveSession(CurrentCompany: Text[30]): Boolean
    var
        ActiveSession: Record "Active Session";
        AZDCurrentSession: Record "AZD Current Session";
    begin
        SelectLatestVersion();
        AZDCurrentSession.ReadIsolation := AZDCurrentSession.ReadIsolation::ReadUncommitted;
        AZDCurrentSession.SetRange("Company Name", CurrentCompany);
        if AZDCurrentSession.FindSet(false) then
            repeat
                ActiveSession.Reset();
                ActiveSession.SetRange("Session ID", AZDCurrentSession."Session ID");
                ActiveSession.SetRange("Client Type", ActiveSession."Client Type"::Background);
                if not ActiveSession.IsEmpty() then
                    exit(true);
            until AZDCurrentSession.Next() = 0;
    end;


    procedure SetCompanyFilter(Filter: Text)
    begin
        this.CompanyFilters := Filter;
    end;
}
