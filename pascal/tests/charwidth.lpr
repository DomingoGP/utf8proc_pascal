program charwidth;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  Strings,
  utf8proc;

type

  wint_t = utf8proc_int32_t;


function my_unassigned(c:integer):boolean;
var
  cat:utf8proc_category_t;
begin
      cat := utf8proc_get_property(c)^.category;
      exit( (cat = UTF8PROC_CATEGORY_CN)  or  (cat = UTF8PROC_CATEGORY_CO));
  end;

function my_isprint(c:integer):boolean;
var
  cat:utf8proc_category_t;
begin
      cat := utf8proc_get_property(c)^.category;
      exit( ( (UTF8PROC_CATEGORY_LU <= cat)  and  (cat <= UTF8PROC_CATEGORY_ZS))  or
             ((c = $0601)  or  (c = $0602)  or  (c = $0603)  or  (c = $06dd)  or  (c = $00ad))  or
             ((cat = UTF8PROC_CATEGORY_CN))  or  ((cat = UTF8PROC_CATEGORY_CO)) );
  end;

var
  w,c, error, updates:integer;
  cat:utf8proc_category_t;
  ambiguous:boolean;

begin
  error := 0;
  updates := 0;

  {* some simple sanity tests of the character widths *}
  c := 0;

  while c <= $110000 do
  begin
      cat := utf8proc_get_property(c)^.category;
      w := utf8proc_charwidth(c);
       ambiguous := utf8proc_charwidth_ambiguous(c);
      if (((cat = UTF8PROC_CATEGORY_MN)  or  (cat = UTF8PROC_CATEGORY_ME))  and  (w > 0)) then
      begin
          writeln(Format('nonzero width %d for combining char %x',[ w, c]));
          inc(error);
      end;
      if ((w = 0)  and
          (((cat >= UTF8PROC_CATEGORY_LU)  and  (cat <= UTF8PROC_CATEGORY_LO))  or
           ((cat >= UTF8PROC_CATEGORY_ND)  and  (cat <= UTF8PROC_CATEGORY_SC))  or
           ((cat >= UTF8PROC_CATEGORY_SO)  and  (cat <= UTF8PROC_CATEGORY_ZS))))  then
      begin
          writeln(Format('zero width for symbol-like char %x', [c]));
          inc(error);
      end;
      // pascal don't have wcwidth
      //if (c <= 127  and  (( not isprint(c)  and  w > 0)  or  (isprint(c)  and  wcwidth(c) != w))) begin
      //    fprintf(stderr, "wcwidth %d mismatch %d for %s ASCII %x\n",
      //    wcwidth(c), w,
      //    isprint(c) ? "printable" : "non-printable", c);
      //    inc(error)
      //end;
      if (c <= 127)  and  utf8proc_charwidth_ambiguous(c) then
      begin
          writeln(Format('ambiwith set for ASCII %x',[ c]));
          inc(error);
      end;
      if  (not my_isprint(c))  and ( w > 0) then
      begin
          writeln(Format('non-printing %x had width %d',[ c, w]));
          inc(error);
      end;
      if (my_unassigned(c)  and  (w <> 1)) then
      begin
          writeln(Format('unexpected width %d for unassigned char %x',[ w, c]));
          inc(error);
      end;
      if (ambiguous  and  (w >= 2)) then
      begin
          writeln(Format('char %x is both doublewidth and ambiguous',[ c]));
          inc(error);
      end;
    inc(c);
  end;
  check(error=0, 'utf8proc_charwidth FAILED %d tests.', [error]);

  check(utf8proc_charwidth($00ad) = 1, 'incorrect width for U+00AD (soft hyphen)',[]);
  check(utf8proc_charwidth_ambiguous($00ad), 'incorrect ambiguous width for U+00AD (soft hyphen)',[]);
  check(utf8proc_charwidth($e000) = 1, 'incorrect width for U+e000 (PUA)',[]);
  check(utf8proc_charwidth_ambiguous($e000), 'incorrect ambiguous width for U+e000 (PUA)',[]);

  check(utf8proc_charwidth_ambiguous($00A1), 'incorrect ambiguous width for U+00A1 (inverted exclamation mark)',[]);
  check(not utf8proc_charwidth_ambiguous($00A2), 'incorrect ambiguous width for U+00A2 (cent sign)',[]);

  //{* print some other information by compariing with system wcwidth *}
  //pascal don't have wcwidth
  //printf("Mismatches with system wcwidth (not necessarily errors):\n");
  //for (c := 0; c <= $110000; ++c) begin
  //    int w := utf8proc_charwidth(c);
  //    int wc := wcwidth(c);
  //    if (sizeof(wchar_t) = 2  and  c >= (1 shl 16)) continue;
  //    {* lots of these errors for out-of-date system unicode tables *}
  //    if (wc = -1  and  my_isprint(c)  and   not my_unassigned(c)  and  w > 0)
  //        updates +:= 1;
  //    if (wc = -1  and   not my_isprint(c)  and  w > 0)
  //        printf("  wcwidth(%x) := -1 for non-printable width-%d char\n", c, w);
  //    if (wc >= 0  and  wc != w)
  //        printf("  wcwidth(%x) := %d != charwidth %d\n", c, wc, w);
  //end;

  writeln(Format('   ... (positive widths for %d chars unknown to wcwidth) ...',[updates]));
  writeln('Character-width tests SUCCEEDED.');

  writeln('');
  writeln('Press enter to exit');
  readln;
end.

