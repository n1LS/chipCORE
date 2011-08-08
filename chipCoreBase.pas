unit chipCoreBase;

interface

uses DAEffect, DAEffectX, DAudioEffectX, math, baseInstrument, audiohelper;

const
  kNumPrograms = 32;
  kNumOutputs  = 2;

  kNumParams   = 0;

type TchipCore = class(AudioEffectX)
    private
      instruments: Array[0..kNumPrograms] of TBaseInstrument;

      currentDelta    : longint;

      procedure initProcess;
    public
      constructor Create(audioMaster: TAudioMasterCallbackFunc);
      destructor Destroy; override;

      procedure process(inputs, outputs: ppsingle; sampleframes: longint); override;
      procedure processReplacing(inputs, outputs: ppsingle; sampleframes: longint); override;
      function processEvents(ev: PVSTEvents): longint; override;

      procedure setProgram(aProgram: longint); override;
      procedure setProgramName(name: pchar); override;
      procedure getProgramName(name: pchar); override;
      procedure setParameter(index: longint; value: single); override;
      function getParameter(index: longint): single; override;
      procedure getParameterLabel(index: longint; aLabel: pchar); override;
      procedure getParameterDisplay(index: longint; text: pchar); override;
      procedure getParameterName(index: longint; aLabel: pchar); override;
      procedure setSampleRate(sampleRate: single); override;
      procedure setBlockSize(blockSize: longint); override;
      procedure resume; override;

      function getOutputProperties(index: longint; properties: PVstPinProperties): boolean; override;
      function getProgramNameIndexed(category, index: longint; text: pchar): boolean; override;
      function copyProgram(destination: longint): boolean; override;
      function getEffectName(name: pchar): boolean; override;
      function getVendorString(text: pchar): boolean; override;
      function getProductString(text: pchar): boolean; override;
      function getVendorVersion: longint;  override; {return 1;}
      function canDo(text: pchar): longint; override;
    end;


implementation

uses
    Windows, SysUtils, DVSTUtils, DAudioEffect;

//-----------------------------------------------------------------------------------------
// TchipCore
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
constructor TchipCore.Create(audioMaster: TAudioMasterCallbackFunc);
var
   i: integer;
begin
  inherited Create(audioMaster, kNumPrograms, kNumParams);

  for i := 0 to kNumPrograms-1 do
  begin
    instruments[i] := TBaseInstrument.Create;
  end;
  
  if Assigned(audioMaster) then
  begin
    setNumInputs(0);				// no inputs
    setNumOutputs(kNumOutputs);	// 2 outputs, 1 for each oscillator
    canProcessReplacing(TRUE);
    hasVu(FALSE);
    hasClip(FALSE);
    isSynth(TRUE);
    setUniqueID(FourCharToLong('c', 'h', 'C', 'R'));			// <<<! *must* change this!!!!
  end;

  initProcess;
  suspend;
end;

//-----------------------------------------------------------------------------------------
destructor TchipCore.Destroy;
var
   i: integer;
begin
  for i := 0 to kNumPrograms-1 do
  begin
    FreeAndNil(instruments[i]);
  end;
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.setProgram(aProgram: longint);
begin
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.setProgramName(name: pchar);
begin
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.getProgramName(name: pchar);
begin
  StrCopy(name, '');
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.getParameterLabel(index: longint; aLabel: pchar);
begin
  StrCopy(aLabel, '');
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.getParameterDisplay(index: longint; text: pchar);
begin
  StrCopy(text, '');
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.getParameterName(index: longint; aLabel: pchar);
begin
  StrCopy(aLabel, '');
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.setParameter(index: longint; value: single);
begin
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getParameter(index: longint): single;
begin
  Result := 0;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getOutputProperties(index: longint; properties: PVstPinProperties): boolean;
begin
  Result := FALSE;

  if (index < kNumOutputs) then
  begin
    StrCopy(properties^.vLabel, pchar(Format('Vstx %d', [index+1])));
    properties^.flags := kVstPinIsActive;
    if (index < 2) then
      properties^.flags := properties^.flags or kVstPinIsStereo; // test, make channel 1+2 stereo

    Result := TRUE;
  end;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getProgramNameIndexed(category, index: longint; text: pchar): boolean;
