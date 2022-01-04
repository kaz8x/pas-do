PROGRAM main;
{$MODE OBJFPC}
USES Classes, Sysutils, fpjson, jsonparser, TypInfo, crt;
VAR input, mname, mdesc, mtime, mtickid, mdescid : String;
PROCEDURE writefile(text: String);
VAR data : TextFile;
BEGIN
    AssignFile(data, '../src/data.json');
    TRY
        rewrite(data);
        writeln(data, text);
        CloseFile(data);
    EXCEPT
        ON E: EInOutError DO
            writeln('Error while handling data file. Details: ', E.Message);
    END; 
END;
FUNCTION readfile(): String;
VAR
    s : String;
    data : TextFile;
BEGIN
    AssignFile(data, '../src/data.json');
    TRY
        reset(data);
        WHILE NOT eof(data) DO
        BEGIN
            readln(data, s);
        END;
        readfile := s;
        CloseFile(data);
    EXCEPT
        ON E: EInOutError DO
            writeln('Error while handling data file. Details: ', E.Message);
    END;
END;
PROCEDURE rendertable();
VAR
    jData : TJSONData;
    i : integer;
BEGIN
    jData := GetJSON(readfile());
    IF jData.Count = 0 THEN 
        writeln('You have no saved tasks')
    ELSE
        FOR i:= 0 TO jData.Count - 1 DO
        BEGIN
            TextColor(Black);
            TextBackground(White);
            write('|');
            TextBackground(Magenta);
            TextColor(White);
            write(TJSONObject(jData).Names[i]);
            TextBackground(White);
            TextColor(Black);
            write('|');
            write(jData.FindPath(TJSONObject(jData).Names[i] + '[0]').AsString);
            write('|');
            TextColor(White);
            CASE(jData.FindPath(TJSONObject(jData).Names[i] + '[2]').AsString) OF
                'Not complete':
                    BEGIN
                        TextBackground(Red);
                        write('Not complete');
                        TextBackground(White);
                    END;
                'Complete':
                    BEGIN
                        TextBackground(Green);
                        write('Complete');
                        TextBackground(White);
                    END;
            END;
            TextColor(Black);
            writeln('|');
            TextBackground(Black);
            TextColor(White);
        END;
    jData.Free;
END;
PROCEDURE writetodo(time, name, desc: String);
VAR
    jData : TJSONData;
    jObject : TJSONObject;
    jArray : TJSONArray;
BEGIN
    jData := GetJSON(readfile());
    jObject := jData as TJSONObject;
    jArray := TJSONArray.Create;
    jArray.Add(time);
    jArray.Add(desc);
    jArray.Add('Not complete');
    jObject.Add(name, jArray);
    writefile(jObject.AsJSON);
    jData.Free;
END;
PROCEDURE ticktodo(tickid: String);
VAR
    jData : TJSONData;
BEGIN
    jData := GetJSON(readfile());
    jData.FindPath(tickid + '[2]').AsString := 'Complete';
    writefile(jData.AsJSON);
    jData.Free;
END;
FUNCTION description(descid: String) : String;
VAR
    jData : TJSONData;
BEGIN
    jData := GetJSON(readfile());
    description := jData.FindPath(descid + '[1]').AsString;
    jData.Free;
END;
PROCEDURE purge();
VAR
    jData : TJSONData;
    jObject : TJSONObject;
    i : Integer;
BEGIN
    jData := GetJSON(readfile());
    jObject := jData as TJSONObject;
    FOR i := 0 TO jData.Count - 1 DO
    BEGIN
        CASE(jData.FindPath(TJSONObject(jData).Names[i] + '[2]').AsString) OF
            'Not complete' : ;
            'Complete' :
                BEGIN
                    write('Still alive');
                    jObject.Delete(jObject.Names[i]);
                END;
        END;
    END;
    writefile(jObject.AsJSON);
    jData.Free;
END;
BEGIN
    //ENTRY
    TextBackground(Black);
    WHILE TRUE DO
    BEGIN
        clrscr;
        rendertable();
        write('->');
        readln(input);
        CASE(input) OF
            'purge' :
                BEGIN
                    //purge();
                END;
            'description' :
                BEGIN
                    TextColor(Green);
                    write('Enter task name: ');
                    TextColor(White);
                    readln(mdescid);
                    TRY
                        writeln(description(mdescid));
                        writeln('***Press any key to exit description***');
                        REPEAT UNTIL keypressed; //FIXME
                    EXCEPT
                        ON E: EAccessViolation DO
                        BEGIN
                            TextColor(Red);
                            writeln('Error occured. Task entered probably doesn`t exist. Press any key to return to main screen. Details:', E.Message);
                            TextColor(White);
                            REPEAT UNTIL keypressed;
                        END;
                    END;
                END;
            'exit' : BREAK;
            '' : ;
            'tick' :
                BEGIN
                    TextColor(Green);
                    write('Enter task name: ');
                    TextColor(White);
                    readln(mtickid);
                    TRY
                        ticktodo(mtickid);
                    EXCEPT
                        ON E: EAccessViolation DO
                        BEGIN
                            TextColor(Red);
                            writeln('Error occured. Task entered probably doesn`t exist. Press any key to return to main screen. Details:', E.Message);
                            TextColor(White);
                            REPEAT UNTIL keypressed;
                        END;
                    END;
                END;
            'help' : 
                BEGIN
                    writeln('Not implemented yet');
                    writeln('***Press any key to exit help***');
                    REPEAT UNTIL keypressed;
                END;
            'addtask' :
                BEGIN
                    TextColor(Green);
                    write('Enter due date for your task in DD/MM/YYYY format: ');
                    TextColor(White);
                    readln(mtime);
                    TextColor(Green);
                    write('Enter task name: ');
                    TextColor(White);
                    readln(mname);
                    TextColor(Green);
                    write('Enter short description for your task: ');
                    TextColor(White);
                    readln(mdesc);
                    writetodo(mtime, mname, mdesc);
                END;
        ELSE 
            TextColor(Red);
            writeln('Unknown command');
            TextColor(White);
            sleep(500);
        END;
    END;
END.