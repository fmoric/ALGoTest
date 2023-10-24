page 50102 "eInvoice Setup FactBox"
{
    ApplicationArea = All;
    Caption = 'eInvoice Setup FactBox';
    PageType = CardPart;
    SourceTable = "eInvoice Setup-BET";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Cert. Exp. Warning Date"; Rec."Cert. Exp. Warning Date")
                {
                    ToolTip = 'Specifies the value of the Cert. Expiration Warning Date field.';
                }
                field("Cert. Expiration Date"; Rec."Cert. Expiration Date")
                {
                    ToolTip = 'Specifies the value of the Cert. Expiration Date field.';
                }
                field("Cert. Friendly Name"; Rec."Cert. Friendly Name")
                {
                    ToolTip = 'Specifies the value of the Cert. Friendly Name field.';
                }
                field("Cert. Has Priv. Key"; Rec."Cert. Has Priv. Key")
                {
                    ToolTip = 'Specifies the value of the Cert. Has Priv. Key field.';
                }
                field("Cert. Issued By"; Rec."Cert. Issued By")
                {
                    ToolTip = 'Specifies the value of the Cert. Issued By field.';
                }
                field("Cert. Issued To"; Rec."Cert. Issued To")
                {
                    ToolTip = 'Specifies the value of the Cert. Issued To field.';
                }
                field("Cert. ThumbPrint"; Rec."Cert. ThumbPrint")
                {
                    ToolTip = 'Specifies the value of the Cert. ThumbPrint field.';
                }
            }
        }
    }
}
