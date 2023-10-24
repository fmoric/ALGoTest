page 50104 "eInvoices-BET"
{
    ApplicationArea = All;
    Caption = 'eInvoices-BET';
    PageType = List;
    SourceTable = "eInvoice Header-BET";
    UsageCategory = Documents;
    Editable = false;
    CardPageId = "eInvoice-BET";
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field("Supplier Invoice ID"; Rec."Supplier Invoice ID")
                {
                    ToolTip = 'Specifies the value of the Supplier Invoice ID field.';
                }
                field("Invoice Status"; Rec."Invoice Status")
                {
                    ToolTip = 'Specifies the value of the Invoice Status field.';
                }
                field("Invoice Issue Date"; Rec."Invoice Issue Date")
                {
                    ToolTip = 'Specifies the value of the Invoice Issue Date field.';
                }
                field("Supplier Name"; Rec."Supplier Name")
                {
                    ToolTip = 'Specifies the value of the Supplier Name field.';
                }
                field("eInvoice Type"; Rec."eInvoice Type")
                {
                    ToolTip = 'Specifies the value of the eInvoice Type field.';
                }
                field("Invoice ID"; Rec."Invoice ID")
                {
                    ToolTip = 'Specifies the value of the Invoice ID field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(GetList)
            {
                Image = List;
                // Visible = CertificateVisible;
                ApplicationArea = All;
                Caption = 'Get List';
                ToolTip = 'Executes the Get List action';
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
                    eInvoiceInput.LookupMode(true);
                    if not (eInvoiceInput.RunModal() = Action::LookupOK) then
                        exit;
                    eInvoiceInput.GetDates(DateFrom, DateTo);
                    eInvInterf := eInvoiceSetup.Implementator;
                    eInvInterf.GetIncomingInvoicesList('', DateFrom, DateTo, eInvoiceSetup);
                end;
            }
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
}