begin
  Result := FALSE;

  if (index < kNumPrograms) then
  begin
    StrCopy(text, PChar(instruments[index].name));
    Result := TRUE;
  end;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.copyProgram(destination: longint): boolean;
begin
  Result := FALSE;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getEffectName(name: pchar): boolean;
begin
  StrCopy(name, 'chipCore');
  Result := TRUE;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getVendorString(text: pchar): boolean;
begin
  StrCopy(text, 'nILS');
  Result := TRUE;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.getProductString(text: pchar): boolean;
begin
  StrCopy(text, 'chipCore');
  Result := TRUE;
end;

function TchipCore.getVendorVersion: longint;
begin
  Result := 1;
end;

//-----------------------------------------------------------------------------------------
function TchipCore.canDo(text: pchar): longint;
begin
  Result := -1;   // explicitly can't do; 0 => don't know

  if StrComp(text, 'receiveVstEvents') = 0 then
    Result := 1;
  if StrComp(text, 'receiveVstMidiEvent') = 0 then
    Result := 1;
end;

//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------
procedure TchipCore.setSampleRate(sampleRate: single);
var
  b: Byte;
begin
  inherited setSampleRate(sampleRate);

  for b := 0 to kNumPrograms-1 do
    begin
      instruments[b].SampleRate := sampleRate;
    end;
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.setBlockSize(blockSize: longint);
begin
  inherited setBlockSize(blockSize);
  // you may need to have to do something here...
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.resume;
begin
  wantEvents(1);
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.initProcess;
var
   i    : longint;
   wh   : longint;
   k, a : double;
begin
  currentDelta := 0;
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.process(inputs, outputs: ppsingle; sampleFrames: longint);
var
   out1,
   out2: psingle;
begin
  begin
{
    out1 := outputs^;
    inc(outputs);
    out2 := outputs^;
}
    if (currentDelta >= 0) then
    begin
      if (currentDelta >= sampleFrames) // should never happen
        then currentDelta := 0;
      inc(out1, currentDelta);
      inc(out2, currentDelta);
      dec(sampleFrames, currentDelta);
      currentDelta := 0;
    end;

    instruments[0].getSamples(sampleFrames, outputs);
{
    // loop
    dec(sampleFrames);
    while (sampleFrames >= 0) do
    begin
      // this is all very raw, there is no means of interpolation,
      // and we will certainly get aliasing due to non-bandlimited
      // waveforms. don't use this for serious projects...
      out1^ := out1^ + fPhase * fVolume * vol;
      inc(out1);
      out2^ := out2^ + fPhase * fVolume * vol;
      inc(out2);
      fPhase := fPhase + baseFreq;

      if (fPhase > 1) then fPhase := frac(fPhase);

      dec(sampleFrames);
    end;
}
  end;
end;

//-----------------------------------------------------------------------------------------
procedure TchipCore.processReplacing(inputs, outputs: ppsingle; sampleFrames: longint);
begin
  process(inputs, outputs, sampleFrames);
end;

//-----------------------------------------------------------------------------------------
function TchipCore.processEvents(ev: PVstEvents): longint;
var
   i        : longint;
   event    : PVstMidiEvent;
   status   : longint;
   note     : longint;
   velocity : longint;
begin
  for i := 0 to ev^.numEvents-1 do
  begin
    if ((ev^.events[i])^.vType <> kVstMidiType) then
      Continue;

    event := PVstMidiEvent(ev^.events[i]);
    status := event^.midiData[0] and $F0;       // ignoring channel
    if (status = $90) or (status = $80) then    // we only look at notes
    begin
      note := event^.midiData[1] and $7F;
      velocity := event^.midiData[2] and $7F;

      if ((status = $90) and (velocity > 0)) then
        begin
          instruments[0].noteOn(note, velocity, event^.deltaFrames);
        end
      else
        begin
          instruments[0].noteOff(note, velocity);
        end;
    end
    else
    if (status = $B0) and (event^.midiData[1] = $7E) then    // all notes off
    begin
      instruments[0].noteOff(0,0);
    end;

    inc(event);
  end;

  Result := 1;   // want more
end;

end.
