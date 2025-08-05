unit test;

{$ifdef FPC}
{$mode delphi}
{$endif}   

interface

var
  lineno: size_t = 0;
  failures: integer = 0;
  total_checks: integer = 0;

function skipspaces(buf: pansichar; i: size_t): size_t;
function encode(dest: pansichar; var dest_len: size_t; buf: pchar): size_t;
function check(ACond: boolean; AFormat: string; const Args: array of const):boolean;

implementation

uses
  character, SysUtils, utf8proc in '../utf8proc.pas';

function skipspaces(buf: pansichar; i: size_t): size_t;
begin
  while (iswhitespace(buf[i])) do
    Inc(i);
  Result := i;
end;

{* if buf points to a sequence of codepoints encoded as hexadecimal strings,
   separated by whitespace, and terminated by any character not in
   [0-9a-fA-F] or whitespace, then stores the corresponding utf8 string
   in dest, exiting the number of bytes read from buf *}
function encode(dest: pansichar; var dest_len: size_t; buf: pchar): size_t;
var
  i, j: size_t;
  d: utf8proc_ssize_t;
  c: integer;
  num: ansistring;
begin
  i := 0;
  j := 0;
  d := 0;
  while True do
  begin
    i := skipspaces(buf, i);
    num := '$';
    j := i;
    while (buf[j] <> #0) and (buf[j] in ['0'..'9', 'a'..'f', 'A'..'F']) do
    begin
      num := num + buf[j];
      Inc(j);
    end;   {* find end of hex input *}

    if (j = i) then
    begin {* no codepoint found *}
      dest[d] := #0; {* NUL-terminate destination string *}
      dest_len := d;
      exit(i + 1);
    end;
    //          check(sscanf((char *) (buf + i), "%x", (unsigned int *) &c) = 1, "invalid hex input %s", buf+i);
    c := StrToIntDef(num, -1);
    //if c=-1 then
    //  writeln('ERROR: NOT HEXA value in line ',lineno,'->[',num,']');
    check(c <> -1, 'ERROR: NOT HEXA value in line %d ->[num]', [lineno, num]);
    i := j; {* skip to char after hex input *}
    Inc(d, utf8proc_encode_char(c, PChar(dest + d)));
  end;
end;

function check(ACond: boolean; AFormat: string; const Args: array of const):boolean;
var
  tmp: string;
begin
  inc(total_checks);
  if not ACond then
  begin
    tmp := Format('*** ERROR in line %d: ', [lineno]);
    tmp := tmp + Format(AFormat, Args);
    writeln(tmp);
    Inc(failures);
  end;
  result := ACond;
end;

end.
