codeunit 50101 "UnknownImplementator-BET" implements "IeInvoice-BET"
{
    var
        WrongSetupErr: Label 'Wrong eInvoice setup.';

    procedure InitializeSetup(var eInvoiceSetup: Record "eInvoice Setup-BET")
    begin
    end;

    procedure GetSetupCaption(Token: Text) Caption: Text;
    begin
    end;

    procedure CheckEnable(var eInvoiceSetup: Record "eInvoice Setup-BET");
    begin
        eInvoiceSetup.TestField(Implementator);
    end;

    procedure SendUBLDocument(UBLXMLDocumentToSend: XmlDocument; var Usage: Enum "Electronic Document Format Usage"; RecordExportBuffer: Record "Record Export Buffer")
    begin
        Error(WrongSetupErr);
    end;

    procedure SendEcho(eInvoiceSetup: Record "eInvoice Setup-BET");
    begin
        Error(WrongSetupErr);
    end;

    procedure GeteInvoiceStatus(RecordID: RecordId; eInvoiceSetup: Record "eInvoice Setup-BET");
    begin
        Error(WrongSetupErr);
    end;

    procedure InitJsonSetup(var eInvoiceSetup: Record "eInvoice Setup-BET") DoModify: Boolean
    begin

    end;

    procedure GetIncomingInvoicesList(StatusCode: Text; FromDate: Date; ToDate: Date; eInvoiceSetup: Record "eInvoice Setup-BET");
    begin

    end;

    procedure GetIncomingInvoice(InvoiceID: Integer; eInvoiceSetup: Record "eInvoice Setup-BET");
    begin

    end;

    procedure ProcesseInvoiceHeader(eInvoiceHeader: Record "eInvoice Header-BET");
    begin

    end;
}
