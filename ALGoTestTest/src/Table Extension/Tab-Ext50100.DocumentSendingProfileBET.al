tableextension 50100 "Document Sending Profile-BET" extends "Document Sending Profile"
{
    fields
    {
        modify("Electronic Document")
        {
            trigger OnAfterValidate()
            begin
                if "Electronic Document" <> "Electronic Document"::"Be-Terna UBL Document Delivery" then
                    "UBL Document Delivery-BET" := '';
            end;
        }
        modify("Electronic Format")
        {
            trigger OnAfterValidate()
            begin
                //TODO remove if cu not here
            end;
        }
        field(50100; "UBL Document Delivery-BET"; Code[10])
        {
            Caption = 'UBL Document Delivery-BET';
            DataClassification = CustomerContent;
            TableRelation = "eInvoice Setup-BET".Code where(Enable = filter(true));
            trigger OnValidate()
            var
                ElectronicDocumentFormat: Record "Electronic Document Format";
            begin
                if Rec."UBL Document Delivery-BET" = '' then
                    exit;
                Rec.TestField("Electronic Document", Rec."Electronic Document"::"Be-Terna UBL Document Delivery");
                Rec.TestField("Electronic Format");
                //TODO check CU for sending CU
            end;
        }
    }

}
