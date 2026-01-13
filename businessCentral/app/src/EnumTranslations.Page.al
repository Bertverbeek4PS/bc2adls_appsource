namespace bc2adls;

//A list page that is build on table Enum Translation
page 11344440 "AZD Enum Translations"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'ADL Enum Translations';
    UsageCategory = Lists;
    SourceTable = "AZD Enum Translation";


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(CompliantTableName; Rec."Compliant Table Name")
                {
                    Editable = false;
                }
                field(CompliantFieldName; Rec."Compliant Field Name")
                {
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshOptions)
            {
                ApplicationArea = All;
                Caption = 'Refresh Options';
                ToolTip = 'Refresh the options of the enum fields.';
                Image = Refresh;

                trigger OnAction()
                begin
                    Rec.RefreshOptions();
                end;
            }
        }
        area(Navigation)
        {
            action(Translations)
            {
                ApplicationArea = All;
                Caption = 'Translations';
                ToolTip = 'View the translations of the enum fields.';
                Image = Language;

                trigger OnAction()
                var
                    ADLSEEnumTranslationLang: Record "AZD Enum Translation Lang";
                    ADLSEEnumTranslationsLang: Page "AZD Enum Translations Lang";
                begin
                    ADLSEEnumTranslationLang.SetRange("Table Id", Rec."Table Id");
                    ADLSEEnumTranslationLang.SetRange("Field Id", Rec."Field Id");
                    ADLSEEnumTranslationsLang.SetSelectionFilter(ADLSEEnumTranslationLang);
                    ADLSEEnumTranslationsLang.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(RefreshOptions_Promoted; RefreshOptions) { }
            }
        }
    }
}

