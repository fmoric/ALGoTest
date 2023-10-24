codeunit 50103 "Be-Terna UBL Delivery-BET"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        NoFileErr: Label 'There is no file generated.';
        NotValidXMLErr: Label 'Not a valid UBL xml.';
        WrongSetupErr: Label 'Setup is not valid.';
        UBLXMLDocumentToSend: XmlDocument;
        InStr: InStream;
        XMLText: Text;
        Usage: Enum "Electronic Document Format Usage";
        IeInvoice: Interface "IeInvoice-BET";
        DocumentSendingProfile: Record "Document Sending Profile";
        eInvoiceSetup: Record "eInvoice Setup-BET";
    begin

        TempBlob.CreateInStream(InStr);

        if not Rec.GetFileContent(TempBlob) then
            Error(NoFileErr);

        if not XmlDocument.ReadFrom(InStr, UBLXMLDocumentToSend) then
            Error(NotValidXMLErr);

        CheckUBLHeader(UBLXMLDocumentToSend, Usage);

        DocumentSendingProfile.Get(Rec."Document Sending Profile");
        DocumentSendingProfile.TestField("UBL Document Delivery-BET");
        if not eInvoiceSetup.Get(DocumentSendingProfile."UBL Document Delivery-BET") then
            Error(WrongSetupErr);

        IeInvoice := eInvoiceSetup.Implementator;
        if IeInvoice.InitJsonSetup(eInvoiceSetup) then
            eInvoiceSetup.Modify();
        IeInvoice.SendUBLDocument(UBLXMLDocumentToSend, Usage, Rec);
    end;


    local procedure CheckUBLHeader(UBLXMLDocumentToSend: XmlDocument; var Usage: Enum "Electronic Document Format Usage")
    var
        NotUBLErr: Label 'This is not UBL invoice document.';
        NoCustTagErr: Label '%1 tag is missing in UBL document.';

        eInvoiceMgt: Codeunit "eInvoice Setup Management-BET";
        XMLHeaderNode: XmlNode;
    begin
        case true of
            UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetInvoiceTag() + ''']', XMLHeaderNode):
                Usage := Usage::"Sales Invoice";
            UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetCreditNoteTag() + ''']', XMLHeaderNode):
                Usage := Usage::"Sales Credit Memo";
            else
                Error(NotUBLErr);
        end;
        if not UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetCustomizationIDTag() + ''']', XMLHeaderNode) then
            Error(NoCustTagErr, eInvoiceMgt.GetCustomizationIDTag());

        if not UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetIDTag() + ''']', XMLHeaderNode) then
            Error(NoCustTagErr, eInvoiceMgt.GetIDTag());
    end;




}
