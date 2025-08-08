#!/bin/bash

# Define parameters ================================================================
# exp_name="d4o_all30_CERI5"
# year=2003
# start_month=04
# start_day=22     # only used for the first month of the period
# end_month=04
# end_day=22       # only used for the last month of the period
# machine="ATOS"
exp_name=$1
year=$2
start_month=$3
start_day=$4
end_month=$5
end_day=$6
machine=$7

# Change ONCE !
# JUNO
if [ "$machine" == "JUNO" ]; then
  # archive directory where the files are stored
  ARCHIVE_DIR="/work/cmcc/spreads-lnd/land/archive/$exp_name"
else
  # ATOS 
  # archive directory where the files are stored
  # ARCHIVE_DIR="/ec/res4/scratch/ita5542/land/archive/$exp_name"
  # ARCHIVE_DIR="/ec/res4/scratch/ita5542/land/archive/${exp_name}_$(date +%Y%m%d)" - used temporarily
  ARCHIVE_DIR="/ec/res4/scratch/ita6760/land/archive/$exp_name"
fi


# Functions =======================================================================
# function that returns the minimum of two numbers
min() {
  echo $(( $1 < $2 ? $1 : $2 ))
}

# Function for printing messages
# - when using dry run, messages are comented in exec file
# - otherwise messages are printed to the log file
write_file() {
  MESSAGE=$1

  MSG_TIME="echo ${MESSAGE}"
  eval $MSG_TIME >> $arch_log_file

}


# Script start ===========================================================================

# if start_day is not set, default to 01
if [ -z "$start_day" ]; then
    start_day=01
fi

hour_now=$(date +"%Y-%m-%d_%H%M%S")
date_ini_end=${year}${month}${star_day}-${year}${month}${end_day}
arch_log_file="./check_archive__${exp_name}_${date_ini_end}__at_${hour_now}.log"

# Execute the command for the current month
echo "Checking $exp_name , dates from to: $date_ini_end , on machine: $machine "
echo "If there are files not found, log file will be generated"
echo "Log file: $arch_log_file"

