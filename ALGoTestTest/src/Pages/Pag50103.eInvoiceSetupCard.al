page 50103 "eInvoice Setup Card"
{
    ApplicationArea = All;
    Caption = 'eInvoice Setup Card';
    PageType = Card;
    SourceTable = "eInvoice Setup-BET";
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.';
                    trigger OnValidate()
                    begin
                        SetInitialPage();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(Implementator; Rec.Implementator)
                {
                    ToolTip = 'Specifies the value of the Implementator field.';
                    Enabled = not IsEnabled;
                    trigger OnValidate()
                    begin
                        SetInitialPage();
                    end;
                }
                field(BaseURL; BaseURL)
                {
                    Caption = 'Service Base URL';
                    Enabled = not IsEnabled;
                    ToolTip = 'Specifies the value of the Service Base URL field.';
                    trigger OnValidate()
                    begin
                        Rec.SetBaseURL(BaseURL);
                    end;
                }
                field(Enable; Rec.Enable)
                {
                    ToolTip = 'Specifies the value of the Enable field.';
                    trigger OnValidate()
                    begin
                        SetInitialPage();
                    end;
                }
                field(Default; Rec.Default)
                {
                    ToolTip = 'Specifies the value of the Default field.';
                }
            }
            group(Certificate)
            {
                Caption = 'Certificate';
                Visible = HasCertificate;
                field("Cert. Expiration Warning"; Rec."Cert. Expiration Warning")
                {
                    Editable = HasCertificate;
                    ToolTip = 'Specifies the value of the Cert. Expiration Warning (Days) field.';
                }
                field("Cert. Expiration Date"; Rec."Cert. Expiration Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Expiration Date field.';
                }
                field("Cert. Exp. Warning Date"; Rec."Cert. Exp. Warning Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Expiration Warning Date field.';
                }
                field("Cert. Friendly Name"; Rec."Cert. Friendly Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Friendly Name field.';
                }
                field("Cert. Has Priv. Key"; Rec."Cert. Has Priv. Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Has Priv. Key field.';
                }
                field("Cert. Issued By"; Rec."Cert. Issued By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Issued By field.';
                }
                field("Cert. Issued To"; Rec."Cert. Issued To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. Issued To field.';
                }
                field("Cert. ThumbPrint"; Rec."Cert. ThumbPrint")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cert. ThumbPrint field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Send Echo")
            {
                Image = TestFile;
                Enabled = EnableActions;
                ApplicationArea = All;
                Caption = 'Send Echo';
                ToolTip = 'Executes the Send Echo action';
                trigger OnAction();
                var
                    IeInvoice: Interface "IeInvoice-BET";
                begin
                    IeInvoice := Rec.Implementator;
                    IeInvoice.SendEcho(Rec);
                end;
            }
            action("Upload Certificate")
            {
                Image = Import;
                Enabled = EnableActions;
                ApplicationArea = All;
                Caption = 'Upload Certificate';
                ToolTip = 'Executes the Upload Certificate action';
                trigger OnAction();
                var
                    EInvoiceSetupMgmt: Codeunit "eInvoice Setup Management-BET";
                begin
                    EInvoiceSetupMgmt.UploadCert(Rec);
                end;
            }
            action(ActionSetup)
            {
                Image = Setup;
                ApplicationArea = All;
                Caption = 'Setup';
                ToolTip = 'Executes the Setup action';
                Enabled = EnableActions and not IsEnabled;
                trigger OnAction()
                var
                    eInvSetupCard: Page "eInvoice Setup Tokens-BET";
                begin
                    eInvSetupCard.SeteInvoiceSetup(Rec);
                    eInvSetupCard.RunModal();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetInitialPage();
    end;

    local procedure SetInitialPage()
    begin
        SetHasCertificate();
        EnableActions := Rec.Code <> '';
        BaseURL := Rec.GetBaseURL();
        IsEnabled := Rec.Enable;
    end;

    local procedure SetHasCertificate()
    begin
        HasCertificate := not IsNullGuid(Rec."Certificate GUID");
    end;

    var
        IsEnabled: Boolean;
        HasCertificate: Boolean;
        BaseURL: Text;
        EnableActions: Boolean;

}
