clc;
clear;
clearvars;
close all;
tStart=tic;

load('optLibs.mat');
%Open start file, where the scheme will be drawn
directory = strcat(pwd,'\PNLThr.osd');
optsys=OpenOptisystem(directory);
Npars=1;%always 1, because parallel calculations weren't implemented

%Get main system variables
Document = optsys.GetActiveDocument;
LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;

%physical settings
FiberDisp=1800;%dispersion of fiber 18[ps/nm/km]*100[km]
maxNLph=12.5;%max NL phase per step [mrad]

halfN=4;%number of channel on one side of the center
N=halfN*2+1;%total number of channels
ch0=30;%start channel
dCh=1;%distance between consecutive channels
Chs=30:dCh:ch0+dCh*(N-1);%array of investigated channels
NCh=halfN+1;%index of channel under investigation
AnCh=Chs(NCh);%number of channel under investigation
OutputOfOneLaser=0;

Chirp0=-0.65;%alpha parameter of input chirp
m0=0.85;%modulation index of input radiation
OuputPower=-10;%total optical power after output amplifier

APDGain=10;
APDResp=0.85;
APDIon=0.9;
NF=0;
FiltBand=50;

Disps=-3000:100:2000;%array with investigating dispersion points
NDisps=length(Disps);
NDisp=length(Disps);%number of dispersion points
BERreq=10^-10;%value of req BER
dDispThr=200;%threshold for dispersion curve variations

Pin=[0,1];%array with param of channels power after input amplifier
    if (mod(length(Pin),Npars)==0) 
        Pin=reshape(Pin,Npars,length(Pin)/Npars);
    else
        error='size of Pin is not agreed with Npars';
        return;
    end
 
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

optFiber=Canvas.GetComponentByName('Optical Fiber');
optFiber.SetParameterValue('Max. nonlinear phase shift',maxNLph);

OSNRController=Canvas.GetComponentByName('Set OSNR');
OSNRController.SetParameterValue('Signal Frequency',ch2Hz(AnCh));

NFork=Canvas.GetComponentByName('Fork 1xN');
NFork.SetParameterValue('Number of output ports',NDisps);

bgName='Ideal Dispersion Compensation FBG';
optFiltName='Gaussian Optical Filter';
optAmpName='Optical Amplifier';
APDName='APD';
LPFName='Low Pass Bessel Filter';
RegName='3R Regenerator';
EyeName='BER Analyzer';
numCol=10;

%draw receivers
for k=1:NDisps
    BG(k)=Canvas.CreateComponent(bgName,DispCompLib,xL0+numCol*dx,yL0+dy*(k-1), compW, compH,1);
    OptFilt(k)=Canvas.CreateComponent(optFiltName,FiltLib,xL0+(numCol+1)*dx,yL0+dy*(k-1), compW, compH,1);
    OptAmp(k)=Canvas.CreateComponent(optAmpName,AmpLib,xL0+(numCol+2)*dx,yL0+dy*(k-1), compW, compH,1);
    APD(k)=Canvas.CreateComponent(APDName,RecLib,xL0+(numCol+3)*dx,yL0+dy*(k-1), compW, compH,1);
    LPF(k)=Canvas.CreateComponent(LPFName,FiltLib,xL0+(numCol+4)*dx,yL0+dy*(k-1), compW, compH,1);
    Reg(k)=Canvas.CreateComponent(RegName,RecLib,xL0+(numCol+5)*dx,yL0+dy*(k-1), compW, compH,1);
    EyeOsc(k)=Canvas.CreateComponent(EyeName,VisLib,xL0+(numCol+7)*dx,yL0+dy*(k-1), compW, compH,1);
    
    %customizing recievers
    BG(k).SetParameterValue('Frequency',ch2Hz(AnCh));
    BG(k).SetParameterValue('Bandwidth',100*(N+2));
    BG(k).SetParameterValue('Dispersion',Disps(k));
    OptFilt(k).SetParameterValue('Frequency',ch2Hz(AnCh));
    OptFilt(k).SetParameterValue('Bandwidth',FiltBand);
    APD(k).SetParameterValue('Gain',APDGain);
    APD(k).SetParameterValue('Responsivity',APDResp);
    APD(k).SetParameterValue('Ionization ratio',APDIon);
    OptAmp(k).SetParameterValue('Operation mode', 'Power control');
    OptAmp(k).SetParameterValue('Power', OuputPower);
    OptAmp(k).SetParameterValue('Noise figure',NF);
    %LPF(k).SetParameterValue('Cutoff frequency','0.75*Symbol rate');
    
    %connecting components
    NFork.GetOutputPort(k).Connect(BG(k).GetInputPort(1));
    BG(k).GetOutputPort(2).Connect(OptFilt(k).GetInputPort(1));
    OptFilt(k).GetOutputPort(1).Connect(OptAmp(k).GetInputPort(1));
    OptAmp(k).GetOutputPort(1).Connect(APD(k).GetInputPort(1));
    APD(k).GetOutputPort(1).Connect(Reg(k).GetInputPort(1));
    Reg(k).GetOutputPort(1).ConnectVisualizer(EyeOsc(k).GetInputPort(1));
    Reg(k).GetOutputPort(2).ConnectVisualizer(EyeOsc(k).GetInputPort(2));
    Reg(k).GetOutputPort(3).ConnectVisualizer(EyeOsc(k).GetInputPort(3));
end

Canvas.UpdateAll;%draw all created components and connections
Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));

OSNRs=15:50;
NOSNRs=length(OSNRs);
data_BER=zeros(NDisps,length(OSNRs));

for m=1:NOSNRs
    OSNRController.SetParameterValue('Set OSNR',OSNRs(m));
    Document.CalculateProject( true , true);
    for k=1:NDisps
        data_BER(k,m)=BEROsc.GetResultValue('Min. BER');
    end
end

Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));
optsys.Quit;
clear optsys;
timeOfCals=toc(tStart);% time of calculations
save([datestr(now,'mm-dd-yyyy_HH-MM-SS'),'N_of_Chs = ',num2str(N)]);

% BG=Canvas.GetComponentByName('Ideal Dispersion Compensation FBG');
% BG.SetParameterValue('Frequency',ch2Hz(AnCh));
% BG.SetParameterValue('Bandwidth',100*(N+2));
% 
% OptFilt=Canvas.GetComponentByName('Gaussian Optical Filter');
% OptFilt.SetParameterValue('Frequency',ch2Hz(AnCh));
% 
% OutputOptAmp=Canvas.GetComponentByName('Optical Amplifier');
% OutputOptAmp.SetParameterValue('Operation mode','Power control');
% OutputOptAmp.SetParameterValue('Power',OuputPower);
% 
% %creating and customizing BERAnalyzer
% EyeName='BER Analyzer';
% VisLib='{F11D0C25-3C7D-11D4-93F0-0050DAB7C5D6}';
% LPFiltName='Low Pass Bessel Filter';
% 
% BEROsc=Canvas.CreateComponent(EyeName,VisLib,xEye,yEye, compW, compH,1);
% LPF=Canvas.GetComponentByName(LPFiltName);

% PRBSs(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(1));
% NRZGens(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(2));
% LPF.GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(3));
% 
% Canvas.UpdateAll;%draw all created components and connections
% nameOfOptsyss=string(1:Npars);
% for k=1:Npars
%     nameOfOptsyss(k)=strcat("\PNLThr_ForCalc_",num2str(k),".osd");
%     Document.Save(strcat(pwd,convertStringsToChars(nameOfOptsyss(k))));% save document for calculations in the other files
% end
% optsys.Quit;
% clear optsys;

