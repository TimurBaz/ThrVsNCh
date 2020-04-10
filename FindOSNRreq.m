function [curOSNR,curBER] = FindOSNRreq(Document,OSNRController,BEROsc,BERreq)
        highOSNR = 50;
		lowOSNR=0;
		counter=0;
        accuracyBER=BERreq*2;
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
end

