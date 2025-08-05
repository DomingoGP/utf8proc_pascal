program casep;

// The 9 tests failed seems correct to me.
// maybe my version of towlower, towupper is not correct

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  SysUtils,
  test,
  Strings,
  LazUtf8,
  utf8proc in '../utf8proc.pas';

type

  wint_t = utf8proc_int32_t;

var

  tests: integer;
  error, better: integer;


  c:utf8proc_int32_t;
  l:utf8proc_int32_t;
  u:utf8proc_int32_t;
  t:utf8proc_int32_t;
  s1,s2:PAnsiChar;
  l0,u0:wint_t;


// in Pascal we don't have towlower
// not sure that this is the correct implementation.


function towlower(c:wint_t):wint_t;
var
  r:ansistring;
  cp:Int32;
begin
   result:=c;
   r:=AnsiLowerCase(PAnsiChar(unicodeToUTF8(c)));
   if utf8proc_iterate(PAnsiChar(r),length(r),@cp)>0 then
     result:=cp;
end;


function towupper(c:wint_t):wint_t;
var
  r:ansistring;
  cp:Int32;
begin
   result:=c;
   r:=AnsiUpperCase(PAnsiChar(unicodeToUTF8(c)));
   if utf8proc_iterate(PAnsiChar(r),length(r),@cp)>0 then
     result:=cp;
end;


//  too many mismatches
//function towupper(c:wint_t):wint_t;cdecl; external 'msvcr120.dll';
//function towlower(c:wint_t):wint_t;cdecl; external 'msvcr120.dll';

begin
  lineno := 0;
  better := 0;
  failures := 0;

  tests := 0;
  error := 0;

  l:=towlower($DF6E);
  u:=towupper($DF6E);

  l:=towlower($61);  //a
  u:=towupper($61);
  l:=towlower($41);  //A
  u:=towupper($41);


  {* some simple sanity tests of the character widths *}
  c:=0;
  while  c <= $110000 do
  begin
       l := utf8proc_tolower(c);
       u := utf8proc_toupper(c);
       t := utf8proc_totitle(c);

       check((l = c)  or  utf8proc_codepoint_valid(l), 'invalid tolower',[]);
       check((u = c)  or  utf8proc_codepoint_valid(u), 'invalid toupper',[]);
       check((t = c)  or  utf8proc_codepoint_valid(t), 'invalid totitle',[]);

       if utf8proc_codepoint_valid(c)  and  ((l = u) <> (l = t))  and
           {* Unicode 11: Georgian Mkhedruli chars have uppercase but no titlecase. *}
            not ((((c >= $10d0)  and  (c <= $10fa))  or  (c >= ($10fd  and Ord( c <= $10ff))))  and  (l <> u)) then
       begin
            writeln(Format('unexpected titlecase %x for lowercase %x / uppercase %x',[ t, l, c]));
            inc(error);
       end;

       if ((sizeof(wint_t) > 2)  or  ((c < (1 shl 16))  and  (u < (1 shl 16))  and  (l < (1 shl 16)))) then
       begin
            l0 := towlower(wint_t(c));
            u0 := towupper(wint_t(c));

            {* OS unicode tables may be out of date.  But if they
               do have a lower/uppercase mapping, hopefully it
               is correct? *}
            if (l0 <> wint_t(c))  and  (l0 <> wint_t(l)) then
            begin
                 writeln(Format('MISMATCH %x != towlower(%x) = %x',[l, c, l0]));
                 inc(error);
            end
            else if (l0 <> wint_t(l)) then
            begin {* often true for out-of-date OS unicode *}
                 inc(better);
                 {* printf("%x != towlower(%x) = %x\n", l, c, l0); *}
            end;
            if (u0 <> wint_t(c))  and  (u0 <> wint_t(u)) then
            begin
                 writeln(Format('MISMATCH %x != towupper(%x) = %x',[u, c, u0]));
                 inc(error);
            end
            else if (u0 <> wint_t(u)) then
            begin {* often true for out-of-date OS unicode *}
                 inc(better);
                 {* printf("%x != towupper(%x) = %x\n", u, c, u0); *}
            end;
       end;

       inc(c);
  end;

  check( error=0, 'utf8proc case conversion FAILED %d tests.', [error]);

  {* issue #130 *}
  check((utf8proc_toupper($00df) = $1e9e)  and
        (utf8proc_totitle($00df) = $1e9e)  and
        (utf8proc_tolower($00df) = $00df)  and
        (utf8proc_tolower($1e9e) = $00df)  and
        (utf8proc_toupper($1e9e) = $1e9e),
        'incorrect $00df/$1e9e case conversions',[]);
  s1 := utf8proc_NFKC_Casefold(#$c3#$9f#$00);
  s2 := utf8proc_NFKC_Casefold(#$e1#$ba#$9e#$00);
  check( (strcomp(s1, 'ss')=0)  and
         (strcomp(s2, 'ss')=0),
        'incorrect $00df/$1e9e casefold normalization',[]);
  utf8proc_free(s1);
  utf8proc_free(s2);

  writeln(Format('More up-to-date than OS unicode tables for %d tests.',[better]));
  writeln('utf8proc case conversion tests SUCCEEDED.');

  writeln('');
  writeln('Press enter to exit');
  readln;
end.

