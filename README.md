# Scripts for TLS pipeline

These scripts may be used to automatically run the TLS pipeline by Phil Wilkes, which can be found [here](https://github.com/philwilkes/TLS2trees). All input is assumed to have file structure as described [here](https://github.com/philwilkes/rxp-pipeline).

## HPC

The algorithms used are very memory-intensive. Therefore it is recommended to run it on the Kirlia cluster of the UGent HPC. For this, a script is provided that will launch all tiles at once.
Due to large dataset sizes and limited personal data quota, ensure you are part of a VO first to obtain larger data quota (you may contact me to join the CAVElab VO).

### 1. Transfer your files to the HPC servers

The script accepts the .riproject folder as input. Tranfer the folder to the HPC servers (a tutorial may be found [here](https://hpcugent.github.io/vsc_user_docs/pdf/intro-Linux-linux-gent.pdf#sec:rsync)).

HPC users use DATA locations for slower, permanent storage and SCRATCH locations. Therefore the input folder is first copied to the following location: `$VSC_SCRATCH_VO/TLS2trees`. The script may do this automatically, in which case it will look in both `$VSC_DATA_VO` and `$VSC_DATA`. Alternatively, the entire path to the .riproject folder may be provided.
If you want to skip this copying step, you may put the folder in `$VSC_SCRATCH_VO/TLS2trees` manually.

To run the pipeline, apptainer is used with a .sif image. On the UGent HPC, apptainer images must be located in the SCRATCH directories. The .sif image used by the script is located in `$VSC_SCRATCH_VO/TLS2trees`. If it is not there, the script will throw an error. If this is the case, please copy the .sif image to this location if you have it or contact me.

### 2. Run the job script

First, ensure the script will be using the kirlia cluster and not the default one by running
```
module swap cluster/kliria
```




TODO: script in VO data



## TODO's
- PBS comments for HPC run
- Test without preprocessing at https://github.com/philwilkes/rxp-pipeline
- Enable script without being part of VO
