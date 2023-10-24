page 50105 "eInvoice Input-BET"
{
    ApplicationArea = All;
    Caption = 'eInvoice Input-BET';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            field(DateFrom; DateFrom)
            {
                Caption = 'Date From';
                ApplicationArea = All;
            }
            field(DateTo; DateTo)
            {
                Caption = 'Date To';
                ApplicationArea = All;
            }
        }
    }
    var
        DateFrom: Date;
        DateTo: Date;

    trigger OnOpenPage()
    begin
        DateTo := Today;
        DateFrom := CalcDate('-1M', Today);
    end;

    procedure GetDates(var DateFromPrm: Date; var DateToPrm: Date)
    begin
        DateFromPrm := DateFrom;
        DateToPrm := DateTo;
    end;
}
