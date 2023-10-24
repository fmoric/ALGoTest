permissionset 50100 GeneratedPermission
{
    Assignable = true;
    Permissions = tabledata "eInvoice Header-BET"=RIMD,
        tabledata "eInvoice Setup-BET"=RIMD,
        table "eInvoice Header-BET"=X,
        table "eInvoice Setup-BET"=X,
        codeunit "Be-Terna UBL Delivery-BET"=X,
        codeunit "eInvoice Setup Management-BET"=X,
        codeunit "Fina Implementator-BET"=X,
        codeunit "UnknownImplementator-BET"=X,
        page "eInvoice Input-BET"=X,
        page "eInvoice Setup Card"=X,
        page "eInvoice Setup FactBox"=X,
        page "eInvoice Setup List-BET"=X,
        page "eInvoice Setup Tokens-BET"=X,
        page "eInvoice-BET"=X,
        page "eInvoices-BET"=X;
}