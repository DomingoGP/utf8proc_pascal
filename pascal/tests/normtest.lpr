program normtest;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  test,
  Strings,
  utf8proc in '../utf8proc.pas';

type
  CharArray = array[0..1023] of ansichar;

var
  f: Text;
  line: string;      // readed line*
  //lineno:integer;
  buf: pansichar;
  len, offset: size_t;
  Source, NFC, NFD, NFKC, NFKD: CharArray;

  //  #define CHECK_NORM(NRM, norm, src) {                                 \
  //    unsigned char *src_norm = (unsigned char*) utf8proc_ ## NRM((utf8proc_uint8_t*) src);      \
  //    check(!strcmp((char *) norm, (char *) src_norm),                                  \
  //          "normalization failed for %s -> %s", src, norm);          \
  //    free(src_norm);                                                 \
  //}


procedure CHECK_NORM_NFC(norm: pansichar; src: pansichar);
var
  src_norm: pansichar;
begin
  src_norm := utf8proc_NFC(src);
  if strcomp(norm, src_norm) <> 0 then
  begin
    writeln('line ', lineno, ' normalization NFC failed for ', src, ' -> ', norm);
    Inc(failures);
  end;
  FreeMem(src_norm);
end;

procedure CHECK_NORM_NFKC(norm: pansichar; src: pansichar);
var
  src_norm: pansichar;
begin
  src_norm := utf8proc_NFKC(src);
  if strcomp(norm, src_norm) <> 0 then
  begin
    writeln('line ', lineno, ' normalization NFKC failed for ', src, ' -> ', norm);
    Inc(failures);
  end;

  FreeMem(src_norm);
end;

procedure CHECK_NORM_NFD(norm: pansichar; src: pansichar);
var
  src_norm: pansichar;
begin
  src_norm := utf8proc_NFD(src);
  if strcomp(norm, src_norm) <> 0 then
  begin
    writeln('line ', lineno, ' normalization NFD failed for ', src, ' -> ', norm);
    Inc(failures);
  end;
  FreeMem(src_norm);
end;

procedure CHECK_NORM_NFKD(norm: pansichar; src: pansichar);
var
  src_norm: pansichar;
begin
  src_norm := utf8proc_NFKD(src);
  if strcomp(norm, src_norm) <> 0 then
  begin
    writeln('line ', lineno, ' normalization NFKD failed for ', src, ' -> ', norm);
    Inc(failures);
  end;
  FreeMem(src_norm);
end;

begin
  lineno := 0;
  failures := 0;
  try
    Assign(f, 'NormalizationTest.txt');
    reset(f);
  except
    writeln('Can''t open file NormalizationText.txt');
    writeln('Press enter to exit');
    readln;
    exit;
  end;
  while not EOF(f) do
  begin
    readLn(f, line);
    Inc(lineno);
    buf := pansichar(line);
    if (buf[0] = '@') then
    begin
      writeln('line ', lineno, ': ', buf);
      continue;
    end
    else if (lineno mod 1000 = 0) then
      writeln('checking line ', lineno, '...');
    if (buf[0] = '#') then
      continue;

    offset := encode(Source, len, buf);
    offset := offset + encode(NFC, len, buf + offset);
    offset := offset + encode(NFD, len, buf + offset);
    offset := offset + encode(NFKC, len, buf + offset);
    offset := offset + encode(NFKD, len, buf + offset);

    CHECK_NORM_NFC(NFC, Source);
    CHECK_NORM_NFC(NFC, NFC);
    CHECK_NORM_NFC(NFC, NFD);
    CHECK_NORM_NFC(NFKC, NFKC);
    CHECK_NORM_NFC(NFKC, NFKD);

    CHECK_NORM_NFD(NFD, Source);
    CHECK_NORM_NFD(NFD, NFC);
    CHECK_NORM_NFD(NFD, NFD);
    CHECK_NORM_NFD(NFKD, NFKC);
    CHECK_NORM_NFD(NFKD, NFKD);

    CHECK_NORM_NFKC(NFKC, Source);
    CHECK_NORM_NFKC(NFKC, NFC);
    CHECK_NORM_NFKC(NFKC, NFD);
    CHECK_NORM_NFKC(NFKC, NFKC);
    CHECK_NORM_NFKC(NFKC, NFKD);

    CHECK_NORM_NFKD(NFKD, Source);
    CHECK_NORM_NFKD(NFKD, NFC);
    CHECK_NORM_NFKD(NFKD, NFD);
    CHECK_NORM_NFKD(NFKD, NFKC);
    CHECK_NORM_NFKD(NFKD, NFKD);

  end;
  Close(f);
  writeln('');
  if failures > 0 then
    writeln('*** ERROR: ', failures, ' TESTS FAILS')
  else
    writeln('SUCCESS all tests passed');
  writeln('Press enter to exit');
  readln;
end.
