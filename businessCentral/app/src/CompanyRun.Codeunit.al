namespace bc2adls;

using System.Reflection;
codeunit 11344454 "AZD Company Run"
{

    Permissions = tabledata "AZD Companies Table" = RIMD;
    TableNo = "AZD Companies Table";
    trigger OnRun()
    var
        TableMetadata: Record "Table Metadata";
        AZDTableLastTimestamp: Record "AZD Table Last Timestamp";
        AZDRun: Record "AZD Run";
    begin
        if TableMetadata.Get(Rec."Table ID") then begin
            Rec."Updated Last Timestamp" := AZDTableLastTimestamp.GetUpdatedLastTimestamp(Rec."Table ID");
            Rec."Last Timestamp Deleted" := AZDTableLastTimestamp.GetDeletedLastEntryNo(Rec."Table ID");
        end else begin
            Rec."Updated Last Timestamp" := 0;
            Rec."Last Timestamp Deleted" := 0;
        end;
        AZDRun.GetLastRunDetails(Rec."Table ID", Rec."Last Run State", Rec."Last Started", Rec."Last Error");
        Rec.Modify(false);
    end;
}
