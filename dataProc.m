clc;clear;
close all;

load([pwd,'/results2Ch/04-10-2020_22-18-22N_of_Chs = 2.mat'],'data_NCh_fixed');
t=data_NCh_fixed;
load([pwd,'/results2Ch/04-10-2020_23-36-54N_of_Chs = 2.mat'],'data_NCh_fixed');
t=[t,removevars(data_NCh_fixed,{'Disps'})];

FiberDisp=1800;

CurveParam=zeros(5,3);
figure;
hold on;
for k=1:5
    [CurveParam(k,1),CurveParam(k,2),CurveParam(k,3)]=CentAndWidthOfDispCurve(t.Disps+FiberDisp,t{:,k+1});
    plot(t.Disps+FiberDisp,t{:,k+1},'Linewidth',5)
end
names=string(t.Properties.VariableNames);
names=names(2:end);
legend(names,'FontSize',30);
hold off;

CurveParam(:,1)=CurveParam(:,3)-CurveParam(:,2)/2;