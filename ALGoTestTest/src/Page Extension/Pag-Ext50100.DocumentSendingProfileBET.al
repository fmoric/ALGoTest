pageextension 50100 "Document Sending Profile-BET" extends "Document Sending Profile"
{

    layout
    {
        modify("Electronic Document")
        {
            trigger OnAfterValidate()
            begin
                SetVisible();
            end;
        }
        addlast("Sending Options")
        {
            group(BetGroup)
            {
                ShowCaption = false;
                Visible = UBLDeliveryVisible;
                field("UBL Document Delivery-BET"; Rec."UBL Document Delivery-BET")
                {

                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the UBL Document Delivery-BET field.';
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        SetVisible();
    end;

    local procedure SetVisible()
    begin
        UBLDeliveryVisible := Rec."Electronic Document" = Rec."Electronic Document"::"Be-Terna UBL Document Delivery";
    end;

    var
        UBLDeliveryVisible: Boolean;
}
