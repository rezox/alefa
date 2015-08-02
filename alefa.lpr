program alefa;

{ <description>

  Copyright (C) 2008 Thierry Andriamirado <thierry_andriamirado@yahoo.fr>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}


{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  { you can add units after this }
  process;

const
  authorMail = 'thierry_andriamirado@yahoo.fr';
  authorTwitter = 'http://twitter.com/tandriamirado';
  
type

  { TAlefa }

  TAlefa = class(TCustomApplication)
  private
    appToRun: string;
    procExec: TProcess;
    // Options:
    optInfinite: boolean;
    optShowExitCode : boolean;
    optUntilExitCode0 : boolean;
    optTries: integer;
    optWait: longint;
    procedure RunIt;
    procedure setOptions;
    procedure initAlefa;
    procedure postExecTry;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure ShowUsage;
  end;

{ TAlefa }

procedure TAlefa.RunIt;
var
  pathAppToRun, parametersAppToRun : String;
  nbTries: Integer;
  nbEndStr: String;
begin
  nbTries := 0;
  if optInfinite then nbEndStr := 'Infinite' else nbEndStr := IntToStr(optTries) +':';
//  appToRun.
  //procExec.CommandLine := appToRun;
  procExec.CommandLine := 'sh -c "' + appToRun +'"';
  
//  ExecuteProcess(appToRun,'');

  repeat
    if nbTries > 0 then begin
       Sleep(optWait);
       writeln('Try #' + IntToStr(nbTries + 1) + '/' + nbEndStr);
    end;
    procExec.Active := true;           // go!
    nbTries := nbTries + 1;
    postExecTry;
    //writeln('nbTries: ' + IntToStr(nbTries));
  until ((nbTries = optTries) and (optInfinite = false)) or ((procExec.ExitStatus = 0)  and (optInfinite = false));

end;

procedure TAlefa.setOptions;
begin
  { Alefa's options }
  // -i, --infinite: infinite retries
  if HasOption('i', 'infinite') then optInfinite := true;
  // -t, --tries=NUMBER: tries NUMBER times. Default: 5
  if HasOption('t', 'tries') then optTries := StrToInt(GetOptionValue('t', 'tries'))
     else optTries := 5;
  // -u, --unlimits: unlimits tries, equiv: -t 0
  if HasOption('u', 'unlimits') then begin
     OptUntilExitCode0 := true;
     optTries := 0;
  end;
  // -w, --wait: SECONDS between retries. Default: 1
  if HasOption('w','wait') then optWait := StrToInt(GetOptionValue('w','wait')) * 1000
     else optWait := 1000;
  // -x, --exitcode: show exit code
  if HasOption('x', 'exitcode') then OptShowExitCode := true;

  { Processe's options }
  procExec.Options := procExec.Options + [poWaitOnExit];
end;

procedure TAlefa.initAlefa;
begin
  OptShowExitCode := false;
  OptUntilExitCode0 := false;
  optTries := 0;
end;

procedure TAlefa.postExecTry;
begin
  if OptShowExitCode then writeln('Exit Code: ' + IntToStr(procExec.ExitStatus));
end;

procedure TAlefa.DoRun;
var
  ErrorMsg: String;

begin
  initAlefa;
  // quick check parameters
  ErrorMsg:=CheckOptions('h i x t: u w::','help infinite exitcode tries: unlimits wait::');
//  ErrorMsg:=CheckOptions('t','tries');
  
  if ErrorMsg<>'' then begin
    WriteHelp;
    writeln('');
    ShowException(Exception.Create(ErrorMsg));
    Halt;
  end;

  // parse parameters
  
  if ParamCount = 0 then begin
    ShowUsage;
    Halt;
  end;
  
  if HasOption('h', 'help') then begin
    // Show help screen and exit
    WriteHelp;
    Halt;
  end else begin
    // Core
    appToRun := ParamStr(ParamCount);
    setOptions;

    // Run it!
    RunIt;
    //postExecTry;
  end;

  { add your program here }

  // stop program loop
  Terminate;
end;

constructor TAlefa.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  procExec := TProcess.Create(nil);
end;

destructor TAlefa.Destroy;
begin
  procExec.Free;
  inherited Destroy;
end;

procedure TAlefa.WriteHelp;
begin
  { add your help code here }
  writeln('Alefa, application launch helper');
  writeln('Copyright (c) 2009 by Thierry Andriamirado');
  WriteLn('');
  writeln('Usage: ', ExtractFileName(ExeName),' [OPTION]... FILE');
  WriteLn('Execute FILE. FILE has to be the last argument, after all the OPTIONs.');
  WriteLn('');
  WriteLn('Mandatory arguments to long options are mandatory for short options too.');
  WriteLn('');
  WriteLn('  -h,  --help               show this help screen.');
  writeln('  -i,  -infinite            re-run until end of time');
  WriteLn('  -t,  --tries=NUMBER       set number of retries to NUMBER (0 unlimits).');
  WriteLn('  -u,  --unlimits           tries until exit code = 0 (equiv: --tries=0).');
  WriteLn('  -w,  --wait=SECONDS       wait SECONDS between retries.');
  WriteLn('  -x,  --exitcode           show exitcode. Can be useful for testing purposes.');
  WriteLn('');
//  WriteLn('Report bugs to <' + authorMail + '>');
  WriteLn('Report bugs to ' + authorTwitter);

end;

procedure TAlefa.ShowUsage;
begin
  writeln('Alefa, application launch helper');
  writeln('Copyright (c) 2008 by Thierry Andriamirado');
  WriteLn('');
  writeln('Usage: ', ExtractFileName(ExeName),' [OPTION]... FILE');
  WriteLn('Execute FILE. FILE has to be the last argument, after all the OPTIONs.');
  WriteLn('');
  WriteLn('Mandatory arguments to long options are mandatory for short options too.');
  WriteLn('');
//  WriteLn('Report bugs to <' + authorMail + '>');
  WriteLn('Report bugs to ' + authorTwitter);

end;

var
  Application: TAlefa;

{$IFDEF WINDOWS}{$R project1.rc}{$ENDIF}

{$IFDEF WINDOWS}{$R alefa.rc}{$ENDIF}

begin
  Application:=TAlefa.Create(nil);
  Application.Run;
  Application.Free;
end.

