function [x,y]=export_data(Graph,numberOfIter)
    x = cell2mat(Graph.GetXData(numberOfIter)); 
    y = cell2mat(Graph.GetYData(numberOfIter));
end