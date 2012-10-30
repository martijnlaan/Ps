{ Compiletime DLL importing support }
unit uPSC_dll;

{$I PascalScript.inc}
interface
{

  Function FindWindow(c1, c2: PChar): Cardinal; external 'FindWindow@user32.dll stdcall';

}
uses
  uPSCompiler, uPSUtils;


function DllExternalProc(Sender: TPSPascalCompiler; Decl: TPSParametersDecl; const Name, FExternal: string): TPSRegProc;
type
  
  TDllCallingConvention = (clRegister 
  , clPascal 
  , ClCdecl 
  , ClStdCall 
  );

var
  DefaultCC: TDllCallingConvention;

procedure RegisterDll_Compiletime(cs: TPSPascalCompiler);

implementation

function rpos(ch: char; const s: string): Longint;
var
  i: Longint;
begin
  for i := length(s) downto 1 do
  if s[i] = ch then begin Result := i; exit; end;
  result := 0;
end;

function DllExternalProc(Sender: TPSPascalCompiler; Decl: TPSParametersDecl; const Name, FExternal: string): TPSRegProc;
var
  FuncName,
  FuncCC, s, s2: string;
  CC: TDllCallingConvention;
  DelayLoad, LoadWithAlteredSearchPath: Boolean;

begin
  DelayLoad := False;
  LoadWithAlteredSearchPath := False;
  FuncCC := FExternal;
  if (pos('@', FuncCC) = 0) then
  begin
    Sender.MakeError('', ecCustomError, 'Invalid External');
    Result := nil;
    exit;
  end;
  FuncName := copy(FuncCC, 1, rpos('@', FuncCC)-1)+#0;
  delete(FuncCc, 1, length(FuncName));
  if pos(' ', Funccc) <> 0 then
  begin
    FuncName := copy(FuncCc, 1, pos(' ',FuncCC)-1)+#0+FuncName;
    Delete(FuncCC, 1, pos(' ', FuncCC));
    if pos(' ', FuncCC) > 0 then
    begin
      s := Copy(FuncCC, pos(' ', Funccc)+1, MaxInt);
      FuncCC := FastUpperCase(Copy(FuncCC, 1, pos(' ', FuncCC)-1));
      repeat
        if pos(' ', s) > 0 then begin
          s2 := Copy(s, 1, pos(' ', s)-1);
          delete(s, 1, pos(' ', s));
        end else begin
          s2 := s;
          s := '';
        end;
        if FastUppercase(s2) = 'DELAYLOAD' then
          DelayLoad := True
        {$IFNDEF LINUX}
        else
        if FastUppercase(s2) = 'LOADWITHALTEREDSEARCHPATH' then
          LoadWithAlteredSearchPath := True
        {$ENDIF}
        else
        begin
          Sender.MakeError('', ecCustomError, 'Invalid External');
          Result := nil;
          exit;
        end;
      until s = '';
    end else
      FuncCC := FastUpperCase(FuncCC);
    if FuncCC = 'STDCALL' then cc := ClStdCall else
    if FuncCC = 'CDECL' then cc := ClCdecl else
    if FuncCC = 'REGISTER' then cc := clRegister else
    if FuncCC = 'PASCAL' then cc := clPascal else
    begin
      Sender.MakeError('', ecCustomError, 'Invalid Calling Convention');
      Result := nil;
      exit;
    end;
  end else
  begin
    FuncName := FuncCC+#0+FuncName;
    FuncCC := '';
    cc := DefaultCC;
  end;
  FuncName := 'dll:'+FuncName+char(cc)+char(bytebool(DelayLoad))+char(bytebool(LoadWithAlteredSearchPath)) + declToBits(Decl);
  Result := TPSRegProc.Create;
  Result.ImportDecl := FuncName;
  Result.Decl.Assign(Decl);
  Result.Name := Name;
  Result.ExportName := False;
end;

procedure RegisterDll_Compiletime(cs: TPSPascalCompiler);
begin
  cs.OnExternalProc := DllExternalProc;
  cs.AddFunction('procedure UnloadDll(s: string)');
  cs.AddFunction('function DLLGetLastError: Longint');
end;

begin
  DefaultCc := clRegister;
end.

