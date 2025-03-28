# Instructions
# - run with DRY run first, without submitting, to check the commands
# - Then, you can either:
#   - submit the $ARCHIVE_EXEC_FILE
#   - or, submit this script with DRY_RUN=false to execute the commands

# Paramters
#
EXP_NAME=$1     # eg d4o_all30_as
DRY_RUN=$2      # true/false
REMOVE_FILES=$3 # true/false
YYYY_INIT=$4    # eg 2002
YYYY_END=$5     # eg 2003
MM_INIT=$6      # eg 09
MM_END=$7       # eg 12
DD_INIT=$8      # eg 01
DD_END=$9       # eg 31

# Change ONCE !
#
# run directory where the data is located
RUN_DIR="/work/cmcc/spreads-lnd/work_d4o/$EXP_NAME/run"  # Update with the correct path
# archive directory where the files are stored
ARCHIVE_DIR="/work/cmcc/spreads-lnd/land/archive_scripts/archive_test/$EXP_NAME"
# nccopy command for generating netcdf4 files. Uses medium compression level (5) for balance between speed, compression and acess time
NCCOPY_CMD="nccopy -k 4 -d 5"

# Functions =================================================================================

# function for executing commands
# - when using dry run, the commands are not executed, only printed to the execution file
# - when not using dry run, the commands are executed
exec_command() {
  COMMAND=$1

  if [[ "$DRY_RUN" == "false" ]]; then
    eval "$COMMAND" >> $ARCHIVE_LOG_FILE
  else
    echo "$COMMAND" >> $ARCHIVE_EXEC_FILE
  fi
}


# Function for printing messages
# - when using dry run, messages are comented in exec file
# - otherwise messages are printed to the log file
message() {
  MESSAGE=$1
  WOUT_TIME=$2

  if [[ "$WOUT_TIME" == "true" ]]; then
    MSG_TIME="$MESSAGE"
  else
    MSG_TIME="# $(date +"%Y-%m-%d %H:%M:%S") - $MESSAGE"
  fi

  if [[ "$DRY_RUN" == "false" ]]; then
    echo $MSG_TIME >> $ARCHIVE_LOG_FILE
  else
    echo $MSG_TIME >> $ARCHIVE_EXEC_FILE
  fi
}


# script start ===========================================================================
#

mkdir -p $ARCHIVE_DIR "./log" "./exec"
HOUR_NOW=$(date +"%Y-%m-%d_%H%M%S")
DATE_INI_END=${YYYY_INIT}${MM_INIT}${DD_INIT}-${YYYY_END}${MM_END}${DD_END}
ARCHIVE_EXEC_FILE="./exec/archive_execution__${EXP_NAME}_${DATE_INI_END}__at_${HOUR_NOW}.sh"
ARCHIVE_LOG_FILE="./log/archive_execution__${EXP_NAME}_${DATE_INI_END}__at_${HOUR_NOW}.log"

if [ $DRY_RUN == "true" ]; then
  echo "<<< DRY RUN MODE >>>"
  echo "Execution file: $ARCHIVE_EXEC_FILE being generated for posterior submission" 

  message "#!/bin/bash" "true"
  message "#BSUB -n 1" "true"
  message "#BSUB -q s_long" "true"
  message "#BSUB -W 24:00" "true"
  message "#BSUB -P 0575" "true"
  message "#BSUB -J archive_land" "true"
  message "#BSUB -o ../${ARCHIVE_LOG_FILE}" "true"
  message "#BSUB -e ../${ARCHIVE_LOG_FILE}" "true"
  message "#BSUB -R \"rusage[mem=10G]\"" "true"
  message "#BSUB -app spreads_filter" "true"
  
else
  echo "Executing and generating log file ${ARCHIVE_LOG_FILE}"
fi


# function that returns the minimum of two numbers
min() {
  if [[ $1 -le $2 ]]; then
    echo $1
  else
    echo $2
  fi
}


