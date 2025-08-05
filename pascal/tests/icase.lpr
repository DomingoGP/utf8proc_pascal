program icase;

{$ifdef FPC}
{$mode delphi}
{$endif}

uses
  test,
  Strings,
  SysUtils,
  utf8proc in '../utf8proc.pas';

type
  iscasefunction = function(c: utf8proc_int32_t): boolean;
  tocasefunction = function(c: utf8proc_int32_t): utf8proc_int32_t;


function read_range(var f: Text; start: putf8proc_int32_t; endx: putf8proc_int32_t): integer;
var
  line: string;
  buf: pansichar;
  s: array [0..15] of ansichar;
  len, s_len, pos: size_t;
begin
  readLn(f, line);
  Inc(lineno);
  buf := pansichar(line);
  len := length(line);
  pos := skipspaces(buf, 0);

  if (pos = len) or (buf[pos] = '#') then
    exit(0);
  Inc(pos, encode(s, s_len, buf + pos) - 1);
  check(s[0] <> #0, 'invalid line %s in data', [buf]);
  utf8proc_iterate(@s[0], -1, start);
  if (buf[pos] = '.') and (buf[pos + 1] = '.') then
  begin
    encode(s, s_len, buf + pos + 2);
    check(s[0] <> #0, 'invalid line %s in data', [buf]);
    utf8proc_iterate(@s[0], -1, endx);
  end
  else
    endx^ := start^;
  exit(1);
end;


function test_iscase(fname: string; iscase: iscasefunction; thatcase: tocasefunction): integer;
var
  f: Text;
  Lines, tests, success: integer;
  c: utf8proc_int32_t;
  start, endx: utf8proc_int32_t;
begin
  try
    Assign(f, fname);
    reset(f);
  except
    writeln('Can''t open file: ' + fname);
    raise;
  end;
  Lines := 0;
  tests := 0;
  success := 1;
  c := 0;

  while (success <> 0) and (not EOF(f)) do
  begin
    if (read_range(f, @start, @endx) <> 0) then
    begin
      while c < start do
      begin
        check(not iscase(c), 'failed  not iscase(%04x) in %s', [c, fname]);
        Inc(c);
      end;
      while c <= endx do
      begin
        check(iscase(c), 'failed iscase(%04x) in %s', [c, fname]);
        check(thatcase(c) = c, 'inconsistent thatcase(%04x) in %s', [c, fname]);
        Inc(tests);
        Inc(c);
      end;
    end;
    Inc(Lines);
  end;
  while c <= $110000 do
  begin
    check(not iscase(c), 'failed  not iscase(%04x) in %s', [c, fname]);
    Inc(c);
  end;

  writeln(Format('Checked %d characters from %d lines of %s', [tests, Lines, fname]));
  Close(f);
  exit(success);
end;

begin
  try
    check(test_iscase('Lowercase.txt', @utf8proc_islower, @utf8proc_tolower) <> 0, 'Lowercase tests failed', []);
    check(test_iscase('Uppercase.txt', @utf8proc_isupper, @utf8proc_toupper) <> 0, 'Uppercase tests failed', []);
    writeln('utf8proc iscase tests SUCCEEDED.');
    writeln('');
  except
  end;
  writeln('Press enter to exit');
  readln;
end.
