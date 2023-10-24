codeunit 50102 "Fina Implementator-BET" implements "IeInvoice-BET"
{

    procedure InitializeSetup(var eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        JsonObj: JsonObject;
        OutStr: OutStream;
        JsonText: Text;
    begin
        if eInvoiceSetup.Implementator <> eInvoiceSetup.Implementator::FINA then
            exit;
        if eInvoiceSetup.GetBaseURL() = '' then
            eInvoiceSetup.SetBaseURL(URLPrezTokenValue);

        InitJsonSetup(eInvoiceSetup);
    end;

    procedure InitJsonSetup(var eInvoiceSetup: Record "eInvoice Setup-BET") DoModify: Boolean
    var
        Res: JsonToken;
        JsonObj: JsonObject;
        OutStr: OutStream;
        InStr: InStream;
        JsonText: Text;
        TextKey: Text;
        OldKeys: List of [Text];
        IsModified: Boolean;
    begin
        eInvoiceSetup.CalcFields(Data);
        eInvoiceSetup.Data.CreateInStream(InStr);
        if JsonObj.ReadFrom(InStr) then
            OldKeys := JsonObj.Keys;

        UpdateJson(SendB2BOutgoingInvoicePKIWebServiceToken, SendB2BOutgoingInvoicePKIWebServiceToken + '/' + ServicesToken + '/' + SendB2BOutgoingInvoicePKIWebServiceToken, JsonObj, OldKeys);

        UpdateJson(SendB2BOutgoingInvoicePKIWebServiceTokenEchoAction, SendB2BOutgoingInvoicePKIWebServiceTokenActionEchoValue, JsonObj, OldKeys);

        UpdateJson(SendB2BOutgoingInvoicePKIWebServiceTokenStatusAction, SendB2BOutgoingInvoicePKIWebServiceTokenStatusActionValue, JsonObj, OldKeys);

        UpdateJson(SendB2BOutgoingInvoicePKIWebServiceTokenSendAction, SendB2BOutgoingInvoicePKIWebServiceTokenSendActionValue, JsonObj, OldKeys);

        UpdateJson(B2BFinaInvoiceWebServiceToken, B2BFinaInvoiceWebServiceToken + '/' + ServicesToken + '/' + B2BFinaInvoiceWebServiceToken, JsonObj, OldKeys);

        UpdateJson(B2BFinaInvoiceWebServiceTokenEchoAction, B2BFinaInvoiceWebServiceTokenEchoActionValue, JsonObj, OldKeys);

        UpdateJson(B2BFinaInvoiceWebServiceTokenIncomingListAction, B2BFinaInvoiceWebServiceTokenIncomingListActionValue, JsonObj, OldKeys);

        UpdateJson(B2BFinaInvoiceWebServiceTokenIncomingInvoiceAction, B2BFinaInvoiceWebServiceTokenIncomingInvoiceActionValue, JsonObj, OldKeys);

        foreach TextKey in OldKeys do
            if JsonObj.Contains(TextKey) then
                JsonObj.Remove(TextKey);

        DoModify := JsonObj.Keys.Count <> OldKeys.Count;

        eInvoiceSetup.Data.CreateOutStream(OutStr);
        JsonObj.WriteTo(JsonText);
        OutStr.Write(JsonText);
    end;

    procedure CheckEnable(var eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        BaseURL: Text;
    begin
        if not eInvoiceSetup.Enable then
            exit;

        CollectEnableErrors(eInvoiceSetup);
    end;
    #region Setup Translations
    procedure GetSetupCaption(Token: Text) Caption: Text
    begin
        case Token of
            SendB2BOutgoingInvoicePKIWebServiceToken:
                exit(SendB2BOutgoingInvoicePKIWebServiceTokenLabel);
            SendB2BOutgoingInvoicePKIWebServiceTokenEchoAction:
                exit(SendB2BOutgoingInvoicePKIWebServiceTokenEchoLabel);
            SendB2BOutgoingInvoicePKIWebServiceTokenStatusAction:
                exit(SendB2BOutgoingInvoicePKIWebServiceTokenStatusLabel);
            SendB2BOutgoingInvoicePKIWebServiceTokenSendAction:
                exit(SendB2BOutgoingInvoicePKIWebServiceTokenSendLabel);
            B2BFinaInvoiceWebServiceToken:
                exit(B2BFinaInvoiceWebServiceLabel);
            B2BFinaInvoiceWebServiceTokenEchoAction:
                exit(B2BFinaInvoiceWebServiceTokenEchoActionLabel);
            B2BFinaInvoiceWebServiceTokenIncomingListAction:
                exit(B2BFinaInvoiceWebServiceTokenIncomingListActionLabel);
            B2BFinaInvoiceWebServiceTokenIncomingInvoiceAction:
                exit(B2BFinaInvoiceWebServiceTokenIncomingInvoiceActionLabel);
            else
                exit(Token);
        end;
    end;
    #endregion
    procedure SendUBLDocument(UBLXMLDocumentToSend: XmlDocument; var Usage: Enum "Electronic Document Format Usage"; RecordExportBuffer: Record "Record Export Buffer")
    var
        ServiceEndpointURL: Text;
        EnvelopedXMLDocument: XmlDocument;
    begin
        EnvelopedXMLDocument := PrepareUBLDocument(UBLXMLDocumentToSend, Usage, RecordExportBuffer);
        ServiceEndpointURL := CreateEndpoint(SendB2BOutgoingInvoicePKIWebServiceToken, RecordExportBuffer."Document Sending Profile");
        SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(SendB2BOutgoingInvoicePKIWebServiceTokenSendAction, RecordExportBuffer."Document Sending Profile"), RecordExportBuffer."Document Sending Profile", true, true);
    end;

    procedure SendEcho(eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        ServiceEndpointURL: Text;
        EnvelopedXMLDocument: XmlDocument;
    begin
        ServiceEndpointURL := CreateEndpoint(SendB2BOutgoingInvoicePKIWebServiceToken, eInvoiceSetup);
        EnvelopedXMLDocument := PrepareEchoDocument(eInvoiceSetup);
        SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(SendB2BOutgoingInvoicePKIWebServiceTokenEchoAction, eInvoiceSetup), eInvoiceSetup, false, false);

        ServiceEndpointURL := CreateEndpoint(B2BFinaInvoiceWebServiceToken, eInvoiceSetup);
        EnvelopedXMLDocument := PrepareEchoBuyerMsg(eInvoiceSetup);
        SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(B2BFinaInvoiceWebServiceTokenEchoAction, eInvoiceSetup), eInvoiceSetup, true, false);

    end;

    procedure GeteInvoiceStatus(RecordID: RecordId; eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        ServiceEndpointURL: Text;
        EnvelopedXMLDocument: XmlDocument;
    begin
        ServiceEndpointURL := CreateEndpoint(SendB2BOutgoingInvoicePKIWebServiceToken, eInvoiceSetup);
        EnvelopedXMLDocument := PrepareB2BOutgoingInvoiceStatus(RecordID, eInvoiceSetup);
        SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(SendB2BOutgoingInvoicePKIWebServiceTokenStatusAction, eInvoiceSetup), eInvoiceSetup, true, true);
    end;

    procedure GetIncomingInvoicesList(StatusCode: Text; FromDate: Date; ToDate: Date; eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        ServiceEndpointURL: Text;
        EnvelopedXMLDocument: XmlDocument;
    begin
        ServiceEndpointURL := CreateEndpoint(B2BFinaInvoiceWebServiceToken, eInvoiceSetup);
        EnvelopedXMLDocument := PrepareB2BOutgoingInvoiceGetDocumentList(StatusCode, FromDate, ToDate, eInvoiceSetup);
        ProcessInvoiceListXML(SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(B2BFinaInvoiceWebServiceTokenIncomingListAction, eInvoiceSetup), eInvoiceSetup, true, true));
    end;

    procedure GetIncomingInvoice(InvoiceID: Integer; eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        ServiceEndpointURL: Text;
        EnvelopedXMLDocument: XmlDocument;
        XmlUBLInvoice: XmlDocument;
        eInvoiceHeader: Record "eInvoice Header-BET";
        OutStr: OutStream;
        ShowXMLDocument: Boolean;
        InStr: InStream;
        UBLDocumentText: Text;
    begin
        ShowXMLDocument := true;
        if eInvoiceHeader.Get(Enum::"eInvoice Type-BET"::Incoming, InvoiceID) then begin
            if eInvoiceHeader.Status.AsInteger() >= Enum::"eInvoice Status-BET"::"Document Downloaded".AsInteger() then begin
                if ShowXMLDocument then begin
                    eInvoiceHeader."eInvoice UBL".CreateInStream(InStr);
                    InStr.Read(UBLDocumentText);
                    Message(UBLDocumentText);
                end;
                exit;
            end;
        end;

        ServiceEndpointURL := CreateEndpoint(B2BFinaInvoiceWebServiceToken, eInvoiceSetup);
        EnvelopedXMLDocument := PrepareB2BGetIncomingInvoiceMsg(InvoiceID, eInvoiceSetup);
        XmlUBLInvoice := ProcessInvoiceDocumentResponseXML(SendRequestToWebService(ServiceEndpointURL, EnvelopedXMLDocument, eInvoiceSetupManagement.GetSetupFromToken(B2BFinaInvoiceWebServiceTokenIncomingInvoiceAction, eInvoiceSetup), eInvoiceSetup, true, false));

        if eInvoiceHeader."Invoice ID" > 0 then begin
            eInvoiceHeader."eInvoice UBL".CreateOutStream(OutStr);
            eInvoiceHeader.Status := Enum::"eInvoice Status-BET"::"Document Downloaded";
            XmlUBLInvoice.WriteTo(OutStr);
            if ShowXMLDocument then begin
                XmlUBLInvoice.WriteTo(UBLDocumentText);
                Message(UBLDocumentText);
            end;
            eInvoiceHeader.Modify();
        end;

    end;

    procedure ProcesseInvoiceHeader(eInvoiceHeader: Record "eInvoice Header-BET")
    var
        XmlDocumentToProcess: XmlDocument;
        InStr: InStream;
        XmlNods: XmlNodeList;
        XMLNod: XmlNode;
        Base64Convert: Codeunit "Base64 Convert";
        TypeHelper: Codeunit "Type Helper";
        TempVar: Variant;
        TexBuild: TextBuilder;
    begin
        eInvoiceHeader.CalcFields("eInvoice UBL");
        if not eInvoiceHeader."eInvoice UBL".HasValue then
            exit;
        eInvoiceHeader."eInvoice UBL".CreateInStream(InStr);
        XmlDocument.ReadFrom(InStr, XmlDocumentToProcess);
        // XmlDocumentToProcess.SelectNodes('//*[local-name()=''' + AttachmentTag + ''']', XmlNods); //TODO Attachment PDF to attached documents TryFunction
        // Base64Convert.FromBase64();

        XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + DueDateTag + ''']', XMLNod);
        TempVar := eInvoiceHeader."Due Date";
        TypeHelper.Evaluate(TempVar, XMLNod.AsXmlElement().InnerText, '', '');
        eInvoiceHeader."Due Date" := TempVar;

        if XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + ProfileIDTag + ''']', XMLNod) then
            eInvoiceHeader."Profile ID" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Profile ID"));

        if XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + InvoiceTypeCodeTag + ''']', XMLNod) then
            eInvoiceHeader."Invoice Type Code" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Invoice Type Code"));

        if XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + DocumentCurrencyCodeTag + ''']', XMLNod) then
            eInvoiceHeader."Document Currency Code" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Document Currency Code"));

        if XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + TaxCurrencyCodeTag + ''']', XMLNod) then
            eInvoiceHeader."Tax Currency Code" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Tax Currency Code"));


        if XmlDocumentToProcess.SelectNodes('//*[local-name()=''' + NoteTag + ''']', XmlNods) then begin
            foreach XmlNod in XmlNods do
                TexBuild.AppendLine(XMLNod.AsXmlElement().InnerText);
            eInvoiceHeader.SetNote(TexBuild.ToText());
        end;
        XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + AccountingSupplierPartyTag + ''']', XMLNod);
        ProcessAccountingSupplierPartyTag(eInvoiceHeader, XMLNod);

        eInvoiceHeader.Modify();
    end;

    local procedure ProcessAccountingSupplierPartyTag(var eInvoiceHeader: Record "eInvoice Header-BET"; XMLNod: XmlNode)
    var
        XMLDocToProcess: XmlDocument;
        XMLDocToProcessPart: XmlDocument;

        XMLDocText: Text;
        AttrCollection: XmlAttributeCollection;
        XMLAttr: XmlAttribute;

    begin
        XMLNod.WriteTo(XMLDocText);
        XmlDocument.ReadFrom(XMLDocText, XMLDocToProcess);
        if XMLDocToProcess.SelectSingleNode('//*[local-name()=''' + EndpointIDTag + ''']', XMLNod) then begin
            eInvoiceHeader."Supp. Endpoint ID" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Endpoint ID"));
            AttrCollection := XMLNod.AsXmlElement().Attributes();
            foreach XmlAttr in AttrCollection do
                if XMLAttr.Name = schemeIDTag then
                    eInvoiceHeader."Supp. Scheme ID" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Scheme ID"));
        end;
        if XMLDocToProcess.SelectSingleNode('//*[local-name()=''' + PostalAddressTag + ''']', XMLNod) then begin
            XMLNod.WriteTo(XMLDocText);
            XmlDocument.ReadFrom(XMLDocText, XMLDocToProcessPart);
            if XMLDocToProcessPart.SelectSingleNode('//*[local-name()=''' + StreetNameTag + ''']', XMLNod) then
                eInvoiceHeader."Supp. Street Name" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Street Name"));
            if XMLDocToProcessPart.SelectSingleNode('//*[local-name()=''' + CityNameTag + ''']', XMLNod) then
                eInvoiceHeader."Supp. City Name" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. City Name"));
            if XMLDocToProcessPart.SelectSingleNode('//*[local-name()=''' + PostalZoneTag + ''']', XMLNod) then
                eInvoiceHeader."Supp. Postal Zone" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Postal Zone"));
            if XMLDocToProcessPart.SelectSingleNode('//*[local-name()=''' + IdentificationCodeTag + ''']', XMLNod) then
                eInvoiceHeader."Supp. Country Code" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Country Code"));
            if XMLDocToProcessPart.SelectSingleNode('//*[local-name()=''' + NameTag + ''']', XMLNod) then
                eInvoiceHeader."Supp. Country Name" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Country Name"));
        end;
        if XMLDocToProcess.SelectSingleNode('//*[local-name()=''' + CompanyIDTag + ''']', XMLNod) then
            eInvoiceHeader."Supp. Company ID" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Company ID"));
        if XMLDocToProcess.SelectSingleNode('//*[local-name()=''' + RegistrationNameTag + ''']', XMLNod) then
            eInvoiceHeader."Supp. Registration Name" := CopyStr(XMLNod.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supp. Registration Name"));
    end;



    local procedure ProcessInvoiceDocumentResponseXML(XmlDocumentToProcess: XmlDocument) XmlUBLInvoice: XmlDocument
    var
        XmlNod: XmlNode;

        Base64Convert: Codeunit "Base64 Convert";
    begin
        case true of
            XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + InvoiceEnvelopeTag + ''']', XmlNod):
                ;
            XmlDocumentToProcess.SelectSingleNode('//*[local-name()=''' + CreditNoteEnvelopeTag + ''']', XmlNod):
                ;
            else
                Error(WrongUsageErr);
        end;

        XmlDocument.ReadFrom(Base64Convert.FromBase64(XmlNod.AsXmlElement().InnerText), XmlUBLInvoice);
    end;

    procedure ProcessInvoiceListXML(XmlDocumentToProcess: XmlDocument)
    var
        NodeList: XmlNodeList;
        XMLNod: XmlNode;
        xText: Text;
    begin
        XmlDocumentToProcess.SelectNodes('//*[local-name()=''' + B2BIncomingInvoiceTag + ''']', NodeList);
        foreach XMLNod in NodeList do
            ProcessIncomingInvoiceListNode(XMLNod);
    end;

    local procedure ProcessIncomingInvoiceListNode(InvoiceNode: XmlNode)
    var
        XMLInvoiceDoc: XmlDocument;
        XMLDocumentText: Text;
        eInvoiceHeader: Record "eInvoice Header-BET";
        ValueNode: XmlNode;
        IntValue: Integer;
        TypeHelper: Codeunit "Type Helper";
        VarVariant: Variant;
    begin
        InvoiceNode.AsXmlElement().WriteTo(XMLDocumentText);
        XmlDocument.ReadFrom(XMLDocumentText, XMLInvoiceDoc);

        eInvoiceHeader.Init();
        eInvoiceHeader."eInvoice Type" := Enum::"eInvoice Type-BET"::Incoming;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + InvoiceIDTag + ''']', ValueNode);
        Evaluate(eInvoiceHeader."Invoice ID", ValueNode.AsXmlElement().InnerText);
        if not eInvoiceHeader.Insert() then
            exit;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + DocumentTypeTextTag + ''']', ValueNode);

        eInvoiceHeader."Document Type" := CopyStr(ValueNode.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Document Type"));

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + InvoiceIssueDateTag + ''']', ValueNode);

        VarVariant := eInvoiceHeader."Invoice Issue Date";
        TypeHelper.Evaluate(VarVariant, ValueNode.AsXmlElement().InnerText, '', '');

        eInvoiceHeader."Invoice Issue Date" := VarVariant;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + StatusCodeTag + ''']', ValueNode);
        eInvoiceHeader."Invoice Status" := ValueNode.AsXmlElement().InnerText;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + SupplierCompanyIDTag + ''']', ValueNode);
        eInvoiceHeader."Supplier Company ID" := ValueNode.AsXmlElement().InnerText;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + SupplierIDTag + ''']', ValueNode);
        eInvoiceHeader."Supplier ID" := ValueNode.AsXmlElement().InnerText;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + SupplierInvoiceIDTag + ''']', ValueNode);
        eInvoiceHeader."Supplier Invoice ID" := ValueNode.AsXmlElement().InnerText;

        XMLInvoiceDoc.SelectSingleNode('//*[local-name()=''' + SupplierRegistrationNameTag + ''']', ValueNode);
        eInvoiceHeader."Supplier Name" := CopyStr(ValueNode.AsXmlElement().InnerText, 1, MaxStrLen(eInvoiceHeader."Supplier Name"));

        eInvoiceHeader.Modify();

    end;
    //[NonDebuggable]  TODO
    procedure SendRequestToWebService(ServiceUrl: Text; XMLToSend: XmlDocument; SoapAction: Text; DocumentSendingProfileCode: Code[20]; ShowMessage: Boolean; ShowXMLResponse: Boolean) ResponseContentXmlDocument: XmlDocument;
    begin
        eInvoiceSetupGlobal := eInvoiceSetupManagement.GeteInvoiceSetupGlobalFromDocSend(DocumentSendingProfileCode);
        ResponseContentXmlDocument := SendRequestToWebService(ServiceUrl, XMLToSend, SoapAction, eInvoiceSetupGlobal, ShowMessage, ShowXMLResponse);
    end;

    procedure SendRequestToWebService(ServiceUrl: Text; XMLToSend: XmlDocument; SoapAction: Text; eInvoiceSetup: Record "eInvoice Setup-BET"; ShowMessage: Boolean; ShowXMLResponse: Boolean) ResponseContentXmlDocument: XmlDocument;
    var
        RequestHttpRequestMessage: HttpRequestMessage;
        RequestHttpHeaders: HttpHeaders;
        RequestHttpContent: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        RequestInStream: InStream;
        RequestOutStream: OutStream;
        RequestContentHttpHeaders: HttpHeaders;
        ContentTypeTok: Label 'text/xml; charset=utf-8', Locked = true;
        WSHttpClient: HttpClient;
        CertValue: Text;
        Password: Text;
        ResponseHttpResponseMessage: HttpResponseMessage;
        XMLResponseText: Text;
        ContentTypeTag: Label 'Content-Type', Locked = true;
        POSTTag: Label 'POST', Locked = true;
        SOAPActionTag: Label 'SOAPAction', Locked = true;
        AckStatusCodeTag: Label 'AckStatusCode', Locked = true;
        OKCode: Label '10', Locked = true;
        AckStatusCodeNode: XmlNode;
        NotValidErr: Label 'Not a valid response!';
        AckStatusTextTag: Label 'AckStatusText', Locked = true;
        StatusTextTag: Label 'StatusText', Locked = true;
        XMLResponseToShow: Text;
    begin
        RequestHttpRequestMessage.Method := POSTTag;
        RequestHttpRequestMessage.SetRequestUri := ServiceUrl;
        RequestHttpRequestMessage.GetHeaders(RequestHttpHeaders);
        if SoapAction <> '' then
            RequestHttpHeaders.Add(SOAPActionTag, SoapAction);

        TempBlob.CreateInStream(RequestInStream, TextEncoding::MSDos);
        TempBlob.CreateOutStream(RequestOutStream, TextEncoding::MSDos);

        XMLToSend.WriteTo(RequestOutStream);

        RequestHttpContent.WriteFrom(RequestInStream);
        RequestHttpContent.GetHeaders(RequestContentHttpHeaders);
        RequestContentHttpHeaders.Remove(ContentTypeTag);

        RequestContentHttpHeaders.Add(ContentTypeTag, ContentTypeTok);
        RequestHttpRequestMessage.Content := RequestHttpContent;
        WSHttpClient.Timeout := 60000;//TODO To setup


        CertValue := eInvoiceSetupManagement.GetCert(eInvoiceSetup);
        Password := eInvoiceSetupManagement.GetPassword(eInvoiceSetup);

        WSHttpClient.AddCertificate(CertValue, Password);
        WSHttpClient.Send(RequestHttpRequestMessage, ResponseHttpResponseMessage);

        ResponseContentXmlDocument := ExtractContentFromResponse(ResponseHttpResponseMessage);
        if ShowXMLResponse then begin
            ResponseContentXmlDocument.WriteTo(XMLResponseText);
            Message(XMLResponseText);
        end;

        if not ResponseContentXmlDocument.SelectSingleNode('//*[local-name()=''' + AckStatusCodeTag + ''']', AckStatusCodeNode) then
            Error(NotValidErr);

        if AckStatusCodeNode.AsXmlElement().InnerText <> OKCode then begin
            ResponseContentXmlDocument.SelectSingleNode('//*[local-name()=''' + AckStatusTextTag + ''']', AckStatusCodeNode);
            Error(AckStatusCodeNode.AsXmlElement().InnerText);
        end;

        if ShowMessage then begin
            case true of
                ResponseContentXmlDocument.SelectSingleNode('//*[local-name()=''' + StatusTextTag + ''']', AckStatusCodeNode):
                    ;
                ResponseContentXmlDocument.SelectSingleNode('//*[local-name()=''' + AckStatusTextTag + ''']', AckStatusCodeNode):
                    ;

            end;
            Message(AckStatusCodeNode.AsXmlElement().InnerText);
        end;
    end;

    local procedure ExtractContentFromResponse(ResponseHttpResponseMessage: HttpResponseMessage): XmlDocument
    var
        BodyXmlNode: XmlNode;
        ContentXmlDocument: XmlDocument;
        NamespaceManager: XmlNamespaceManager;
        ResponseContentText: Text;
        SoapXmlDocument: XmlDocument;
    begin
        ResponseHttpResponseMessage.Content().ReadAs(ResponseContentText);
        XmlDocument.ReadFrom(ResponseContentText, SoapXmlDocument);
        NamespaceManager.NameTable(SoapXmlDocument.NameTable());
        NamespaceManager.AddNamespace(soapPrefix, envelopeNamespace);
        SoapXmlDocument.SelectSingleNode(BodyPathTxt, NamespaceManager, BodyXmlNode);
        XmlDocument.ReadFrom(BodyXmlNode.AsXmlElement().InnerXml(), ContentXmlDocument);
        exit(ContentXmlDocument);
    end;

    local procedure PrepareB2BGetIncomingInvoiceMsg(InvoiceID: Integer; eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopedXMLDocument: XmlDocument;
    var
        B2BGetIncomingInvoiceMsgEnvelope: XmlElement;
        EnvelopeNode: XmlElement;
        TimestampID: Text;
        BodyID: Text;
        BinarySecurityTokenID: Text;
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
        BodyNode: XmlNode;
        XMLDocumentText: Text;
        SignatureNode: XmlElement;
        SecurityNode: XmlNode;
    begin
        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, GetB2BIncomingInvoicev01, TimestampID, BodyID, eInvoiceSetup);
        eInvoiceSetupManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
        B2BGetIncomingInvoiceMsgEnvelope := CreateB2BGetB2BIncomingInvoiceMsgEnvelope(SupplierSchemeID, SupplierEndpointID, InvoiceID);

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(B2BGetIncomingInvoiceMsgEnvelope);

        EnvelopeNode.WriteTo(XMLDocumentText);

        XmlDocument.ReadFrom(XMLDocumentText, EnvelopedXMLDocument);

        SignatureNode := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetup);
        EnvelopedXMLDocument.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);
    end;

    local procedure PrepareB2BOutgoingInvoiceGetDocumentList(StatusCode: Text; FromDate: Date; ToDate: Date; eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopedXMLDocument: XmlDocument;
    var
        EnvelopeNode: XmlElement;
        TimestampID: Text;
        BodyID: Text;
        BinarySecurityTokenID: Text;
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
        B2BOutgoingInvoiceGetDocumentListEnvelope: XmlElement;
        BodyNode: XmlNode;
        XMLDocumentText: Text;
        SignatureNode: XmlElement;
        SecurityNode: XmlNode;
    begin
        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, GetB2BIncomingInvoiceListv01Namespace, TimestampID, BodyID, eInvoiceSetup);
        eInvoiceSetupManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
        B2BOutgoingInvoiceGetDocumentListEnvelope := CreateB2BOutgoingInvoiceGetDocumentListEnvelope(SupplierSchemeID, SupplierEndpointID, StatusCode, FromDate, ToDate);

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(B2BOutgoingInvoiceGetDocumentListEnvelope);

        EnvelopeNode.WriteTo(XMLDocumentText);

        XmlDocument.ReadFrom(XMLDocumentText, EnvelopedXMLDocument);

        SignatureNode := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetup);
        EnvelopedXMLDocument.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);
    end;

    local procedure CreateB2BGetB2BIncomingInvoiceMsgEnvelope(BuyerScheme: Text; BuyerID: Text; InvoiceID: Integer) EnvelopedB2BGetB2BIncomingInvoiceMsgNode: XmlElement;
    var
        HeaderBuyerNode: XmlElement;
        MessageIDNode: XmlElement;
        BuyerIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        DataNode: XmlElement;
        B2BIncomingInvoiceNode: XmlElement;
        InvoiceIDNode: XmlElement;
    begin
        EnvelopedB2BGetB2BIncomingInvoiceMsgNode := XmlElement.Create(GetB2BIncomingInvoiceMsgTag, GetB2BIncomingInvoicev01, '');
        HeaderBuyerNode := XmlElement.Create(HeaderBuyerTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        BuyerIDNode := XmlElement.Create(BuyerIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', BuyerScheme, BuyerID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9103Value);

        HeaderBuyerNode.Add(MessageIDNode);
        HeaderBuyerNode.Add(BuyerIDNode);
        HeaderBuyerNode.Add(MessageTypeNode);

        EnvelopedB2BGetB2BIncomingInvoiceMsgNode.Add(HeaderBuyerNode);

        DataNode := XmlElement.Create(DataTag, GetB2BIncomingInvoicev01, '');

        B2BIncomingInvoiceNode := XmlElement.Create(B2BIncomingInvoiceTag, GetB2BIncomingInvoicev01, '');
        InvoiceIDNode := XmlElement.Create(InvoiceIDTag, GetB2BIncomingInvoicev01, InvoiceID);

        B2BIncomingInvoiceNode.Add(InvoiceIDNode);

        DataNode.Add(B2BIncomingInvoiceNode);
        EnvelopedB2BGetB2BIncomingInvoiceMsgNode.Add(DataNode);

    end;

    local procedure CreateB2BOutgoingInvoiceGetDocumentListEnvelope(BuyerScheme: Text; BuyerID: Text; StatusCode: Text; FromDate: Date; ToDate: Date) EnvelopedB2BOutgoingInvoiceGetListNode: XmlElement;
    var
        HeaderBuyerNode: XmlElement;
        MessageIDNode: XmlElement;
        BuyerIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        DataNode: XmlElement;
        B2BIncomingInvoiceListNode: XmlElement;
        FilterNode: XmlElement;
        InvoiceStatusNode: XmlElement;
        DateRangeNode: XmlElement;
        FromNode: XmlElement;
        ToNode: XmlElement;
    begin
        EnvelopedB2BOutgoingInvoiceGetListNode := XmlElement.Create(GetB2BIncomingInvoiceListMsgTag, GetB2BIncomingInvoiceListv01Namespace, '');

        HeaderBuyerNode := XmlElement.Create(HeaderBuyerTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        BuyerIDNode := XmlElement.Create(BuyerIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', BuyerScheme, BuyerID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9101Value);

        HeaderBuyerNode.Add(MessageIDNode);
        HeaderBuyerNode.Add(BuyerIDNode);
        HeaderBuyerNode.Add(MessageTypeNode);
        EnvelopedB2BOutgoingInvoiceGetListNode.Add(HeaderBuyerNode);

        DataNode := XmlElement.Create(DataTag, GetB2BIncomingInvoiceListv01Namespace, '');

        B2BIncomingInvoiceListNode := XmlElement.Create(B2BIncomingInvoiceListTag, GetB2BIncomingInvoiceListv01Namespace, '');

        FilterNode := XmlElement.Create(FilterTag, invoicewebservicecomponentsNamespace, '');

        if StatusCode <> '' then begin
            InvoiceStatusNode := XmlElement.Create(InvoiceStatusTag, invoicewebservicecomponentsNamespace, StatusCode);
            FilterNode.Add(InvoiceStatusNode);
        end;

        if (FromDate <> 0D) and (ToDate <> 0D) then begin
            DateRangeNode := XmlElement.Create(DateRangeTag, invoicewebservicecomponentsNamespace, '');
            FromNode := XmlElement.Create(FromTag, invoicewebservicecomponentsNamespace, Format(FromDate, 0, 9));
            ToNode := XmlElement.Create(ToTag, invoicewebservicecomponentsNamespace, Format(ToDate, 0, 9));
            DateRangeNode.Add(FromNode);
            DateRangeNode.Add(ToNode);
            FilterNode.Add(DateRangeNode);

        end;
        B2BIncomingInvoiceListNode.Add(FilterNode);

        DataNode.Add(B2BIncomingInvoiceListNode);

        EnvelopedB2BOutgoingInvoiceGetListNode.Add(DataNode);
    end;

    local procedure PrepareB2BOutgoingInvoiceStatus(RecordID: RecordId; eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopedXMLDocument: XmlDocument;
    var
        BinarySecurityTokenID: Text;
        EnvelopeNode: XmlElement;
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
        TimestampID: Text;
        BodyID: Text;
        B2BOutgoingInvoiceStatus: XmlElement;
        B2BOutgoingInvoiceStatusEnvelope: XmlElement;
        BodyNode: XMLNode;
        InvoiceID: Text;
        InvoiceYear: Integer;
        XMLDocumentText: Text;
        SignatureNode: XmlElement;
        SecurityNode: XMLNode;
    begin
        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, GetB2BOutgoingInvoiceStatusv01Namespace, TimestampID, BodyID, eInvoiceSetup);
        eInvoiceSetupManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
        GetInvoiceIDYear(RecordID, InvoiceID, InvoiceYear);

        B2BOutgoingInvoiceStatusEnvelope := CreateB2BOutgoingInvoiceStatusEnvelope(SupplierSchemeID, SupplierEndpointID, InvoiceID, InvoiceYear);

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(B2BOutgoingInvoiceStatusEnvelope);

        EnvelopeNode.WriteTo(XMLDocumentText);

        XmlDocument.ReadFrom(XMLDocumentText, EnvelopedXMLDocument);

        SignatureNode := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetup);
        EnvelopedXMLDocument.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);
    end;

    local procedure GetInvoiceIDYear(RecordID: RecordId; var InvoiceID: Text; var InvoiceYear: Integer)
    var
        RecordR: RecordRef;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        //TODO subscriber
        RecordR.Get(RecordID);
        case RecordR.Number of
            Database::"Sales Invoice Header":
                begin
                    RecordR.SetTable(SalesInvoiceHeader);
                    InvoiceID := SalesInvoiceHeader."No.";
                    InvoiceYear := Date2DMY(SalesInvoiceHeader."Posting Date", 3);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecordR.SetTable(SalesCrMemoHeader);
                    InvoiceID := SalesCrMemoHeader."No.";
                    InvoiceYear := Date2DMY(SalesCrMemoHeader."Posting Date", 3);
                end;
            Database::"Service Invoice Header":
                begin
                    RecordR.SetTable(ServiceInvoiceHeader);
                    InvoiceID := ServiceInvoiceHeader."No.";
                    InvoiceYear := Date2DMY(ServiceInvoiceHeader."Posting Date", 3);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecordR.SetTable(ServiceCrMemoHeader);
                    InvoiceID := ServiceCrMemoHeader."No.";
                    InvoiceYear := Date2DMY(ServiceCrMemoHeader."Posting Date", 3);
                end;
            else
                Error('Error'); //TODO subscriber
        end;
    end;

    local procedure PrepareEchoBuyerMsg(eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopedXMLDocument: XmlDocument;
    var
        EnvelopeNode: XmlElement;
        EchoMsgEnvelope: XmlElement;
        TimestampID: Text;
        BodyID: Text;
        BinarySecurityTokenID: Text;
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
        BodyNode: XmlNode;
        XMLDocumentText: Text;
        SignatureNode: XmlElement;
        SecurityNode: XmlNode;
    begin
        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, EchoBuyerv01Namespace, TimestampID, BodyID, eInvoiceSetup);

        eInvoiceSetupManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
        EchoMsgEnvelope := CreateEchoBuyerMsgEnvelope(SupplierSchemeID, SupplierEndpointID, 'x');//TODO

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(EchoMsgEnvelope);

        EnvelopeNode.WriteTo(XMLDocumentText);

        XmlDocument.ReadFrom(XMLDocumentText, EnvelopedXMLDocument);

        SignatureNode := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetup);
        EnvelopedXMLDocument.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);

    end;

    local procedure PrepareEchoDocument(eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopedXMLDocument: XmlDocument;
    var
        EnvelopeNode: XmlElement;
        EchoMsgEnvelope: XmlElement;
        TimestampID: Text;
        BodyID: Text;
        BinarySecurityTokenID: Text;
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
        BodyNode: XmlNode;
        XMLDocumentText: Text;
        SignatureNode: XmlElement;
        SecurityNode: XmlNode;
    begin
        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, Echov01Namespace, TimestampID, BodyID, eInvoiceSetup);

        eInvoiceSetupManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
        EchoMsgEnvelope := CreateEchoMsgEnvelope(SupplierSchemeID, SupplierEndpointID, 'x');//TODO

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(EchoMsgEnvelope);

        EnvelopeNode.WriteTo(XMLDocumentText);

        XmlDocument.ReadFrom(XMLDocumentText, EnvelopedXMLDocument);

        SignatureNode := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetup);
        EnvelopedXMLDocument.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);

    end;

    procedure PrepareUBLDocument(UBLXMLDocumentToSend: XmlDocument; var Usage: Enum "Electronic Document Format Usage"; RecordExportBuffer: Record "Record Export Buffer") EnvelopedXMLDocument: XmlDocument;
    var
        SupplierScheme: Text;
        SupplierID: Text;
        BuyerScheme: Text;
        BuyerID: Text;
        BinarySecurityTokenID: Text;
        TimestampID: Text;
        BodyID: Text;
        EnvelopeNode: XmlElement;
        B2BOutgoingInvoiceEnvelopeNode: XmlElement;
        BodyNode: XmlNode;
        SupplierInvoiceID: Text;
        SpecificationIdentifierID: Text;
        Base64SignedDocument: Text;
        SignatureNode: XmlElement;
        SecurityNode: XmlNode;
        XMLDocumentText: Text;
    begin
        UBLXMLDocumentToSend.WriteTo(XMLDocumentText);
        Clear(UBLXMLDocumentToSend);
        XMLDocument.ReadFrom(XMLDocumentText, UBLXMLDocumentToSend);

        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, SendB2BOutgoingInvoicev01Namespace, TimestampID, BodyID, RecordExportBuffer);

        GetDataFromUBL(UBLXMLDocumentToSend, SupplierInvoiceID, SpecificationIdentifierID, SupplierScheme, SupplierID, BuyerScheme, BuyerID);

        B2BOutgoingInvoiceEnvelopeNode := CreateB2BOutgoingInvoiceEnvelope(Usage, SupplierInvoiceID, SpecificationIdentifierID, SupplierScheme, SupplierID, BuyerScheme, BuyerID);

        HandleNamespaces(UBLXMLDocumentToSend, Usage);

        HandleUBLInitTags(UBLXMLDocumentToSend, Usage);

        Base64SignedDocument := CombinedSignatures(UBLXMLDocumentToSend, RecordExportBuffer."Document Sending Profile");

        if Usage in [Usage::"Sales Invoice", Usage::"Service Invoice"] then
            B2BOutgoingInvoiceEnvelopeNode.SelectSingleNode('//*[local-name()=''' + InvoiceEnvelopeTag + ''']', BodyNode)
        else
            B2BOutgoingInvoiceEnvelopeNode.SelectSingleNode('//*[local-name()=''' + CreditNoteEnvelopeTag + ''']', BodyNode);

        BodyNode.AsXmlElement().Add(XmlText.Create(Base64SignedDocument));

        EnvelopeNode.SelectSingleNode('//*[local-name()=''' + BodyTag + ''']', BodyNode);
        BodyNode.AsXmlElement().Add(B2BOutgoingInvoiceEnvelopeNode);

        EnvelopeNode.WriteTo(XMLDocumentText);
        XmlDocument.ReadFrom(XMLDocumentText, UBLXMLDocumentToSend);

        SignatureNode := SignEnvelope(UBLXMLDocumentToSend, BinarySecurityTokenID, TimestampID, BodyID, RecordExportBuffer."Document Sending Profile");

        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + SecurityTag + ''']', SecurityNode);

        SecurityNode.AsXmlElement().Add(SignatureNode);

        EnvelopedXMLDocument := UBLXMLDocumentToSend;
    end;

    local procedure SignEnvelope(EnvelopedXMLDocument: XMLDocument; BinarySecurityTokenID: Text; TimestampID: Text; BodyID: Text; DocumentSendingProfileCode: Code[20]) EnvelopeSignature: XmlElement;
    begin
        eInvoiceSetupGlobal := eInvoiceSetupManagement.GeteInvoiceSetupGlobalFromDocSend(DocumentSendingProfileCode);
        EnvelopeSignature := SignEnvelope(EnvelopedXMLDocument, BinarySecurityTokenID, TimestampID, BodyID, eInvoiceSetupGlobal);
    end;

    local procedure SignEnvelope(EnvelopedXMLDocument: XMLDocument; BinarySecurityTokenID: Text; TimestampID: Text; BodyID: Text; eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopeSignature: XmlElement;
    var
        SignedXml: Codeunit SignedXml;
        SignatureKey: Codeunit "Signature Key";
        BodyIDPrefixList: Label 'soapenc xsd xsi', Locked = true;
        TimestampIDPrefixList: Label 'wsse soapenc soapenv xsd xsi', Locked = true;
        CanonicalizationMethodPrefixList: Label 'soapenc soapenv xsd xsi', Locked = true;
    begin

        SignatureKey := InitializeSignatureKey(eInvoiceSetup);

        SignedXml.InitializeSignedXml(EnvelopedXMLDocument);
        SignedXml.SetSigningKey(SignatureKey);

        SignedXml.InitializeReference(FormatURI(BodyID));

        SignedXml.SetDigestMethod(XmlDsigSHA256Url);
        SignedXml.AddXmlDsigExcC14NTransformToReference(BodyIDPrefixList);
        SignedXml.AddReferenceToSignedXML();

        SignedXml.InitializeReference(FormatURI(TimestampID));
        SignedXml.SetDigestMethod(XmlDsigSHA256Url);
        SignedXml.AddXmlDsigExcC14NTransformToReference(TimestampIDPrefixList);
        SignedXml.AddReferenceToSignedXML();

        SignedXml.SetXmlDsigExcC14NTransformAsCanonicalizationMethod(CanonicalizationMethodPrefixList);
        SignedXml.SetSignatureMethod(XmlDsigRSASHA256Url);

        // KeyInfo
        SignedXml.InitializeKeyInfo();
        SignedXml.AddClause(GetKeyInfoNodeXmlElement(BinarySecurityTokenID));

        SignedXml.ComputeSignature();
        EnvelopeSignature := SignedXml.GetXml();

    end;

    local procedure GetKeyInfoNodeXmlElement(BinarySecurityTokenID: Text) RootNode: XmlElement
    var
        ReferenceNode: XmlElement;
    begin
        RootNode := XmlElement.Create(SecurityTokenReferenceTag, oasis200401wsswssecuritysecext10Namespace, '');
        RootNode.Add(XmlAttribute.CreateNamespaceDeclaration(wssePrefix, oasis200401wsswssecuritysecext10Namespace));

        ReferenceNode := XmlElement.Create(ReferenceTag, oasis200401wsswssecuritysecext10Namespace, '');
        ReferenceNode.Add(XmlAttribute.CreateNamespaceDeclaration(wssePrefix, oasis200401wsswssecuritysecext10Namespace));
        ReferenceNode.Add(XmlAttribute.Create(URITag, FormatURI(BinarySecurityTokenID)));
        ReferenceNode.Add(XmlAttribute.Create(ValueTypeTag, ValueTypeNamespace));
        RootNode.Add(ReferenceNode);
    end;

    local procedure GetDataFromUBL(UBLXMLDocumentToSend: XmlDocument; var SupplierInvoiceID: Text; var SpecificationIdentifierID: Text; var SupplierScheme: Text; var SupplierID: Text; var BuyerScheme: Text; var BuyerID: Text)
    var
        AttributeCollection: XmlAttributeCollection;
        EndpointAttribute: XmlAttribute;
        EndpointIDNode: XmlNode;
        ElectronicMailNode: XmlNode;

        SupplierInvoiceIDNode: XmlNode;
        SpecificationIdentifierIDNode: XmlNode;
        XMLNodList: XmlNodeList;
        XMLParent: XmlElement;
        IsAccountingSupplierPartyTag: Boolean;
        IsAccountingCustomerPartyTag: Boolean;
    begin
        //TODO ErrorInfo
        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceSetupManagement.GetIDTag() + ''']', SupplierInvoiceIDNode);

        SupplierInvoiceID := SupplierInvoiceIDNode.AsXmlElement().InnerText();

        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceSetupManagement.GetCustomizationIDTag() + ''']', SpecificationIdentifierIDNode);

        SpecificationIdentifierID := SpecificationIdentifierIDNode.AsXmlElement().InnerText();

        UBLXMLDocumentToSend.SelectNodes('//*[local-name()=''' + EndpointIDTag + ''']', XMLNodList);

        foreach EndpointIDNode in XMLNodList do begin
            EndpointIDNode.GetParent(XMLParent);
            if (StrPos(XMLParent.Name, AccountingSupplierPartyTag) = 0) then
                while XMLParent.GetParent(XMLParent) and ((not IsAccountingSupplierPartyTag) and (not IsAccountingCustomerPartyTag)) do begin
                    IsAccountingSupplierPartyTag := (StrPos(XMLParent.Name, AccountingSupplierPartyTag) <> 0);
                    IsAccountingCustomerPartyTag := (StrPos(XMLParent.Name, AccountingCustomerPartyTag) <> 0);
                end;

            if IsAccountingSupplierPartyTag then begin
                AttributeCollection := EndpointIDNode.AsXmlElement().Attributes();

                foreach EndpointAttribute in AttributeCollection do
                    if EndpointAttribute.Name = schemeID then
                        SupplierScheme := EndpointAttribute.Value;

                SupplierID := EndpointIDNode.AsXmlElement().InnerText();
            end;

            if IsAccountingCustomerPartyTag then begin
                AttributeCollection := EndpointIDNode.AsXmlElement().Attributes();

                foreach EndpointAttribute in AttributeCollection do
                    if EndpointAttribute.Name = schemeID then
                        BuyerScheme := EndpointAttribute.Value;

                BuyerID := EndpointIDNode.AsXmlElement().InnerText();
            end;

            Clear(IsAccountingSupplierPartyTag);
            Clear(IsAccountingCustomerPartyTag);

        end;
        if BuyerID = '' then begin
            UBLXMLDocumentToSend.SelectNodes('//*[local-name()=''' + ElectronicMailTag + ''']', XMLNodList);
            BuyerScheme := EmailScheme;
            foreach ElectronicMailNode in XMLNodList do begin
                ElectronicMailNode.GetParent(XMLParent);
                if (StrPos(XMLParent.Name, AccountingSupplierPartyTag) = 0) then
                    while XMLParent.GetParent(XMLParent) and ((not IsAccountingSupplierPartyTag) and (not IsAccountingCustomerPartyTag)) do
                        IsAccountingCustomerPartyTag := (StrPos(XMLParent.Name, AccountingCustomerPartyTag) <> 0);
                if IsAccountingCustomerPartyTag then BuyerID := ElectronicMailNode.AsXmlElement().InnerText();
            end;
        end;

    end;

    local procedure CreateB2BOutgoingInvoiceEnvelope(Usage: Enum "Electronic Document Format Usage"; SupplierInvoiceID: Text;
                                                                SpecificationIdentifierID: Text;
                                                                SupplierScheme: Text;
                                                                SupplierID: Text;
                                                                BuyerScheme: Text;
                                                                BuyerID: Text) SendB2BOutgoingInvoiceMsgNode: XmlElement;
    var
        HeaderSupplierNode: XmlElement;
        MessageIDNode: XmlElement;
        SupplierIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        XMLStandardNode: XmlElement;
        BuyerIDNode: XmlElement;
        SpecificationIdentifierNode: XmlElement;
        SupplierInvoiceIDNode: XmlElement;
        InvoiceEnvelopeNode: XmlElement;
        DataNode: XmlElement;
        B2BOutgoingInvoiceEnvelopeNode: XmlElement;

    begin
        SendB2BOutgoingInvoiceMsgNode := XmlElement.Create(SendB2BOutgoingInvoiceMsgTag, SendB2BOutgoingInvoicev01Namespace, '');

        HeaderSupplierNode := XmlElement.Create(HeaderSupplierTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        SupplierIDNode := XmlElement.Create(SupplierIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', SupplierScheme, SupplierID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9001Value);

        HeaderSupplierNode.Add(MessageIDNode);
        HeaderSupplierNode.Add(SupplierIDNode);
        HeaderSupplierNode.Add(MessageTypeNode);

        SendB2BOutgoingInvoiceMsgNode.Add(HeaderSupplierNode);

        DataNode := XmlElement.Create(DataTag, SendB2BOutgoingInvoicev01Namespace, '');

        B2BOutgoingInvoiceEnvelopeNode := XmlElement.Create(B2BOutgoingInvoiceEnvelopeTag, SendB2BOutgoingInvoicev01Namespace, '');

        SpecificationIdentifierNode := XmlElement.Create(SpecificationIdentifierTag, SendB2BOutgoingInvoicev01Namespace, SpecificationIdentifierID);

        XMLStandardNode := XmlElement.Create(XMLStandardTag, SendB2BOutgoingInvoicev01Namespace, UBLValue);

        SupplierInvoiceIDNode := XmlElement.Create(SupplierInvoiceIDTag, SendB2BOutgoingInvoicev01Namespace, SupplierInvoiceID);

        BuyerIDNode := XmlElement.Create(BuyerIDTag, SendB2BOutgoingInvoicev01Namespace, StrSubstNo('%1:%2', BuyerScheme, BuyerID));

        if Usage in [Usage::"Sales Invoice", Usage::"Service Invoice"] then
            InvoiceEnvelopeNode := XmlElement.Create(InvoiceEnvelopeTag, SendB2BOutgoingInvoicev01Namespace, '')
        else
            InvoiceEnvelopeNode := XmlElement.Create(CreditNoteEnvelopeTag, SendB2BOutgoingInvoicev01Namespace, '');

        B2BOutgoingInvoiceEnvelopeNode.Add(XMLStandardNode);
        B2BOutgoingInvoiceEnvelopeNode.Add(SpecificationIdentifierNode);
        B2BOutgoingInvoiceEnvelopeNode.Add(SupplierInvoiceIDNode);
        B2BOutgoingInvoiceEnvelopeNode.Add(BuyerIDNode);
        B2BOutgoingInvoiceEnvelopeNode.Add(InvoiceEnvelopeNode);
        DataNode.Add(B2BOutgoingInvoiceEnvelopeNode);
        SendB2BOutgoingInvoiceMsgNode.Add(DataNode);
    end;

    local procedure CreateB2BOutgoingInvoiceStatusEnvelope(SupplierScheme: Text; SupplierID: Text; InvoiceID: Text; InvoiceYear: Integer) EnvelopedB2BOutgoingInvoiceStatusNode: XmlElement;
    var
        HeaderSupplierNode: XmlElement;
        MessageIDNode: XmlElement;
        SupplierIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        DataNode: XmlElement;
        B2BOutgoingInvoiceStatusNode: XmlElement;
        SupplierInvoiceIDNode: XmlElement;
        InvoiceYearNode: XmlElement;

    begin
        EnvelopedB2BOutgoingInvoiceStatusNode := XmlElement.Create(GetB2BOutgoingInvoiceStatusMsgTag, GetB2BOutgoingInvoiceStatusv01Namespace, '');

        HeaderSupplierNode := XmlElement.Create(HeaderSupplierTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        SupplierIDNode := XmlElement.Create(SupplierIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', SupplierScheme, SupplierID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9011Value);

        HeaderSupplierNode.Add(MessageIDNode);
        HeaderSupplierNode.Add(SupplierIDNode);
        HeaderSupplierNode.Add(MessageTypeNode);
        EnvelopedB2BOutgoingInvoiceStatusNode.Add(HeaderSupplierNode);

        DataNode := XmlElement.Create(DataTag, GetB2BOutgoingInvoiceStatusv01Namespace, '');

        B2BOutgoingInvoiceStatusNode := XmlElement.Create(B2BOutgoingInvoiceStatusTag, GetB2BOutgoingInvoiceStatusv01Namespace, '');

        SupplierInvoiceIDNode := XmlElement.Create(SupplierInvoiceIDTag, GetB2BOutgoingInvoiceStatusv01Namespace, InvoiceID);
        InvoiceYearNode := XmlElement.Create(InvoiceYearTag, GetB2BOutgoingInvoiceStatusv01Namespace, Format(InvoiceYear));

        B2BOutgoingInvoiceStatusNode.Add(SupplierInvoiceIDNode);
        B2BOutgoingInvoiceStatusNode.Add(InvoiceYearNode);
        DataNode.Add(B2BOutgoingInvoiceStatusNode);

        EnvelopedB2BOutgoingInvoiceStatusNode.Add(DataNode);
    end;

    local procedure CreateEchoBuyerMsgEnvelope(SupplierScheme: Text; SupplierID: Text; EchoMessage: Text) EchoBuyerMsgNode: XmlElement;
    var
        HeaderSupplierNode: XmlElement;
        MessageIDNode: XmlElement;
        BuyerIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        DataNode: XmlElement;
        EchoDataNode: XmlElement;
        EchoNode: XmlElement;
    begin
        EchoBuyerMsgNode := XmlElement.Create(EchoBuyerMsgTag, EchoBuyerv01Namespace, '');

        HeaderSupplierNode := XmlElement.Create(HeaderBuyerTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        BuyerIDNode := XmlElement.Create(BuyerIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', SupplierScheme, SupplierID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9999Value);

        HeaderSupplierNode.Add(MessageIDNode);
        HeaderSupplierNode.Add(BuyerIDNode);
        HeaderSupplierNode.Add(MessageTypeNode);

        EchoBuyerMsgNode.Add(HeaderSupplierNode);

        DataNode := XmlElement.Create(DataTag, EchoBuyerv01Namespace, '');

        EchoDataNode := XmlElement.Create(EchoDataTag, EchoBuyerv01Namespace, '');

        EchoNode := XmlElement.Create(EchoTag, EchoBuyerv01Namespace, EchoMessage);

        EchoDataNode.Add(EchoNode);

        DataNode.Add(EchoDataNode);
        EchoBuyerMsgNode.Add(DataNode);
    end;

    local procedure CreateEchoMsgEnvelope(SupplierScheme: Text; SupplierID: Text; EchoMessage: Text) EchoMsgNode: XmlElement;
    var
        HeaderSupplierNode: XmlElement;
        MessageIDNode: XmlElement;
        SupplierIDNode: XmlElement;
        MessageTypeNode: XmlElement;
        DataNode: XmlElement;
        EchoDataNode: XmlElement;
        EchoNode: XmlElement;
    begin
        EchoMsgNode := XmlElement.Create(EchoMsgTag, Echov01Namespace, '');

        HeaderSupplierNode := XmlElement.Create(HeaderSupplierTag, invoicewebservicecomponentsNamespace, '');

        MessageIDNode := XmlElement.Create(MessageIDTag, invoicewebservicecomponentsNamespace, CreateXmlElementID());

        SupplierIDNode := XmlElement.Create(SupplierIDTag, invoicewebservicecomponentsNamespace, StrSubstNo('%1:%2', SupplierScheme, SupplierID));

        MessageTypeNode := XmlElement.Create(MessageTypeTag, invoicewebservicecomponentsNamespace, MessageType9999Value);

        HeaderSupplierNode.Add(MessageIDNode);
        HeaderSupplierNode.Add(SupplierIDNode);
        HeaderSupplierNode.Add(MessageTypeNode);

        EchoMsgNode.Add(HeaderSupplierNode);

        DataNode := XmlElement.Create(DataTag, Echov01Namespace, '');

        EchoDataNode := XmlElement.Create(EchoDataTag, Echov01Namespace, '');

        EchoNode := XmlElement.Create(EchoTag, Echov01Namespace, EchoMessage);

        EchoDataNode.Add(EchoNode);

        DataNode.Add(EchoDataNode);
        EchoMsgNode.Add(DataNode);
    end;

    local procedure CreateSoapEnvelope(var BinarySecurityTokenID: Text; V0Namespace: Text; var TimestampID: Text; var BodyID: Text; RecordExportBuffer: Record "Record Export Buffer") EnvelopeNode: XmlElement;
    begin
        eInvoiceSetupGlobal := eInvoiceSetupManagement.GeteInvoiceSetupGlobalFromDocSend(RecordExportBuffer."Document Sending Profile");

        EnvelopeNode := CreateSoapEnvelope(BinarySecurityTokenID, V0Namespace, TimestampID, BodyID, eInvoiceSetupGlobal);
    end;

    local procedure CreateSoapEnvelope(var BinarySecurityTokenID: Text; V0Namespace: Text; var TimestampID: Text; var BodyID: Text; eInvoiceSetup: Record "eInvoice Setup-BET") EnvelopeNode: XmlElement;
    var

        X509Cert2: Codeunit X509Certificate2;
        CertValue: Text;

        HeaderNode: XmlElement;
        SecurityNode: XmlElement;
        BinarySecurityTokenNode: XmlElement;
        TimestampNode: XmlElement;
        CreatedNode: XmlElement;
        ExpiresNode: XmlElement;
        BodyNode: XmlElement;
        CreatedDateTime: DateTime;

    begin
        BinarySecurityTokenID := CreateXmlElementID();
        TimestampID := CreateXmlElementID();
        BodyID := CreateXmlElementID();

        EnvelopeNode := XmlElement.Create(EnvelopeTag, envelopeNamespace, '');

        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(soapenvPrefix, envelopeNamespace));

        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(soapencPrefix, encodingNamespace));

        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(v0Prefix, V0Namespace));
        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(v1Prefix, invoicewebservicecomponentsNamespace));

        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(xsdPrefix, XMLSchemaNamespace));
        EnvelopeNode.Add(XmlAttribute.CreateNamespaceDeclaration(xsiPrefix, XMLSchemainstanceNamespace));

        HeaderNode := XmlElement.Create(HeaderTag, envelopeNamespace, '');
        EnvelopeNode.Add(HeaderNode);

        SecurityNode := XmlElement.Create(SecurityTag, oasis200401wsswssecuritysecext10Namespace, '');
        HeaderNode.Add(SecurityNode);

        SecurityNode.Add(XmlAttribute.CreateNamespaceDeclaration(wssePrefix, oasis200401wsswssecuritysecext10Namespace));
        SecurityNode.Add(XmlAttribute.CreateNamespaceDeclaration(wsuPrefix, oasis200401wsswssecurityutility10Namespace));
        SecurityNode.Add(XmlAttribute.Create(mustUnderstandTag, envelopeNamespace, '1'));

        CertValue := eInvoiceSetupManagement.GetCert(eInvoiceSetup);

        //This is mandatory it changes CertValue 
        X509Cert2.VerifyCertificate(CertValue, eInvoiceSetupManagement.GetPassword(eInvoiceSetup), Enum::"X509 Content Type"::Cert);

        BinarySecurityTokenNode := XmlElement.Create(BinarySecurityTokenTag, oasis200401wsswssecuritysecext10Namespace, CertValue);

        SecurityNode.Add(BinarySecurityTokenNode);

        BinarySecurityTokenNode.Add(XmlAttribute.Create(EncodingTypeTag, EncodingTypeNamespace));
        BinarySecurityTokenNode.Add(XmlAttribute.Create(ValueTypeTag, ValueTypeNamespace));
        BinarySecurityTokenNode.Add(XmlAttribute.Create(IdTag, oasis200401wsswssecurityutility10Namespace, BinarySecurityTokenID));

        TimestampNode := XmlElement.Create(TimestampTag, oasis200401wsswssecurityutility10Namespace, '');
        TimestampNode.Add(XmlAttribute.Create(IdTag, TimestampID));

        SecurityNode.Add(TimestampNode);

        CreatedDateTime := CurrentDateTime;

        CreatedNode := XmlElement.Create(CreatedTag, oasis200401wsswssecurityutility10Namespace, Format(CreatedDateTime, 0, 9));

        ExpiresNode := XmlElement.Create(ExpiresTag, oasis200401wsswssecurityutility10Namespace, Format(CreatedDateTime + 1000 * 60 * 10, 0, 9));

        TimestampNode.Add(CreatedNode);
        TimestampNode.Add(ExpiresNode);

        BodyNode := XmlElement.Create(BodyTag, envelopeNamespace, '');
        BodyNode.Add(XmlAttribute.Create(IdTag, BodyID));

        EnvelopeNode.Add(BodyNode);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectEnableErrors(var eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        ErrorMessage: Record "Error Message" temporary;
        ErrorInf: ErrorInfo;
        eInvoiceManagement: Codeunit "eInvoice Setup Management-BET";
        NoCertErr: Label 'There is no certificate uploaded.';
    begin
        if eInvoiceManagement.GetCert(eInvoiceSetup) = '' then
            Error(ErrorInfo.Create(NoCertErr, true));

        if eInvoiceSetup.GetBaseURL() = '' then
            Error(ErrorInfo.Create(StrSubstNo(EmptyErrLbl, eInvoiceSetup.FieldCaption("Base URL")), true));

        CheckSetupForEmptyValues(eInvoiceSetup);

        if HasCollectedErrors then begin
            foreach ErrorInf in system.GetCollectedErrors() do begin
                ErrorMessage.ID := ErrorMessage.ID + 1;
                ErrorMessage.Message := ErrorInf.Message;
                ErrorMessage.Validate("Record ID", ErrorInf.RecordId);
                ErrorMessage.Insert();
            end;
            ClearCollectedErrors();

            page.RunModal(page::"Error Messages", ErrorMessage);
            Error('')
        end;
    end;

    local procedure CheckSetupForEmptyValues(eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        JsonObj: JsonObject;
        JsonTok: JsonToken;
        ListOfKeys: List of [Text];
        TexKey: Text;
        ErrorInf: ErrorInfo;
    begin
        JsonObj := eInvoiceSetupManagement.GetInvoiceSetup(eInvoiceSetup);
        ListOfKeys := JsonObj.Keys;
        foreach TexKey in ListOfKeys do begin
            JsonObj.Get(TexKey, JsonTok);
            if JsonTok.AsValue().AsText() = '' then
                Error(ErrorInfo.Create(StrSubstNo(EmptyErrLbl, GetSetupCaption(TexKey)), true));
        end;
    end;
    // [NonDebuggable] TODO Remove comment
    local procedure CombinedSignatures(UBLXMLDocumentToSend: XmlDocument; DocumentSendingProfileCode: Code[20]) Base64SignedDocument: Text
    var
        SignedXml: Codeunit SignedXml;
        SignatureKey: Codeunit "Signature Key";
        X509Cert2: Codeunit X509Certificate2;
        Signature1: XmlElement;
        Signature2: XmlElement;
        Base64Cert: Text;
        CertPass: Text;
        SignatureNode: XmlNode;
        UBLDocumentSignaturesElement: XmlElement;
        SignatureInformationElement: XmlElement;
        ObjectElement: XmlElement;
        SignatureProperties: XmlElement;
        SignatureProperty1: XmlElement;
        SignatureProperty2: XmlElement;
        NameElement1: XmlElement;
        NameElement2: XmlElement;
        X509Data: XmlElement;
        X509Certificate: XmlElement;
        SignaturePropertiesId: Text;
        SignatureID: Text;
        CertValue: Text;
        SearchNode: XmlNode;
        SearchNode2: XmlNode;
        B64Convert: Codeunit "Base64 Convert";
        XMLToText: Text;
    begin
        UBLXMLDocumentToSend.WriteTo(XMLToText);
        Clear(UBLXMLDocumentToSend);
        XmlDocument.ReadFrom(XMLToText, UBLXMLDocumentToSend);
        Clear(XMLToText);

        Base64Cert := eInvoiceSetupManagement.GetCert(eInvoiceSetupGlobal);
        CertPass := eInvoiceSetupManagement.GetPassword(eInvoiceSetupGlobal);
        SignatureKey.FromXmlString(X509Cert2.GetCertificatePrivateKey(Base64Cert, CertPass));

        SignedXml.InitializeSignedXml(UBLXMLDocumentToSend);
        SignedXml.SetSigningKey(SignatureKey);
        SignedXML.SetSignatureMethod(XmlDsigRSASHA256Url);
        SignedXml.InitializeReference('');
        SignedXML.SetDigestMethod(XmlDsigSHA256Url);
        SignedXML.AddXmlDsigEnvelopedSignatureTransform();
        SignedXml.ComputeSignature();
        Signature1 := SignedXml.GetXml();

        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + ExtensionContentTag + ''']', SignatureNode);
        UBLDocumentSignaturesElement := XmlElement.Create(UBLDocumentSignaturesTag, CommonSignatureComponentsNamespace, '');
        SignatureInformationElement := XmlElement.Create(SignatureInformationTag, SignatureAggregateComponentsNamespace, '');
        ObjectElement := XmlElement.Create(ObjectTag, xmldsigNamespace, '');


        SignaturePropertiesId := CreateXmlElementID();
        SignatureID := CreateXmlElementID();

        SignatureProperties := XmlElement.Create(SignaturePropertiesTag, xmldsigNamespace, '');
        SignatureProperties.Add(XmlAttribute.Create(IdTag, SignaturePropertiesId));

        SignatureProperty1 := XmlElement.Create(SignaturePropertyTag, xmldsigNamespace, '');
        SignatureProperty1.Add(XmlAttribute.Create(TargetTag, SignatureID));

        SignatureProperties.Add(SignatureProperty1);

        NameElement1 := XmlElement.Create(NameTag, AdobeNamespace, eInvoiceSetupGlobal."Cert. Friendly Name");
        SignatureProperty1.Add(NAmeElement1);

        SignatureProperty2 := XmlElement.Create(SignaturePropertyTag, xmldsigNamespace, '');
        SignatureProperty2.Add(XmlAttribute.Create(TargetTag, SignatureID));

        SignatureProperties.Add(SignatureProperty2);

        NameElement2 := XmlElement.Create(MTag, AdobeNamespace, CreateDateTimeTimestamp());
        SignatureProperty2.Add(NameElement2);

        ObjectElement.Add(SignatureProperties);
        Signature1.Add(ObjectElement);

        SignatureInformationElement.Add(Signature1);

        UBLDocumentSignaturesElement.Add(SignatureInformationElement);

        SignatureNode.AsXmlElement().Add(UBLDocumentSignaturesElement);

        SignedXml.InitializeSignedXml(UBLXMLDocumentToSend);
        SignedXml.SetSigningKey(SignatureKey);
        SignedXML.SetSignatureMethod(XmlDsigRSASHA256Url);

        SignedXml.InitializeReference(FormatURI(SignaturePropertiesId));
        SignedXML.SetDigestMethod(XmlDsigSHA256Url);
        SignedXML.AddXmlDsigEnvelopedSignatureTransform();
        SignedXML.AddXmlDsigExcC14NTransformToReference();

        SignedXml.InitializeDataObject();
        SignedXml.AddObject(ObjectElement);

        SignedXml.InitializeKeyInfo();

        X509Data := XmlElement.Create(X509DataTag, xmldsigNamespace, '');

        CertValue := eInvoiceSetupManagement.GetCert(eInvoiceSetupGlobal);

        //This is mandatory it changes CertValue 
        X509Cert2.VerifyCertificate(CertValue, eInvoiceSetupManagement.GetPassword(eInvoiceSetupGlobal), Enum::"X509 Content Type"::Cert);

        X509Certificate := XmlElement.Create(X509CertificateTag, xmldsigNamespace, CertValue);

        X509Data.Add(X509Certificate);

        SignedXml.AddClause(X509Data);

        SignedXml.ComputeSignature();

        Signature2 := SignedXml.GetXml();

        Signature1.SelectSingleNode('//*[local-name()=''' + ReferenceTag + ''']', SearchNode);

        Signature2.SelectSingleNode('//*[local-name()=''' + ReferenceTag + ''']', SearchNode2);
        SearchNode2.AddAfterSelf(SearchNode);

        Signature1.SelectSingleNode('//*[local-name()=''' + SignatureTag + ''']', SearchNode);
        SearchNode.ReplaceWith(Signature2);


        SignedXml.InitializeSignedXml(UBLXMLDocumentToSend);
        SignedXml.SetSigningKey(SignatureKey);
        SignedXML.SetSignatureMethod(XmlDsigRSASHA256Url);
        SignedXml.LoadXml(Signature2);
        SignedXml.ComputeSignature();
        Signature1 := SignedXml.GetXml();

        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + SignatureTag + ''']', SearchNode);
        SearchNode.ReplaceWith(Signature1);
        UBLXMLDocumentToSend.WriteTo(XMLToText);
        exit(B64Convert.ToBase64(XMLToText));
    end;


    local procedure CombineSignatures(Signature1: XmlElement; Signature2: XmlElement): XmlElement
    var
        SearchNode: XmlNode;
        SearchNode2: XmlNode;
        t: Text;
    begin
        Signature1.SelectSingleNode('//*[local-name()=''' + ReferenceTag + ''']', SearchNode);

        Signature2.SelectSingleNode('//*[local-name()=''' + ReferenceTag + ''']', SearchNode2);
        SearchNode2.AddAfterSelf(SearchNode);

        Signature1.SelectSingleNode('//*[local-name()=''' + SignatureTag + ''']', SearchNode);
        SearchNode.ReplaceWith(Signature2);

        exit(Signature2);
    end;

    //[NonDebuggable] TODO
    local procedure InitializeSignatureKey(eInvoiceSetup: Record "eInvoice Setup-BET") SignatureKey: Codeunit "Signature Key"
    var
        X509Cert2: Codeunit X509Certificate2;
    begin
        SignatureKey.FromXmlString(X509Cert2.GetCertificatePrivateKey(eInvoiceSetupManagement.GetCert(eInvoiceSetup), eInvoiceSetupManagement.GetPassword(eInvoiceSetup)));
    end;

    local procedure CreateDateTimeTimestamp(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffsetDuration: Duration;
        TimezoneOffsetInteger: Integer;
        TimezoneOffsetText: Text;
    begin
        TypeHelper.GetUserTimezoneOffset(TimezoneOffsetDuration);
        TimezoneOffsetInteger := TimezoneOffsetDuration DIV (1000 * 60 * 60);
        if TimezoneOffsetInteger < 0 then
            TimezoneOffsetText := '-' + Format(ABS(TimezoneOffsetInteger)).PadLeft(2, '0')
        else
            TimezoneOffsetText := '+' + Format(TimezoneOffsetInteger).PadLeft(2, '0');
        exit(Format(TypeHelper.GetCurrUTCDateTime(), 0, 'D:<Year4><Month,2><Hours24,2><Day,2><Minutes,2><Seconds,2>' + TimezoneOffsetText + '''00'''));
    end;

    local procedure CreateXmlElementID(): Text
    begin
        exit('uuid-' + CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}'), 1, 36));
    end;

    local procedure FormatURI(URI: Text): Text[250]
    var
        URITok: Label '#%1', Locked = true;
    begin
        if StrPos(URI, '#') = 0 then
            URI := StrSubstNo(URITok, URI);
        exit(CopyStr(URI, 1, 250));
    end;

    local procedure HandleUBLInitTags(var UBLXMLDocumentToSend: XmlDocument; Usage: Enum "Electronic Document Format Usage")
    var
        eInvoiceMgt: Codeunit "eInvoice Setup Management-BET";
        UBLExtensionsDic: Dictionary of [Text, Text];
        TextKey: Text;
        xTextKey: Text;
        XMLSearchNode: XmlNode;
        DicTextValue: Text;
    begin
        InitializeUBLExtensionsDictionary(UBLExtensionsDic);

        foreach TextKey in UBLExtensionsDic.Keys do begin
            UBLExtensionsDic.Get(TextKey, DicTextValue);
            if not UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + TextKey + ''']', XMLSearchNode) then begin
                if xTextKey = '' then
                    UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetHeaderTag(Usage) + ''']', XMLSearchNode)
                else
                    UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + xTextKey + ''']', XMLSearchNode);

                XMLSearchNode.AsXmlElement().AddFirst(XmlElement.Create(TextKey, DicTextValue, ''));
            end;

            xTextKey := TextKey;
        end;
        if UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + UBLDocumentSignaturesTag + ''']', XMLSearchNode) then
            XMLSearchNode.Remove();
    end;

    local procedure HandleNamespaces(var UBLXMLDocumentToSend: XmlDocument; Usage: Enum "Electronic Document Format Usage")
    var
        eInvoiceMgt: Codeunit "eInvoice Setup Management-BET";
        XMLAttributes: XmlAttributeCollection;
        XMLAttr: XmlAttribute;
        NamespaceDic: Dictionary of [Text, Text];
        DicTextValue: Text;
        TextKey: Text;
        XMLHeaderNode: XmlNode;
    begin
        UBLXMLDocumentToSend.SelectSingleNode('//*[local-name()=''' + eInvoiceMgt.GetHeaderTag(Usage) + ''']', XMLHeaderNode);

        InitializeNamespaceDictionary(NamespaceDic);

        XMLAttributes := XMLHeaderNode.AsXmlElement().Attributes();

        foreach XMLAttr in XMLAttributes do
            if NamespaceDic.Get(XMLAttr.Value, DicTextValue) then
                NamespaceDic.Remove(XMLAttr.Value);

        foreach TextKey in NamespaceDic.Keys do begin
            NamespaceDic.Get(TextKey, DicTextValue);
            XMLHeaderNode.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration(DicTextValue, TextKey))
        end;
    end;

    local procedure InitializeNamespaceDictionary(var NamespaceDic: Dictionary of [Text, Text])
    begin
        NamespaceDic.Set(SignatureAggregateComponentsNamespace, SignatureAggregateComponentsNamespacePrefix);
        NamespaceDic.Set(SignatureBasicComponentsNamespace, SignatureBasicComponentsNamespacePrefix);
        NamespaceDic.Set(CommonSignatureComponentsNamespace, CommonSignatureComponentsNamespacePrefix);
        NamespaceDic.Set(CommonExtensionComponentsNamespace, CommonExtensionComponentsNamespacePrefix);

    end;

    local procedure InitializeUBLExtensionsDictionary(var UBLExtensionsDic: Dictionary of [Text, Text])
    begin
        UBLExtensionsDic.Set(UBLExtensionsTag, CommonExtensionComponentsNamespace);
        UBLExtensionsDic.Set(UBLExtensionTag, CommonExtensionComponentsNamespace);
        UBLExtensionsDic.Set(ExtensionContentTag, CommonExtensionComponentsNamespace);
    end;

    local procedure CreateEndpoint(TokenValue: Text; DocumentSendingProfileCode: Code[20]) EndpointAdderss: Text
    var
        JsonObj: JsonObject;
        JsonTok: JsonToken;
        EndpointValue: Text;
        BaseURL: Text;
        WebRequestHelper: Codeunit "Web Request Helper";
    begin
        EndpointAdderss := CreateEndpoint(TokenValue, eInvoiceSetupManagement.GeteInvoiceSetupGlobalFromDocSend(DocumentSendingProfileCode));
    end;

    local procedure CreateEndpoint(TokenValue: Text; eInvoiceSetup: Record "eInvoice Setup-BET") EndpointAdderss: Text
    var
        JsonObj: JsonObject;
        JsonTok: JsonToken;
        EndpointValue: Text;
        BaseURL: Text;
        WebRequestHelper: Codeunit "Web Request Helper";
    begin
        EndpointValue := eInvoiceSetupManagement.GetSetupFromToken(TokenValue, eInvoiceSetup);

        BaseURL := eInvoiceSetup.GetBaseURL();

        if BaseURL[StrLen(BaseURL)] <> '/' then
            BaseURL += '/';

        if EndpointValue[1] = '/' then
            EndpointValue := CopyStr(EndpointValue, 2);

        EndpointAdderss := BaseURL + EndpointValue;

        if not WebRequestHelper.IsValidUri(EndpointAdderss) then
            Error(GetLAstErrorText());
    end;

    local procedure UpdateJson(Token: Text; value: Text; JsonObj: JsonObject; ListOfKeys: List of [Text]) DoModify: Boolean
    begin
        DoModify := JsonObj.Add(Token, value);

        if ListOfKeys.Remove(Token) then;
    end;


    var
        EmptyErrLbl: Label '%1 must not be empty.';
        eInvoiceSetupManagement: Codeunit "eInvoice Setup Management-BET";
        SendB2BOutgoingInvoicePKIWebServiceTokenLabel: Label 'Send B2B Sufix Address';
        SendB2BOutgoingInvoicePKIWebServiceTokenEchoLabel: Label 'Send B2B Outgoing Invoice Echo SOAP Action';
        SendB2BOutgoingInvoicePKIWebServiceTokenStatusLabel: Label 'Send B2B Outgoing Invoice Status SOAP Action';
        SendB2BOutgoingInvoicePKIWebServiceTokenSendLabel: Label 'Send B2B Outgoing Invoice Send SOAP Action';
        B2BFinaInvoiceWebServiceTokenEchoActionLabel: Label 'B2B Fina Invoice Echo SOAP Action';
        B2BFinaInvoiceWebServiceTokenIncomingListActionLabel: Label 'B2B Fina Incoming Invoice List SOAP Action';
        B2BFinaInvoiceWebServiceTokenIncomingInvoiceActionLabel: Label 'B2B Fina Get Incoming List SOAP Action';
        B2BFinaInvoiceWebServiceLabel: Label 'B2B Fina Invoice Sufix Address';
        URLPrezTokenValue: Label 'https://prez.fina.hr/', Locked = true;
        ServicesToken: Label 'services', Locked = true;
        B2BFinaInvoiceWebServiceTokenEchoActionValue: Label 'http://fina.hr/eracun/b2b/EchoBuyer', Locked = true;
        B2BFinaInvoiceWebServiceTokenIncomingListActionValue: Label 'http://fina.hr/eracun/b2b/GetB2BIncomingInvoiceList', Locked = true;
        B2BFinaInvoiceWebServiceTokenIncomingInvoiceActionValue: Label 'http://fina.hr/eracun/b2b/GetB2BIncomingInvoice', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenActionEchoValue: Label 'http://fina.hr/eracun/b2b/Echo', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenStatusActionValue: Label 'http://fina.hr/eracun/b2b/GetB2BOutgoingInvoiceStatus', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenSendActionValue: Label 'http://fina.hr/eracun/b2b/SendB2BOutgoingInvoice', Locked = true;
        #region Tokens
        B2BFinaInvoiceWebServiceTokenEchoAction: Label 'B2BFinaInvoiceWebServiceTokenEchoAction', Locked = true;
        B2BFinaInvoiceWebServiceTokenIncomingListAction: Label 'B2BFinaInvoiceWebServiceTokenIncomingListAction', Locked = true;
        B2BFinaInvoiceWebServiceTokenIncomingInvoiceAction: Label 'B2BFinaInvoiceWebServiceTokenIncomingInvoiceAction', Locked = true;
        B2BFinaInvoiceWebServiceToken: Label 'B2BFinaInvoiceWebService', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceToken: Label 'SendB2BOutgoingInvoicePKIWebService', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenEchoAction: Label 'SendB2BOutgoingInvoicePKIWebServiceTokenEchoAction', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenStatusAction: Label 'SendB2BOutgoingInvoicePKIWebServiceTokenAction', Locked = true;
        SendB2BOutgoingInvoicePKIWebServiceTokenSendAction: Label 'SendB2BOutgoingInvoicePKIWebServiceTokenSendAction', Locked = true;
        SignatureAggregateComponentsNamespace: Label 'urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2', Locked = true;
        SignatureAggregateComponentsNamespacePrefix: Label 'sac', Locked = true;
        SignatureBasicComponentsNamespace: Label 'urn:oasis:names:specification:ubl:schema:xsd:SignatureBasicComponents-2', Locked = true;
        SignatureBasicComponentsNamespacePrefix: Label 'sbc', Locked = true;
        CommonSignatureComponentsNamespace: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2', Locked = true;
        CommonSignatureComponentsNamespacePrefix: Label 'sig', Locked = true;
        CommonExtensionComponentsNamespace: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2', Locked = true;
        CommonExtensionComponentsNamespacePrefix: Label 'ext', Locked = true;
        EchoBuyerv01Namespace: Label 'http://fina.hr/eracun/b2b/EchoBuyer/v0.1', Locked = true;
        xmldsigNamespace: Label 'http://www.w3.org/2000/09/xmldsig#', Locked = true;
        UBLExtensionsTag: Label 'UBLExtensions', Locked = true;
        UBLExtensionTag: Label 'UBLExtension', Locked = true;
        ExtensionContentTag: Label 'ExtensionContent', Locked = true;
        UBLDocumentSignaturesTag: Label 'UBLDocumentSignatures', Locked = true;
        SignatureInformationTag: Label 'SignatureInformation', Locked = true;
        SignaturePropertiesTag: Label 'SignatureProperties', Locked = true;
        ReferenceTag: Label 'Reference', Locked = true;
        SignatureTag: Label 'Signature', Locked = true;
        ObjectTag: Label 'Object', Locked = true;
        IdTag: Label 'Id', Locked = true;
        SignaturePropertyTag: Label 'SignatureProperty', Locked = true;
        TargetTag: Label 'Target', Locked = true;
        AdobeNamespace: Label 'http://ns.adobe.com/pdf/2006', Locked = true;
        NameTag: Label 'Name', Locked = true;
        MTag: Label 'M', Locked = true;
        X509DataTag: Label 'X509Data', Locked = true;
        X509CertificateTag: Label 'X509Certificate', Locked = true;
        #endregion
        EnvelopeTag: Label 'Envelope', Locked = true;
        GetB2BIncomingInvoicev01: Label 'http://fina.hr/eracun/b2b/sync/GetB2BIncomingInvoice/v0.1', Locked = true;
        GetB2BIncomingInvoiceListv01Namespace: Label 'http://fina.hr/eracun/b2b/sync/GetB2BIncomingInvoiceList/v0.1', Locked = true;
        envelopeNamespace: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        encodingNamespace: Label 'http://schemas.xmlsoap.org/soap/encoding/', Locked = true;
        SendB2BOutgoingInvoicev01Namespace: Label 'http://fina.hr/eracun/b2b/pki/SendB2BOutgoingInvoice/v0.1', Locked = true;
        Echov01Namespace: Label 'http://fina.hr/eracun/b2b/pki/Echo/v0.1', Locked = true;
        GetB2BOutgoingInvoiceStatusv01Namespace: Label 'http://fina.hr/eracun/b2b/pki/GetB2BOutgoingInvoiceStatus/v0.1', Locked = true;
        invoicewebservicecomponentsNamespace: Label 'http://fina.hr/eracun/b2b/invoicewebservicecomponents/v0.1', Locked = true;
        XMLSchemaNamespace: Label 'http://www.w3.org/2001/XMLSchema', Locked = true;
        XMLSchemainstanceNamespace: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        v0Prefix: Label 'v0', Locked = true;
        v1Prefix: Label 'v01', Locked = true;
        xsdPrefix: Label 'xsd', Locked = true;
        xsiPrefix: Label 'xsi', Locked = true;
        soapencPrefix: Label 'soapenc', Locked = true;
        soapenvPrefix: Label 'soapenv', Locked = true;
        eInvoiceSetupGlobal: Record "eInvoice Setup-BET";
        GotGlobaleInvoice: Boolean;
        AccountingSupplierPartyTag: Label 'AccountingSupplierParty', Locked = true;
        AccountingCustomerPartyTag: Label 'AccountingCustomerParty', Locked = true;
        EndpointIDTag: Label 'EndpointID', Locked = true;
        schemeID: Label 'schemeID', Locked = true;
        HeaderTag: Label 'Header', Locked = true;
        SecurityTag: Label 'Security', Locked = true;
        mustUnderstandTag: Label 'mustUnderstand', Locked = true;
        BinarySecurityTokenTag: Label 'BinarySecurityToken', Locked = true;
        EncodingTypeTag: Label 'EncodingType', Locked = true;
        ValueTypeTag: Label 'ValueType', Locked = true;
        TimestampTag: Label 'Timestamp', Locked = true;
        CreatedTag: Label 'Created', Locked = true;
        ExpiresTag: Label 'Expires', Locked = true;
        BodyTag: Label 'Body', Locked = true;
        wssePrefix: Label 'wsse', Locked = true;
        wsuPrefix: Label 'wsu', Locked = true;
        oasis200401wsswssecuritysecext10Namespace: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;
        oasis200401wsswssecurityutility10Namespace: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd', Locked = true;
        EncodingTypeNamespace: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary', Locked = true;
        ValueTypeNamespace: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3', Locked = true;
        SendB2BOutgoingInvoiceMsgTag: Label 'SendB2BOutgoingInvoiceMsg', Locked = true;
        HeaderSupplierTag: Label 'HeaderSupplier', Locked = true;
        MessageIDTag: Label 'MessageID', Locked = true;
        SupplierIDTag: Label 'SupplierID', Locked = true;
        MessageTypeTag: Label 'MessageType', Locked = true;
        MessageType9999Value: Label '9999', Locked = true;
        MessageType9011Value: Label '9011', Locked = true;
        MessageType9001Value: Label '9001', Locked = true;
        DataTag: Label 'Data', Locked = true;
        B2BOutgoingInvoiceEnvelopeTag: Label 'B2BOutgoingInvoiceEnvelope', Locked = true;
        XMLStandardTag: Label 'XMLStandard', Locked = true;
        UBLValue: Label 'UBL', Locked = true;
        SpecificationIdentifierTag: Label 'SpecificationIdentifier', Locked = true;
        SupplierInvoiceIDTag: Label 'SupplierInvoiceID', Locked = true;
        BuyerIDTag: Label 'BuyerID', Locked = true;
        InvoiceEnvelopeTag: Label 'InvoiceEnvelope', Locked = true;
        CreditNoteEnvelopeTag: Label 'CreditNoteEnvelope', Locked = true;
        XmlDsigRSASHA256Url: Label 'http://www.w3.org/2000/09/xmldsig#rsa-sha1';
        XmlDsigSHA256Url: Label 'http://www.w3.org/2000/09/xmldsig#sha1';
        EchoMsgTag: Label 'EchoMsg', Locked = true;
        EchoDataTag: Label 'EchoData', Locked = true;
        EchoTag: Label 'Echo', Locked = true;
        EchoBuyerMsgTag: Label 'EchoBuyerMsg', Locked = true;
        InvoiceStatusTag: Label 'InvoiceStatus', Locked = true;
        DateRangeTag: Label 'DateRange', Locked = true;
        FromTag: Label 'From', Locked = true;
        ToTag: Label 'To', Locked = true;
        GetB2BIncomingInvoiceListMsgTag: Label 'GetB2BIncomingInvoiceListMsg', Locked = true;
        B2BIncomingInvoiceListTag: Label 'B2BIncomingInvoiceList', Locked = true;
        HeaderBuyerTag: Label 'HeaderBuyer', Locked = true;
        MessageType9101Value: Label '9101', Locked = true;
        FilterTag: Label 'Filter', Locked = true;
        schemeIDTag: Label 'schemeID', Locked = true;
        PostalAddressTag: Label 'PostalAddress', Locked = true;
        AttachmentTag: Label 'Attachment', Locked = true;
        InvoiceTypeCodeTag: Label 'InvoiceTypeCode', Locked = true;
        DocumentCurrencyCodeTag: Label 'DocumentCurrencyCode', Locked = true;
        TaxCurrencyCodeTag: Label 'TaxCurrencyCode', Locked = true;
        DueDateTag: Label 'DueDate', Locked = true;
        ProfileIDTag: Label 'ProfileID', Locked = true;
        NoteTag: Label 'Note', Locked = true;
        soapPrefix: Label 'soap', Locked = true;
        BodyPathTxt: Label '/soap:Envelope/soap:Body', Locked = true;
        WrongUsageErr: Label 'Wrong Usage!';
        B2BOutgoingInvoiceStatusTag: Label 'B2BOutgoingInvoiceStatus', Locked = true;
        InvoiceYearTag: Label 'InvoiceYear', Locked = true;
        GetB2BOutgoingInvoiceStatusMsgTag: Label 'GetB2BOutgoingInvoiceStatusMsg', Locked = true;
        EmailScheme: Label 'EM', Locked = true;
        ElectronicMailTag: Label 'ElectronicMail', Locked = true;
        InvoiceIDTag: Label 'InvoiceID', Locked = true;
        B2BIncomingInvoiceTag: Label 'B2BIncomingInvoice', Locked = true;
        InvoiceIssueDateTag: Label 'InvoiceIssueDate', Locked = true;
        StatusCodeTag: Label 'StatusCode', Locked = true;
        SupplierCompanyIDTag: Label 'SupplierCompanyID', Locked = true;
        SupplierRegistrationNameTag: Label 'SupplierRegistrationName', Locked = true;
        DocumentTypeTextTag: Label 'DocumentTypeText', Locked = true;
        SecurityTokenReferenceTag: Label 'SecurityTokenReference', Locked = true;
        URITag: Label 'URI', Locked = true;
        GetB2BIncomingInvoiceMsgTag: Label 'GetB2BIncomingInvoiceMsg', Locked = true;
        MessageType9103Value: Label '9103', Locked = true;
        StreetNameTag: Label 'StreetName', Locked = true;
        CityNameTag: Label 'CityName', Locked = true;
        PostalZoneTag: Label 'PostalZone', Locked = true;
        IdentificationCodeTag: Label 'IdentificationCode', Locked = true;
        CompanyIDTag: Label 'CompanyID', Locked = true;
        RegistrationNameTag: Label 'RegistrationName', Locked = true;
}
