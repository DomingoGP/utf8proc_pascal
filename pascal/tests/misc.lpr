//* Miscellaneous tests, e.g. regression tests */

program misc;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  utf8proc in '../utf8proc.pas';

procedure issue128; {* #128 *}
var
  input, nfc, nfd, nfc_out, nfd_out: pansichar;
begin
  input := #$72#$cc#$87#$cc#$a3#$00; {* "r\u0307\u0323" *}
  nfc := #$e1#$b9#$9b#$cc#$87#$00; {* "\u1E5B\u0307" *}
  nfd := #$72#$cc#$a3#$cc#$87#$00; {* "r\u0323\u0307" *}
  nfc_out := utf8proc_NFC(input);
  writeln(Format('NFC "%s" -> "%s" vs. "%s"', [input, nfc_out, nfc]));
  check(strlen(nfc_out) = 5, 'incorrect nfc length', []);
  check(CompareMem(nfc, nfc_out, 6), 'incorrect nfc data', []);
  nfd_out := utf8proc_NFD(input);
  writeln(Format('NFD "%s" -> "%s" vs. "%s"', [input, nfd_out, nfd]));
  check(strlen(nfd_out) = 5, 'incorrect nfd length', []);
  check(CompareMem(nfd, nfd_out, 6), 'incorrect nfd data', []);
  utf8proc_free(nfd_out);
  utf8proc_free(nfc_out);
end;

procedure issue102; {* #128 *}
var
  input, stripna, correct, output: pansichar;
begin
  input := #$58#$e2#$81#$a5#$45#$cc#$80#$c2#$ad#$e1#$b4#$ac#$00; {* "X\u2065E\u0300\u00ad\u1d2c" *}
  stripna := #$78#$c3#$a8#$61#$00; {* "x\u00e8a" *}
  correct := #$78#$e2#$81#$a5#$c3#$a8#$61#$00; {* "x\u2065\u00e8a" *}
  utf8proc_map(input, 0, @output, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT or
    UTF8PROC_CASEFOLD or UTF8PROC_IGNORE or UTF8PROC_STRIPNA);
  writeln(Format('NFKC_Casefold "%s" -> "%s" vs. "%s"', [input, output, stripna]));
  check(strlen(output) = 4, 'incorrect NFKC_Casefold+stripna length', []);
  check(CompareMem(stripna, output, 5), 'incorrect NFKC_Casefold+stripna data', []);
  utf8proc_free(output);
  output := utf8proc_NFKC_Casefold(input);
  writeln(Format('NFKC_Casefold "%s" -> "%s" vs. "%s"', [input, output, correct]));
  check(strlen(output) = 7, 'incorrect NFKC_Casefold length', []);
  check(CompareMem(correct, output, 8), 'incorrect NFKC_Casefold data', []);
  utf8proc_free(output);
end;

begin
  issue128();
  issue102();
  {$ifdef UNICODE_VERSION}
  writeln(Format('Unicode version: Makefile has %s, has API %s', [UNICODE_VERSION, utf8proc_unicode_version]));
  check( UNICODE_VERSION = utf8proc_unicode_version, 'utf8proc_unicode_version mismatch');
  {$endif}

  writeln('Misc tests SUCCEEDED.');
  writeln('');
  writeln('Press enter to exit');
  readln;
end.
