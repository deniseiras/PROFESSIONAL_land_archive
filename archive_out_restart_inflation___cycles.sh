#!/bin/bash

# Define parameters
exp_name="d4o_all30_v4"
dry_run=true
rm_files=true
start_year=2005
end_year=2006
start_month=01
end_month=12  

# Iterate over months from start_month to end_month
for month in $(seq -w $start_month $end_month); do
    # Define the start and end day of each month
    case $month in
        01|03|05|07|08|10|12) days=31;;
        04|06|09|11) days=30;;
        02) days=29;; # Not handling leap years for simplicity
    esac
    
    # Execute the command for the current month
    echo "Executing ""$exp_name" "$dry_run" "$rm_files" "$start_year" "$end_year" "$month" "$month" 01 "$days"
    ./archive_out_restart_inflation.sh "$exp_name" "$dry_run" "$rm_files" "$start_year" "$end_year" "$month" "$month" 01 "$days" &
    
    # Optional: Wait for the command to finish before proceeding
    wait

done

wait
