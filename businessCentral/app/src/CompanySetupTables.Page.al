namespace bc2adls;

using System.Reflection;
page 11344454 "AZD Company Setup Tables"
{
    ApplicationArea = All;
    Caption = 'Company Tables';
    LinksAllowed = false;
    UsageCategory = Administration;
    PageType = ListPart;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTable = "AZD Companies Table";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Sync Company"; Rec."Sync Company")
                {
                }
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Caption"; Rec."Table Caption")
                {
                }

                field(FieldsChosen; NumberFieldsChosenValue)
                {
                    Editable = false;
                    Caption = '# Fields selected';
                    ToolTip = 'Specifies if any field has been chosen to be exported. Click on Choose Fields action to add fields to export.';
                    trigger OnDrillDown()
                    var
                        AZDTable: Record "AZD Table";
                    begin
                        AZDTable.Get(Rec."Table ID");
                        AZDTable.DoChooseFields();
                        CurrPage.Update();
                    end;
                }
                field("No. of Records"; Rec.GetNoOfDatabaseRecordsText())
                {
                    Caption = 'No. of Records';
                    Editable = false;
                    ToolTip = 'Specifies the No. of Records for the table.';
                }
                field(Status; Rec."Last Run State")
                {
                    Caption = 'Last exported state';
                    Editable = false;
                }
                field("Last Started"; Rec."Last Started")
                {
                    Caption = 'Last started at';
                    Editable = false;
                }
                field("Last Error"; Rec."Last Error")
                {
                    Caption = 'Last error';
                    Editable = false;
                }
                field("Updated Last Timestamp"; Rec."Updated Last Timestamp")
                {
                    Caption = 'Last timestamp';
                    Visible = false;
                }
                field("Last Timestamp Deleted"; Rec."Last Timestamp Deleted")
                {
                    Caption = 'Last timestamp deleted';
                    Visible = false;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {

            action(Refresh)
            {
                Image = Refresh;
                Caption = 'Refresh';
                ToolTip = 'Refresh all Last Run State.';

                trigger OnAction()
                var
                    CurrAZDCompanySetupTable: record "AZD Companies Table";
                begin
                    if CurrAZDCompanySetupTable.FindSet() then
                        repeat
                            RefreshStatus(CurrAZDCompanySetupTable);
                        until CurrAZDCompanySetupTable.Next() = 0;
                    CurrPage.Update(true);
                end;
            }
            action(AddTable)
            {
                Caption = 'Add';
                ToolTip = 'Add a table to be exported.';
                Image = New;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    AZDSetup: Codeunit "AZD Setup";
                begin
                    AZDSetup.AddTableToExport();
                    CurrPage.Update();
                end;
            }

            action(DeleteTable)
            {
                Caption = 'Delete';
                ToolTip = 'Removes a table that had been added to the list meant for export.';
                Image = Delete;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    AZDTable: Record "AZD Table";
                begin
                    AZDTable.Get(Rec."Table ID");
                    AZDTable.Delete(true);
                    CurrPage.Update();
                end;
            }

            action(ChooseFields)
            {
                Caption = 'Choose fields';
                ToolTip = 'Select the fields of this table to be exported.';
                Image = SelectEntries;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var

                    AZDTable: Record "AZD Table";
                begin
                    AZDTable.Get(Rec."Table ID");
                    AZDTable.DoChooseFields();
                end;
            }

            action("Reset")
            {
                Caption = 'Reset';
                ToolTip = 'Set the selected tables to export all of its data again.';
                Image = ResetStatus;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    SelectedAZDCompaniesTable: Record "AZD Companies Table";
                    SelectedAZDTable: Record "AZD Table";
                    AZDSetup: Record "AZD Setup";
                    Options: Text[50];
                    OptionStringLbl: Label 'Current Company,All Companies';
                    ResetTablesForAllCompaniesQst: Label 'Do you want to reset the selected tables for all companies?';
                    ResetTablesQst: Label 'Do you want to reset the selected tables for the current company or all companies?';
                    ChosenOption: Integer;
                begin
                    Options := OptionStringLbl;
                    AZDSetup.GetSingleton();
                    if AZDSetup."Storage Type" = AZDSetup."Storage Type"::"Open Mirroring" then begin
                        if Confirm(ResetTablesForAllCompaniesQst, true) then
                            ChosenOption := 2
                        else
                            exit;
                    end else
                        ChosenOption := Dialog.StrMenu(Options, 1, ResetTablesQst);
                    CurrPage.SetSelectionFilter(SelectedAZDCompaniesTable);
                    SelectedAZDTable.SetFilter("Table ID", GetTableIDFilter(SelectedAZDCompaniesTable));
                    case ChosenOption of
                        0:
                            exit;
                        1:
                            SelectedAZDTable.ResetSelected(false);
                        2:
                            SelectedAZDTable.ResetSelected(true);
                        else
                            Error('Chosen option is not valid');
                    end;
                    CurrPage.Update();
                end;
            }

            action(Logs)
            {
                Caption = 'Execution logs';
                ToolTip = 'View the execution logs for this table in the currently opened company.';
                Image = Log;

                trigger OnAction()
                var
                    AZDRun: Page "AZD Run";
                begin
                    AZDRun.SetDisplayForTable(Rec."Table ID");
                    AZDRun.SetCompanyName(Rec."Sync Company");
                    AZDRun.Run();
                end;

            }
            action(ImportBC2ADLS)
            {
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a file with BC2ADLS tables and fields.';

                trigger OnAction()
                var
                    AZDTable: Record "AZD Table";
                begin
                    XmlPort.Run(XmlPort::"BC2ADLS Import", false, true, AZDTable);
                    CurrPage.Update(false);
                end;
            }
            action(ExportBC2ADLS)
            {
                Caption = 'Export';
                Image = Export;
                ToolTip = 'Exports a file with BC2ADLS tables and fields.';

                trigger OnAction()
                var
                    AZDTable: Record "AZD Table";
                begin
                    AZDTable.Reset();
                    XmlPort.Run(XmlPort::"BC2ADLS Export", false, false, AZDTable);
                    CurrPage.Update(false);
                end;
            }
            action(AssignExportCategory)
            {
                Caption = 'Assign Export Category';
                Image = Apply;
                ToolTip = 'Assign an Export Category to the Table.';

                trigger OnAction()
                var
                    AZDTable: Record "AZD Table";
                    AssignExportCategory: Page "AZD Assign Export Category";
                begin
                    CurrPage.SetSelectionFilter(AZDTable);
                    AssignExportCategory.LookupMode(true);
                    if AssignExportCategory.RunModal() = Action::LookupOK then
                        AZDTable.ModifyAll(ExportCategory, AssignExportCategory.GetExportCategoryCode());
                    CurrPage.Update();
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TableMetadata: Record "Table Metadata";
        AZDTable: Record "AZD Table";
        AZDCurrentSession: Record "AZD Current Session";
    begin
        if AZDTable.Get(Rec."Table ID") then
            if TableMetadata.Get(Rec."Table ID") then
                NumberFieldsChosenValue := AZDTable.FieldsChosen()
            else
                NumberFieldsChosenValue := 0;
        if AZDTable.Get(Rec."Table ID") then
            AZDTable.IssueNotificationIfInvalidFieldsConfiguredToBeExported();
        if AZDCurrentSession.ChangeCompany(Rec."Sync Company") then
            NoExportInProgress := not AZDCurrentSession.AreAnySessionsActive();
    end;

    trigger OnOpenPage()
    var
        CurrAZDCompanySetupTable: record "AZD Companies Table";
    begin
        if CurrAZDCompanySetupTable.FindSet() then
            repeat
                RefreshStatus(CurrAZDCompanySetupTable);
            until CurrAZDCompanySetupTable.Next() < 1;
    end;

    local procedure RefreshStatus(var CurrRec: Record "AZD Companies Table")
    var
        NewSessionId: Integer;
    begin
        Session.StartSession(NewSessionId, Codeunit::"AZD Company Run", CurrRec."Sync Company", CurrRec);
    end;

    local procedure GetTableIDFilter(var SelectedAZDCompaniesTable: Record "AZD Companies Table") TableIDFilter: Text
    begin
        if SelectedAZDCompaniesTable.FindSet(false) then
            repeat
                if TableIDFilter = '' then
                    TableIDFilter := Format(SelectedAZDCompaniesTable."Table ID")
                else
                    TableIDFilter := TableIDFilter + '|' + Format(SelectedAZDCompaniesTable."Table ID");
            until SelectedAZDCompaniesTable.Next() = 0;
    end;

    var
        NoExportInProgress: Boolean;

        NumberFieldsChosenValue: Integer;

}
