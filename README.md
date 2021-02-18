# Speech ABR model

Implementation of the model from [Saiz-Alia, M., & Reichenbach, T. (2020). "Computational modeling of the auditory brainstem response to continuous speech". Journal of Neural Engineering.](https://iopscience.iop.org/article/10.1088/1741-2552/ab970d/meta)

### Contents
- python - python environment used to run the code (warning! it's Python 2.7 with many severely obsolete packages)
- the rest of the Python/MATLAB code...

### Setup
1. Clone the repository and move to the root directory:
```sh 
git clone https://github.com/MKegler/SpeechABRmodel.git
cd SpeechABRmodel
```
2. Set up an environment for the necessary packages since this model requires some outdated packages. This can be accomplished in two ways:

- **a.** Create an environment with the YAML file provided
    ```sh 
    conda env create --file speech_abr.yml
    ```
    Note: Not fully tested (yet). *Use with caution*.

- **b.** Create conda env. and install the required packages through pip using provided ```requirement.txt``` file. *Note*: before installing requirements the dependencies (Cython & numpy 1.11.0) need to be satisfied.
    ```sh 
    conda create --name speechABRmodel python=2.7
    conda activate speechABRmodel
    pip install Cython numpy==1.11 
    pip install -r requirements.txt
    ```
    *Note*: the packages are quite outdated, so you may come across a few warnings or non-critical errors. Please ignore them.

1. Open matlab from inside the environment
```sh 
matlab
```
4. Open and run script.m 

### TODOs
- [x] Test the code on another workstation
- [ ] Try streamlining the environment setup via conda + .yml.
- [ ] Clean up the environment - can we get it to work using the latest version of MATLAB & Python3? 
- [ ] Clean up the code - can we make it fully Python or fully MATLAB? (without a monumental effort)
- [ ] Repo contains some large files (over 50 MB)... Separate code and data and upload the latter to the cloud.

Las updated 18 Feb 2021
Marina Saiz (ms6215@ic.ac.uk)

Last updated 20 Nov 2020
Joanna Chang (jcc319@ic.ac.uk)
Mikolaj Kegler (mak616@ic.ac.uk)