# Iterate over months from start_month to end_month
for month in $(seq -w $start_month $end_month); do
  # if month is not the first month, default to 01
  if [ "$month" != "$start_month" ]; then
    begin_day=01
  else
    begin_day=$start_day
  fi

  # if month is not the last month
  if [ "$month" != "$end_month" ] || [ -z "$end_day" ]; then
    # Define the maximum number of days for each month
    if [[ "$month" == "02" ]]; then
      if (( $year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0) )); then
        finish_day=29  # Leap year
      else
        finish_day=28
      fi
    elif [ "$month" == "04" ] || [ "$month" == "06" ] || [ "$month" == "09" ] || [ "$month" == "11" ]; then
      finish_day=30
    else
      finish_day=31
    fi
  else
    # if month is the last month, use end_day
    finish_day=$end_day
  fi 
  

  # Loop over the days inputed by the user
  for iday in $(seq -w "$begin_day" "$finish_day"); do
    # Specify the target date (e.g., 2000-03-15)
    target_date="${year}-${month}-${iday}"
    echo "================================================================================================================================================="
    echo "Starting checking date ${target_date}"

    # subdirectories for organized archiving within ARCHIVE_DIR
    output_dir="$ARCHIVE_DIR/output_history_$target_date"
    restart_dir="$ARCHIVE_DIR/restart_$target_date"
    inflation_dir="$ARCHIVE_DIR/inflation_$target_date"


    echo "Checking OUTPUT and RESTART files..."
    for h in {0..7}; do # when is 08 ?

      for memb in $(seq -f "%04g" 1 30); do

        # OUTPUT files
        #

        # d4o_all30_CERI5.clm2_0001.h0.2003-04-22-00000_nc4.nc
        output_file="${output_dir}/${exp_name}.clm2_${memb}.h${h}.${target_date}-00000_nc4.nc"
        if [ ! -e "$output_file" ]; then
          write_file "${output_file}"
        fi

        # RESTART files
        #

        day_of_month=$(date -d "$target_date" +%d)
        # Only check restart files if the date is the 1st or 15th of the month
        if [[ "$day_of_month" == "01" || "$day_of_month" == "15" ]]; then
          
          # d4o_all30_CERI7.clm2_0001.rh0.2004-01-01-00000.nc.gz
          history_m_file="${restart_dir}/${exp_name}.clm2_${memb}.rh${h}.${target_date}-00000.nc.gz"
          if [ ! -e "$history_m_file" ]; then
            write_file "${history_m_file}"
          fi
          # Only check once for member
          if [ "$h" -eq 0 ]; then
            # d4o_all30_CERI7.clm2_0001.r.2004-01-01-00000.nc.gz
            history_r_file="${restart_dir}/${exp_name}.clm2_${memb}.r.${target_date}-00000.nc.gz"
            if [ ! -e "$history_r_file" ]; then
              write_file "${history_r_file}"
            fi

            # d4o_all30_CERI7.cpl_0001.r.2004-01-01-00000.nc.gz
            cpl_r_file="${restart_dir}/${exp_name}.cpl_${memb}.r.${target_date}-00000.nc.gz"
            if [ ! -e "$cpl_r_file" ]; then
              write_file "${cpl_r_file}" 
            fi

            # d4o_all30_CERI7.datm_0001.r.2004-01-01-00000.nc.gz
            datm_r_file="${restart_dir}/${exp_name}.datm_${memb}.r.${target_date}-00000.nc.gz"
            if [ ! -e "$datm_r_file" ]; then
              write_file "${datm_r_file}"
            fi

            # d4o_all30_CERI7.hydros_0001.r.2004-01-01-00000.nc.gz
            hydros_r_file="${restart_dir}/${exp_name}.hydros_${memb}.r.${target_date}-00000.nc.gz"
            if [ ! -e "$hydros_r_file" ]; then
              write_file "${hydros_r_file}"
            fi

            # d4o_all30_CERI7.hydros_0001.rh0.2004-01-01-00000.nc.gz
            hydros_rh0_file="${output_dir}/${exp_name}.hydros_${memb}.rh0.${target_date}-00000.nc.gz"
            if [ ! -e "$hydros_rh0_file" ]; then
              write_file "${hydros_rh0_file}"
            fi
          fi
        fi  # if 1st or 15th of the month
      done # memb
    done # h

    echo "Checking PREASSIM, ANALYSIS and INFLATION files ..."
    for d in $(seq -f "%02g" 1 3); do

      for memb in $(seq -f "%04g" 1 30); do
        # clm_analysis_member_0001_d01.2004-01-01-00000_nc4.nc
        analysis_file="${output_dir}/clm_analysis_member_${memb}_d${d}.${target_date}-00000_nc4.nc"
        if [ ! -e "$analysis_file" ]; then
          write_file "${analysis_file}"
        fi
        # clm_preassim_member_0001_d01.2004-01-01-00000_nc4.nc
        preassim_member_file="${output_dir}/clm_preassim_member_${memb}_d${d}.${target_date}-00000_nc4.nc"
        if [ ! -e "$preassim_member_file" ]; then
          write_file "${preassim_member_file}"
        fi
      done

      # clm_analysis_mean_d01.2004-01-01-00000_nc
      analysis_mean_file="${output_dir}/clm_analysis_mean_d${d}.${target_date}-00000_nc4.nc"
      if [ ! -e "$analysis_mean_file" ]; then
        write_file "${analysis_mean_file}"
      fi
      # clm_analysis_sd_d01.2004-01-01-00000_nc
      analysis_sd_file="${output_dir}/clm_analysis_sd_d${d}.${target_date}-00000_nc4.nc"
      if [ ! -e "$analysis_sd_file" ]; then
        write_file "${analysis_sd_file}"
      fi
      # clm_preassim_mean_d01.2004-01-01-00000_nc
      preassim_mean_file="${output_dir}/clm_preassim_mean_d${d}.${target_date}-00000_nc4.nc"
      if [ ! -e "$preassim_mean_file" ]; then
        write_file "${preassim_mean_file}"
      fi
      # clm_preassim_sd_d01.2004-01-01-00000_nc
      preassim_sd_file="${output_dir}/clm_preassim_sd_d${d}.${target_date}-00000_nc4.nc"
      if [ ! -e "$preassim_sd_file" ]; then
        write_file "${preassim_sd_file}"
      fi


      # INFLATION files
      #

      # clm_output_priorinf_mean_d01.2004-01-01-00000.nc.gz
      output_priorinf_mean_file="${inflation_dir}/clm_output_priorinf_mean_d${d}.${target_date}-00000.nc.gz"
      if [ ! -e "$output_priorinf_mean_file" ]; then
        write_file "${output_priorinf_mean_file}"
      fi
      # clm_output_priorinf_sd_d01.2004-01-01-00000.nc.gz
      output_priorinf_sd_file="${inflation_dir}/clm_output_priorinf_sd_d${d}.${target_date}-00000.nc.gz"
      if [ ! -e "$output_priorinf_sd_file" ]; then
        write_file "${output_priorinf_sd_file}"
      fi

    done # d

  done # iday
done # month

# TODO check for that
# # Remove unwanted clm_output_mean and clm_output_sd files for the given date in RUN_DIR
# rm -f "$RUN_DIR"/"$exp_name"*clm_output_mean*."$target_date"-00000.nc "$RUN_DIR"/"$exp_name"*clm_output_sd*."$target_date"-00000.nc

echo
echo "================================================================================================================================================="
echo "Checking completed for dates between days ${begin_day} and ${finish_day}, month ${month} and ${month} of year between ${year} and ${year}"
# if file arch_log_file exists, print that there are no files not found, otherwise print No errors found
if [ ! -e "$arch_log_file" ]; then
  echo "No errors found, all files are present in the archive directory $ARCHIVE_DIR"
else
  echo "Errors found, some files are missing in the archive directory $ARCHIVE_DIR, check the log file for details"
  echo "Log file: $arch_log_file"
fi
echo "================================================================================================================================================="

# script end ===========================================================================
