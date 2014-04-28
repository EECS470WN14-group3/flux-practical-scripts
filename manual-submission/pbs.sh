#!/bin/bash
# Created Fall 2010 by: Joshua Smith <smjoshua@umich.edu>
# Updated Winter 2014 by: Kyle Smith <kylebs@umich.edu>
#
# This script is executed to run the synthesis job on the computing node.

pushd ../

# Create a local directory for this run and copy project files into it
TMP_DIR=${SCRATCH_DIR}/${PBS_JOBID}
echo "PBS - Copying project files to scratch space: ${TMP_DIR}..."
mkdir -p $TMP_DIR
cd $TMP_DIR
rsync -avz $PROJ_DIR/ .
if [ "$?" -ne '0' ]; then
  echo "PBS - Error while trying to copy project files to tmp"
  cd
  rm -rf $TMP_DIR
  popd
  exit 1
fi

# Copy EECS470 libs for Synopsys
LIBS_DIR=${SCRATCH_DIR}/eecs470-libs
echo "PBS - Copying eecs470 Synopsys libs to scratch space..."
mkdir -p $LIBS_DIR
cd $LIBS_DIR

# this assumes you have a copy of the EECS 470 Synopsys libs in ${LOCAL_EECS470_DIR}!
rsync -avz ${LOCAL_EECS470_DIR} .

if [ "$?" -ne '0' ]; then
  echo "PBS - Error while trying to copy eecs470 Synopsys libs to scratch space using source directory: ${LOCAL_EECS470_DIR}"
  echo "PBS --- Have you copied the EECS 470 libs to your HPC home directory?"
  echo "PBS --- Try running:"
  echo "PBS --- $ cd"
  echo "PBS --- $ aklog -c umich.edu"
  echo "PBS --- $ cp -R /afs/umich.edu/class/eecs470/lib eecs470-libs"
  cd
  rm -rf $TMP_DIR
  popd
  exit 1
fi

# Find & Replace old paths with the new local one
echo "PBS - Re-linking all eecs470 Synopsys libs to the updated local path @ ${LIBS_DIR}..."
cd $TMP_DIR
find . -type f -exec sed -i "s,${EECS470_LIBS_DIR},${LIBS_DIR},g" {} \;

# Run synthesis
echo "PBS - Running synthesis..."
make syn

# Clean up simulation output
make clean

# Copy `proc.rep` result file back to home space
cd $TMP_DIR
cp syn/proc.rep ${PROJ_DIR}/proc.${PBS_JOBID}.rep
if [ "$?" -ne '0' ]; then
  echo "PBS - Error while trying to copy proc.rep back to project home"
  cd
  popd
  exit 1
fi

echo "PBS - Done!"

popd

