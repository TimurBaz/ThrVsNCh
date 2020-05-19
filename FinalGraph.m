clc;clear;close all;

Lsize=3;
fSize=40;
% Ns=   [3,5, 7, 9,11,13,15,17,19,21,23,25,27,29,31,33,35,41,51, 61, 71, 81];
% NLThr=[3,1,-1,-2,-3,-4,-5,-5,-6,-6,-7,-7,-7,-8,-7,-8,-8,-9,-9,-11,-12,-12];
Ns    = [3,5,7,9,11];
NLThr = [8,8,9,8, 7];

opt.Linewidth=Lsize;
opt.Marker='o';
opt.LineStyle='-';

labelOpt={'Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold'};

figure;

subplot(1,2,1)
plot(Ns,NLThr,opt)
xlabel('Number of channels',labelOpt{:});
ylabel('Nonlinear threshold power, dBm',labelOpt{:});
set(gca,'FontSize', fSize,'FontName','Times New Roman');


subplot(1,2,2)
plot(Ns,10.^(NLThr/10),opt)
xlabel('Number of channels',labelOpt{:});
ylabel('Nonlinear threshold power, mW',labelOpt{:});
set(gca,'FontSize', fSize,'FontName','Times New Roman');

NsDb=10*log10(Ns);
f=fit(NsDb.',NLThr.','poly1');

figure
plot(NsDb.',f(NsDb),'Linewidth',Lsize,'Color','red')
xl = xlim;
yl = ylim;
xt = 0.2 * (xl(2)-xl(1)) + xl(1);
yt = 0.80 * (yl(2)-yl(1)) + yl(1);
caption = sprintf('y = %0.3f $\\times$ x + %0.3f', f.p1, f.p2);
text(xt, yt, caption, 'Interpreter','latex','FontSize', fSize, 'Color', 'black', 'FontWeight', 'bold');

hold on;
plot(NsDb.',NLThr.',opt,'Color','#0072BD')
xlabel('Number of channels, dB',labelOpt{:});
ylabel('Nonlinear threshold power, dBm',labelOpt{:});
set(gca,'FontSize', fSize,'FontName','Times New Roman');
legend('fit', 'data','FontSize',fSize,'Interpreter','latex');

figure
plot(Ns,NLThr+NsDb,opt)
xlabel('Number of channels',labelOpt{:});
ylabel('Total power threshold, dBm',labelOpt{:});
set(gca,'FontSize', fSize,'FontName','Times New Roman');