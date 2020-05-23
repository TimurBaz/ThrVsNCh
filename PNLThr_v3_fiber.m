clc;
clear;
clearvars;
close all;
tStart=tic;

load('optLibs.mat');
%Open start file, where the scheme will be drawn
directory = strcat(pwd,'\PNLThr_start_for_save.osd');
optsys=OpenOptisystem(directory);

%Get main system variables
Document = optsys.GetActiveDocument;
LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;

%physical settings
FiberDisp=1800;%dispersion of fiber 18[ps/nm/km]*100[km]
maxNLph=1;%max NL phase per step [mrad]

halfN=2;%number of channel on one side of the center
N=halfN*2+1;%total number of channels
ch0=30;%start channel
dCh=1;%distance between consecutive channels
Chs=30:dCh:ch0+dCh*(N-1);%array of investigated channels
NCh=halfN+1;%index of channel under investigation
AnCh=Chs(NCh);%number of channel under investigation
OutputOfOneLaser=0;

Chirp0=-0.65;%alpha parameter of input chirp
m0=0.85;%modulation index of input radiation

Pin=[0:10];%array with param of channels power after input amplifier
 
%drawing settings
compW=34;%width of a Component
compH=34;%heigth of a Component
xL0=10;%start coodinate of first column of dynamic Components
yL0=60;%start coodinate of first row of dynamic Components
dx=100;%horizontal distance between dynamic Components
dy=200;%vertical distance between dynamic Components
xEye=1000;%x coordinate of BER analyzer
yEye=100;%y coordinate of BER analyzer

%customizing lasers of transmitter
LasArr = Canvas.GetComponentByName('CW Laser Array');
LasArr.SetParameterValue('Number of output ports',N);
Layout.AddParameter('OutChP', 2, 'Global', -20, 10,'0', 'dBm','');
Layout.SetParameterValue('OutChP',OutputOfOneLaser);
for k=1:N
    TrFreqName=['Frequency[',num2str(k-1),']'];
    TrPowerName=['Power[',num2str(k-1),']'];
    LasArr.SetParameterValue(TrFreqName,ch2Hz(Chs(k)));
    LasArr.SetParameterMode(TrPowerName,3);%set scripted mode
    LasArr.SetParameterScript(TrPowerName,'OutChP');%parameter will get value from variable OutChP
end


%custmizing Mux, PRBSs, NRZgeneratos and modulators. Connecting them
PRBSName='Pseudo-Random Bit Sequence Generator';
NRZGenName='NRZ Pulse Generator';
ModName='EA Modulator Analytical';
Layout.AddParameter('InChirp', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('InChirp',Chirp0);
Layout.AddParameter('Inm', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('Inm',m0);

MuxName='Ideal Mux';
Mux=Canvas.CreateComponent(MuxName,MuxLib,xL0+dx*4,yL0+dy*(2-0.5), compW, compH,1);
Mux.SetParameterValue('Number of input ports',N);
for k=1:N
    %creating components
    PRBSs(k) = Canvas.CreateComponent(PRBSName,TransLib,xL0+dx,yL0+dy*(k-1), compW, compH,1);
    NRZGens(k) = Canvas.CreateComponent(NRZGenName,TransLib,xL0+dx*2,yL0+dy*(k-1), compW, compH,1);
    Mods(k) = Canvas.CreateComponent(ModName,TransLib,xL0+dx*2,yL0+dy*(k-0.5), compW, compH,1);
    
    %customizing modulator
    Mods(k).SetParameterMode('Modulation index',3);
    Mods(k).SetParameterMode('Chirp factor',3);
    Mods(k).SetParameterScript('Modulation index','Inm');
    Mods(k).SetParameterScript('Chirp factor','InChirp');
    
    %connecting components
    LasArr.GetOutputPort(k).Connect(Mods(k).GetInputPort(2));
    PRBSs(k).GetOutputPort(1).Connect(NRZGens(k).GetInputPort(1));
    NRZGens(k).GetOutputPort(1).Connect(Mods(k).GetInputPort(1));
    Mux.GetInputPort(k).Connect(Mods(k).GetOutputPort(1));
end

%connecting mux with input amplifier
InAmp=Canvas.GetComponentByName('Optical Amplifier');
InAmp.GetInputPort(1).Connect(Mux.GetOutputPort(1));
%InAmp.SetParameterValue('Power', 0+10*log10(N));%set total input power

optFiber=Canvas.GetComponentByName('Optical Fiber CWDM');
optFiber.SetParameterValue('Max. nonlinear phase shift',maxNLph);

SaveFileComp=Canvas.GetComponentByName('Save to file');
SaveFileComp.SetParameterValue('Filename',0);%Set normal mode

NPin=length(Pin);
Layout.SetTotalSweepIterations(1);
InAmp.SetParameterMode('Power',0);%Set normal mode
timeForFile=datestr(now,'mm-dd-yyyy_HH_MM_SS');

Canvas.UpdateAll;%draw all created components and connections
optsys.ActivateApplication();
Document.Save(strcat(pwd,'\PNLThr_ForCalc_Fiber.osd'));
optsys.Quit();
clear optsys;

for k=1:NPin
    disp(Pin(k));
    optsys=OpenOptisystem(strcat(pwd,'\PNLThr_ForCalc_Fiber.osd'));
    Document = optsys.GetActiveDocument;
    LayoutMgr = Document.GetLayoutMgr;
    Layout = LayoutMgr.GetCurrentLayout;
    Canvas = Layout.GetCurrentCanvas;
    InAmp=Canvas.GetComponentByName('Optical Amplifier');
    SaveFileComp=Canvas.GetComponentByName('Save to file');
    
    totalPower=Pin(k)+10*log10(N);
    fileNamek=[timeForFile,sprintf('_N_of_Chs=%d_Pin=%d.ods',N,Pin(k))];
    
    InAmp.SetParameterValue('Power',totalPower);
    SaveFileComp.SetParameterValue('Filename',fileNamek);
    Document.CalculateProject(true,true);
    
    optsys.Quit();
    clear optsys
end





timeOfCals=toc(tStart);% time of calculations
