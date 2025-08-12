#!/bin/bash

# Usage: check_archive.sh <exp_name> <archive_root_dir> <start_date> <end_date> [max_h]
# Example: ./check_archive.sh d4o_all30_CERI7 /ec/res4/scratch/ita6760/land/archive/d4o_all30_CERI7 20030521 20030525 7

exp_name=$1         # experiment name, e.g. d4o_all30_CERI7
archive_dir=$2 # 
start_date=$3       # start_date in format YYYYMMDD
end_date=$4         # end_date in format YYYYMMDD
max_h=${5:-7}       # max_h=$5 optional, otherwise defaults to 7

# Parse start_date and end_date
start_year=$(echo $start_date | cut -c1-4)
start_month=$(echo $start_date | cut -c5-6)
start_day=$(echo $start_date | cut -c7-8)
end_year=$(echo $end_date | cut -c1-4)
end_month=$(echo $end_date | cut -c5-6)
end_day=$(echo $end_date | cut -c7-8)


# Functions =======================================================================
# function that returns the minimum of two numbers
min() {
  echo $(( $1 < $2 ? $1 : $2 ))
}

# Function for printing messages
# - when using dry run, messages are comented in exec file
# - otherwise messages are printed to the log file
write_file() {
  msg=$1
  msg_comm="echo ${msg}"
  eval $msg_comm >> $arch_log_file

}


# Script start ===========================================================================

# if start_day is not set, default to 01
if [ -z "$start_day" ]; then
    start_day=01
fi

hour_now=$(date +"%Y-%m-%d_%H%M%S")
arch_log_file="./check_archive__${exp_name}_${start_date}_${end_date}__at_${hour_now}.log"

# Execute the command for the current month
echo "Checking $exp_name , dates from: ${start_date} to: ${end_date}"
echo "If there are files not found, log file will be generated"
echo "Log file: $arch_log_file"


# Iterate over years from start_year to end_year
for i_year in $(seq $start_year $end_year); do

  # If the year is the start year, set the start month
  if [ "$i_year" -eq "$start_year" ]; then
    begin_month=$start_month
  else
    begin_month=01
  fi
  # If the year is the end year, set the end month
  if [ "$i_year" -eq "$end_year" ]; then
    finish_month=$end_month
  else
    finish_month=12
  fi

  # Iterate over months from begin_month to finish_month
  # Use seq -w to ensure months are zero-padded  
  for i_month in $(seq -w $begin_month $finish_month); do

    if [ "$i_year" -eq "$start_year" ] && [ "$i_month" == "$start_month" ]; then
      begin_day=$start_day
    else
      begin_day=01
    fi

    if [ "$i_year" -eq "$end_year" ] && [ "$i_month" == "$end_month" ]; then
      finish_day=$end_day
    else
      if [[ "$i_month" == "02" ]]; then
        if (( $i_year % 4 == 0 && ($i_year % 100 != 0 || $i_year % 400 == 0) )); then
          finish_day=29  # Leap year
        else
          finish_day=28
        fi
      elif [ "$i_month" == "04" ] || [ "$i_month" == "06" ] || [ "$i_month" == "09" ] || [ "$i_month" == "11" ]; then
        finish_day=30
      else
        finish_day=31
      fi
    fi 
    

    # Loop over the days inputed by the user
    for i_day in $(seq -w "$begin_day" "$finish_day"); do

   
      target_date="${i_year}-${i_month}-${i_day}"
      echo "================================================================================================================================================="
      echo "Starting checking date ${target_date}"

      # subdirectories for organized archiving within archive_dir
      output_dir="$archive_dir/output_history_$target_date"
      restart_dir="$archive_dir/restart_$target_date"
      inflation_dir="$archive_dir/inflation_$target_date"


      echo "Checking OUTPUT and RESTART files..."
      
      for h in $(seq 0 $max_h); do

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
              hydros_rh0_file="${restart_dir}/${exp_name}.hydros_${memb}.rh0.${target_date}-00000.nc.gz"
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

    done # i_day
  done # i_month
done # i_year

echo
echo "================================================================================================================================================="
echo "Checking completed for dates between ${start_date} and ${end_date} in archive directory $archive_dir"
# if file arch_log_file exists, print that there are no files not found, otherwise print No errors found
if [ ! -e "$arch_log_file" ]; then
  echo "No errors found, all files are present in the archive directory $archive_dir"
else
  echo "Errors found, some files are missing in the archive directory $archive_dir, check the log file for details"
  echo "Log file: $arch_log_file"
fi
echo "================================================================================================================================================="

# script end ===========================================================================
