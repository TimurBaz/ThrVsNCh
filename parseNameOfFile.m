function [date,Numb,Pin]=parseNameOfFile(FileName)
    FileName=char(FileName);
    a2=regexp(FileName,'_Pin')-1;
    a1=regexp(FileName,'Chs=')+4;
    b2=regexp(FileName,'.ods')-1;
    b1=regexp(FileName,'_Pin=')+5;
    Numb=str2num(FileName(a1:a2));
    date=FileName(1:19);
    Pin=str2num(FileName(b1:b2));
end