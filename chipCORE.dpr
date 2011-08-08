library chipCORE;

uses
  SysUtils,
  Classes,
  chipCoreBase,
  DAudioEffect,
  DAEffect,
  baseInstrument,
  audiohelper;

{$R *.RES}


var
   effect : AudioEffect = nil;
   oome   : boolean = FALSE;

function main(audioMaster: TAudioMasterCallbackFunc): PAEffect; cdecl;
begin
  Result := nil;

  // get vst version
  if audioMaster(nil, audioMasterVersion, 0, 0, nil, 0) = 0 then
    Exit; // old version 

  effect := TchipCore.Create(audioMaster);
  if effect = nil then
    Exit;

  if (oome) then
  begin
    effect.Free;
    effect := nil;
    Exit;
  end;

  Result := effect.Effect;
end;


exports main;

begin
end.
