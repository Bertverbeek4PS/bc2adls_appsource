namespace bc2adls;

xmlport 11344437 "ADL BC2ADLS Export"
{
    Caption = 'ADL BC2ADLS Export';
    UseRequestPage = false;
    Direction = Export;
    Permissions = tabledata "ADL Field" = r,
                  tabledata "ADL Table" = r;

    schema
    {
        textelement(Root)
        {
            tableelement(ADLSETable; "ADL Table")
            {
                MaxOccurs = Unbounded;
                XmlName = 'ADLSETable';
                SourceTableView = where(Enabled = const(true));

                fieldattribute(TableId; ADLSETable."Table ID")
                {
                    Occurrence = Required;
                }

                tableelement(ADLSEField; "ADL Field")
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
