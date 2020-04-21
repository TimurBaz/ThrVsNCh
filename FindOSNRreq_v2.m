function curOSNR = FindOSNRreq_v2(Document,Layout,OSNRController,BEROsc,BERreq)
        highOSNR = 50;
		lowOSNR=0;
		counter=0;
        accuracyBER=0;
        Layout.SetParameterValue('Sequence length',128);
		while ((highOSNR - lowOSNR > 0.1) & (counter < 10))
			counter= counter+1;
			curOSNR = (highOSNR + lowOSNR)/2;
			OSNRController.SetParameterValue('Set OSNR',curOSNR);
			Document.CalculateProject( true , true);
			curBER=BEROsc.GetResultValue('Min. BER');
			if (curBER > BERreq + accuracyBER)
				lowOSNR=curOSNR;
			else
				highOSNR=curOSNR;
            end
        end
        
        lowOSNR=max(10,curOSNR-5);
        highOSNR=min(50,curOSNR+4);
        OSNRs=lowOSNR:1:highOSNR;
        OSNRs=OSNRs.';
        N=length(OSNRs);
        if (N>4)
            BERs=zeros(N,1);
            Layout.SetParameterValue('Sequence length',1024);
            for k=1:N
                OSNRController.SetParameterValue('Set OSNR',OSNRs(k));
                Document.CalculateProject( true , true);
                BERs(k)=BEROsc.GetResultValue('Min. BER');
            end
            if (~isempty(BERs(BERs==1)))
                lowOSNR=max(OSNRs(BERs==1));
            end
            BERs=log10(BERs);
            N=length(BERs);
            if (N>1)
                f=fit(BERs,OSNRs,'poly1');
                curOSNR=f(log10(BERreq));
                curOSNR=max(curOSNR,lowOSNR);
                curOSNR=min(curOSNR,highOSNR);
            else
                curOSNR=50;
            end
        else
            curOSNR=50;
        end
end
