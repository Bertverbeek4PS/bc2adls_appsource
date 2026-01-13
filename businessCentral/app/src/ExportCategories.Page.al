namespace bc2adls;

page 11344442 "AZD Export Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Catgories';
    PageType = List;
    SourceTable = "AZD Export Category Table";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
        }
    }
}


