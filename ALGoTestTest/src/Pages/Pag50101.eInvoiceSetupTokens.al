page 50101 "eInvoice Setup Tokens-BET"
{
    ApplicationArea = All;
    Caption = 'eInvoice Setup Tokens';
    PageType = List;
    SourceTable = Integer;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(TokenName; IeInvoice.GetSetupCaption(TokenName))
                {
                    Caption = 'Setup Name';
                    ApplicationArea = All;
                    Enabled = false;
                }
                field(TokenValue; TokenValue)
                {
                    Caption = 'Setup Value';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        SetValue();
                    end;
                }
            }
        }
    }
    trigger OnClosePage()
    begin
        SaveNewValues()
    end;

    trigger OnAfterGetRecord()
    begin
        GetValues();
    end;

    local procedure SaveNewValues()
    var
        OutStr: OutStream;
        NewJsonObj: JsonObject;
        JsonTok: JsonToken;
        JsonVal: JsonValue;
    begin
        eInvoiceSetup.Data.CreateOutStream(OutStr);
        foreach TokenName in ListOfKeys do begin
            JsonObj.Get(TokenName, JsonTok);
            JsonVal := JsonTok.AsValue();
            NewJsonObj.Add(TokenName, JsonVal);
        end;
        NewJsonObj.WriteTo(OutStr);
        eInvoiceSetup.Modify();
    end;

    local procedure SetValue()
    var
        JsonTok: JsonToken;
        JsonVal: JsonValue;
    begin
        ListOfKeys.Get(Rec.Number, TokenName);
        JsonObj.Get(TokenName, JsonTok);
        JsonVal := JsonTok.AsValue();
        JsonVal.SetValue(TokenValue);
        JsonObj.Replace(TokenName, JsonVal);
    end;

    local procedure GetValues()
    var
        JsonTok: JsonToken;
    begin
        ListOfKeys.Get(Rec.Number, TokenName);
        JsonObj.Get(TokenName, JsonTok);
        TokenValue := JsonTok.AsValue().AsText();
    end;

    procedure SeteInvoiceSetup(var eInvoiceSetupPrm: Record "eInvoice Setup-BET")
    begin
        eInvoiceSetup := eInvoiceSetupPrm;
        IeInvoice := eInvoiceSetup.Implementator;

        if IeInvoice.InitJsonSetup(eInvoiceSetup) then begin
            eInvoiceSetup.Modify();
            Commit();
        end;


        JsonObj := eInvoiceStupManagement.GetInvoiceSetup(eInvoiceSetup);
        ListOfKeys := JsonObj.Keys;
        Rec.SetRange(Number, 1, ListOfKeys.Count);

    end;

    var
        ListOfKeys: List of [Text];
        eInvoiceSetup: Record "eInvoice Setup-BET";
        IeInvoice: Interface "IeInvoice-BET";
        eInvoiceStupManagement: Codeunit "eInvoice Setup Management-BET";
        JsonObj: JsonObject;
        TokenName: Text;
        TokenValue: Text;
}
