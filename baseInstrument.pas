unit baseInstrument;

interface

uses DAEffect, DAEffectX, DAudioEffectX, math, audiohelper, windows;

type TBaseInstrument = class (TObject)
  private
    fName: String;
    fPhase,
    fFrequency: Single;
    fVolume: Single;
    fSampleRate: Single;
  public
    constructor create; overload;

    function getSample: single;
    procedure getSamples(count: Integer; buffer: ppsingle);
    procedure noteOn(note, velocity: Byte; deltaFrames: Integer);
    procedure noteOff(note, velocity: Byte);
    property Name: String read fName write fName;
    property SampleRate: Single read fSampleRate write fSampleRate;
end;

implementation

constructor TBaseInstrument.create;
begin
  inherited create;

  fName := 'BaseInstrument';
end;

procedure TBaseInstrument.noteOn(note, velocity: Byte; deltaFrames: Integer);
begin
  fVolume := 1.0; // velocity / 127;
  fFrequency := noteFreq[note] / fSampleRate;
end;

procedure TBaseInstrument.noteOff(note, velocity: Byte);
begin
  fVolume := 0;
end;

function TBaseInstrument.getSample: single;
begin
  fPhase := fPhase + fFrequency;
  fPhase := frac(fPhase);

  Result := fPhase * fVolume;
end;

procedure TBaseInstrument.getSamples(count: Integer; buffer: ppsingle);
var
  n: Integer;
  sample: single;
  out1,
  out2: psingle;
begin
  out1 := buffer^;
  inc(buffer);
  out2 := buffer^;

  for n := 0 to count - 1 do
  begin
    sample := getSample;

    out1^ := out1^ + sample;
    inc(out1);
    out2^ := out2^ + sample;
    inc(out2);
  end;
end;

end.
