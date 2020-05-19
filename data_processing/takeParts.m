clc;clear;close all;

[file,path] = uigetfile();
load([path,file],'data_NCh_fixed','N','dCh');

neededColumns=[6,7,8];

data_NCh_fixed=data_NCh_fixed(:,[1,neededColumns]);

filename=sprintf('%sCh%d_part3',path,N);
save(filename);