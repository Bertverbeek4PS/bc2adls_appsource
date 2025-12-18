namespace bc2adls;

codeunit 11344455 "ADL Wrapper Execute"
{
    Access = Internal;
    TableNo = "ADL Table";

    trigger OnRun()
    var
        ADLSEExecute: Codeunit "ADL Execute";
        ADLSEExecution: Codeunit "ADL Execution";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not ADLSEExecute.Run(Rec) then begin
            CustomDimensions.Add('Entity', Format(Rec."Table ID"));
            CustomDimensions.Add('SessionId', Format(SessionId()));
            CustomDimensions.Add('AL Call Stack', GetLastErrorCallStack());
            CustomDimensions.Add('Last Error Code', GetLastErrorCode());
            CustomDimensions.Add('Last Error Text', GetLastErrorText());
            ADLSEExecution.Log('ADLSE-050', 'Session is failes to start', Verbosity::Normal, CustomDimensions);
        end;
    end;
}
