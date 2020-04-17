clc;clear;
close all;

Lsize=3;
fSize=14;
FiberDisp=1800;
DispLeft=-1500;
DispRight=2500;

ResultsFolder='results_week_1';
q=dir(ResultsFolder);
q=q(4:end);
picFolder=[ResultsFolder,'_pic'];
mkdir(picFolder);

for w=1:length(q)
    nameOfCurFile=q(w).name;
    load([pwd,'/',ResultsFolder,'/',nameOfCurFile],'data_NCh_fixed','N');
    nC=size(data_NCh_fixed,2)-1;

    CurveParam=zeros(nC,3);
    f=figure('Position',[1,74,1680,600],'PaperSize',[16,5.7],'PaperUnits','centimeters');
    subplot(1,2,1);
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

    legend(names,'FontSize',fSize,'Interpreter','latex');
    xlabel('Resudial dispersion, ps/nm','Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');
    ylabel('OSNR$_{\textrm{req}}$, dB','Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');
    set(gca,'FontSize', fSize,'FontName','Times New Roman');
    xlim([DispLeft,DispRight]);
    hold off;

    subplot(1,2,2);
    set(gca,'FontSize', fSize,'FontName','Times New Roman');
    xlabel('P$_{\textrm{in}}$, dBm','Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');
    yyaxis left;
    plot(PinVal,CurveParam(:,1),'Linewidth',Lsize);
    ylabel('Curve Center, ps/nm','Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');

    yyaxis right;
    plot(PinVal,CurveParam(:,2),'Linewidth',Lsize);
    ylabel('Curve Width, ps/nm','Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');

    sgtitle(['Total number of channels = ',num2str(N)],'Interpreter','latex','FontSize', fSize);
%     hgexport(f,nameOfCurFile(1:end-4));
    print('-painters','-dpdf','-fillpage',[picFolder,'/',nameOfCurFile(1:end-4)]);
    close(gcf);
    % CurveParam(:,1)=CurveParam(:,3)-CurveParam(:,2)/2;
end