clc;
clear;
clearvars;
close all;
tStart=tic;

load('optLibs.mat');
%Open start file, where the scheme will be drawn
directory = strcat(pwd,'\PNLThr_start_for_load.osd');
optsys=OpenOptisystem(directory);

fileName='05-21-2020_11_32_35_N_of_Chs=3_Pin=0-10.ods';
a2=regexp(fileName,'_Pin')-1;
a1=regexp(fileName,'Chs=')+4;
b2=regexp(fileName,'.ods')-1;
b1=regexp(fileName,'_Pin=')+5;
N=str2num(fileName(a1:a2));
temp=split(fileName(b1:b2),"-");
Pmin=str2num(temp{1});
Pmax=str2num(temp{2});
NPin=Pmax-Pmin+1;

%Get main system variables
Document = optsys.GetActiveDocument;
LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;

%physical settings
FiberDisp=1800;%dispersion of fiber 18[ps/nm/km]*100[km]
maxNLph=12.5;%max NL phase per step [mrad]

halfN=1;%number of channel on one side of the center
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
logBERreq=log10(BERreq);
dDispThr=200;%threshold for dispersion curve variations
 
%drawing settings
compW=34;%width of a Component
compH=34;%heigth of a Component
xL0=10;%start coodinate of first column of dynamic Components
yL0=60;%start coodinate of first row of dynamic Components
dx=100;%horizontal distance between dynamic Components
dy=200;%vertical distance between dynamic Components

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
    APD(k).GetOutputPort(1).Connect(LPF(k).GetInputPort(1));
    LPF(k).GetOutputPort(1).Connect(Reg(k).GetInputPort(1));
    Reg(k).GetOutputPort(1).ConnectVisualizer(EyeOsc(k).GetInputPort(1));
    Reg(k).GetOutputPort(2).ConnectVisualizer(EyeOsc(k).GetInputPort(2));
    Reg(k).GetOutputPort(3).ConnectVisualizer(EyeOsc(k).GetInputPort(3));
end

Canvas.UpdateAll;%draw all created components and connections
Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));
optsys.ActivateApplication();

LoadFromFile=Canvas.GetComponentByName('Load from file');
LoadFromFile.SetParameterValue('Filename',fileName);

OSNRs=15:1:50;
NOSNRs=length(OSNRs);
data_BER=zeros(NPin,NDisps,length(OSNRs));
Document.Save(strcat(pwd,'\PNLThr_ForCalc_Rec.osd'));

for q=0:NPin-1
    LoadFromFile.SetParameterValue('Number of signals to skip',q);
    for m=1:NOSNRs
        OSNRController.SetParameterValue('Set OSNR',OSNRs(m));
        Document.CalculateProject( true , true);
        for k=1:NDisps
            data_BER(q+1,k,m)=EyeOsc(k).GetResultValue('Min. log of BER');
        end
    end
end

Document.Save(strcat(pwd,'\PNLThr_ForCalc_Rec.osd'));
optsys.Quit;
clear optsys;
timeOfCals=toc(tStart);% time of calculations
save([datestr(now,'mm-dd-yyyy_HH-MM-SS'),'N_of_Chs = ',num2str(N)]);