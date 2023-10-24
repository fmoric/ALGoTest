table 50100 "eInvoice Setup-BET"
{
    Caption = 'eInvoice Setup';
    DataClassification = CustomerContent;
    DataCaptionFields = Code, Description;
    LookupPageId = "eInvoice Setup List-BET";
    DrillDownPageId = "eInvoice Setup List-BET";
    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Implementator"; Enum "eInvoice Setup Implement.-BET")
        {
            DataClassification = CustomerContent;
            Caption = 'Implementator';
            trigger OnValidate()
            begin
                InitializeSetup();
            end;
        }
        field(4; "Base URL"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Base URL';
        }
        field(5; Enable; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enable';
            trigger OnValidate()
            var
                IeInvoice: Interface "IeInvoice-BET";
            begin
                IeInvoice := Rec.Implementator;
                IeInvoice.CheckEnable(Rec);
            end;
        }
        field(6; "Default"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Default';
            trigger OnValidate()
            var
                eInvoiceSetup: Record "eInvoice Setup-BET";
                ConfirmMgt: Codeunit "Confirm Management";
                ConfirmLabel: Label 'Code %1 is set as default. Do you want to proceed?';
            begin
                if not Default then
                    exit;
                eInvoiceSetup.SetFilter(Code, '<>%1', Rec.Code);
                eInvoiceSetup.SetRange(Default, true);
                if eInvoiceSetup.FindFirst() then
                    if not ConfirmMgt.GetResponseOrDefault(StrSubstNo(ConfirmLabel, eInvoiceSetup.Code), true) then
                        Error('');
            end;
        }
        field(10; Data; Blob)
        {
            Caption = 'Data';
            DataClassification = SystemMetadata;
        }
        field(20; "Certificate GUID"; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(21; "Password GUID"; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(22; "Cert. Expiration Date"; DateTime)
        {
            Caption = 'Cert. Expiration Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "Cert. Has Priv. Key"; Boolean)
        {
            Caption = 'Cert. Has Priv. Key';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "Cert. ThumbPrint"; Text[50])
        {
            Caption = 'Cert. ThumbPrint';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "Cert. Issued By"; Text[250])
        {
            Caption = 'Cert. Issued By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "Cert. Issued To"; Text[250])
        {
            Caption = 'Cert. Issued To';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; "Cert. Friendly Name"; Text[50])
        {
            Caption = 'Cert. Friendly Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(28; "Cert. Expiration Warning"; Integer)
        {
            Caption = 'Cert. Expiration Warning (Days)';
            DataClassification = CustomerContent;
            MinValue = 0;
            InitValue = 7;
            trigger OnValidate()
            begin
                SetExpDate();
            end;
        }
        field(29; "Cert. Exp. Warning Date"; DateTime)
        {
            Editable = false;
            Caption = 'Cert. Expiration Warning Date';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    procedure SetBaseURL(BaseURL: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        OutStr: OutStream;

    begin
        Clear("Base URL");
        "Base URL".CreateOutStream(OutStr);
        if BaseURL <> '' then begin
            //Check if url is valid
            WebRequestHelper.IsValidUri(BaseURL);
            //Check if url http
            WebRequestHelper.IsHttpUrl(BaseURL);
            OutStr.Write(BaseURL);
        end;
    end;

    procedure GetBaseURL() BaseURL: Text
    var
        InStr: InStream;
    begin
        CalcFields("Base URL");
        "Base URL".CreateInStream(InStr);
        InStr.Read(BaseURL);
    end;
    /// <summary>
    /// SetExpdate.
    /// </summary>
    trigger OnInsert()
    begin
        InitializeSetup();
    end;

    procedure InitializeSetup()
    var
        IeInvoice: Interface "IeInvoice-BET";
    begin
        IeInvoice := Rec.Implementator;
        IeInvoice.InitializeSetup(Rec);
    end;

    local procedure SetExpDate()
    var
        DateForm: DateFormula;
        CertExpiredErr: Label 'Loaded certificate has expired.';
        CertKey: Text;
        eInvoiceSetupMgmt: Codeunit "eInvoice Setup Management-BET";
    begin
        //Get Cert
        eInvoiceSetupMgmt.IsolatedStorageGet(Rec."Certificate GUID", DataScope::Company, CertKey);
        //Check expiration
        if eInvoiceSetupMgmt.IsCertExpired(Rec) then
            Error(CertExpiredErr);
        //Evaluate exp. date warrning formula
        Evaluate(DateForm, '<-' + Format("Cert. Expiration Warning") + 'D>');
        //set  date for warrning
        "Cert. Exp. Warning Date" := CreateDateTime(CalcDate(DateForm, DT2Date("Cert. Expiration Date")), DT2Time("Cert. Expiration Date"));
    end;

}
