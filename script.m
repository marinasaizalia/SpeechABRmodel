%%
clear; clc; close all;

folder = 'Test/'; %To speech files
name = 'odin4'; %name of the speech story
Dur = 1; %duration of speech to be used (in s)
anf = [12, 4, 4]; %number of ANFs (high, mid, low)SR
numb =  0; %this is useless here (it was for computing in the cluster)
chunk=1; % as I repeated the simulation n times with different chunks

cond = 'clean'; %condition name
run_Model_cluster_ver2_ffGn_fb_2(folder, name, cond, chunk, Dur, anf, numb)