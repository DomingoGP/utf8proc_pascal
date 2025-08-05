//* simple test program to print out the utf8proc properties for a codepoint */
program printproperty;

{$ifdef FPC}
{$mode delphi}
{$endif}

uses
  test,
  Strings,
  SysUtils,
  StrUtils,
  utf8proc in '../utf8proc.pas';

var
  i: integer;
  str_up, str_lo: string;
  x, c: utf8proc_uint32_t;
  cstr: array[0..15] of ansichar;
  map: pansichar;
  p: Putf8proc_property_t;

begin
  i := 1;
  for i := 1 to Pred(argc) do
  begin
    if (strcomp(argv[i], '-V') = 0) then
    begin
      writeln('utf8proc version ', utf8proc_version());
      continue;
    end;
    x := StrToIntDef('$' + argv[i], High(Int32));
    check(x <> High(Int32), 'invalid hex input %s', [argv[i]]);
    c := x;
    p := utf8proc_get_property(c);

    if (utf8proc_codepoint_valid(c)) then
      cstr[utf8proc_encode_char(c, cstr)] := #0
    else
      strcat(cstr, 'N/A');

    utf8proc_map(cstr, 0, @map, UTF8PROC_NULLTERM or UTF8PROC_CASEFOLD);
    str_up := IfThen(utf8proc_isupper(c), ' (isupper)', '');
    str_lo := IfThen(utf8proc_islower(c), ' (islower)', '');

    writeln(Format('U+%s: %s', [argv[i], pansichar(cstr)]));
    writeln(Format('  category := %s', [utf8proc_category_string(Ord(utf8proc_category(c)))]));
    writeln(Format('  combining_class := %d', [p^.combining_class]));
    writeln(Format('  bidi_class := %d', [p^.bidi_class]));
    writeln(Format('  decomp_type := %d', [p^.decomp_type]));
    writeln(Format('  uppercase_mapping := %04X (seqindex %04X)%s', [utf8proc_toupper(c), p^.uppercase_seqindex, str_up]));
    writeln(Format('  lowercase_mapping := %04X (seqindex %04X)%s', [utf8proc_tolower(c), p^.lowercase_seqindex, str_lo]));
    writeln(Format('  titlecase_mapping := %04X (seqindex %04X)', [utf8proc_totitle(c), p^.titlecase_seqindex]));
    writeln(Format('  casefold := %s', [pansichar(map)]));
    writeln(Format('  comb_index := %d', [p^.comb_index]));
    writeln(Format('  comb_length := %d', [p^.comb_length]));
    writeln(Format('  comb_issecond := %s', [BoolToStr(p^.comb_issecond, True)]));
    writeln(Format('  bidi_mirrored := %s', [BoolToStr(p^.bidi_mirrored, True)]));
    writeln(Format('  comp_exclusion := %s', [BoolToSTr(p^.comp_exclusion, True)]));
    writeln(Format('  ignorable := %s', [BoolToStr(p^.ignorable, True)]));
    writeln(Format('  control_boundary := %s', [BoolToStr(p^.control_boundary, True)]));
    writeln(Format('  boundclass := %d', [p^.boundclass]));
    writeln(Format('  indic_conjunct_break := %d', [p^.indic_conjunct_break]));
    writeln(Format('  charwidth := %d', [utf8proc_charwidth(c)]));

    utf8proc_free(map);
  end;

  writeln('Press enter to exit');
  readln;
end.
