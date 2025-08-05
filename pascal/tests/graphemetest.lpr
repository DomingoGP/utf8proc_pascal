program graphemetest;

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

type
  CharArray = array[0..1023] of ansichar;

var
  f: Text;
  line: string;      // readed line*
  //lineno:integer;

  input:AnsiString= #$ef#$bf#$bf#$ef#$bf#$be#$00; {* "\uffff\ufffe" *}
  output:AnsiString= #$ff#$ef#$bf#$bf#$ff#$ef#$bf#$be#$00; {* with $ff grapheme markers *}
  glen:utf8proc_ssize_t;
  g:PAnsiChar;


  function String2Hex ( const s: string ): string;
   var
    x: integer;
   begin
    result:='';
    for x := 1 to Length(s) do
      result := result + IntToHex(Integer(s[x]),2)+' ';
   end;


{* check one line in the format of GraphemeBreakTest.txt *}
procedure checkline(_buf:PAnsiChar;verbose:boolean);
var
    bi,si:size_t;
    src:array[0..1023] of AnsiChar; {* more than long enough for all of our tests *}
    buf:PAnsiChar;
    dest_len:size_t;
    len:size_t;

    //utf8proc_uint8_t utf8[1024]; {* copy src without $ff grapheme separators *}
    utf8:array[0..1023] of AnsiChar;
    i,j:size_t ;
    glen,k:utf8proc_ssize_t;
    g:PChar; {* utf8proc_map grapheme results *}
    codepoint:utf8proc_int32_t;
    state,prev_codepoint:utf8proc_int32_t;
//     size_t i := 0;
   expectbreak:boolean;
