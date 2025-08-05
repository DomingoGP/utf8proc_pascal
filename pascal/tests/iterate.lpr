program iterate;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  Strings,
  utf8proc in '../utf8proc.pas';

type
  CharArray = array[0..1023] of ansichar;

var

  tests: integer;
  error: integer;

  byt: utf8proc_int32_t;
  buf: array [0..15] of ansichar;

procedure testbytes(ABuf: pansichar; len: utf8proc_ssize_t; retval: utf8proc_ssize_t; line: integer);
var
  lout: array[0..15] of utf8proc_int32_t;
  ret: utf8proc_ssize_t;
  tmp: array[0..15] of ansichar;
  i: integer;
begin
      {* Make a copy to ensure that memory is left uninitialized after "len"
       * bytes. This way, Valgrind can detect overreads.
       *}
  //memcpy(tmp, Abuf, (unsigned long int)len);
  move(ABuf[0], tmp[0], len);
  Inc(tests);
  ret := utf8proc_iterate(tmp, len, lout);
  if ret <> retval then
  begin
    //fprintf(stderr, "Failed (%d):", line);
    Write('Failed(', line, '):');
    i := 0;
    while i < len do
    begin
      Write(Format(' $%02X', [Ord(tmp[i])]));
      Inc(i);
    end;
    //fprintf(stderr, " -> %zd\n", ret);
    writeln(Format(' -> %X', [ret]));
    Inc(error);
  end;
end;


//#define CHECKVALID(pos, val, len) buf[pos] = val; testbytes(buf,len,len,__LINE__)
//#define CHECKINVALID(pos, val, len) buf[pos] = val; testbytes(buf,len,UTF8PROC_ERROR_INVALIDUTF8,__LINE__)

procedure CHECKVALID(aPos: integer; aVal: ansichar; aLen: integer; aLine: integer);
begin
  buf[aPos] := aVal;
  testbytes(buf, aLen, aLen, aLine);
end;

procedure CHECKINVALID(aPos: integer; aVal: ansichar; aLen: integer; aLine: integer);
begin
  buf[aPos] := aVal;
  testbytes(buf, aLen, UTF8PROC_ERROR_INVALIDUTF8, aLine);
end;


begin
  lineno := 0;
  failures := 0;

  tests := 0;
  error := 0;

  // Check valid sequences that were considered valid erroneously before
  buf[0] := #$ef;
  buf[1] := #$b7;
  for byt := $90 to ($a0 - 1) do
  begin
    CHECKVALID(2, ansichar(byt), 3, {$I %LINENUM%});
  end;
  // Check $fffe and $ffff
  buf[1] := #$bf;
  CHECKVALID(2, #$be, 3, {$I %LINENUM%});
  CHECKVALID(2, #$bf, 3, {$I %LINENUM%});
  // Check $??fffe  and  $??ffff
  byt := $1fffe;
  while byt < $110000 do
  begin
    buf[0] := ansichar($f0 or (byt shr 18));
    buf[1] := ansichar($80 or ((byt shr 12) and $3f));
    CHECKVALID(3, #$be, 4, {$I %LINENUM%});
    CHECKVALID(3, #$bf, 4, {$I %LINENUM%});
    Inc(byt, $10000);
  end;

  // Continuation byte not after lead
  byt := $80;
  while byt < $c0 do
  begin
    CHECKINVALID(0, ansichar(byt), 1, {$I %LINENUM%});
    Inc(byt);
  end;

  //// Continuation byte not after lead   DUPLICATED
  //for (byt = 0x80; byt < 0xc0; byt++) {
  //    CHECKINVALID(0, byt, 1);
  //}

  // Test lead bytes
  byt := $c0;
  while byt <= $ff do
  begin
    // Single lead byte at end of string
    CHECKINVALID(0, ansichar(byt), 1, {$I %LINENUM%});
    // Lead followed by non-continuation character < 0x80
    CHECKINVALID(1, ansichar(65), 2, {$I %LINENUM%});
    // Lead followed by non-continuation character > 0xbf
    CHECKINVALID(1, #$c0, 2, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test overlong 2-byte
  buf[0] := #$c0;
  byt := $81;
  while byt <= $bf do
  begin
    CHECKINVALID(1, ansichar(byt), 2, {$I %LINENUM%});
    Inc(byt);
  end;

  buf[0] := #$c1;
  byt := $80;
  while byt <= $bf do
  begin
    CHECKINVALID(1, ansichar(byt), 2, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test overlong 3-byte
  buf[0] := #$e0;
  buf[2] := #$80;
  byt := $80;
  while byt <= $9f do
  begin
    CHECKINVALID(1, ansichar(byt), 3, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test overlong 4-byte
  buf[0] := #$f0;
  buf[2] := #$80;
  buf[3] := #$80;
  byt := $80;
  while byt <= $8f do
  begin
    CHECKINVALID(1, ansichar(byt), 4, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test 4-byte > 0x10ffff
  buf[0] := #$f4;
  buf[2] := #$80;
  buf[3] := #$80;
  byt := $90;
  while byt <= $bf do
  begin
    CHECKINVALID(1, ansichar(byt), 4, {$I %LINENUM%});
    Inc(byt);
  end;
  buf[1] := #$80;
  byt := $f5;
  while byt <= $f7 do
  begin
    CHECKINVALID(0, ansichar(byt), 4, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test 5-byte
  buf[4] := #$80;
  byt := $f8;
  while byt <= $fb do
  begin
    CHECKINVALID(0, ansichar(byt), 5, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test 6-byte
  buf[5] := #$80;
  byt := $fc;
  while byt <= $fd do
  begin
    CHECKINVALID(0, ansichar(byt), 6, {$I %LINENUM%});
    Inc(byt);
  end;

  // Test 7-byte
  buf[6] := #$80;
  CHECKINVALID(0, #$fe, 7, {$I %LINENUM%});

  // Three and above byte sequences
  byt := $e0;
  while byt < $f0 do
  begin
    // Lead followed by only 1 continuation byte
    CHECKINVALID(0, ansichar(byt), 2, {$I %LINENUM%});
    // Lead ended by non-continuation character < 0x80
    CHECKINVALID(2, #65, 3, {$I %LINENUM%});
    // Lead ended by non-continuation character > 0xbf
    CHECKINVALID(2, #$c0, 3, {$I %LINENUM%});
    Inc(byt);
  end;

  // 3-byte encoded surrogate character(s)
  buf[0] := #$ed;
  buf[2] := #$80;
  // Single surrogate
  CHECKINVALID(1, #$a0, 3, {$I %LINENUM%});
  // Trailing surrogate first
  CHECKINVALID(1, #$b0, 3, {$I %LINENUM%});

  // Four byte sequences
  buf[1] := #$80;
  byt := $f0;
  while byt < $f5 do
  begin
    // Lead followed by only 1 continuation bytes
    CHECKINVALID(0, ansichar(byt), 2, {$I %LINENUM%});
    // Lead followed by only 2 continuation bytes
    CHECKINVALID(0, ansichar(byt), 3, {$I %LINENUM%});
    // Lead followed by non-continuation character < 0x80
    CHECKINVALID(3, #65, 4, {$I %LINENUM%});
    // Lead followed by non-continuation character > 0xbf
    CHECKINVALID(3, #$c0, 4, {$I %LINENUM%});
    Inc(byt);
  end;

  check(error = 0, 'utf8proc_iterate FAILED %d tests out of %d', [error, tests]);
  writeln('utf8proc_iterate tests SUCCEEDED, (', tests, ') tests passed.');
  writeln('');
  writeln('Press enter to exit');
  readln;
end.
