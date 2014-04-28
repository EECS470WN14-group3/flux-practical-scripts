#!/bin/bash -l
# Created Fall 2010 by: Joshua Smith <smjoshua@umich.edu>
# Updated Winter 2014 by: Kyle Smith <kylebs@umich.edu>

SCRIPTS_DIR="$(pwd -P)"
pushd ../

PROJ_DIR="$(pwd -P)"
EECS470_LIBS_DIR="/afs/umich.edu/class/eecs470/lib"

################################################################################
## PBS Script Parameters                                                      ##
## Full reference available at:                                               ##
## http://cac.engin.umich.edu/resources/software/pbs                          ##
################################################################################
PBS_SHELL=/bin/sh
PBS_JOB_NAME="470-synth"
PBS_ACCOUNT="brehob_flux"
PBS_JOB_ATTRS="qos=flux,nodes=1:ppn=12,mem=47gb,pmem=4000mb,walltime=10:00:00"
PBS_QUEUE="flux"
PBS_EMAIL_ADDR="kylebs@umich.edu"
PBS_EMAIL_OPTS="abe"
PBS_FLAGS="-V"
PBS_FILE="${SCRIPTS_DIR}/pbs.sh"


################################################################################
## Copy EECS 470 Synopsys Libs Locally From: ${EECS470_LIBS_DIR}              ##
################################################################################
# Scratch space ftw
LOCAL_EECS470_DIR="${HOME}/eecs470-lib"
SCRATCH_DIR="/scratch/${PBS_ACCOUNT}/${USER}"
if ! [ -d "${LOCAL_EECS470_DIR}" ]; then
  echo "Warning: Local EECS 470 Synopsys library directory doesn't exist, attemping to copy..."
  cp -R "${EECS470_LIBS_DIR}" "${LOCAL_EECS470_DIR}"

  if [ "$?" -ne '0' ]; then
    echo "Error: Failed to copy EECS 470 Synopsys library to local directory:"
    echo "       ${EECS470_LIBS_DIR} -> ${LOCAL_EECS470_DIR}"
    popd
    exit 1
  fi
fi

# Export some environment variables so PBS can access them when job runs
export EECS470_LIBS_DIR
export LOCAL_EECS470_DIR
export PROJ_DIR
export PBS_ACCOUNT
export SCRATCH_DIR

# Need to load these so paths of dc_shell/vcs are found
module load synopsys/2013.03-SP1
module load vcs/2013.06-sp1

# Submit the batch job
echo "Submitting batch job..."
JOB_ID=`qsub -S $PBS_SHELL -N $PBS_JOB_NAME -A $PBS_ACCOUNT -l $PBS_JOB_ATTRS -q $PBS_QUEUE -M $PBS_EMAIL_ADDR -m $PBS_EMAIL_OPTS $PBS_FLAGS $PBS_FILE`
if [ "$?" -ne '0' ]; then
  echo "Error: Could not submit job via qsub"
  popd
  exit 1
fi
echo "Submitted batch job, id=$JOB_ID"

# clean up stuff
unset EECS470_LIBS_DIR
unset LOCAL_EECS470_DIR
unset PROJ_DIR
unset PBS_ACCOUNT
unset SCRATCH_DIR

popd

# to make parsing of result easier...
echo "jobID=$JOB_ID"

