table 50101 "eInvoice Header-BET"
{
    Caption = 'eInvoice Header-BET';
    DataClassification = CustomerContent;
    LookupPageId = "eInvoices-BET";
    DrillDownPageId = "eInvoices-BET";
    DataCaptionFields = "Document Type", "Supplier Invoice ID";

    fields
    {
        field(1; "eInvoice Type"; Enum "eInvoice Type-BET")
        {
            Caption = 'eInvoice Type';
        }
        field(2; "Invoice ID"; Integer)
        {
            Caption = 'Invoice ID';
        }
        field(3; "Document Type"; Text[50])
        {
            Caption = 'Document Type';
        }
        field(4; "Invoice Status"; Text[20])
        {
            Caption = 'Invoice Status';
        }
        field(5; "Supplier Invoice ID"; Text[20])
        {
            Caption = 'Supplier Invoice ID';
        }
        field(6; "Supplier ID"; Text[50])
        {
            Caption = 'Supplier ID';
        }
        field(7; "Supplier Name"; Text[50])
        {
            Caption = 'Supplier Name';
        }
        field(8; "Supplier Company ID"; Text[20])
        {
            Caption = 'Supplier Company ID';
        }
        field(9; "Invoice Issue Date"; Date)
        {
            Caption = 'Invoice Issue Date';
        }
        field(10; Status; Enum "eInvoice Status-BET")
        {
            Caption = 'Status';
        }
        field(20; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(21; "Profile ID"; Text[20])
        {
            Caption = 'Profile ID';
        }
        field(22; "Invoice Type Code"; Text[10])
        {
            Caption = 'Invoice Type Code';
        }
        field(23; "Document Currency Code"; Text[10])
        {
            Caption = 'Document Currency Code';
        }
        field(24; "Tax Currency Code"; Text[10])
        {
            Caption = 'Tax Currency Code';
        }
        field(25; "Note"; Blob)
        {
            Caption = 'Note';
        }
        field(30; "Supp. Endpoint ID"; Text[50])
        {
            Caption = 'Supplier Endpoint ID';
        }
        field(31; "Supp. Scheme ID"; Text[10])
        {
            Caption = 'Supplier Scheme ID';
        }
        field(32; "Supp. Street Name"; Text[100])
        {
            Caption = 'Supplier Street Name';
        }
        field(33; "Supp. City Name"; Text[30])
        {
            Caption = 'Supplier City Name';
        }
        field(34; "Supp. Postal Zone"; Text[20])
        {
            Caption = 'Supplier Postal Zone';
        }
        field(35; "Supp. Country Code"; Text[10])
        {
            Caption = 'Supplier Country Code';
        }
        field(36; "Supp. Country Name"; Text[50])
        {
            Caption = 'Supplier Country Name';
        }
        field(37; "Supp. Company ID"; Text[20])
        {
            Caption = 'Supplier Company ID';
        }
        field(38; "Supp. Registration Name"; Text[50])
        {
            Caption = 'Supplier Registration Name';
        }
        field(100; "eInvoice UBL"; Blob)
        {
            Caption = 'eInvoice UBL';
        }
    }
    keys
    {
        key(PK; "eInvoice Type", "Invoice ID")
        {
            Clustered = true;
        }
    }
    procedure SetUBL(XMLUBL: Text)
    var
        OutStr: OutStream;
    begin
        Clear("eInvoice UBL");
        "eInvoice UBL".CreateOutStream(OutStr);
        if XMLUBL <> '' then begin
            OutStr.Write(XMLUBL);
        end;
    end;

    procedure GetUBL() XMLUBL: Text
    var
        InStr: InStream;
    begin
        CalcFields("eInvoice UBL");
        "eInvoice UBL".CreateInStream(InStr);
        InStr.Read(XMLUBL);
    end;

    procedure SetNote(XMLNote: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Note");
        "Note".CreateOutStream(OutStr);
        if XMLNote <> '' then begin
            OutStr.Write(XMLNote);
        end;
    end;

    procedure GetNote() XMLNote: Text
    var
        InStr: InStream;
    begin
        CalcFields("Note");
        "Note".CreateInStream(InStr);
        InStr.Read(XMLNote);
    end;
}
