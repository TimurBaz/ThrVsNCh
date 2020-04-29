clc;clear;close all;

[file,path] = uigetfile('MultiSelect','on');


for w=1:length(file)
    load([path,file{w}],'data_NCh_fixed','N','dCh');
    if (w==1)
        T=data_NCh_fixed;
    else
        T=[T,data_NCh_fixed(:,2:end)];
    end
end

data_NCh_fixed=T;
clear T;
filename=sprintf('%sCh%d_merged',path,N);
save(filename);