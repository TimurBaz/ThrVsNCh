clc;
clear;
clearvars;
close all;
tStart=tic;

%Open start file, where the scheme will be drawn
directory = strcat(pwd,'\PNLThr.osd');
optsys=OpenOptisystem(directory);

%Get main system variables
Document = optsys.GetActiveDocument;
LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;

%physical settings
FiberDisp=1800;%dispersion of fiber 18[ps/nm/km]*100[km]

halfN=5;%number of channel on one side of the center
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

Disps=-3000:100:2000;%array with investigating dispersion points
NDisp=length(Disps);%number of dispersion points
BERreq=10^-10;%value of req BER
dDispThr=200;%threshold for dispersion curve variations

Pin=[-6:-3];%array with param of channels power after input amplifier
 
%drawing settings
compW=34;%width of a Component
compH=34;%heigth of a Component
xL0=10;%start coodinate of first column of dynamic Components
yL0=30;%start coodinate of first row of dynamic Components
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
TransLib='{6DA31CEE-058F-11D4-93BD-0050DAB7C5D6}';
Layout.AddParameter('InChirp', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('InChirp',Chirp0);
Layout.AddParameter('Inm', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('Inm',m0);

MuxName='Ideal Mux';
MuxLib='{1747A24E-52A0-11D4-9403-0050DAB7C5D6}';
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
InAmp=Canvas.GetComponentByName('Optical Amplifier_1');
InAmp.GetInputPort(1).Connect(Mux.GetOutputPort(1));

OSNRController=Canvas.GetComponentByName('Set OSNR');
OSNRController.SetParameterValue('Signal Frequency',ch2Hz(AnCh));

BG=Canvas.GetComponentByName('Ideal Dispersion Compensation FBG');
BG.SetParameterValue('Frequency',ch2Hz(AnCh));
BG.SetParameterValue('Bandwidth',100*(N+2));

OptFilt=Canvas.GetComponentByName('Gaussian Optical Filter');
OptFilt.SetParameterValue('Frequency',ch2Hz(AnCh));

OutputOptAmp=Canvas.GetComponentByName('Optical Amplifier');
OutputOptAmp.SetParameterValue('Operation mode','Power control');
OutputOptAmp.SetParameterValue('Power',OuputPower);

%creating and customizing BERAnalyzer
EyeName='BER Analyzer';
VisLib='{F11D0C25-3C7D-11D4-93F0-0050DAB7C5D6}';
LPFiltName='Low Pass Bessel Filter';

BEROsc=Canvas.CreateComponent(EyeName,VisLib,xEye,yEye, compW, compH,1);
LPF=Canvas.GetComponentByName(LPFiltName);

PRBSs(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(1));
NRZGens(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(2));
LPF.GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(3));

Canvas.UpdateAll;%draw all created components and connections
Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));% save document for current calculations in another file 

OSNRreqs=zeros(1,NDisp);%temp variable with OSNR
BERs=zeros(1,NDisp);%temp variable with BER

%create table for results of calcs
NameOfCols=string(arrayfun(@(x) sprintf('Pin = %d dBm',x),Pin,'UniformOutput',false));
data_NCh_fixed = table(Disps.','VariableNames',"Disps");

CurveParam=zeros(length(Pin),3);%array for dispersion curve params...
%first column - center, second - span, third - max dispersion

%cycle with main calculations
totalInputPower = Pin + 10 * log10(N);

folderName=[datestr(now,'mm-dd-yyyy_HH-MM-SS'),'_N_of_Chs =',num2str(N)];
mkdir(folderName);
for p=1:length(Pin)
    optsys.Quit;
    clear optsys;
    directory = strcat(pwd,'\PNLThr_ForCalc.osd');
    optsys=OpenOptisystem(directory);
    
    Document = optsys.GetActiveDocument;
    LayoutMgr = Document.GetLayoutMgr;
    Layout = LayoutMgr.GetCurrentLayout;
    Canvas = Layout.GetCurrentCanvas;

    OSNRController=Canvas.GetComponentByName('Set OSNR');
    InAmp=Canvas.GetComponentByName('Optical Amplifier_1');
    BG=Canvas.GetComponentByName('Ideal Dispersion Compensation FBG');
    BEROsc=Canvas.GetComponentByName(EyeName);
    eyeDiagram=BEROsc.GetGraph("Eye Diagram");
    
    %total input power in dBm =
    %10*log10(PowerOfOneChannel*N)=10*log10(PowerOfOneChannel)+10*log10(N)=Pin+10*log10(N)
    InAmp.SetParameterValue('Power', totalInputPower(p));%set total input power
    
    cd(folderName);
    curFolderName=['Pin = ',num2str(Pin(p)),' dBm'];
    mkdir(curFolderName);
    cd('..');
    %one dispersion curve calcalations
    for d =1:NDisp
        BG.SetParameterValue('Dispersion', Disps(d));
        OSNRreqs(d) = FindOSNRreq_v2(Document,Layout,OSNRController,BEROsc,BERreq);
        [x,y]=export_data(eyeDiagram,1);
        save([folderName,'\',curFolderName,'\','N_of_Chs =',num2str(N), ' Pin = ', num2str(Pin(p)),'_Dispersion = ',num2str(Disps(d))],'x','y')
    end
    [CurveParam(p,1),CurveParam(p,2),CurveParam(p,3)]=CentAndWidthOfDispCurve(Disps+FiberDisp,OSNRreqs);
    data_NCh_fixed = [data_NCh_fixed,table(OSNRreqs.','VariableNames',NameOfCols(p))];
%     save(['N_of_Chs =',num2str(N), ' PinStart =',num2str(Pin(1))],'data_NCh_fixed');%backup
    %checking nonlinear thr
    if (p~=1)
        if ((abs(CurveParam(1,1)-CurveParam(p,1))>dDispThr)|(abs(CurveParam(1,2)-CurveParam(p,2))>dDispThr))
            break;
        end
    end
    
end

Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));

optsys.Quit;

save([datestr(now,'mm-dd-yyyy_HH-MM-SS'),'N_of_Chs = ',num2str(N)]);
timeOfCals=toc(tStart);


