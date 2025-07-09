#!/bin/bash

# Define parameters
exp_name="d4o_all30_v11_30nodes"
dry_run=true
rm_files=true
year=2016
start_month=01
end_month=12
machine="JUNO"

# Iterate over months from start_month to end_month
for month in $(seq -w $start_month $end_month); do
    # Define the start and end day of each month
    case $month in
        01|03|05|07|08|10|12) days=31;;
        04|06|09|11) days=30;;
        02) days=29;; # Not handling leap years for simplicity
    esac
    
    # Execute the command for the current month
    echo "Executing ""$exp_name" "$dry_run" "$rm_files" "$year" "$year" "$month" "$month" 01 "$days"
    ./archive_out_restart_inflation.sh "$exp_name" "$dry_run" "$rm_files" "$year" "$year" "$month" "$month" 01 "$days" "$machine" &
    
    # Optional: Wait for the command to finish before proceeding
    #wait

done

wait
