//* Miscellaneous tests, e.g. regression tests */

program misc;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  utf8proc;

procedure issue128; {* #128 *}
var
  input, nfc, nfd: pansichar;
begin
  input := #$72#$cc#$87#$cc#$a3#$00; {* "r\u0307\u0323" *}
  nfc := #$e1#$b9#$9b#$cc#$87#$00; {* "\u1E5B\u0307" *}
  nfd := #$72#$cc#$a3#$cc#$87#$00; {* "r\u0323\u0307" *}
  check_compare('NFC', input, nfc, utf8proc_NFC(input), 1);
  check_compare('NFD', input, nfd, utf8proc_NFD(input), 1);
end;

procedure issue102; {* #102 *}
var
  input, stripna, correct, output: pansichar;
begin
  input := #$58#$e2#$81#$a5#$45#$cc#$80#$c2#$ad#$e1#$b4#$ac#$00; {* "X\u2065E\u0300\u00ad\u1d2c" *}
  stripna := #$78#$c3#$a8#$61#$00; {* "x\u00e8a" *}
  correct := #$78#$e2#$81#$a5#$c3#$a8#$61#$00; {* "x\u2065\u00e8a" *}
  utf8proc_map(input, 0, @output, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT or
    UTF8PROC_CASEFOLD or UTF8PROC_IGNORE or UTF8PROC_STRIPNA);
  check_compare('NFKC_Casefold+stripna', input, stripna, output, 1);
  check_compare('NFKC_Casefold', input, correct, utf8proc_NFKC_Casefold(input), 1);
end;

  procedure issue317;  {/* #317 */}
  var
    input_s:array[0..6] of ansichar = (#$ec,#$a3,#$a0,#$e1,#$86,#$a7,#$00); {/* "\uc8e0\u11a7" */}
    combined_s:array[0..3] of ansichar = (#$ec,#$a3,#$a,#$00);   {/* "\uc8e1" */}
    input, combined: pansichar;
    codepoint: utf8proc_int32_t;
  begin
    input := PAnsiChar(@input_s[0]);
    combined := PAnsiChar(@combined_s[0]);

    {/* inputs that should *not* be combined* */}
    check_compare('NFC', input, input, utf8proc_NFC(input), 1);
    utf8proc_encode_char($11c3, input + 3);
    check_compare('NFC', input, input, utf8proc_NFC(input), 1);

    {/* inputs that *should* be combined (TCOUNT-1 chars starting at TBASE+1) */}
    for codepoint := $11a8 to Pred($11c3) do
    begin
      utf8proc_encode_char(codepoint, input + 3);
      utf8proc_encode_char($c8e0 + (codepoint - $11a7), combined);
      check_compare('NFC', input, combined, utf8proc_NFC(input), 1);
    end;
  end;


{/* check that utf8proc_normalize_utf32 passes uninterpretable codepoints through
   rather than deleting them, and never composes across one */}
procedure check_normalize_utf32(name:PAnsiChar;
                                input:putf8proc_int32_t; len:utf8proc_ssize_t;
                                expected:putf8proc_int32_t;expected_len:utf8proc_ssize_t);
var
  buffer:array[0..7] of utf8proc_int32_t;
  i, result0: utf8proc_ssize_t;
begin
  check(len <= (sizeof(buffer)/sizeof( buffer[0])), '%s: test buffer too small', [name]);
  for i := 0 to len -1 do
    buffer[i] := input[i];
  result0 := utf8proc_normalize_utf32(buffer, len, UTF8PROC_COMPOSE);
  check(result0 = expected_len, '%s: returned length %d, expected %d',[ name, result0, expected_len]);
  for i := 0 to expected_len-1 do
    check(buffer[i] = expected[i], '%s: buffer[%d] = 0x%x, expected 0x%x',[
          name, i, buffer[i], expected[i]]);
end;

  procedure issue288; {/* #288 */}
  var
    input: array[0..3] of utf8proc_int32_t;
    expected: array[0..3] of utf8proc_int32_t;
  begin
    {/* baseline: composition still happens */}
    // utf8proc_int32_t input[] = {0x0041, 0x0301};        {/* "A" + combining acute */}
    input[0] := $0041;
    input[1] := $0301;
    //utf8proc_int32_t expected[] = {0x00c1};             {/* "\u00c1" */}
    expected[0] := $00c1;
    check_normalize_utf32('compose', @input[0], 2, @expected[0], 1);
    {/* an out-of-range codepoint is preserved, and blocks composition across it
     (unsafe_get_property would read past utf8proc_stage1table) */}
    //utf8proc_int32_t input[] = {0x0041, 0x110000, 0x0301};
    input[0] := $0041;
    input[1] := $110000;
    input[2] := $0301;
    check_normalize_utf32('out-of-range codepoint', @input[0], 3, @input[0], 3);
    {/* likewise the grapheme-break sentinel written by utf8proc_decompose_char */}
    //utf8proc_int32_t input[] = {0x0041, -1, 0x0301};
    input[0] := $0041;
    input[1] := -1;
    input[2] := $0301;
    check_normalize_utf32('grapheme-break sentinel', @input[0], 3, @input[0], 3);

    writeln('PASSED: utf8proc_normalize_utf32 preserves uninterpretable codepoints');
  end;

begin
  issue128();
  issue102();
  issue317();
  issue288();
  {$ifdef UNICODE_VERSION}
  writeln(Format('Unicode version: Makefile has %s, has API %s', [UNICODE_VERSION, utf8proc_unicode_version]));
  check( UNICODE_VERSION = utf8proc_unicode_version, 'utf8proc_unicode_version mismatch');
  {$endif}

  writeln('Misc tests SUCCEEDED.');
  writeln('');
  writeln('Press enter to exit');
  readln;
end.
