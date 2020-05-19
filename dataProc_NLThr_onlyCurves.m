clc;clear;
close all;

Lsize=5;
fSize=30;

labelOpt={'Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold'};

opt.Linewidth=Lsize;

FiberDisp=1800;
DispLeft=-1500;
DispRight=3000;

ResultsFolder='fixed_step_1';
q=dir(ResultsFolder);
q=q(4:end);
picFolder=[ResultsFolder,'_pic'];
mkdir(picFolder);


for w=1:length(q)
    nameOfCurFile=q(w).name;
    load([pwd,'/',ResultsFolder,'/',nameOfCurFile],'data_NCh_fixed','N','dCh');
    nC=size(data_NCh_fixed,2)-1;
%     nC=min(nC,2);

    CurveParam=zeros(nC,3);
    f=figure('Position',[1,74,1680,900],'PaperSize',[16,9],'PaperUnits','centimeters');
    grid on;
    grid minor;
    hold on;
    for k=1:nC
        [CurveParam(k,1),CurveParam(k,2),CurveParam(k,3)]=CentAndWidthOfDispCurve(data_NCh_fixed.Disps+FiberDisp,data_NCh_fixed{:,k+1});
        plot(data_NCh_fixed.Disps+FiberDisp,data_NCh_fixed{:,k+1},'Linewidth',Lsize)
    end

    names=string(data_NCh_fixed.Properties.VariableNames);
    names=names(2:end);
    PinVal=zeros(1,nC);
    for k=1:nC
        PinVal(k)=str2num(names{k}((regexp(names(k),"=")+1):(regexp(names(k),"dBm")-1)));
        names(k)=sprintf("P$_{\\textrm{in}} = %d $ dBm",PinVal(k));
    end

    legend(names,'FontSize',20,'Interpreter','latex','Location','southwest');
    xlabel('Residual dispersion, ps/nm',labelOpt{:});
    ylabel('OSNR$_{\textrm{req}}$ at $10^{-10}$ BER, dB',labelOpt{:});
    set(gca,'FontSize', fSize,'FontName','Times New Roman');
    xlim([DispLeft,DispRight]);
    hold off;
    
    CurGraphTitle=sprintf('Total number of channels = %d; Grid spacing = %d GHz',N,dCh*100);
    sgtitle(CurGraphTitle,'Interpreter','latex','FontSize', fSize);
%     hgexport(f,nameOfCurFile(1:end-4));
    print('-painters','-dpdf','-fillpage',[picFolder,'/',nameOfCurFile(1:end-4)]);
    close(gcf);
    % CurveParam(:,1)=CurveParam(:,3)-CurveParam(:,2)/2;
end