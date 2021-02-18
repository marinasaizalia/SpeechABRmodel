function [Overallspikes,nspikes] = Raster(SpikeCell,T,StimFs)
% This function takes the spike train data and makes it binary so we can later process it
% with fr_es_conv_boxcar.m. This function returns an array with 1's at 
% the index number where a spike occurs and also returns the number of spikes. It takes a 'Cell', as an input. 
% This is directly produced when the python code is exported with the savemat function. 
% It also takes the time vector and the sampling frequency of the simulation as an input. 

for m = 1 : length (SpikeCell)
    a(m) = length(SpikeCell{m}); 
end

maxlength = max(a); 

for mm = 1 : length (SpikeCell) 
   SpikeData(mm,:) = [SpikeCell{mm},zeros(1,maxlength-length(SpikeCell{mm}))];
end 

res = 1/StimFs; 
npts = length(T); 
indices = single(SpikeData./res); 
indices = round(indices);
size_spikes = size(SpikeData); 
i = size_spikes(1); 
j = size_spikes(2); 
nspikes = 0; 


mi = [];
mj = [];

for s = 1 : i
    for p = 1 : j
        if indices(s,p) ~= 0          
            mi(nspikes+1) = s;
            mj(nspikes+1) = indices(s,p);
            nspikes = nspikes + 1 ; 
        end
    end
end

BinarySpikes = sparse(mi, mj, 1, i, npts);

Overallspikes = sum(BinarySpikes); 
end





