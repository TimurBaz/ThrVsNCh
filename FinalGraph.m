clc;clear;close all;

Lsize=3;
fSize=30;
Ns=3:2:35;
NLThr=[3,0,-1,-3,-3,-4,-5,-5,-6,-8,-7,-8,-7,-8,-7,-8,-8];

opt.Linewidth=Lsize;
opt.Marker='o';
opt.LineStyle='-';

labelOpt={'Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold'};

figure;
plot(Ns,NLThr,opt)
xlabel('Number of channels',labelOpt{:});
ylabel('Nonlinear threshold power, dBm',labelOpt{:});
set(gca,'FontSize', fSize,'FontName','Times New Roman');