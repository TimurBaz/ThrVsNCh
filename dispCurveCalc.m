function OSNRreqs=dispCurveCalc(ParStep,BERreq,directory,OSNRContName,BGName,BEROscName,InAmpName,Pamp,Disps,FoldersName)
    %optsys - class with already opened file for calculations
    %FoldersName - directory for eyes
    %Pamp - total input power
    %Disps - array with dispersions for compensator
    optsys=OpenOptisystem(directory);
    Document = optsys.GetActiveDocument;
    LayoutMgr = Document.GetLayoutMgr;
    Layout = LayoutMgr.GetCurrentLayout;
    Canvas = Layout.GetCurrentCanvas;
    OSNRController=Canvas.GetComponentByName(OSNRContName);
    InAmp=Canvas.GetComponentByName(InAmpName);
    BG=Canvas.GetComponentByName(BGName);
    BEROsc=Canvas.GetComponentByName(BEROscName);
    eyeDiagram=BEROsc.GetGraph("Eye Diagram");
    
    NDisp=length(Disps);
    OSNRreqs=zeros(NDisp,1);
    
    InAmp.SetParameterValue('Power', Pamp);%set total input power
    mkdir(FoldersName);
    for d =1:NDisp
        if (mod(d,ParStep)==0)
            optsys.Quit;
            clear optsys;
            optsys=OpenOptisystem(directory);
            Document = optsys.GetActiveDocument;
            LayoutMgr = Document.GetLayoutMgr;
            Layout = LayoutMgr.GetCurrentLayout;
            Canvas = Layout.GetCurrentCanvas;
            OSNRController=Canvas.GetComponentByName(OSNRContName);
            InAmp=Canvas.GetComponentByName(InAmpName);
            BG=Canvas.GetComponentByName(BGName);
            BEROsc=Canvas.GetComponentByName(BEROscName);
            eyeDiagram=BEROsc.GetGraph("Eye Diagram");
            InAmp.SetParameterValue('Power', Pamp);
        end
        BG.SetParameterValue('Dispersion', Disps(d));
        OSNRreqs(d) = FindOSNRreq_v2(Document,Layout,OSNRController,BEROsc,BERreq);
%         [x,y]=export_data(eyeDiagram,1);
%         save([FoldersName,'\','N_of_Chs =',num2str(N), ' Pin = ', num2str(Pin(p)),'_Dispersion = ',num2str(Disps(d))],'x','y')
    end
    optsys.Quit;
end