# Main Loop over years and months and days inputed by the user
#
for yyyy in $(seq -w $YYYY_INIT $YYYY_END); do
  for mm in $(seq -w $MM_INIT $MM_END); do
    # Define the maximum number of days for each month
    if [ "$mm" == "02" ]; then
      max=29
    elif [ "$mm" == "04" ] || [ "$mm" == "06" ] || [ "$mm" == "09" ] || [ "$mm" == "11" ]; then
      max=30
    else
      max=31
    fi

    # Loop over the days inputed by the user
    for dd in $(seq -w "$DD_INIT" "$(min "$max" "$DD_END")"); do
      # Specify the target date (e.g., 2000-03-15)
      TARGET_DATE="${yyyy}-${mm}-${dd}"
      message "================================================================================================================================================="
      message "Starting archiving for date ${TARGET_DATE}"

      # Create subdirectories for organized archiving within ARCHIVE_DIR
      OUTPUT_DIR="$ARCHIVE_DIR/output_history_$TARGET_DATE"
      RESTART_DIR="$ARCHIVE_DIR/restart_$TARGET_DATE"
      INFLATION_DIR="$ARCHIVE_DIR/inflation_$TARGET_DATE"
      mkdir -p "$OUTPUT_DIR" "$RESTART_DIR" "$INFLATION_DIR"

      message "Compressing OUTPUT/HISTORY files with netcdf4 format..."
      for file in "$RUN_DIR"/"$EXP_NAME"*.h[0-9]*."$TARGET_DATE"-00000.nc; do
        if [ -e "$file" ]; then
          filename=$(basename "$file")

          exec_command "${NCCOPY_CMD} ${file} ${OUTPUT_DIR}/${filename%.nc}_nc4.nc"
          if [[ "$REMOVE_FILES" == "true" ]]; then
            exec_command "rm -f ${file} &"
          fi
        else
          message "File ${file} does not exist, skipping ..."
        fi
      done

      message "Compressing CLM_ANALYSIS files with netcdf4 format..."
      for file in "$RUN_DIR"/clm_analysis_member_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_analysis_mean_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_analysis_sd_*."$TARGET_DATE"-00000.nc; do
        if [ -e "$file" ]; then
          filename=$(basename "$file")
          exec_command "${NCCOPY_CMD} ${file} ${OUTPUT_DIR}/${filename%.nc}_nc4.nc"
          if [[ "$REMOVE_FILES" == "true" ]]; then
            exec_command "rm -f ${file} &"
          fi
        else
          message "File ${file} does not exist, skipping ..."
        fi
      done

      message "Compressing CLM_PREASSIM_MEMBER files with netcdf4 format..."
      for file in "$RUN_DIR"/clm_preassim_member_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_preassim_mean_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_preassim_sd_*."$TARGET_DATE"-00000.nc; do
        if [ -e "$file" ]; then
          filename=$(basename "$file")
          exec_command "${NCCOPY_CMD} ${file} ${OUTPUT_DIR}/${filename%.nc}_nc4.nc"
          if [[ "$REMOVE_FILES" == "true" ]]; then
            exec_command "rm -f ${file} &"
          fi
        else
          message "File ${file} does not exist, skipping ..."
        fi
      done

      # Only archive restart if the date is the 1st or 15th of the month
      DAY_OF_MONTH=$(date -d "$TARGET_DATE" +%d)
      if [[ "$DAY_OF_MONTH" == "01" || "$DAY_OF_MONTH" == "15" ]]; then
        message "Compressing RESTART files with gzip format"
        # Create directories for restart and inflation files only if archiving
        RESTART_DIR="$ARCHIVE_DIR/restart_$TARGET_DATE"
        mkdir -p "$RESTART_DIR"

        # Archive and move all restart files for the given date from RUN_DIR to ARCHIVE_DIR
        for file in "$RUN_DIR"/"$EXP_NAME"*.r*."$TARGET_DATE"-00000.nc "$RUN_DIR"/"$EXP_NAME"*.rh*."$TARGET_DATE"-00000.nc; do
          if [ -e "$file" ]; then
            filename=$(basename "$file")
            exec_command "gzip $file"
            exec_command "mv ${RUN_DIR}/${filename}.gz ${RESTART_DIR}/"
          else
            message "File ${file} does not exist, skipping ..."
          fi
        done
      fi

      message "Compressing INFLATION files with gzip..."
      INFLATION_DIR="$ARCHIVE_DIR/inflation_$TARGET_DATE"
      mkdir -p "$INFLATION_DIR"
      for file in "$RUN_DIR"/clm_output_priorinf*."$TARGET_DATE"-00000.nc; do
        if [ -e "$file" ]; then
          filename=$(basename "$file")
          exec_command "gzip ${file}"
          exec_command "mv ${RUN_DIR}/${filename}.gz ${INFLATION_DIR}/"
        else
          message "File ${file} does not exist, skipping ..."
        fi
      done

      message "Archiving completed for date ${TARGET_DATE}"

    done # dd
  done # mm
done  # yyyy


# TODO check for that
# # Remove unwanted clm_output_mean and clm_output_sd files for the given date in RUN_DIR
# rm -f "$RUN_DIR"/"$EXP_NAME"*clm_output_mean*."$TARGET_DATE"-00000.nc "$RUN_DIR"/"$EXP_NAME"*clm_output_sd*."$TARGET_DATE"-00000.nc

message "================================================================================================================================================="
message "Archiving and cleanup completed for dates between days ${DD_INIT} and ${DD_END}, month ${MM_INIT} and ${MM_END} of year between ${YYYY_INIT} and ${YYYY_END}"
message "================================================================================================================================================="

# script end ===========================================================================