library SearchFile;
uses
{$IFDEF DEBUG}
  //FastMM4 in '..\FastMM4\FastMM4.pas'
{$ENDIF }
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.IOUtils,
  System.Types,
  CommonMkos in 'CommonMkos.pas';
{$R *.res}
///<summary>
///Функция для рекурсивного поиска файлов
///</summary>
function SearchFiles(Masks: PChar; StartDir: PChar; var FileCount: Integer; var FileArr: WideString): Boolean; stdcall;
var
  MaskArray: TArray<string>;
  Mask: string;
  FoundFiles: TStringDynArray;
begin
  Result := False;
  FileCount := 0;
  FileArr := '';
  //Разделяем маски по точкам с запятой
  MaskArray := string(Masks).Split([';'], TStringSplitOptions.ExcludeEmpty);
  try
    for Mask in MaskArray do
    begin //для каждой маски
      FoundFiles := TDirectory.GetFiles(string(StartDir), Mask.Trim, TSearchOption.soAllDirectories);
      //результаты
      for var I := 0 to High(FoundFiles) do
        FileArr := FileArr + sLineBreak + FoundFiles[I];
      FileCount := FileCount + High(FoundFiles) + 1;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      FileCount := -1;
    end;
  end;
end;
/// <summary>
///   функция посика масок в файле
/// </summary>
function SearchPattern(FileName: PChar; Pattern: PChar; var Results: TSearchResults; var TotalMatches: Int64): Boolean; stdcall;
const
  BufferSize = 1024 * 1024; //1MB буфер для чтения файла
var
  FS: TFileStream;
  PatternLen, BytesRead, I, j: Integer;
  Buffer, PrevBuffer: TBytes;
  PatternBytes: TBytes;
  MaxMatches: Int64;
  Found: Boolean;
  CurrentPos: Int64;
begin
  Result := False;
  try
    if (FileName = nil) or (Pattern = nil) then
      Exit;
    PatternLen := Length(Pattern); //длина шаблона
    if PatternLen = 0 then
      Exit;
    PatternBytes := TEncoding.ANSI.GetBytes(Pattern); //шаблон в однобайтовый массив
    FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, BufferSize + PatternLen(* - 1*));
      SetLength(PrevBuffer, PatternLen(* - 1*));
      MaxMatches := TotalMatches + 1;
      TotalMatches := 0;
      CurrentPos := 0;
      while True do begin //чтение файла блоками
        BytesRead := FS.Read(Buffer[0], BufferSize); //читаем блок
        if BytesRead < BufferSize then begin //если это не первый блок
          SetLength(Buffer, BytesRead + Length(PrevBuffer)); //последний блок - сокращаем буфер
          Move(PrevBuffer[0], Buffer[BytesRead], Length(PrevBuffer));
        end
        else begin
          if Length(PrevBuffer) > 0 then
            Move(PrevBuffer[0], Buffer[BytesRead], Length(PrevBuffer)); //конец предыдущего блока к началу текущего
        end;
        for I := 0 to Length(Buffer) - PatternLen do begin //поиск шаблона в текущем буфере
          Found := True;
          for j := 0 to PatternLen - 1 do begin
            if Buffer[I + j] <> PatternBytes[j] then begin
              Found := False;
              Break;
            end;
          end;
          if Found then begin //совпадение
            if TotalMatches < Length(Results) then
              Results[TotalMatches] := CurrentPos + I;
            Inc(TotalMatches);
          end;
          if (MaxMatches > 0) and (TotalMatches >= MaxMatches) then begin //достигли макс. количества совпадений
            Break;
          end;
        end; //for I := 0 to Length(Buffer) - PatternLen do
        if (MaxMatches > 0) and (TotalMatches >= MaxMatches) then begin  // еще раз, для выходи из цикла
          Break;
        end;
        CurrentPos := CurrentPos + BytesRead; //обновляем текущую позицию в файле
        if BytesRead > 0 then begin //конец текущего блока для следующей итерации
          SetLength(PrevBuffer, PatternLen(* - 1*));
          if BytesRead >= PatternLen(* - 1*) then
            Move(Buffer[BytesRead - (PatternLen(* - 1*))], PrevBuffer[0], Length(PrevBuffer))
          else
          begin
            if Length(PrevBuffer) > BytesRead then //переносим остаток из предыдущего PrevBuffer
              Move(PrevBuffer[BytesRead], PrevBuffer[0], Length(PrevBuffer) - BytesRead);
            Move(Buffer[0], PrevBuffer[Length(PrevBuffer) - BytesRead], BytesRead);
          end;
        end;
        if BytesRead < BufferSize then //конец файла
          Break;
      end; //while True do begin
      Result := True;
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
end;

//Экспортируемые функции
exports
  SearchFiles,
  SearchPattern;
begin
{$IFDEF DEBUG}
  //ReportMemoryLeaksOnShutdown := true; // отслеживание утечек памяти
{$ENDIF}
end.
