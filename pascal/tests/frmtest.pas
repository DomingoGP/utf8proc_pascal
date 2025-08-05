unit frmTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    btnNormalize: TButton;
    Edit1: TEdit;
    edNFC: TEdit;
    edNFKC_casefold: TEdit;
    edNFKD: TEdit;
    edNFKC: TEdit;
    edNFD: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lbNFC: TLabel;
    lbNFD: TLabel;
    lbNFKC: TLabel;
    lbNFKD: TLabel;
    lbNFKC_casefold: TLabel;
    procedure btnNormalizeClick(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses
  utf8proc;

{$R *.lfm}

function String2Hex ( const s: string ): string;
var
 x: integer;
begin
 result:='';
 for x := 1 to Length(s) do
   result := result + IntToHex(Integer(s[x]),2)+' ';
end;

procedure TForm1.btnNormalizeClick(Sender: TObject);
begin
  edNFC.Text:=utf8procNormalizeNFC(Edit1.Text);
  lbNFC.Caption:=String2Hex(edNFC.Text);
  edNFD.Text:=utf8procNormalizeNFD(Edit1.Text);
  lbNFD.Caption:=String2Hex(edNFD.Text);
  edNFKC.Text:=utf8procNormalizeNFKC(Edit1.Text);
  lbNFKC.Caption:=String2Hex(edNFKC.Text);
  edNFKD.Text:=utf8procNormalizeNFKD(Edit1.Text);
  lbNFKD.Caption:=String2Hex(edNFKD.Text);
  edNFKC_casefold.Text:=utf8procNormalizeNFKDCaseFold(Edit1.Text);
  lbNFKC_casefold.Caption:=String2Hex(edNFKC_casefold.Text);
end;

end.

