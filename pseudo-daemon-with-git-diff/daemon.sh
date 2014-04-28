#!/bin/bash

PBS_SCRIPT="synth.sh"
JOB_LOG_FILE="jobs-for-commits.log"

export REMOTE_NAME="origin"
export SYNTH_BRANCH="flux"

PENDING_UPDATE=0
PENDING_UPDATE_JOBID=0

while [ 1 ]; do
  # get a comma-separated list of all jobs that aren't complete
  jobs="$(qstat -u $USER | grep -vE '00 C' | grep -E '^[0-9]+' | tr -s '[:blank:]' ',')"

  # check remote git repository for a commit change
  update_detected=0
  local_commit="$(git rev-list --max-count=1 $REMOTE_NAME/$SYNTH_BRANCH)"
  remote_commit="$(git ls-remote --heads $REMOTE_NAME $SYNTH_BRANCH)"
  remote_issue="$?"
  remote_commit="$(echo "$remote_commit" | cut -f1)"
  [ "$remote_issue" -eq 0 ] && [ "$local_commit" != "$remote_commit" ] && update_detected=1;

  # send updates back to remote REST server
  # curl   --data-urlencode "v=1"                                   \
  #        --data-urlencode "jobs=${jobs}"                          \
  #        --data-urlencode "log=$(cat $JOB_LOG_FILE)"              \
  #        --data-urlencode "update_requested=${update_requested}"  \
  #        http://api.your-server.com/ &> /dev/null

  # if update detected, queue up job!
  if [ $update_detected -ne 0 ]; then
    echo "update detected!"

    # write the update activity to the local log
    echo "update detected @ $(date +%s)" >> updates.log;

    PENDING_UPDATE="$remote_commit"
    PENDING_UPDATE_JOBID=0

    # kill any queued jobs-- this one is obviously newer
    for job in $jobs; do
      # get the status of this job (Q == Queued, C == Complete, R == Running)
      status="$(echo "$job" | cut -d',' -f10)"
      jobid="$(echo "$job" | cut -d',' -f1 | cut -d'.' -f1)"

      if [ "$status" == "Q" ]; then
        echo "detected previously queued job: $jobid, killing it...";
        qdel $jobid;
      fi
    done

    # update the repo, pull down the latest
    git fetch $REMOTE_NAME
    # git reset --hard
    # git checkout $SYNTH_BRANCH
    # git reset --hard
    # git pull $REMOTE_NAME $SYNTH_BRANCH

    # grab the new commit hash to report back with
    export COMMIT_HASH="$(git rev-parse --short "$remote_commit")"

    # submit the new job using l33t h@ck5
    # NOTE: this git logic is pretty stupid and hacked together. don't just
    # blindly put this into production without testing + tweaking first.
    git checkout "${SYNTH_BRANCH}_base" $PBS_SCRIPT
    submit_result="$( ./$PBS_SCRIPT )"
    if [ "$?" -ne '0' ]; then
      echo "Error: Failed to submit job with PBS script: $PBS_SCRIPT";
    else
      # parse out the job id from the output of the PBS script
      jobid="$( echo "$submit_result" | tail -1 | cut -d'=' -f2 | cut -d'.' -f1)"
      submit_time=$(date +%s);

      # log the jobid:commit_hash relationship
      echo "$jobid,$COMMIT_HASH,$submit_time" >> $JOB_LOG_FILE;
    fi
  else
    sleep 1;
  fi

  git reset --hard "${SYNTH_BRANCH}_base"
done

