page 50100 "eInvoice Setup List-BET"
{
    ApplicationArea = All;
    Caption = 'eInvoice Setup List';
    PageType = List;
    Editable = false;
    SourceTable = "eInvoice Setup-BET";
    UsageCategory = Administration;
    CardPageId = "eInvoice Setup Card";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(Implementator; Rec.Implementator)
                {
                    ToolTip = 'Specifies the value of the Implementator field.';
                }
                field(Enable; Rec.Enable)
                {
                    ToolTip = 'Specifies the value of the Enable field.';
                }
                field(HasCertificate; HasCertificate)
                {
                    Editable = false;
                    Caption = 'Has Certificate';
                    ToolTip = 'Specifies the value of the Has Certificate field.';
                }
                field(Default; Rec.Default)
                {
                    ToolTip = 'Specifies the value of the Default field.';
                }
            }
        }
        area(factboxes)
        {
            part("eInvoice Setup FactBox"; "eInvoice Setup FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'Certificate';
                Visible = HasCertificate;
                SubPageLink = Code = field(Code);
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Upload Certificate")
            {
                Image = TestFile;
                // Visible = CertificateVisible;
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
                Image = TestFile;
                // Visible = CertificateVisible;
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
    var
        HasCertificate: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        SetHasPageFeatures();
    end;

    trigger OnAfterGetRecord()
    begin
        SetHasPageFeatures();
    end;

    local procedure SetHasPageFeatures()
    var
        IeInvoice: Interface "IeInvoice-BET";
    begin
        HasCertificate := not IsNullGuid(Rec."Certificate GUID");
        IsEnabled := Rec.Enable;
        EnableActions := Rec.Code <> '';
        IeInvoice := Rec.Implementator;
        // IeInvoice.InitJsonSetup(Rec);
        // if Rec.Modify() then;
    end;

    local procedure UpdateJsonSetup()
    var
        myInt: Integer;
    begin

    end;

    var
        IsEnabled: Boolean;
        EnableActions: Boolean;
}
