program custom;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test, utf8proc;

var
  thunk_test:integer = 1;

  function custom(codepoint:utf8proc_int32_t; thunk:Pointer): utf8proc_int32_t;
  begin
      check(PInteger(thunk) =  @thunk_test, 'unexpected thunk passed',[]);
      if (codepoint = Ord('a'))  then
          exit( Ord('b') );
      if (codepoint = Ord('S')) then
          exit( $00df); {* ß *}
      exit(codepoint);
  end;

var
  input:PAnsiChar =   #$41#$61#$53#$62#$ef#$bd#$81#$00; {* "AaSb\uff41" *}
  correct:PAnsiChar = #$61#$62#$73#$73#$62#$61#$00;     {* "abssba" *}
  output:PAnsiChar;

 {/* a callback whose output depends on how many times it has been called, so
    utf8proc_map_custom's two internal decompose passes see different data: the
    second pass expands to more codepoints than the buffer was sized for. This
    must be rejected rather than overflowing the heap (issue #249). */}
  function  inconsistent(codepoint: utf8proc_int32_t;thunk: pointer):utf8proc_int32_t;
  var
    calls:PInteger;
    r: utf8proc_int32_t;
  begin
    calls := PInteger(thunk);
    if calls^=0 then
      r := Ord('a')
    else
      r:= $0390; {/* 0x0390 has a 3-codepoint NFD */}
    //codepoint;
    inc(calls^);
    result := r;
  end;


var
   calls: integer;
   out0: pbyte;
   in0:array[0..1] of byte;
   r: utf8proc_ssize_t;

begin
  utf8proc_map_custom(input, 0,  @output, UTF8PROC_CASEFOLD  or  UTF8PROC_COMPOSE  or  UTF8PROC_COMPAT  or  UTF8PROC_NULLTERM,
                      @custom,  @thunk_test);
  check_compare('map_custom', input, correct, output, 1);
  writeln('map_custom tests SUCCEEDED.');

  //utf8proc_uint8_t in[] = {0x78, 0x00}; /* "x" */
  in0[0] := $78;
  in0[1] := $00;
  out0 := nil;
  calls := 0;
  r := utf8proc_map_custom(@in0[0], 0, @out0, UTF8PROC_NULLTERM or UTF8PROC_DECOMPOSE, inconsistent, @calls);
  check(r = UTF8PROC_ERROR_OVERFLOW, 'inconsistent custom_func must fail, not overflow the buffer (got %d)',[r]);
  check(out0 = nil, 'no buffer should be returned on error',[]);
  writeln('map_custom inconsistent-callback test SUCCEEDED.');

  writeln('');
  writeln('Press enter to exit');
  readln;
end.

