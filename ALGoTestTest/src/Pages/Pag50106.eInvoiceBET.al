page 50106 "eInvoice-BET"
{
    ApplicationArea = All;
    Caption = 'eInvoice-BET';
    PageType = Document;
    SourceTable = "eInvoice Header-BET";
    Editable = false;
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Invoice Status"; Rec."Invoice Status")
                {
                    ToolTip = 'Specifies the value of the Invoice Status field.';
                }
                field("Supplier Name"; Rec."Supplier Name")
                {
                    ToolTip = 'Specifies the value of the Supplier Name field.';
                }
                field("Invoice Issue Date"; Rec."Invoice Issue Date")
                {
                    ToolTip = 'Specifies the value of the Invoice Issue Date field.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the value of the Due Date field.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Document Currency Code"; Rec."Document Currency Code")
                {
                    ToolTip = 'Specifies the value of the Document Currency Code field.';
                }
                field("Tax Currency Code"; Rec."Tax Currency Code")
                {
                    ToolTip = 'Specifies the value of the Tax Currency Code field.';
                }

            }
            group(SupplierGr)
            {
                Caption = 'Supplier';
                field("Supp. Registration Name"; Rec."Supp. Registration Name")
                {
                    ToolTip = 'Specifies the value of the Supplier Registration Name field.';
                }
                field("Supp. Street Name"; Rec."Supp. Street Name")
                {
                    ToolTip = 'Specifies the value of the Supplier Street Name field.';
                }
                field("Supp. City Name"; Rec."Supp. City Name")
                {
                    ToolTip = 'Specifies the value of the Supplier City Name field.';
                }
                field("Supp. Postal Zone"; Rec."Supp. Postal Zone")
                {
                    ToolTip = 'Specifies the value of the Supplier Postal Zone field.';
                }
                field("Supp. Country Name"; Rec."Supp. Country Name")
                {
                    ToolTip = 'Specifies the value of the Supplier Country Name field.';
                }
                field("Supp. Company ID"; Rec."Supp. Company ID")
                {
                    ToolTip = 'Specifies the value of the Supplier Company ID field.';
                }
            }
            group(NoteGr)
            {
                Caption = 'Notes';
                field(NoteText; NoteText)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the value of the Notes field.';
                    MultiLine = true;
                }
            }
            group(UBLGr)
            {
                Caption = 'UBL';
                field(UBLText; UBLText)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the value of the Notes field.';
                    MultiLine = true;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(GetDocument)
            {
                Image = Document;
                // Visible = CertificateVisible;
                ApplicationArea = All;
                Caption = 'Get Document';
                ToolTip = 'Executes the Get Document action';
                // Enabled = EnableActions and not IsEnabled;

                trigger OnAction()
                var
                    eInvoiceSetup: Record "eInvoice Setup-BET";
                    eInvInterf: Interface "IeInvoice-BET";
                    eInvoiceInput: Page "eInvoice Input-BET";
                    DateFrom: Date;
                    DateTo: Date;
                begin
                    eInvoiceSetup.SetRange(Default, true);
                    eInvoiceSetup.FindFirst();
                    eInvInterf := eInvoiceSetup.Implementator;
                    eInvInterf.GetIncomingInvoice(Rec."Invoice ID", eInvoiceSetup);
                end;
            }
            action(ProcessDocument)
            {
                Image = Document;
                // Visible = CertificateVisible;
                ApplicationArea = All;
                Caption = 'Process Document';
                ToolTip = 'Executes the Process Document action';
                // Enabled = EnableActions and not IsEnabled;

                trigger OnAction()
                var
                    eInvoiceSetup: Record "eInvoice Setup-BET";
                    eInvInterf: Interface "IeInvoice-BET";
                    eInvoiceInput: Page "eInvoice Input-BET";
                    DateFrom: Date;
                    DateTo: Date;
                begin
                    eInvoiceSetup.SetRange(Default, true);
                    eInvoiceSetup.FindFirst();
                    eInvInterf := eInvoiceSetup.Implementator;
                    eInvInterf.ProcesseInvoiceHeader(Rec);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        NoteText := Rec.GetNote();
        UBLText := Rec.GetUBL();
    end;

    var
        NoteText: Text;
        UBLText: Text;
}
