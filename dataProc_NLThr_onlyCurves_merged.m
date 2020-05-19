clc;clear;
close all;

Lsize=5;
fSize=23;

labelOpt={'Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold'};

opt.Linewidth=Lsize;

FiberDisp=1800;
DispLeft=-1500;
DispRight=2500;

ResultsFolder='results_week_2';
q=dir(ResultsFolder);
q=q(4:end);
picFolder=[ResultsFolder,'_pic'];
mkdir(picFolder);

m=0;
if (mod(length(q),2)==0)
   while m+2<=length(q)
      for t=1:2
        w=m+t;
        nameOfCurFile=q(w).name;
        load([pwd,'/',ResultsFolder,'/',nameOfCurFile],'data_NCh_fixed','N','dCh');
        nC=size(data_NCh_fixed,2)-1;
    %     nC=min(nC,2);
        if (t==1)
            f=figure('Position',[1,74,1680,600],'PaperSize',[24,9],'PaperUnits','centimeters');
            subplot(1,2,1);
        else
            subplot(1,2,2);
        end
        grid on;
        grid minor;
        hold on;
        for k=1:nC
            plot(data_NCh_fixed.Disps+FiberDisp,data_NCh_fixed{:,k+1},'Linewidth',Lsize)
        end
        names=string(data_NCh_fixed.Properties.VariableNames);
        names=names(2:end);
        PinVal=zeros(1,nC);
        for k=1:nC
            PinVal(k)=str2num(names{k}((regexp(names(k),"=")+1):(regexp(names(k),"dBm")-1)));
            names(k)=sprintf("P$_{\\textrm{in}} = %d $ dBm",PinVal(k));
        end

        legend(names,'FontSize',fSize,'Interpreter','latex','Location','southwest');
        xlabel('Residual dispersion, ps/nm',labelOpt{:});
        ylabel('OSNR$_{\textrm{req}}$ at $10^{-10}$ BER, dB',labelOpt{:});
        set(gca,'FontSize', fSize,'FontName','Times New Roman');
        xlim([DispLeft,DispRight]);

        CurGraphTitle=sprintf('Total number of channels = %d; Grid spacing = %d GHz',N,dCh*100);
        title(CurGraphTitle,'Interpreter','latex','FontSize', fSize);
    %     hgexport(f,nameOfCurFile(1:end-4));
        if (t==2)
            hold off;
            print('-painters','-dpdf','-fillpage',[picFolder,'/',nameOfCurFile(1:end-4)]);
            close(gcf);
        end
        % CurveParam(:,1)=CurveParam(:,3)-CurveParam(:,2)/2;
      end
      m=w;
    end
end