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
procedure print_escaped(var f:Text;utf8:PAnsiChar);
procedure print_string_and_escaped(var f:Text;utf8:PAnsiChar);
procedure check_compare(transformation:string;
                   input:PAnsiChar; expected:PAnsiChar;
                   received:PAnsiChar;free_received:integer);

implementation

uses
  SysUtils, Strings, utf8proc,character;

function skipspaces(buf: pansichar; i: size_t): size_t;
begin
  while iswhitespace(buf[i]) do
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
    if lineno <> 0 then
       tmp := Format('*** FAILED at line %d: ', [lineno])
     else
       tmp := '*** FAILED ';
    tmp := tmp + Format(AFormat, Args);
    writeln(tmp);
    Inc(failures);
  end;
  result := ACond;
end;


procedure print_escaped(var f:Text;utf8:PAnsiChar);
var
  codepoint:utf8proc_int32_t;
  len:integer;
begin
  write(f,'"');
  while utf8^<>#0 do
  begin
    len := utf8proc_iterate(utf8, -1, @codepoint);
    Inc(utf8,len);
    if codepoint < $10000 then
      write(f, Format('\u%04x',[codepoint]))
    else
      write(f, Format('\U%06x',[codepoint]));
  end;
  write(f,'"');
end;

procedure print_string_and_escaped(var f: Text; utf8: pansichar);
begin
  Write(f, '"', utf8, '" (');
  print_escaped(f, utf8);
  Write(f, ')');
end;

procedure check_compare(transformation: string; input: pansichar;
  expected: pansichar; received: pansichar; free_received: integer);
var
  passed: boolean;
  f: Text;
begin
  passed := strcomp(received, expected) = 0;
  if passed then
  begin
    f := StdOut;
    Write(f, 'PASSED ', transformation, ' ');
  end
  else
  begin
    f := StdErr;
    Write(f, 'FAILED ', transformation, ' ');
  end;
  print_string_and_escaped(f, input);
  Write(f, ' -> ');
  print_string_and_escaped(f, received);
  if not passed then
  begin
    Write(f, ' <> expected ');
    print_string_and_escaped(f, expected);
  end;
  writeln(f);
  if free_received <> 0 then
    FreeMem(received);
  if not passed then
  begin
    writeln('HALT in check_compare.');
    writeln('Press <enter> to exit');
    readln;
    halt(1);
  end;
end;

end.
