program 登录器配置器;

uses
  Vcl.Forms,
  GxxMain in 'GxxMain.pas' {FrmMain},
  GxxDialogs in 'GxxDialogs.pas';

{$R 'GxxResources.res'}
{$R 'LoginBootstrapResource.res'}
{$R 'ClientResource.res'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '登录器生成器';
  Application.CreateForm(TFrmMain, FrmMain);
  FrmMain.Show;
  Application.Run;
end.
