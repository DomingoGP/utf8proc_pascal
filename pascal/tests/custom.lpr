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


begin
  utf8proc_map_custom(input, 0,  @output, UTF8PROC_CASEFOLD  or  UTF8PROC_COMPOSE  or  UTF8PROC_COMPAT  or  UTF8PROC_NULLTERM,
                      @custom,  @thunk_test);
  check_compare('map_custom', input, correct, output, 1);
  writeln('map_custom tests SUCCEEDED.');
  writeln('');
  writeln('Press enter to exit');
  readln;
end.

