#!/bin/csh
## || marks changes to make the script run CAM in parallel (and batch)
## 'sl' marks changes to make the script run on /scratch/local on each node
#
# Shell script to work with *syncronous* filter integration       ?
# This script needs to be piped to the filter program with the
# filter namelist async variable set to .true.

# If this is first of recursive calls need to get rid of async_may_go
# Technically, this could lock, but seems incredibly unlikely
if ($?First) then
#  Do nothing if this is not the first time
else
   setenv First no
###   rm -f async_may_go
# Clean up any assim_model_ic and ud files and temp directories
   rm -f assim_model_ic*
   rm -f assim_model_ud*
#sl    rm -rf tempdir*
# Call the model's initialization script to allow it to set up if needed
   csh ./init_advance_model.csh
endif

while(1 == 1)
   rm -f .async_garb
   ls async_may_go > .async_garb
   if ($status == 0) break
   echo waiting_for_async_may_go_file
   sleep 5
end
echo found_async_may_go_file

# create file to signal status of batch execution of ensemble
echo 'batch not done' > batchflag

# batch execution of ensemble
qsub advance_ens.csh

# Wait for it to finish
echo waiting_for_batch_advance_ens
while(1 == 1)
   ls batchflag >! .batch_garb
   if ($status != 0) break
   sleep 30
end
echo batch_is_done

# Remove the semaphore file
rm -f async_may_go

# Cleaned up; let the filter know it can proceed
echo All_done:Please_proceed

# Doing recursive call
# || csh ./async_filter.csh
csh ./sync_submit.csh
