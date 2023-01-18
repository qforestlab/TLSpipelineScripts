# Scripts for TLS pipeline


These scripts may be used to automatically run the TLS pipeline by Phil Wilkes, which can be found [here](https://github.com/philwilkes/TLS2trees). All input is assumed to have file structure as described [here](https://github.com/philwilkes/rxp-pipeline).

## HPC

---

The algorithms used are very memory-intensive. Therefore it is recommended to run it on the Kirlia cluster of the UGent HPC. For this, a script is provided that will launch all tiles at once.
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
- Memory: the default memory is the usable memory per node divided by the amount of cores per node, multiplied by the requested amount of nodes. If we request 1 core per tile, this gives us about 20.5 Gib per tile. If this is not enough, as might be the case for large datasets, make sure to request more memory. If the memory needed exceeds the max for one node (738 Gib), make sure to divide your cores over multiple nodes!

Submit job by running:
```
qsub -l walltime=<h:m:s>,nodes=<#nodes>:ppn=<#cores/node>,mem=<#Gb>
```
Add the `-m abe` option to get e-mail notifications of your job beginning (b), ending (e) and aborting (a).

#### Monitoring job
Run `qstat` to see info about your jobs, check [here](http://hpcugent.github.io/vsc_user_docs/pdf/intro-HPC-linux-gent.pdf#section.4.4) for more info.

### 3. Obtaining output

TODO


## Local

---



### Docker

TEST

## TODO's
- PBS comments for HPC run
- Test without preprocessing at https://github.com/philwilkes/rxp-pipeline
- Enable script without being part of VO
