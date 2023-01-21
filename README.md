# Scripts for TLS pipeline


These scripts may be used to automatically run the TLS pipeline by Phil Wilkes, which can be found [here](https://github.com/philwilkes/TLS2trees). All input is assumed to have file structure as described [here](https://github.com/philwilkes/rxp-pipeline). You may contact me on Teams or at wout.cherlet@ugent.be with any questions.

## HPC

The algorithms used are very memory-intensive. Therefore it is recommended to run it on the Kirlia cluster of the UGent HPC. For this, a script is provided that will launch all tiles at once, organize output and log messages.
Due to large dataset sizes and limited personal data quota, ensure you are part of a VO first to obtain larger data quota (you may contact me to join the CAVElab VO).

### 1. Transfer your files to the HPC servers

The script accepts the .riproject folder as input. Tranfer the folder to the HPC servers (a tutorial may be found [here](https://hpcugent.github.io/vsc_user_docs/pdf/intro-Linux-linux-gent.pdf#sec:rsync)).

HPC users use DATA locations for slower, permanent storage and SCRATCH locations. Therefore the input folder is first copied to the following location: `$VSC_SCRATCH_VO/TLS2trees`. The script may do this automatically, in which case it will look in both `$VSC_DATA_VO` and `$VSC_DATA`. Alternatively, the entire path to the .riproject folder may be provided.
If you want to skip this copying step, you may put the folder in `$VSC_SCRATCH_VO/TLS2trees` manually.

To run the pipeline, apptainer is used with a .sif image. On the UGent HPC, apptainer images must be located in the SCRATCH directories. The .sif image used by the script is located in `$VSC_SCRATCH_VO/TLS2trees`. If it is not there, the script will throw an error. If this is the case, please copy the .sif image to this location if you have it or contact me.

### 2. Run the job script
You will need to specify some resource requirements for the job, more info [here](http://hpcugent.github.io/vsc_user_docs/pdf/intro-HPC-linux-gent.pdf#section.4.6):
- Walltime: specify the amount of hours, minutes and seconds the job may take. If this time is exceeded, the job will terminate. The default is only 1 hour, so be sure to set this to a more appropriate value.
- Nodes and cores: specify the amount of nodes and cores per node you want to use. One core per tile is ideal. The amount of tiles may be determined by checking the amount of files in the downsample folder.
- Memory: the default memory is the usable memory per node divided by the amount of cores per node, multiplied by the requested amount of nodes. If we request 1 core per tile on the kirlia cluster, this gives us about 20.5 Gib per tile. If this is not enough, as might be the case for large datasets, make sure to request more memory. If the memory needed exceeds the max for one node (738 Gib), make sure to divide your cores over multiple nodes!

First, make sure you are using the kirlia cluster, by running:
```
module swap cluster/kirlia
```
Do this every time you log in to the HPC servers!

Submit job by running:
```
qsub -l walltime=<h:m:s>,nodes=<#nodes>:ppn=<#cores/node>,mem=<#Gb> TLS2trees_HPC.sh <proj>.riproject (optional) <ID>
```
The optional ID may be used to run multiple jobs at once with different parameters, and will be used to define a unique output location.
Add the `-m abe` option to get e-mail notifications of your job beginning (b), ending (e) and aborting (a).

#### Monitoring job
Run `qstat` to see info about your jobs, check [here](http://hpcugent.github.io/vsc_user_docs/pdf/intro-HPC-linux-gent.pdf#section.4.4) for more info.

### 3. Obtaining output

Output can be found in $VSC_SCRATCH_VO/TLS2trees/output (and an optional ID directory if provided). Make sure to copy this data to your personal or the VO DATA directory, as the SCRATCH is not meant for persistent data.

Additionaly, an output and error file in the form of TLS2trees_HPC.sh.o\<runID\> and TLS2trees_HPC.sh.e\<runID\> can be found in the directory where you ran the `qsub` command. These may give you more info on used walltime, which tiles failed at which step and other error messages. For further troubleshooting, log files are created for each tile within the output/logs directory.



## Local

The scripts may also be ran locally, using either Docker or Singularity. This may be used to rerun failed tiles individually, but beware that your computer will likely run out of memory and crash if you run multiple tiles at once. Cave013 should be able to manage a couple of tiles at once and can be reached using `ssh -p 2225  youraccountname@cave013.ugent.be`.

### Docker (_[Install](https://docs.docker.com/engine/install/ubuntu/)_)

 1. If docker container not built yet, or changes are made to algorithms, run in TLS2trees directory:
	`sudo docker build -t tls2trees:latest .`
 2. Run semantic + instance segmentation in containers:
    - Make script executable: `chmod +x pipeline.sh` or `chmod +x pipelineAllDocker.sh`
    - Execute script: `sudo ./pipeline.sh </home/.../XXX.riproject/> <TileID>` (or `sudo ./pipelineAllDocker.sh </home/.../XXX.riproject/>` to analyze all tiles at once)
    (make sure to add absolute path to riproject directory + run as root!)
        - On ssh, add nohup and send output to log file: `sudo nohup ./pipelineAllDocker.sh </home/.../XXX.riproject/> &> output.log &`
        - When running `pipeline.sh`, an additional script is ran that logs stats about the container, which may provide insights in memory and cpu usage.
        - 'Container not found' warnings originate from the docker wait command and are not a problem
 3. Output can be found in /home/.../XXX.riproject/clouds/
 4. If unable to open output files, run `sudo chown -R <user>:<user> </home/.../XXX.riproject>`


### Singularity (_[Install](https://docs.sylabs.io/guides/3.0/user-guide/installation.html)_)

**_Currently only all tiles, use Docker for single tiles + NOT TESTED!_**

 1. If singularity container not built yet, or changes are made to algorithms, run in tls2trees directory: 
	`sudo singularity build tls2trees_latest.sif docker-daemon://tls2trees:latest`
 2. Run semantic + instance segmentation in containers:
    - Make scripts executable: `chmod +x pipelineAllSingularity.sh`
    - Execute scripts: `sudo ./pipelineAllSingularity.sh </home/.../XXX.riproject/>`
 3. Output can be found in /home/.../XXX.riproject/clouds/singularity/
 4. If unable to open output files, run `sudo chown -R <user>:<user> </home/.../XXX.riproject>`


## TODO's
- Test without preprocessing at https://github.com/philwilkes/rxp-pipeline, may need to change source code
- HPC script usable without being part of VO
