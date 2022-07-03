codeunit 50104 "JSON Managment"
{
    trigger OnRun()
    begin
        //ExportCustomerJSON();
        //SalesOrderToJson();
        ReadSalesOrderJson();
    end;

    local procedure ExportCustomerJSON()
    var
        Customer: Record Customer;
        CustomerJObject: JsonObject;
        JObject: JsonObject;
        JArr: JsonArray;
    begin
        if Customer.FindSet() then;
        CustomerJObject.Add('no', Customer."No.");
        CustomerJObject.Add('name', Customer."Name");
        CustomerJObject.Add('address', Customer.Address);
        CustomerJObject.Add('city', Customer.City);
        CustomerJObject.Add('country', Customer."Country/Region Code");

        DownloadJSONFile(CustomerJObject);
    end;

    local procedure SalesOrderToJson(): JsonObject
    var
        SalesHeader: Record "Sales Header";
        JSalesOrder: JsonObject;
    begin
        if SalesHeader.FindFirst() then;
        JSalesOrder.Add('orderNo', SalesHeader."No.");
        JSalesOrder.Add('orderDate', SalesHeader."Order Date");
        JSalesOrder.Add('sellToCustomerNo', SalesHeader."Sell-to Customer No.");
        JSalesOrder.Add('amountIncludingVAT', SalesHeader."Amount Including VAT");
        JSalesOrder.Add('isApprovedForPosting', SalesHeader.IsApprovedForPosting());
        JSalesOrder.Add('lines', SalesLinesToJson(SalesHeader)); //Fill Lines into JArray

        DownloadJSONFile(JSalesOrder);
    end;

    local procedure SalesLinesToJson(SalesHeader: Record "Sales Header"): JsonArray
    var
        SalesLine: Record "Sales Line";
        JSalesLines: JsonArray;
        JSalesLine: JsonObject;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                // Sales Line Attributes
                Clear(JSalesLine);
                JSalesLine.Add('type', SalesLine.Type.AsInteger());
                JSalesLine.Add('no', SalesLine."No.");
                JSalesLine.Add('quantity', SalesLine.Quantity);
                JSalesLine.Add('unitPrice', SalesLine."Unit Price");
                JSalesLine.Add('amount', SalesLine."Line Amount");

                JSalesLines.Add(JSalesLine);
            until SalesLine.Next() = 0;

        exit(JSalesLines);
    end;

    local procedure ReadSalesOrderJson()
    var
        SalesHeader: Record "Sales Header";
        JSalesOrder: JsonObject;
        JOrderNoToken: JsonToken;
        JOrderDateToken: JsonToken;
        JSellToCustomerNoToken: JsonToken;
        JLinesToken: JsonToken;
        JLinesArray: JsonArray;
        Filename: Text;
        Instr: InStream;
    begin
        if not UploadIntoStream('Select File to Upload', '', '', Filename, Instr) then
            exit;

        JSalesOrder.ReadFrom(Instr);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        if JSalesOrder.Get('orderNo', JOrderNoToken) then
            SalesHeader.Validate("No.", JOrderNoToken.AsValue().AsCode());

        if JSalesOrder.Get('orderDate', JOrderDateToken) then
            SalesHeader.Validate("Order Date", JOrderDateToken.AsValue().AsDate());

        if JSalesOrder.Get('sellToCustomerNo', JSellToCustomerNoToken) then
            SalesHeader.Validate("Sell-to Customer No.", JSellToCustomerNoToken.AsValue().AsCode());

        SalesHeader.Insert(true);

        if JSalesOrder.Get('lines', JLinesToken) then begin
            JLinesArray := JLinesToken.AsArray(); // Array of Objects
            ReadSalesLinesJson(JLinesArray, SalesHeader);
        end;
    end;

    local procedure ReadSalesLinesJson(JSalesLines: JsonArray; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        JSalesLineToken: JsonToken;
        JSalesLine: JsonObject;
        JTypeToken: JsonToken;
        JNoToken: JsonToken;
        JQuantityToken: JsonToken;
    begin
        foreach JSalesLineToken in JSalesLines do begin
            JSalesLine := JSalesLineToken.AsObject();
            SalesLine.Init();
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
            SalesLine.Validate("Line No.", GetSalesLineNo(SalesHeader));

            if JSalesLine.Get('type', JTypeToken) then
                SalesLine.Validate(Type, "Sales Line Type".FromInteger(JTypeToken.AsValue().AsInteger()));

            if JSalesLine.Get('no', JNoToken) then
                SalesLine.Validate("No.", JNoToken.AsValue().AsCode());

            if JSalesLine.Get('quantity', JQuantityToken) then
                SalesLine.Validate(Quantity, JQuantityToken.AsValue().AsDecimal());

            SalesLine.Insert(true);
        end;
    end;

    local procedure DownloadJSONFile(var JObject: JsonObject)
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        WriteText: Text;
    begin
        TempBlob.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        JObject.WriteTo(OutStr);
        OutStr.WriteText(WriteText);
        InStr.ReadText(WriteText);
        FileName := 'Test.json';
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    local procedure GetSalesLineNo(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            Exit(SalesLine."Line No." + 10000);

        exit(10000);
    end;
}