enum 50100 "eInvoice Setup Implement.-BET" implements "IeInvoice-BET"
{
    Extensible = true;
    UnknownValueImplementation = "IeInvoice-BET" = "UnknownImplementator-BET";
    DefaultImplementation = "IeInvoice-BET" = "UnknownImplementator-BET";
    value(0; " ")
    {
        Caption = '';

    }
    value(1; FINA)
    {
        Caption = 'FINA';
        Implementation = "IeInvoice-BET" = "Fina Implementator-BET";
    }
}
