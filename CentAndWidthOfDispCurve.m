function [DispCent,DispSpan,DispMax] = CentAndWidthOfDispCurve(Disps,OSNRreqs)
    [OSNRcent,NCent]=min(OSNRreqs);
    DispCent=Disps(NCent);
    
    DispL=Disps(1):10:Disps(NCent);
    DispR=Disps(NCent):10:Disps(end);

    IntOSNRLeft=interp1(Disps(1:NCent),OSNRreqs(1:NCent),DispL);
    IntOSNRRight=interp1(Disps(NCent:end),OSNRreqs(NCent:end),DispR);
    [OSNRleft,Nleft]=min(abs(OSNRcent+3-IntOSNRLeft));
    DispLeft=DispL(Nleft);
    [OSNRright,Nright]=min(abs(OSNRcent+3-IntOSNRRight));
    DispRight=DispR(Nright);
    
    DispMax=DispRight;
    DispSpan=DispRight-DispLeft;
    DispCent=DispMax-DispSpan/2;
end

