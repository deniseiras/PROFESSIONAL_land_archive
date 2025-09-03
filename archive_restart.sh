#!/bin/bash

# Usage: archive_restart.sh <exp_name> <archive_root_dir> <archive_out_dir> <start_date> <end_date> [max_h]

exp_name=$1         # experiment name, e.g. d4o_all30_CERI7
archive_dir=$2      # copy from
archive_out=$3      # copy to 
start_date=$4       # start_date in format YYYYMMDD
end_date=$5         # end_date in format YYYYMMDD
max_h=${6:-7}       # optional, defaults to 7
do_checksum=${8:-true}

# Parse start_date and end_date
start_year=$(echo $start_date | cut -c1-4)
start_month=$(echo $start_date | cut -c5-6)
start_day=$(echo $start_date | cut -c7-8)
end_year=$(echo $end_date | cut -c1-4)
end_month=$(echo $end_date | cut -c5-6)
end_day=$(echo $end_date | cut -c7-8)

# Logging
hour_now=$(date +"%Y-%m-%d_%H%M%S")
arch_log_file="./archive_restart__${exp_name}_${start_date}_${end_date}__at_${hour_now}.log"

write_file() { echo "$1" >> "$arch_log_file"; }

# Fast checksum method
CHECKSUM_CMD="md5sum"  # change to xxh64sum if installed for even faster checks
PARALLEL_PROCESSES=64

declare -a copy_pids
declare -a files_to_check

# Function to copy file (no checksum yet)
copy_file() {
    src_file="$1"
    dest_dir="$2"
    if [ -e "$src_file" ]; then
        cp -uv "$src_file" "$dest_dir" &
        copy_pids+=($!)
        files_to_check+=("$src_file|$dest_dir/$(basename "$src_file")")
        # Limit copies in parallel
        while (( $(jobs -r | wc -l) >= PARALLEL_PROCESSES )); do
            wait -n
        done
    else
        write_file "$src_file"
    fi
}

# Loop over dates and prepare copies
for i_year in $(seq $start_year $end_year); do
  [[ $i_year -eq $start_year ]] && begin_month=$start_month || begin_month=01
  [[ $i_year -eq $end_year ]] && finish_month=$end_month || finish_month=12

  for i_month in $(seq -w $begin_month $finish_month); do
    if [[ $i_year -eq $start_year && $i_month == $start_month ]]; then begin_day=$start_day; else begin_day=01; fi

    if [[ $i_year -eq $end_year && $i_month == $end_month ]]; then
      finish_day=$end_day
    else
      case $i_month in
        02) if (( i_year % 4 == 0 && (i_year % 100 != 0 || i_year % 400 == 0) )); then finish_day=29; else finish_day=28; fi ;;
        04|06|09|11) finish_day=30 ;;
        *) finish_day=31 ;;
      esac
    fi

    for i_day in $(seq -w "$begin_day" "$finish_day"); do
      target_date="${i_year}-${i_month}-${i_day}"

      if [[ $(date -d "$target_date" +%d) == "01" ]]; then
        echo "================================================================================================================================================="
        echo "Starting copying date ${target_date}"

        restart_dir="$archive_dir/restart_$target_date"
        restart_out="$archive_out/restart_$target_date"
        mkdir -p "$restart_out"
        for h in $(seq 0 $max_h); do
          for memb in $(seq -f "%04g" 1 30); do
            copy_file "${restart_dir}/${exp_name}.clm2_${memb}.rh${h}.${target_date}-00000.nc.gz" "$restart_out"

            if [ "$h" -eq 0 ]; then
              copy_file "${restart_dir}/${exp_name}.clm2_${memb}.r.${target_date}-00000.nc.gz" "$restart_out"
              copy_file "${restart_dir}/${exp_name}.cpl_${memb}.r.${target_date}-00000.nc.gz" "$restart_out"
              copy_file "${restart_dir}/${exp_name}.datm_${memb}.r.${target_date}-00000.nc.gz" "$restart_out"
              copy_file "${restart_dir}/${exp_name}.hydros_${memb}.r.${target_date}-00000.nc.gz" "$restart_out"
              copy_file "${restart_dir}/${exp_name}.hydros_${memb}.rh0.${target_date}-00000.nc.gz" "$restart_out"
            fi
          done
        done
      fi
    done
  done
done


erro=0
if [[ "$do_checksum" == "true" ]]; then
  echo "Waiting for all copies to complete..."
  wait

  echo "Verifying checksums..."
  for entry in "${files_to_check[@]}"; do
      (
          src="${entry%%|*}"
          dest="${entry##*|}"
          if [ -f "$dest" ]; then
              src_sum=$($CHECKSUM_CMD "$src" | awk '{print $1}')
              dest_sum=$($CHECKSUM_CMD "$dest" | awk '{print $1}')
              if [[ "$src_sum" != "$dest_sum" ]]; then
                  echo "ERROR: $dest checksum mismatch"
                  erro=1
              else
                  echo "OK: $dest"
              fi
          else
              echo "ERROR: Missing file $dest"
              erro=1
          fi
      ) &
      # Limit checksum jobs in parallel
      while (( $(jobs -r | wc -l) >= PARALLEL_PROCESSES )); do
          wait -n
      done
  done
  wait
fi 

echo
echo "================================================================================================================================================="
echo "Copying completed for dates between ${start_date} and ${end_date} in archive directory $archive_out"
if [[ $erro -eq 0 ]]; then
    echo "✅ All copies are valid."
else
    echo "⚠️ Errors found during file copy integrity check."
fi
if [ ! -e "$arch_log_file" ]; then
  echo "No missing files in the archive directory $archive_dir"
else
  echo "Some files are missing in the archive directory $archive_dir, check the log file for details"
  echo "Log file: $arch_log_file"
fi
echo "================================================================================================================================================="
