namespace bc2adls;

using System.Environment;

table 11344455 "AZD Sync Companies"
{
    Access = Internal;
    Caption = 'AZD Sync Companies';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    LookupPageId = "AZD Company Setup";
    DrillDownPageId = "AZD Company Setup";
    Permissions = tabledata "AZD Field" = rd,
        tabledata "AZD Table Last Timestamp" = d,
        tabledata "AZD Deleted Record" = d;

    fields
    {
        field(25; "Sync Company"; Text[30])
        {
            NotBlank = true;
            Caption = 'Sync Company';
            ToolTip = 'The company that is being Exported.';
            TableRelation = Company.Name where("Evaluation Company" = const(false));
        }

    }

    keys
    {
        key(PK; "Sync Company")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Sync Company")
        {
        }
        fieldgroup(Brick; "Sync Company")
        {
        }
    }

    trigger OnInsert()
    begin
        UpsertAllTableIds(0);
    end;

    trigger OnDelete()
    begin
        UpsertAllTableIds(2);
    end;

    trigger OnModify()
    begin
        UpsertAllTableIds(1);
    end;

    local procedure UpsertAllTableIds(Rowmarker: Integer)
    var
        AZDTable: Record "AZD Table";
        AZDCompaniesTable: Record "AZD Companies Table";
        RenameAZDCompaniesTable: Record "AZD Companies Table";
        SyncCompany: Text[30];
        xSyncCompany: Text[30];
    begin
        // Rowmarker semantics used here:
        // 0 = Insert -> add missing rows for this Sync Company across ALL table IDs (do not update existing rows)
        // 1 = Modify -> update existing rows for this Sync Company across ALL table IDs (do not insert missing rows)
        // 2 = Delete -> remove ALL rows for this Sync Company across ALL table IDs (except current row already being deleted)

        SyncCompany := Rec."Sync Company";
        xSyncCompany := xRec."Sync Company";
        if SyncCompany = '' then
            exit;

        case Rowmarker of
            2: // Delete: remove this company entry for all other tables (current one is already being deleted)

                if AZDTable.FindSet() then
                    repeat
                        if RenameAZDCompaniesTable.Get(AZDTable."Table ID", SyncCompany) then
                            RenameAZDCompaniesTable.Delete(true);
                    until AZDTable.Next() = 0;
            0: // Insert: add missing rows only

                if AZDTable.FindSet() then
                    repeat
                        AZDCompaniesTable.Init();
                        AZDCompaniesTable."Table ID" := AZDTable."Table ID";
                        AZDCompaniesTable."Sync Company" := SyncCompany;
                        AZDCompaniesTable.Insert(false);
                    until AZDTable.Next() = 0;

            1: // Modify: update existing rows only
                begin

                    if not AZDCompaniesTable.Get(AZDTable."Table ID", SyncCompany) then begin
                        AZDCompaniesTable.Init();
                        AZDCompaniesTable."Table ID" := AZDTable."Table ID";
                        AZDCompaniesTable."Sync Company" := SyncCompany;
                        AZDCompaniesTable.Insert(true);
                    end;
                    repeat
                        if RenameAZDCompaniesTable.Get(AZDCompaniesTable."Table ID", AZDCompaniesTable."Sync Company") then
                            RenameAZDCompaniesTable.Rename(AZDCompaniesTable."Table ID", SyncCompany);
                    until AZDCompaniesTable.Next() = 0;
                end;
        end;
    end;
}
