pageextension 50101 "Posted Sales Invoices-BET" extends "Posted Sales Invoices"
{
    actions
    {
        addafter(SendCustom)
        {
            action(CheckCustom)
            {
                ApplicationArea = All;
                Caption = 'Check Document';
                Ellipsis = true;
                Image = SendToMultiple;

                trigger OnAction()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                    eInvoiceSetup: Record "eInvoice Setup-BET";
                    IEInv: Interface "IeInvoice-BET";
                    DocumentSendingProfile: Record "Document Sending Profile";
                    Cust: Record Customer;
                begin
                    Cust.Get(Rec."Bill-to Customer No.");
                    DocumentSendingProfile.Get(Cust."Document Sending Profile");
                    eInvoiceSetup.Get(DocumentSendingProfile."UBL Document Delivery-BET");
                    IEInv := eInvoiceSetup.Implementator;
                    IEInv.GeteInvoiceStatus(Rec.RecordId, eInvoiceSetup);
                end;
            }
        }
    }
}
