codeunit 50010 "Example Json creation"
{
    procedure ExampleOne()
    var
        MyJobject: JsonObject;
    begin
        MyJobject.Add('A Key', 'Example One');
        MyJobject.Add('Another Key', 'Another Value');
        MyJobject.Add('Number Value', 42);
        MyJobject.Add('Boolean Value', false);
    end;

    procedure ExampleTwo()
    var
        MyJobject: JsonObject;
        NestedJObject: JsonObject;
    begin
        MyJobject.Add('A Key', 'Example Two');

        NestedJObject.Add('First Nested Key', 'nested value');
        NestedJObject.Add('Second Nested Key', 'some other value');
        MyJobject.Add('Nested thing', NestedJObject);
    end;

    procedure ExampleThree()
    var
        MyJobject: JsonObject;
        ThingJObject: JsonObject;
        MyJArray: JsonArray;
    begin
        MyJobject.Add('A Key', 'Example Three');

        Clear(ThingJObject);
        ThingJObject.Add('name', 'thing 1');
        ThingJObject.Add('age', 10);
        MyJArray.Add(ThingJObject);

        Clear(ThingJObject);
        ThingJObject.Add('name', 'thing 2');
        ThingJObject.Add('age', 12);
        MyJArray.Add(ThingJObject);

        MyJobject.Add('List of Things', MyJArray);
    end;

    var
        myInt: Integer;
}