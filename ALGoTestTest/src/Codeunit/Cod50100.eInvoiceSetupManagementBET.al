codeunit 50100 "eInvoice Setup Management-BET"
{


    procedure GetInvoiceSetup(var eInvoiceSetup: Record "eInvoice Setup-BET") JsonObj: JsonObject;
    var
        InStr: InStream;
    begin
        eInvoiceSetup.CalcFields(Data);
        eInvoiceSetup.Data.CreateInStream(InStr);
        JsonObj.ReadFrom(InStr)
    end;
    #region Certificate Handeling
    // [NonDebuggable] TODO

    internal procedure GetCert(eInvoiceSetup: Record "eInvoice Setup-BET") StoredCert: Text
    begin
        //Get certificate
        Clear(StoredCert);
        IsolatedStorageGet(eInvoiceSetup."Certificate GUID", DataScope::Company, StoredCert);
    end;
    // [NonDebuggable] TODO
    internal procedure GetPassword(eInvoiceSetup: Record "eInvoice Setup-BET") StoredPassword: Text
    begin
        //Get password
        IsolatedStorageGet(eInvoiceSetup."Password GUID", DataScope::Company, StoredPassword);
    end;
    // [NonDebuggable] TODO
    /// <summary>
    /// UploadCert.
    /// </summary>
    internal procedure UploadCert(eInvoiceSetup: Record "eInvoice Setup-BET")
    var
        Base64Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        CertFileFilterTxt: Label 'Certificate Files (*.pfx;*.p12;*.p7b;*.cer;*.crt;*.der)|*.pfx;*.p12;*.p7b;*.cer;*.crt;*.der';
        CertExtFilterTxt: Label 'pfx,p12,p7b,cer,crt,der', Locked = true;
        SelectFileTxt: Label 'Select a certificate file';
        Base64Cert: Text;
        CertPass: Text;
        FilePath: Text;
        PasswordDlgMtgm: Codeunit "Password Dialog Management";
    begin
        //Select and upload cert
        FilePath := FileMgt.BLOBImportWithFilter(TempBlob, SelectFileTxt, '', CertFileFilterTxt, CertExtFilterTxt);
        if FilePath = '' then
            exit;
        TempBlob.CreateInStream(InStr);
        SavePasswordToIsolatedStorage(eInvoiceSetup, PasswordDlgMtgm.OpenPasswordDialog(true, true));
        //Get password
        IsolatedStorageGet(eInvoiceSetup."Password GUID", DataScope::Company, CertPass);
        //Convert Cert to base 64, Lost instr
        Base64Cert := Base64Convert.ToBase64(InStr);
        //Get password
        ValidateCertFields(eInvoiceSetup, Base64Cert, CertPass);
        //Create guid for isolated storage
        if IsNullGuid(eInvoiceSetup."Certificate GUID") then
            eInvoiceSetup."Certificate GUID" := CreateGuid();

        //Save to storage
        IsolatedStorageSet(eInvoiceSetup."Certificate GUID", Base64Cert, DataScope::Company);
        eInvoiceSetup.Modify();
    end;

    local procedure ValidateCertFields(var eInvoiceSetup: Record "eInvoice Setup-BET"; CertBase64Value: Text; Password: Text)
    var
        X509Cert2: Codeunit X509Certificate2;
        CertValue: Text;
        CertFriendlyName: Text;
        CertIssuedBy: Text;
        CertIssuedTo: Text;
        CertThumbPrint: Text;
    begin
        //Validate cert values
        CertValue := CertBase64Value;
        X509Cert2.VerifyCertificate(CertValue, Password, Enum::"X509 Content Type"::Cert);

        X509Cert2.GetCertificateExpiration(CertBase64Value, Password, eInvoiceSetup."Cert. Expiration Date");

        eInvoiceSetup.Validate("Cert. Expiration Warning");
        eInvoiceSetup.Validate("Cert. Has Priv. Key", X509Cert2.HasPrivateKey(CertBase64Value, Password));
        eInvoiceSetup.TestField("Cert. Has Priv. Key");

        X509Cert2.GetCertificateThumbprint(CertBase64Value, Password, CertThumbPrint);
        X509Cert2.GetCertificateIssuer(CertBase64Value, Password, CertIssuedBy);
        X509Cert2.GetCertificateSubject(CertBase64Value, Password, CertIssuedTo);
        X509Cert2.GetCertificateFriendlyName(CertBase64Value, Password, CertFriendlyName);

        eInvoiceSetup."Cert. ThumbPrint" := CopyStr(CertThumbPrint, 1, 50);

        RemoveCerSigns(CertIssuedBy);
        eInvoiceSetup."Cert. Issued By" := CopyStr(CertIssuedBy, 1, 250);

        RemoveCerSigns(CertIssuedTo);
        eInvoiceSetup."Cert. Issued To" := CopyStr(CertIssuedTo, 1, 250);

        RemoveCerSigns(CertFriendlyName);
        eInvoiceSetup."Cert. Friendly Name" := CopyStr(CertFriendlyName, 1, 50);

        eInvoiceSetup.Modify();
    end;
    /// <summary>
    /// IsCertExpired.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure IsCertExpired(eInvoiceSetup: Record "eInvoice Setup-BET"): Boolean
    begin
        if IsNullGuid(eInvoiceSetup."Certificate GUID") then
            exit(false);
        if eInvoiceSetup."Cert. Expiration Date" = 0DT then
            exit(false);
        //Check expiration dates
        exit(eInvoiceSetup."Cert. Expiration Date" < CurrentDateTime);
    end;

    local procedure RemoveCerSigns(var CertText: Text)
    var
        i: Integer;
        ReplaceTxt: Text;
    begin
        while StrPos(CertText, '=') <> 0 do begin
            i := StrPos(CertText, '=');
            while (i > 1) and (CertText[i] <> ' ') do
                i -= 1;

            if i = 1 then
                ReplaceTxt := CopyStr(CertText, i, StrPos(CertText, '='))
            else
                ReplaceTxt := CopyStr(CertText, i + 1, StrPos(CertText, '=') - i);

            CertText := CertText.Replace(ReplaceTxt, '');

        end;
    end;
    #endregion
    #Region Isolated Storage Handler
    [NonDebuggable]
    /// <summary>
    /// SavePasswordToIsolatedStorage.
    /// </summary>
    internal procedure SavePasswordToIsolatedStorage(var eInvoiceSetup: Record "eInvoice Setup-BET"; Password: Text)
    var
        SavingPasswordErr: Label 'Could not save the password.';
    begin
        //Insert pass. into iso storage or delete if no pass
        if Password <> '' then begin
            if not IsolatedStorageSet(eInvoiceSetup."Password GUID", Password, DataScope::Company) then
                Error(SavingPasswordErr);
        end else
            if IsolatedStorageDelete(eInvoiceSetup."Password GUID", DataScope::Company) then;
    end;

    [NonDebuggable]
    /// <summary>
    /// IsolatedStorageGet.
    /// </summary>
    /// <param name="IsolatedGUID">Guid.</param>
    /// <param name="Datascope">DataScope.</param>
    /// <param name="Value">VAR Text.</param>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure IsolatedStorageGet(var IsolatedGUID: Guid; Datascope: DataScope; var Value: Text): Boolean
    begin
        if IsNullGuid(IsolatedGUID) then
            exit(false);
        Clear(Value);
        exit(IsolatedStorage.Get(CopyStr(IsolatedGUID, 1, 200), Datascope, Value));
    end;

    [NonDebuggable]
    /// <summary>
    /// IsolatedStorageSet.
    /// </summary>
    /// <param name="IsolatedGUID">Guid.</param>
    /// <param name="Value">Text.</param>
    /// <param name="Datascope">DataScope.</param>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure IsolatedStorageSet(var IsolatedGUID: Guid; Value: Text; Datascope: DataScope): Boolean
    begin
        if IsNullGuid(IsolatedGUID) then
            IsolatedGUID := CreateGuid();
        //Set isolated storage if no encription
        if (not EncryptionEnabled()) or (StrLen(Value) > 215) then
            exit(IsolatedStorage.Set(CopyStr(IsolatedGUID, 1, 200), Value, Datascope));
        //Set isolated storage with encription
        exit(IsolatedStorage.SetEncrypted(CopyStr(IsolatedGUID, 1, 200), Value, Datascope));
    end;

    [NonDebuggable]
    /// <summary>
    /// IsolatedStorageDelete.
    /// </summary>
    /// <param name="Key">Text.</param>
    /// <param name="Datascope">DataScope.</param>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure IsolatedStorageDelete(var IsolatedGUID: Guid; Datascope: DataScope): Boolean
    begin
        if IsNullGuid(IsolatedGUID) then
            exit(false);
        //Check for content to delete
        if not IsolatedStorage.Contains(CopyStr(IsolatedGUID, 1, 200), Datascope) then
            exit(false);
        //Delete content
        exit(IsolatedStorage.Delete(CopyStr(IsolatedGUID, 1, 200), Datascope));
    end;
    #endregion
    procedure GetHeaderTag(Usage: Enum "Electronic Document Format Usage"): Text
    begin
        case Usage of
            Usage::"Sales Invoice":
                exit(GetInvoiceTag());
            Usage::"Sales Credit Memo":
                exit(GetCreditNoteTag());
        end;
    end;

    procedure GetInvoiceTag(): Text
    begin
        exit(InvoiceTag);
    end;

    procedure GetCreditNoteTag(): Text
    begin
        exit(CreditNoteTag);
    end;

    procedure GetCustomizationIDTag(): Text
    begin
        exit(CustomizationIDTag);
    end;

    procedure GetIDTag(): Text
    begin
        exit(IDTag);
    end;

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CountryReginon: Record "Country/Region";
    begin
        //TODO Subscriber
        PEPPOLManagement.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    procedure GetSetupFromToken(TokenValue: Text; DocumentSendingProfile: Code[20]) SetupValue: Text
    begin
        GeteInvoiceSetupGlobalFromDocSend(DocumentSendingProfile);
        SetupValue := GetSetupFromToken(TokenValue, eInvoiceSetupGlobal);
    end;

    procedure GetSetupFromToken(TokenValue: Text; eInvoiceSetup: Record "eInvoice Setup-BET") SetupValue: Text
    var
        JsonObj: JsonObject;
        JsonTok: JsonToken;
    begin
        JsonObj := eInvoiceSetupManagement.GetInvoiceSetup(eInvoiceSetup);
        JsonObj.Get(TokenValue, JsonTok);
        SetupValue := JsonTok.AsValue().AsText();
    end;

    procedure GeteInvoiceSetupGlobalFromDocSend(DocumentSending: Code[20]) eInvoiceSetup: Record "eInvoice Setup-BET";
    var
        DocumentProfile: Record "Document Sending Profile";
    begin
        if GotGlobaleInvoice then
            exit(eInvoiceSetupGlobal);
        DocumentProfile.Get(DocumentSending);

        eInvoiceSetupGlobal.Get(DocumentProfile."UBL Document Delivery-BET");
        GotGlobaleInvoice := true;
        exit(eInvoiceSetupGlobal);
    end;

    var
        GotGlobaleInvoice: Boolean;
        eInvoiceSetupGlobal: Record "eInvoice Setup-BET";
        eInvoiceSetupManagement: Codeunit "eInvoice Setup Management-BET";
        InvoiceTag: Label 'Invoice', Locked = true;
        CreditNoteTag: Label 'CreditNote', Locked = true;
        CustomizationIDTag: Label 'CustomizationID', Locked = true;
        IDTag: Label 'ID', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnCheckElectronicSendingEnabled', '', false, false)]
    local procedure OnCheckElectronicSendingEnabled(var ExchServiceEnabled: Boolean; var sender: Record "Document Sending Profile")
    var
        eInvoiceSetup: Record "eInvoice Setup-BET";
    begin
        if ExchServiceEnabled then
            exit;

        if sender."Electronic Document" <> sender."Electronic Document"::"Be-Terna UBL Document Delivery" then
            exit;

        if not eInvoiceSetup.Get(sender."UBL Document Delivery-BET") then
            exit;

        ExchServiceEnabled := eInvoiceSetup.Enable;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnBeforeVANDocumentReport', '', false, false)]
    local procedure OnBeforeVANDocumentReport(HeaderDoc: Variant; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var ElectronicDocumentFormat: Record "Electronic Document Format");
    begin
        if TempDocumentSendingProfile."Electronic Document" <> TempDocumentSendingProfile."Electronic Document"::"Be-Terna UBL Document Delivery" then
            exit;

        if not ElectronicDocumentFormat.Get(TempDocumentSendingProfile."Electronic Format", TempDocumentSendingProfile.Usage) then
            exit;
        ElectronicDocumentFormat.TestField("Delivery Codeunit ID", Codeunit::"Be-Terna UBL Delivery-BET");
    end;


}
