namespace bc2adls;

xmlport 11344437 "AZD BC2ADLS Export"
{
    Caption = 'ADL BC2ADLS Export';
    UseRequestPage = false;
    Direction = Export;
    Permissions = tabledata "AZD Field" = r,
                  tabledata "AZD Table" = r;

    schema
    {
        textelement(Root)
        {
            tableelement(ADLSETable; "AZD Table")
            {
                MaxOccurs = Unbounded;
                XmlName = 'ADLSETable';
                SourceTableView = where(Enabled = const(true));

                fieldattribute(TableId; ADLSETable."Table ID")
                {
                    Occurrence = Required;
                }
                fieldattribute(ExportCategory; ADLSETable.ExportCategory)
                {
                    Occurrence = Required;
                }

                tableelement(ADLSEField; "AZD Field")
                {
                    MinOccurs = Zero;
                    SourceTableView = where(Enabled = const(true));
                    XmlName = 'ADLSEField';

                    fieldattribute(TableID;
                    ADLSEField."Table ID")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(FieldID; ADLSEField."Field ID")
                    {
                        Occurrence = Required;
                    }

                    trigger OnPreXmlItem()
                    begin
                        ADLSEField.SetRange("Table ID", ADLSETable."Table ID");
                    end;


                }
            }
        }
    }
}
