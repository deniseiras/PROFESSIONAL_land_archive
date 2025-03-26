#!/bin/bash

#BSUB -n 72
#BSUB -R "span[ptile=72]" 
#BSUB -q p_short
#BSUB -W 1:00
#BSUB -P R000
#BSUB -x 
#BSUB -J arch_outrest
#BSUB -o log/arch_output78.out.%J
#BSUB -e log/arch_output78.out.%J
#BSUB -app spreads_filter
#BSUB -I

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


# script start
#

mkdir -p $ARCHIVE_DIR
ARCHIVE_EXEC_FILE="./archive_execution_${EXP_NAME}_${YYYY_INIT}_${YYYY_END}_${MM_INIT}_${MM_END}.sh"
ARCHIVE_LOG_FILE="./archive_execution_${EXP_NAME}_${YYYY_INIT}_${YYYY_END}_${MM_INIT}_${MM_END}.log"

# function print messages and execute commands
# when using dry run, the commands are not executed, only printed to the execution file
message_exec_command() {
  MESSAGE=$1
  COMMAND=$2

  MSG_TIME="# $(date +"%Y-%m-%d %H:%M:%S") - $MESSAGE"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "# $MSG_TIME" >> $ARCHIVE_EXEC_FILE
    if [[ ! -z "$COMMAND" ]]; then
      echo "$COMMAND" >> $ARCHIVE_EXEC_FILE
    fi  
  else
    echo "$MSG_TIME"
    if [[ ! -z "$COMMAND" ]]; then
      eval "$COMMAND" >> $ARCHIVE_LOG_FILE
    fi    
  fi
}


min() {
  if [[ $1 -le $2 ]]; then
    echo $1
  else
    echo $2
  fi
}


# Main Loop over years and months and days inputed by the user
for yyyy in $(seq $YYYY_INIT $YYYY_END); do
  for mm in $(seq $MM_INIT $MM_END); do
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

      # Create subdirectories for organized archiving within ARCHIVE_DIR
      OUTPUT_DIR="$ARCHIVE_DIR/output_history_$TARGET_DATE"
      RESTART_DIR="$ARCHIVE_DIR/restart_$TARGET_DATE"
      INFLATION_DIR="$ARCHIVE_DIR/inflation_$TARGET_DATE"
      mkdir -p "$OUTPUT_DIR" "$RESTART_DIR" "$INFLATION_DIR"

      # Compress and move output/history files for the specified date from RUN_DIR to ARCHIVE_DIR
      for file in "$RUN_DIR"/"$EXP_NAME"*.h[0-9]*."$TARGET_DATE"-00000.nc; do
        if [ -e "$file" ]; then
          filename=$(basename "$file")

          MESSAGE='Compressing "$filename" with netcdf4 format...'
          COMMAND='nccopy -k 4 -d 1 "$file" "$OUTPUT_DIR/${filename%.nc}_nc4.nc"'
          exec_command "$MESSAGE" "$COMMAND"
          if [[ "$REMOVE_FILES" == "true" ]]; then
            exec_command 'Removing "$file" ...' 'rm "$file"'
          fi
        else
          exec_command "File $file does not exist, skipping ..."
        fi
      done

      # for file in "$RUN_DIR"/clm_analysis_member_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_analysis_mean_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_analysis_sd_*."$TARGET_DATE"-00000.nc; do
      #   if [ -e "$file" ]; then
      #     filename=$(basename "$file")
      #     echo "Compressing $filename with netcdf4 format..."
      #     nccopy -k 4 -d 1 "$file" "$OUTPUT_DIR/${filename%.nc}_nc4.nc"
      #     rm "$file"
      #   fi
      # done

      # for file in "$RUN_DIR"/clm_preassim_member_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_preassim_mean_*."$TARGET_DATE"-00000.nc "$RUN_DIR"/clm_preassim_sd_*."$TARGET_DATE"-00000.nc; do
      #   if [ -e "$file" ]; then
      #     filename=$(basename "$file")
      #     echo "Compressing $filename with netcdf4 format..."
      #     nccopy -k 4 -d 1 "$file" "$OUTPUT_DIR/${filename%.nc}_nc4.nc"
      #     rm "$file"
      #   fi
      # done

      # # Only archive restart if the date is the 1st or 15th of the month
      # DAY_OF_MONTH=$(date -d "$TARGET_DATE" +%d)
      # if [[ "$DAY_OF_MONTH" == "01" || "$DAY_OF_MONTH" == "15" ]]; then
      #   # Create directories for restart and inflation files only if archiving
      #   RESTART_DIR="$ARCHIVE_DIR/restart_$TARGET_DATE"
      #   INFLATION_DIR="$ARCHIVE_DIR/inflation_$TARGET_DATE"
      #   mkdir -p "$RESTART_DIR" "$INFLATION_DIR"

      #   # Archive and move all restart files for the given date from RUN_DIR to ARCHIVE_DIR
      #   for file in "$RUN_DIR"/"$EXP_NAME"*.r*."$TARGET_DATE"-00000.nc "$RUN_DIR"/"$EXP_NAME"*.rh*."$TARGET_DATE"-00000.nc; do
      #     if [ -e "$file" ]; then
      #       filename=$(basename "$file")
      #       echo "Compressing $filename with gzip..."
      #       gzip "$file"
      #       mv "$RUN_DIR/$filename.gz" "$RESTART_DIR/"
      #     fi
      #   done
      # fi
      # # Compress and move only clm_output inflation files for the specified date from RUN_DIR to ARCHIVE_DIR
      # for file in "$RUN_DIR"/clm_output_priorinf*."$TARGET_DATE"-00000.nc; do
      #   if [ -e "$file" ]; then
      #     filename=$(basename "$file")
      #     echo "Compressing $filename with gzip..."
      #     gzip "$file"
      #     mv "$RUN_DIR/$filename.gz" "$INFLATION_DIR/"
      #   fi
      # done

      echo "Archiving completed for date $TARGET_DATE"
      date

    done # dd
  done # mm
done  # yyyy


# TODO check for that

# # Remove unwanted clm_output_mean and clm_output_sd files for the given date in RUN_DIR
# rm -f "$RUN_DIR"/"$EXP_NAME"*clm_output_mean*."$TARGET_DATE"-00000.nc "$RUN_DIR"/"$EXP_NAME"*clm_output_sd*."$TARGET_DATE"-00000.nc

message_exec_command 'Archiving and cleanup completed for dates between month "${MM_INIT}" and "${MM_END}" of year between "${YYYY_INIT}" and "${YYYY_END}"'


