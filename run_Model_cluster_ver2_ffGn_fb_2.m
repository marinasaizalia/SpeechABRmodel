
function [] = run_Model_cluster_ver2_ffGn_fb_2(folder, name, cond, chunk, Dur, anf, numb)
% Cluster simple version:
% Main function for running the ABR model. It loads the speech file, runs the python part of the model (inner ear and CN), 
% opens Spiketrains and returns
% Rates at the three different levels as m file

tic 

dir_root = pwd;
path_file = ['Input/' folder name '_' num2str(cond) '_' num2str(chunk) '_resampled.mat'];
path_file_clean = ['Input/' folder name '_' 'clean' '_' num2str(chunk) '_resampled.mat'];

% Parameters for ANF and CN
Fs = 100e3;  
N_freqs = 300; 
gbs = 200;

system('mkdir temp');
save('temp/input.mat', 'path_file', 'dir_root', 'Fs', 'Dur', 'anf', 'N_freqs', 'gbs', 'numb'); % so it is open in python and we pass parameters
%% AN and CN
% runAN_CN needs python modules that are in comp_model environment so we
% need to add the python path
% PATH_PYTHON = '/Users/joanna/opt/anaconda3/envs/speech_abr2/lib/python2.7/site-packages';
%PATH_PYTHON = '/export131/home/ms6215/anaconda3/envs/temp2clone/lib/python2.7/site-packages';
% setenv('PYTHONPATH', PATH_PYTHON)

system('python runAN_CN_simulation_cluster_ffGn.py');
%% CN and AN fr computation
load(['temp/out_' num2str(numb) '_Spiketrains.mat']) 

npts = Dur * Fs; 
T = (0:npts-1)/Fs; %Establishing a time vector 

[CNSpikes,cn_numb]= Raster(CN,T,Fs); %Using the raster function to produce Binary arrays of Spike trains so that we can process it with the firing estimation function 
[ANSpikes,an_numb]= Raster(AN,T,Fs); %Doing the above for AN as well 

%Using the firing estimation function with a Boxcar kernel of width 30, these parameters can be changed. The width can be as big but a bigger width leads to rate values that arent accurate. The Kernel can be Gaussian or Exponential but for purposes of speech signal analysis, Boxcar is best. 
ANRate = fr_es_conv_boxcar(ANSpikes,30); 
CNRate = fr_es_conv_boxcar(CNSpikes,30);

%% IC
% IC MODEL PARAMETERS:
fs = Fs;
tau_ex_ic = 1e-3;       % IC exc time constant
tau_inh_ic = 1e-3;      % IC inh tune constant
ic_delay = 0.002;       % delay along inhibitory pathway (initial=0.002)
inh_str_ic = 1.5;       % re: exc strength == 1
afamp_ic = 1;           % alpha function area --> changes RATE of output cell

% Generate alpha functions for IC model (same as CN model, but with different taus):
[B3, A3] = get_alpha_norm(tau_ex_ic, fs, 1);
[B4, A4] = get_alpha_norm(tau_inh_ic, fs, 1);

cn_sout = CNRate;
ic_lp_ex1 = [afamp_ic*(1/fs)*(filter(B3, A3, [cn_sout])) zeros(1,fs*ic_delay)];
ic_lp_inh1 = [zeros(1,fs*ic_delay) afamp_ic*inh_str_ic*(1/fs)*(filter(B4, A4, [cn_sout]))];

% final IC model response:
ic_sout = ((ic_lp_ex1-ic_lp_inh1) + abs(ic_lp_ex1-ic_lp_inh1))/2;
ic_t = [0:(length(ic_sout)-1)]/fs;

%% F0
load(['Input/' folder 'F0_' name '_' num2str(chunk) '_resampled.mat'])
NewF0 = F0 (1:npts); % Slicing the F0 signal to required duration 

% Align F0 and outs by crosscorrelating F0 and speech signal CLEAN!
load(path_file_clean);
signal = signal(1:npts);

[r,lags] = xcorr(signal, NewF0);
[~, in] = max(r);
diff_lag = lags(in); % in samples
if diff_lag < 0 
    NewF0 = NewF0((diff_lag*(-1))+1:end);
    tmax = length(NewF0);
elseif diff_lag > 0
    NewF0 = [zeros(1, diff_lag), NewF0];
    tmax = length(signal);
