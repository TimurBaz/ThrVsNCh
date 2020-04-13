clc;
clear;
clearvars;
close all;
tStart=tic;

directory = strcat(pwd,'\PNLThr.osd');
optsys=OpenOptisystem(directory);

Document = optsys.GetActiveDocument;

LayoutMgr = Document.GetLayoutMgr;
Layout = LayoutMgr.GetCurrentLayout;
Canvas = Layout.GetCurrentCanvas;
PmMgr = Layout.GetParameterMgr;
count = Canvas.GetMainCount;

FiberDisp=1800;
compW=34;
compH=34;
xL0=10;
yL0=30;
dx=100;
dy=200;

halfN=3;
N=halfN*2+1;

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
Chirp0=-0.65;
m0=0.85;
Layout.AddParameter('InChirp', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('InChirp',Chirp0);
Layout.AddParameter('Inm', 2, 'Global', -2, 2,'0', '','');
Layout.SetParameterValue('Inm',m0);

for k=1:N
    PRBSs(k) = Canvas.CreateComponent(PRBSName,TransLib,xL0+dx,yL0+dy*(k-1), compW, compH,1);
    NRZGens(k) = Canvas.CreateComponent(NRZGenName,TransLib,xL0+dx*2,yL0+dy*(k-1), compW, compH,1);
    PRBSs(k).GetOutputPort(1).Connect(NRZGens(k).GetInputPort(1));
    Mods(k) = Canvas.CreateComponent(ModName,TransLib,xL0+dx*2,yL0+dy*(k-0.5), compW, compH,1);
    Mods(k).SetParameterMode('Modulation index',3);
    Mods(k).SetParameterMode('Chirp factor',3);
    Mods(k).SetParameterScript('Modulation index','Inm');
    Mods(k).SetParameterScript('Chirp factor','InChirp');
    NRZGens(k).GetOutputPort(1).Connect(Mods(k).GetInputPort(1));
%     a=LasArr.GetOutputPort(k);
    LasArr.GetOutputPort(k).Connect(Mods(k).GetInputPort(2));
end

OptAmpName='Optical Amplifier';
AmpLib='{255EDC8F-37E4-11D4-93EC-0050DAB7C5D6}';
OutChannelPower=10;%dBm
Layout.AddParameter('OutChP', 2, 'Global', -20, 10,'0', 'dBm','');
Layout.SetParameterValue('OutChP',OutChannelPower);

for k=1:N
    OptAmp(k)=Canvas.CreateComponent(OptAmpName,AmpLib,xL0+dx*3,yL0+dy*(k-0.5), compW, compH,1);
    OptAmp(k).GetInputPort(1).Connect(Mods(k).GetOutputPort(1));
    OptAmp(k).SetParameterValue('Operation mode','Power control');
    OptAmp(k).SetParameterMode('Power',3);%set scripted mode
    OptAmp(k).SetParameterScript('Power','OutChP');
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


NCh=halfN+1;
AnCh=Chs(NCh);

OptFilt=Canvas.GetComponentByName('Gaussian Optical Filter');
OptFilt.SetParameterValue('Frequency',190+AnCh/10);


xEye=1000;
yEye=100;
EyeName='BER Analyzer';
VisLib='{F11D0C25-3C7D-11D4-93F0-0050DAB7C5D6}';
LPFiltName='Low Pass Bessel Filter';

BEROsc=Canvas.CreateComponent(EyeName,VisLib,xEye,yEye, compW, compH,1);
LPF=Canvas.GetComponentByName(LPFiltName);

PRBSs(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(1));
NRZGens(NCh).GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(2));
LPF.GetOutputPort(1).ConnectVisualizer(BEROsc.GetInputPort(3));

Canvas.UpdateAll;

OuputPower=-10;
OutputOptAmp=Canvas.GetComponentByName('Optical Amplifier');
OutputOptAmp.SetParameterValue('Operation mode','Power control');
OutputOptAmp.SetParameterValue('Power',OuputPower);


Disps=-3000:2000:2000;
NDisp=length(Disps);
BGName='Ideal Dispersion Compensation FBG';
BG=Canvas.GetComponentByName(BGName);
BG.SetParameterValue('Frequency',190+AnCh/10);
OSNRController=Canvas.GetComponentByName('Set OSNR');
OSNRController.SetParameterValue('Signal Frequency',190+AnCh/10);

OSNRreqs=zeros(1,NDisp);
BERs=zeros(1,NDisp);
BERreq=10^-10;

Pin=[-1:0];

NameOfCols=string(arrayfun(@(x) sprintf('Pin = %d dBm',x),Pin,'UniformOutput',false));
data_NCh_fixed = table(Disps.','VariableNames',"Disps");

dDispThr=200;
CurveParam=zeros(length(Pin),3);
Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));

for p=1:length(Pin)
    % create a COM server running OptiSystem
    optsys.Quit;
    clear optsys;
    directory = strcat(pwd,'\PNLThr_ForCalc.osd');
    optsys=OpenOptisystem(directory);
    
    Document = optsys.GetActiveDocument;
    LayoutMgr = Document.GetLayoutMgr;
    Layout = LayoutMgr.GetCurrentLayout;
    Canvas = Layout.GetCurrentCanvas;

    OSNRController=Canvas.GetComponentByName('Set OSNR');
    BGName='Ideal Dispersion Compensation FBG';
    BG=Canvas.GetComponentByName(BGName);
    BEROsc=Canvas.GetComponentByName(EyeName);
    
    Layout.SetParameterValue('OutChP',Pin(p));
    
    for d =1:NDisp
        BG.SetParameterValue('Dispersion', Disps(d));
        [OSNRreqs(d),BERs(d)] = FindOSNRreq(Document,OSNRController,BEROsc,BERreq);
    end
    [CurveParam(p,1),CurveParam(p,2),CurveParam(p,3)]=CentAndWidthOfDispCurve(Disps+FiberDisp,OSNRreqs);
    data_NCh_fixed = [data_NCh_fixed,table(OSNRreqs.','VariableNames',NameOfCols(p))];
    save(['N_of_Chs =',num2str(N), ' PinStart = ',num2str(Pin(1))],'data_NCh_fixed');
    if (p~=1)
        if ((abs(CurveParam(1,1)-CurveParam(p,1))>dDispThr)|(abs(CurveParam(1,2)-CurveParam(p,2))>dDispThr))
            break;
        end
    end
end

% [DispCent,DispSpan,DispMax] = CentAndWidthOfDispCurve(Disps,OSNRreqs);

Document.Save(strcat(pwd,'\PNLThr_ForCalc.osd'));

optsys.Quit;

% DispCent=DispCent+FiberDisp;
% DispMax=DispMax+FiberDisp;

save([datestr(now,'mm-dd-yyyy_HH-MM-SS'),'N_of_Chs = ',num2str(N)]);
timeOfCals=toc(tStart);

% figure;
% plot(Disps+FiberDisp,OSNRreqs)


