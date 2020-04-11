function [DispCent,DispSpan,DispMax] = CentAndWidthOfDispCurve(Disps,OSNRreqs)
    [OSNRcent,NCent]=min(OSNRreqs);
    DispCent=Disps(NCent);
    
    DispL=Disps(1):10:Disps(NCent);
    DispR=Disps(NCent):10:Disps(end);
    if ((NCent>1)&(length(Disps)-NCent>0))
        IntOSNRLeft=interp1(Disps(1:NCent),OSNRreqs(1:NCent),DispL);
        IntOSNRRight=interp1(Disps(NCent:end),OSNRreqs(NCent:end),DispR);
        [OSNRleft,Nleft]=min(abs(OSNRcent+3-IntOSNRLeft));
        DispLeft=DispL(Nleft);
        [OSNRright,Nright]=min(abs(OSNRcent+3-IntOSNRRight));
        DispRight=DispR(Nright);
    
        DispMax=DispRight;
        DispSpan=DispRight-DispLeft;
        DispCent=DispMax-DispSpan/2;
    else
        DispMax=0;
        DispSpan=0;
        DispCent=0;
    end
end

