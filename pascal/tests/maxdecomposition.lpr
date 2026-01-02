program maxdecomposition;

{$ifdef FPC}
{$mode delphi}
{$endif}   

uses
  utf8proc;

var
  maxsize:utf8proc_ssize_t;
  success:boolean;
  dst:array[0..127] of utf8proc_int32_t;
  c:utf8proc_int32_t;
  sz:utf8proc_ssize_t;

const
  expected_maxsize = 4;

begin

  {* Check the maximum decomposed size exited by utf8proc_decompose_char with UTF8PROC_DECOMPOSE,
     in order to give a hint in the documentation.  The hint will need to be updated if this changes. *}
    maxsize:=0;
    for c := 0 to $110000 do
    begin
      sz := utf8proc_decompose_char(c, dst, 128, UTF8PROC_DECOMPOSE, nil);
      if sz > maxsize then
        maxsize := sz;
    end;
    success := expected_maxsize = maxsize;
    if success then
      write('SUCCEEDED')
    else
      write('FAILED');
    writeln(' maximum decomposed size = ',maxsize,' chars');
    writeln('Press <enter> to exit.');
    readln;
    ExitCode := (integer( not success));
end.

