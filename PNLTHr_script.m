clc;
clear;
clearvars;
close all;


% create a COM server running OptiSystem
optsys = actxserver('optisystem.application');

% Section looks for OptiSystem process and waits for it to start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Execute the system command
        taskToLookFor = 'OptiSystemx64.exe';
        % Now make up the command line with the proper argument
        % that will find only the process we are looking for.
        commandLine = sprintf('tasklist /FI "IMAGENAME eq %s"', taskToLookFor);
        % Now execute that command line and accept the result into "result".
        [status, result] = system(commandLine);
        % Look for our program's name in the result variable.
        itIsRunning = strfind(lower(result), lower(taskToLookFor));
        while isempty(itIsRunning)
          % pause(0.1)
           [status, result] = system(commandLine);
             itIsRunning = strfind(lower(result), lower(taskToLookFor));    
        end
%%%%%%%%%%%%%%%%%%%%%%%%%
directory = strcat(pwd,'\PNLThr.osd');
optsys.Open(directory);

Document = optsys.GetActiveDocument;

LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;
count = Canvas.GetMainCount;

compW=34;
compH=34;
xL0=10;
yL0=30;
dx=100;
dy=200;

N=7;

LasArr = Canvas.GetComponentByName('CW Laser Array');
LasArr.SetParameterValue('Number of output ports',N);
ch0=30;
dCh=1;
Chs=30:dCh:ch0+dCh*(N-1);
for k=1:N
    paramName=['Frequency[',num2str(k-1),']'];
    LasArr.SetParameterValue(paramName,190+Chs(k)/10);
end

PRBSName='Pseudo-Random Bit Sequence Generator';
ModName='EA Modulator Analytical';
NRZGenName='NRZ Pulse Generator';
TransLib='{6DA31CEE-058F-11D4-93BD-0050DAB7C5D6}';

for k=1:N
    PRBSs(k) = Canvas.CreateComponent(PRBSName,TransLib,xL0+dx,yL0+dy*(k-1), compW, compH,1);
    NRZGens(k) = Canvas.CreateComponent(NRZGenName,TransLib,xL0+dx*2,yL0+dy*(k-1), compW, compH,1);
    PRBSs(k).GetOutputPort(1).Connect(NRZGens(k).GetInputPort(1));
    Mods(k) = Canvas.CreateComponent(ModName,TransLib,xL0+dx*2,yL0+dy*(k-0.5), compW, compH,1);
    NRZGens(k).GetOutputPort(1).Connect(Mods(k).GetInputPort(1));
%     a=LasArr.GetOutputPort(k);
    LasArr.GetOutputPort(k).Connect(Mods(k).GetInputPort(2));
end

OptAmpName='Optical Amplifier';
AmpLib='{255EDC8F-37E4-11D4-93EC-0050DAB7C5D6}';
for k=1:N
    OptAmp(k)=Canvas.CreateComponent(OptAmpName,AmpLib,xL0+dx*3,yL0+dy*(k-0.5), compW, compH,1);
    OptAmp(k).GetInputPort(1).Connect(Mods(k).GetOutputPort(1));
end

MuxName='Ideal Mux';
MuxLib='{1747A24E-52A0-11D4-9403-0050DAB7C5D6}';
Mux=Canvas.CreateComponent(MuxName,MuxLib,xL0+dx*4,yL0+dy*(2-0.5), compW, compH,1);
Mux.SetParameterValue('Number of input ports',N);
for k=1:N
    Mux.GetInputPort(k).Connect(OptAmp(k).GetOutputPort(1));
end

OptFib=Canvas.GetComponentByName('Optical Fiber');
OptFib.GetInputPort(1).Connect(Mux.GetOutputPort(1));
% b=q.GetInputPort(2);
% a=LasArr.GetOutputPort(1);
% a.Connect(b);


NCh=4;
AnCh=Chs(NCh);

OptFilt=Canvas.GetComponentByName('Gaussian Optical Filter');
OptFilt.SetParameterValue('Frequency',190+AnCh/10);


xEye=1000;
yEye=100;
EyeName='Eye Diagram Analyzer';
VisLib='{F11D0C25-3C7D-11D4-93F0-0050DAB7C5D6}';
LPFiltName='Low Pass Bessel Filter';

EyeOsc=Canvas.CreateComponent(EyeName,VisLib,xEye,yEye, compW, compH,1);
LPF=Canvas.GetComponentByName(LPFiltName);

PRBSs(NCh).GetOutputPort(1).ConnectVisualizer(EyeOsc.GetInputPort(1));
NRZGens(NCh).GetOutputPort(1).ConnectVisualizer(EyeOsc.GetInputPort(2));
LPF.GetOutputPort(1).ConnectVisualizer(EyeOsc.GetInputPort(3));

Canvas.UpdateAll;


Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));

optsys.Quit;