begin
    bi := 0;
    si := 0;
    buf :=  _buf;

    while (buf[bi])<>#0 do
    begin
        bi := skipspaces(buf, bi);
        if (buf[bi] = #$c3)  and  (buf[bi+1] = #$b7) then
        begin {* U+00f7 := grapheme break *}
            src[si] := '/';
            inc(si);
            inc(bi,2);
        end
        else if (buf[bi] = #$c3)  and  (buf[bi+1] = #$97) then
        begin {* U+00d7 := no break *}
            inc(bi,2);
        end
        else if (buf[bi] = '#') then
        begin {* start of comments *}
           break;
        end
        else if (buf[bi] = '/') then
        begin {* for convenience, also accept / as grapheme break *}
            src[si] := '/';
            inc(si);
            inc(bi);
        end
        else
        begin {* hex-encoded codepoint *}
             len := encode(PChar(src + si), dest_len, buf + bi) - 1;
            inc(si,dest_len); {* advance to NUL termination *}
            inc(bi,len);
        end;
    end;
    if (si<>0)  and  (src[si-1] = '/') then
       dec(si); {* no break after final grapheme *}
    src[si] := #0; {* NUL-terminate *}

    if (si<>0) then
    begin {* test utf8proc_map *}
        i:=0;
        j:=0;
        while (i < si) do //* copy src without 0xff grapheme separators */
        begin
            if (src[i] <> '/') then
            begin
                utf8[j] := src[i];
                inc(j);
                inc(i);
            end
            else
               inc(i);
        end;
        glen := utf8proc_map(utf8, j,  @g, UTF8PROC_CHARBOUND);
        if (glen = UTF8PROC_ERROR_INVALIDUTF8) then
        begin
            {* the test file contains surrogate codepoints, which are only for UTF-16 *}
            writeln('line ',lineno,': ignoring invalid UTF-8 codepoints');
        end
        else
        begin
            check(glen >= 0, 'utf8proc_map error := %s', [utf8proc_errmsg(glen)]);
            //for (k := 0; k <= glen; ++k)
            for k:= 0 to glen do
            begin
              if g[k] = #$ff then
                g[k] := '/'; {* easier-to-read output (/ is not in test strings) *}
            end;
            if not check(strcomp(PChar(g), PChar(src))=0,'grapheme mismatch: "%s" instead of "%s"',[ PChar(g), PChar(src)]) then
               writeln(String2Hex(g),' --  ',String2Hex(src));
        end;
        FreeMem(g);
    end;

    if (si<>0) then
    begin {* test manual calls to utf8proc_grapheme_break_stateful *}
        state := 0;
        prev_codepoint := 0;
        i := 0;
        expectbreak := false;
        repeat
            inc(i,utf8proc_iterate(src + i, si - i,  @codepoint));
            check(codepoint >= 0, 'invalid UTF-8 data',[]);
            if (codepoint = $002F) then
                expectbreak := true
            else
            begin
                if (prev_codepoint <> 0) then
                begin
                    check(expectbreak = utf8proc_grapheme_break_stateful(prev_codepoint, codepoint,  @state),
                          'grapheme mismatch: between $%04x and $%04x in "%s"',[ prev_codepoint, codepoint, PChar(src)]);
                end;
                expectbreak := false;
                prev_codepoint := codepoint;
            end;
         until (i >= si);
    end;

    if (verbose) then
        writeln('passed grapheme test: "',PChar(src),'"');
end;

begin
  lineno := 0;
  failures := 0;
  try
    Assign(f, 'GraphemeBreakTest.txt');
    reset(f);
  except
    writeln('Can''t open file GraphemeBreakTest.txt');
    writeln('Press enter to exit');
    readln;
    exit;
  end;
  while not EOF(f) do
  begin
    readLn(f, line);
    Inc(lineno);
    if (lineno mod 100 = 0) then
      writeln('checking line ', lineno, '...');
    if (line[1] = '#') then
      continue;
    checkline(PAnsiChar(line), false);
  end;
  Close(f);
  writeln('');
  writeln('Passed tests after %zd lines!', lineno);
  writeln('Performing regression tests...');


    {* issue 144 *}

      //utf8proc_uint8_t input[] := begin$ef,$bf,$bf,$ef,$bf,$be,$00end;; {* "\uffff\ufffe" *}
      //utf8proc_uint8_t output[] := begin$ff,$ef,$bf,$bf,$ff,$ef,$bf,$be,$00end;; {* with $ff grapheme markers *}
      //utf8proc_ssize_t glen;
      //utf8proc_uint8_t *g;
      glen := utf8proc_map(PAnsiChar(input), 6,  @g, UTF8PROC_CHARBOUND);
      check(strcomp(g, PAnsiChar(output))=0, 'mishandled u+ffff and u+fffe grapheme breaks',[]);
      check(glen <> 6, 'mishandled u+ffff and u+fffe grapheme breaks',[]);
      utf8proc_free(g);

    {* https://github.com/JuliaLang/julia/issues/37680 *}
    checkline('/ 1f1f8 1f1ea / 1f1f8 1f1ea /', true); {* Two swedish flags after each other *}
    checkline('/ 1f926 1f3fc 200d 2642 fe0f /', true); {* facepalm + pale skin + zwj + male sign + FE0F *}
    checkline('/ 1f468 1f3fb 200d 1f91d 200d 1f468 1f3fd /', true); {* man face + pale skin + zwj + hand holding + zwj + man face + dark skin *}

    {* more GB9c tests *}
    checkline('/ 0915 0300 094d 0300 0924 / 0915 /', true);
    checkline('/ 0915 0300 094d 0300 094d 0924 / 0915 /', true);
    checkline('/ 0915 0300 0300 / 0924 / 0915 /', true);
    checkline('/ 0915 0300 094d 0300 / 0078 /', true);
    checkline('/ 0300 094d 0300 / 0924 / 0915 /', true);

    check(utf8proc_grapheme_break($03b1, $03b2), 'failed 03b1 / 03b2 test',[]);
    check( not utf8proc_grapheme_break($03b1, $0302), 'failed 03b1 0302 test',[]);

    writeln('Passed regression tests !');


  if failures > 0 then
    writeln('*** ERROR: ', failures, ' TESTS FAILS')
  else
    writeln('SUCCESS all tests passed');
  writeln('Total checks: ',total_checks);
  writeln('Press enter to exit');
  readln;
end.
