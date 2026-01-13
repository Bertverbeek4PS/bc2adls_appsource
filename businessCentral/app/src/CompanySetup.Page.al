namespace bc2adls;

using System.Threading;
page 11344455 "AZD Company Setup"
{
    Caption = 'Export Companies to Azure Data Lake Storage';
    ApplicationArea = all;
    UsageCategory = Administration;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "AZD Sync Companies";
    RefreshOnActivate = true;
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Sync Company"; Rec."Sync Company")
                {

                }
                field(JobObjectIDtoRun; JobObjectIDtoRun)
                {
                    Caption = 'Job Object ID';
                    ToolTip = 'Specifies the object ID of the job queue entry assigned to schedule the export.';
                    Editable = false;
                }
                field(JobObjectCaptiontoRun; JobObjectCaptiontoRun)
                {
                    Caption = 'Job Object Caption';
                    ToolTip = 'Specifies the caption of the object executed by the scheduled job queue entry.';
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                    begin
                        JobQueueEntry.ChangeCompany(Rec."Sync Company");
                        JobQueueEntry.SetRange("Object ID to Run", Report::AZDScheduleMultiTaskAssign);
                        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
                    end;
                }
                field(JobStatus; JobStatus)
                {
                    Caption = 'Job Status';
                    OptionCaption = 'Ready,In Process,Error,On Hold,Finished,On Hold with Inactivity Timeout,Waiting, ';
                    ToolTip = 'Specifies the current status of the scheduled export job for this company.';
                    Editable = false;
                }
                field(JobEarliestStartDateTime; JobEarliestStartDateTime)
                {
                    Caption = 'Earliest Start';
                    ToolTip = 'Specifies the earliest start date/time of the scheduled job queue entry for this company.';
                    Editable = false;
                }
            }
            part("Company Tables"; "AZD Company Setup Tables")
            {
                UpdatePropagation = Both;
                SubPageLink = "Sync Company" = field("Sync Company");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ExportNow)
            {
                Caption = 'Export All Companies';
                ToolTip = 'Starts the export process by spawning different sessions for each table. The action is disabled in case there are export processes currently running, also in other companies.';
                Image = Start;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                trigger OnAction()
                var
                    TempJobQueueEntry: Record "Job Queue Entry" temporary;
                    "AZD Multi Company Export": Codeunit "AZD Multi Company Export";
                begin
                    "AZD Multi Company Export".Run(TempJobQueueEntry);
                    CurrPage.Update();
                end;
            }
            action(ExportSelectedCompanyNow)
            {
                Caption = 'Export Selected Company';
                ToolTip = 'Starts the export process for the selected company.';
                Image = Start;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                trigger OnAction()
                var
                    AZDSyncCompanies: Record "AZD Sync Companies";
                    TempJobQueueEntry: Record "Job Queue Entry" temporary;
                    "AZD Multi Company Export": Codeunit "AZD Multi Company Export";
                    FilterString: Text;
                begin
                    SetSelectionFilter(AZDSyncCompanies);
                    if AZDSyncCompanies.FindSet() then
                        repeat
                            if not FilterString.Contains(AZDSyncCompanies."Sync Company") then
                                if FilterString = '' then
                                    FilterString := AZDSyncCompanies."Sync Company"
                                else
                                    FilterString := FilterString + '|' + AZDSyncCompanies."Sync Company";
                        until AZDSyncCompanies.Next() = 0;
                    TempJobQueueEntry.Init();
                    TempJobQueueEntry.Insert(false);
                    "AZD Multi Company Export".SetCompanyFilter(FilterString);
                    "AZD Multi Company Export".Run(TempJobQueueEntry);
                    CurrPage.Update();
                end;
            }

            action(StopExport)
            {
                Caption = 'Stop export';
                ToolTip = 'Tries to stop all sessions that are exporting data, including those that are running in other companies.';
                Image = Stop;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AZDExecution: Codeunit "AZD Execution";
                begin
                    AZDExecution.StopExport();
                    CurrPage.Update();
                end;
            }
            action(SchemaExport)
            {
                Caption = 'Schema export';
                ToolTip = 'This will export the schema of the tables selected in the setup to the lake. This is a one-time operation and should be done before the first export of data.';
                Image = Start;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AZDExecution: Codeunit "AZD Execution";
                begin
                    AZDExecution.SchemaExport();
                    CurrPage.Update();
                end;
            }
            action(ClearSchemaExported)
            {
                Caption = 'Clear schema export date';
                ToolTip = 'This will clear the schema exported on field. If this is cleared you can change the schema and export it again.';
                Image = ClearLog;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AZDExecution: Codeunit "AZD Execution";
                begin
                    AZDExecution.ClearSchemaExportedOn();
                    CurrPage.Update();
                end;
            }

            action(Schedule)
            {
                Caption = 'Schedule export';
                ToolTip = 'Schedules the export process as a job queue entry.';
                Image = Timesheet;

                trigger OnAction()
                var
                    AZDExecution: Codeunit "AZD Execution";
                begin
                    AZDExecution.ScheduleMultiExport();
                end;
            }

            action(ClearDeletedRecordsList)
            {
                Caption = 'Clear tracked deleted records';
                ToolTip = 'Removes the entries in the deleted record list that have already been exported. The codeunit AZD Clear Tracked Deletions may be invoked using a job queue entry for the same end.';
                Image = ClearLog;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AZDDeletedRecord: Record "AZD Deleted Record";
                    NewSessionID: Integer;
                begin
                    if Rec.FindSet() then
                        repeat
                            if AZDDeletedRecord.ChangeCompany(Rec."Sync Company") then
                                if not AZDDeletedRecord.IsEmpty() then
                                    Session.StartSession(NewSessionID, Codeunit::"AZD Clear Tracked Deletions", Rec."Sync Company");
                        until Rec.Next() = 0;
                    CurrPage.Update();
                end;
            }
        }
        area(Navigation)
        {
            action("Job Queue")
            {
                Caption = 'Job Queue';
                ToolTip = 'Specifies the scheduled Job Queues for the export to Datalake.';
                Image = BulletList;
                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.ChangeCompany(Rec."Sync Company");
                    JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"AZD Multi Company Export", Report::AZDScheduleMultiTaskAssign);
                    Page.Run(Page::"Job Queue Entries", JobQueueEntry);
                end;
            }
            action("Export Category")
            {
                Caption = 'Export Category';
                ToolTip = 'Specifies the Export Categories available for scheduling the export to Datalake.';
                Image = Export;
                RunObject = page "AZD Export Categories";
            }
        }
    }
    trigger OnInit()
    begin
        if not Rec.FindFirst() then begin
            Rec.Init();
            Rec."Sync Company" := CopyStr(CompanyName(), 1, MaxStrLen(Rec."Sync Company"));
            Rec.Insert(true);
        end;
    end;


    trigger OnAfterGetRecord()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.ChangeCompany(Rec."Sync Company") then begin
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
            JobQueueEntry.SetRange("Object ID to Run", Report::AZDScheduleMultiTaskAssign);
            if JobQueueEntry.FindFirst() then begin
                JobEarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";
                JobStatus := JobQueueEntry.Status;
                JobObjectIDtoRun := JobQueueEntry."Object ID to Run";
                JobQueueEntry.CalcFields("Object Caption to Run");
                JobObjectCaptiontoRun := JobQueueEntry."Object Caption to Run";
            end
            else begin
                JobEarliestStartDateTime := 0DT;
                JobStatus := JobStatus::" ";
                JobObjectIDtoRun := 0;
                JobObjectCaptiontoRun := '';
            end;
        end
    end;



    var
        JobEarliestStartDateTime: DateTime;
        JobStatus: Option Ready,"In Process",Error,"On Hold",Finished,"On Hold with Inactivity Timeout",Waiting," ";
        JobObjectIDtoRun: Integer;
        JobObjectCaptiontoRun: Text[250];
}
