interface "IeInvoice-BET"
{
    procedure InitializeSetup(var eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure CheckEnable(var eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure GetSetupCaption(Token: Text) Caption: Text
    procedure SendUBLDocument(UBLXMLDocumentToSend: XmlDocument; var Usage: Enum "Electronic Document Format Usage"; RecordExportBuffer: Record "Record Export Buffer")
    procedure SendEcho(eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure GeteInvoiceStatus(RecordID: RecordId; eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure InitJsonSetup(var eInvoiceSetup: Record "eInvoice Setup-BET") DoModify: Boolean
    procedure GetIncomingInvoicesList(StatusCode: Text; FromDate: Date; ToDate: Date; eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure GetIncomingInvoice(InvoiceID: Integer; eInvoiceSetup: Record "eInvoice Setup-BET")
    procedure ProcesseInvoiceHeader(eInvoiceHeader: Record "eInvoice Header-BET")

}