else
    tmax = length(signal);
end

[r,lags] = xcorr(signal, NewF0);
[~, in] = max(r);

if lags(in)~=0
    error('Bad alignment')
end

%% weights for the individual responses (ANF, CN and IC) adding to the total ABR response
w1 = 1*(0.05*0.0299*0.05)/2;
w2 = 1*(0.9*0.2222*0.3)/2;
w3 = 3.5*(0.15*4.3675*1)/2;

ANRate = w1*ANRate;
CNRate = w2*CNRate;
ic_sout = w3*ic_sout;

to = min([length(ANRate), length(CNRate), length(ic_sout)]);
ABRRate = ANRate(1,1:to) + (CNRate(1,1:to)) + ic_sout(1,1:to);

toc
%% Ploting signals
signals = figure;
set(signals, 'Visible', 'on');

NewT = (0:length(NewF0)-1)/Fs; 
subplot(511);plot(NewT,NewF0, 'k');ylabel('F0');axis([0 T(tmax)-0.5 1.1*min(NewF0) 1.1*max(NewF0)]); box off
subplot(512);plot(T,ANRate);ylabel('ANF');axis([0 T(tmax) 1.1*min(ANRate) 1.1*max(ANRate)]); box off
subplot(513);plot(T,CNRate, 'r');ylabel('CN');axis([0 T(tmax) 1.1*min(CNRate) 1.1*max(CNRate)]); box off
subplot(514);plot(ic_t,ic_sout, 'g');ylabel('IC');axis([0 T(tmax) 0 1.1*max(ic_sout)]); box off
subplot(515);plot(ic_t(1:to),ABRRate, 'k');ylabel('ABR');axis([0 T(tmax) 0 1.1*max(ic_sout)]); box off
xlabel('Time (s)')

set(findall(gcf,'-property','FontSize'),'FontSize',12)


%% Plotting crosscorrelation
% Crosscorrelation at different stages
data = zeros(4,3);

correlation= figure;
set(correlation, 'Visible', 'on');

subplot(411)
[lagDiff_ms_A, amp_A, SNR_A, xcorr_data_A]= complexcrosscorrelationplot_ver2(ANRate, NewF0, Fs);box off
ylabel('ANF')

subplot(412)
[lagDiff_ms_C, amp_C, SNR_C, xcorr_data_C] = complexcrosscorrelationplot_ver2(CNRate, NewF0, Fs);box off
ylabel('CN')

subplot(413)
[lagDiff_ms_I, amp_I, SNR_I, xcorr_data_I] = complexcrosscorrelationplot_ver2(ic_sout, NewF0, Fs);box off
ylabel('IC')

subplot(414)
[lagDiff_ms_ABR, amp_ABR, SNR_ABR, xcorr_data_ABR] = complexcrosscorrelationplot_ver2(ABRRate, NewF0, Fs);box off

xlabel('Time (ms)'); 

data(1,1) = lagDiff_ms_A;
data(1,2) = amp_A;
data(1,3) = SNR_A;
data(2,1) = lagDiff_ms_C;
data(2,2) = amp_C;
data(2,3) = SNR_C;
data(3,1) = lagDiff_ms_I;
data(3,2) = amp_I;
data(3,3) = SNR_I;
data(4,1) = lagDiff_ms_ABR;
data(4,2) = amp_ABR;
data(4,3) = SNR_ABR;

%% Delete interm
delete('temp/input.mat')
delete(['temp/' 'out_' num2str(numb) '_Spiketrains.mat'])

%% Save output
[status, msg, msgID] = mkdir(['Output/' name]);

save(['Output/' name '/' name '_' num2str(cond) '_' num2str(chunk) '_data_out'], 'data', 'xcorr_data_A', 'xcorr_data_C', 'xcorr_data_I', 'xcorr_data_ABR') 
save(['Output/' name '/' name '_' num2str(cond) '_' num2str(chunk) '_data_sig_out'], 'ANRate','CNRate','ic_sout', 'ABRRate') 
savefig(signals, ['Output/' name '/'  name '_' num2str(cond) '_' num2str(numb) '_signals.fig'])
savefig(correlation, ['Output/' name '/' name '_' num2str(cond) '_' num2str(chunk) '_correlation.fig'])

fprintf('\n\n DONE! \n\n')
end



