Docker Workflow:
 1. If docker container not built yet, or changes are made to algorithms, run in tls2trees directory:
	`sudo docker build -t tls2trees:latest .`
 2. Run semantic + instance segmentation in containers:
    - Make script executable: `chmod +x pipeline.sh` or `chmod +x pipelineAllDocker.sh`
    - Execute script: `sudo ./pipeline.sh </home/.../XXX.riproject/> <TileID>` or `sudo ./pipelineAllDocker.sh </home/.../XXX.riproject/>` to analyze all tiles at once.
    (make sure to add absolute path to riproject directory + run as root!)
    - On ssh, add nohup and send output to log file: `sudo nohup ./pipelineAllDocker.sh </home/.../XXX.riproject/> &> output.log &`
    - 'Container not found' warnings originate from the docker wait command and are not a problem
 3. Output can be found in /home/.../XXX.riproject/clouds/
 4. If unable to open output files, run `sudo chown -R <user>:<user> </home/.../XXX.riproject>` (should be done automatically)

Singularity Workflow:
 1. If singularity container not built yet, or changes are made to algorithms, run in tls2trees directory:
	`sudo singularity build tls2trees_latest.sif docker-daemon://tls2trees:latest`
 2. Run semantic + instance segmentation in containers:
    - Make scripts executable: `chmod +x singularitySemSeg.sh` and `chmod +x singularityInstSeg.sh`
    - Execute scripts: `sudo ./singularitySemSeg.sh </home/.../XXX.riproject/>` and `sudo ./singularityInstSeg.sh </home/.../XXX.riproject/>`
         (make sure containers launched in first script are fully finished before launching second script! This can be done by running `ps aux | grep "[S]ingularity"` in a new terminal, if no output is shown then containers are finished.)
 3. Output can be found in /home/.../XXX.riproject/clouds/singularity/
 4. If unable to open output files, run `sudo chown -R <user>:<user> </home/.../XXX.riproject>` (should be done automatically)