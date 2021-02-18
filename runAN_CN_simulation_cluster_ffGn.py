# Cluster simple version

from __future__ import division, absolute_import, print_function

#Importing packages
import numpy as np
import pandas as pd
import brian
from brian import ms
import cochlea
import thorns as th
import thorns.waves as wv
import scipy.io as sio
import sys, os

# Disable
def blockPrint():
    sys.stdout = open(os.devnull, 'w')

# Restore
def enablePrint():
    sys.stdout = sys.__stdout__

enablePrint()

par = sio.loadmat('temp/input.mat')
path_file = str(par['path_file'][0]) 

dir_root = str(par['dir_root'][0]) 
os.chdir(dir_root)

import cochlear_nucleus.brn as cn

sig_L = float(par['Dur'])
Fs =  float(par['Fs'])
anf = par['anf'][0]
n_freqs = int(par['N_freqs'])
gbs = int(par['gbs'])
numb = str(par['numb'][0][0])

def main():
    
    #Extracting speech signal 
    dictsample = sio.loadmat(path_file) 
    sample = dictsample['signal'] 
    sample  = sample.flatten() 
    duration = float(sig_L) 
    index = int(duration*Fs) 
    mysample = sample[0:index] 

    
    print('ANF')
    # 1) Generate spike trains from Auditory Nerve Fibres using Cochlea Package 
    anf_trains = cochlea.run_zilany2014(
        sound=mysample,
        fs=Fs,
        anf_num=(anf[0],anf[1],anf[2]),   
        cf=(125,20000,n_freqs),
        species='human', 
        seed=0,
        powerlaw= 'approximate', 
        ffGn=True
    )

    # 2)  Generate ANF and GBC groups in Brian using inbuilt functions in the Cochlear Nucleus package  
    brian.defaultclock.dt = 0.03*ms

    anfs = cn.make_anf_group(anf_trains) 
    gbcs = cn.make_gbc_group(gbs) 

    # Connect ANFs and GBCs using the synapses class in Brian 
    synapses = brian.Connection(
        anfs,
        gbcs,
        'ge_syn',
        delay = 3*ms #This is important to make sure that there is a delay between the groups. I changed it to 4 from 5
    )

    #this value of convergence is taken from the Cochlear Nucleus documentation 
    convergence = 20

    weight = cn.synaptic_weight(
        pre='anf',
        post='gbc',
        convergence=convergence
    )

    #Initiating the synaptic connections to be random with a fixed probability p that is proportional to the synaptic convergence 
    synapses.connect_random(
        anfs,
        gbcs,
        p=convergence/len(anfs),
        fixed=True,
        weight=weight,
    )

    # Monitors for the GBCs. Brian Spike Monitors are objects that basically collect the amount of spikes in a neuron group 
    gbc_spikes = brian.SpikeMonitor(gbcs)
    
    print('CN')
    # Run the simulation using the run function in the CN package. This basically uses Brian's run function 
    cn.run(
        duration=duration,
        objects=[anfs, gbcs, synapses, gbc_spikes] #include ANpop and CN pop in this if you need to
    )

    gbc_trains = th.make_trains(gbc_spikes)

    #Extracting the spike times for both AN and CN groups 
    CNspikes = gbc_trains['spikes'];
    ANspikes = anf_trains['spikes'];

    #Converting dict format to array format so that spike train data is basically a one dimensional array or row vector of times where spikes occur 
    CN_spikes = np.asarray(CNspikes)
    AN_spikes = np.asarray(ANspikes)
    
    #Saving it in the appropriate format so that we can do further processing in MATLAB
    data = {'CN':CN_spikes,'AN':AN_spikes}
    sio.savemat('temp/' 'out_' + numb +'_Spiketrains',data)


if __name__ == "__main__":
    main()
