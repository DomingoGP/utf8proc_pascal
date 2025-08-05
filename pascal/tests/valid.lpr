program valid;
{
  FPC HAS PROBLEMS TO DETECT CHANGES in ../utf8proc.pas
  delete all files in lib/ before compile to avoid problems.


}

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  Strings,
  utf8proc in '../utf8proc.pas';

var
  c, error: integer;

begin
  utf8proc_codepoint_valid($D6D8);
  c := 0;
  utf8proc_codepoint_valid($D6D8);

  {* some simple sanity tests of  *}
  while c < $d800 do
  begin
    if not utf8proc_codepoint_valid(c) then
    begin
      writeln(Format('Failed: codepoint_valid(%04X) -> false', [c]));
      Inc(error);
    end;
    Inc(c);
  end;
  while c < $e000 do
  begin
    if utf8proc_codepoint_valid(c) then
    begin
      writeln(Format('Failed: codepoint_valid(%04X) -> true', [c]));
      Inc(error);
    end;
    Inc(c);
  end;
  while c < $110000 do
  begin
    if not utf8proc_codepoint_valid(c) then
    begin
      writeln(Format('Failed: codepoint_valid(%06X) -> false', [c]));
      Inc(error);
    end;
    Inc(c);
  end;
  while c < $110010 do
  begin
    if utf8proc_codepoint_valid(c) then
    begin
      writeln(Format('Failed: codepoint_valid(%06X) -> true', [c]));
      Inc(error);
    end;
    Inc(c);
  end;
  check(error = 0, 'utf8proc_codepoint_valid FAILED %d tests.', [error]);
  writeln('Validity tests SUCCEEDED.');

  writeln('press Enter to exit');
  readln;
  ExitCode := 0;
end.
