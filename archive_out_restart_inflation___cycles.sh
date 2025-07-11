#!/bin/bash

# Define parameters
exp_name="d4o_all30_v11_30nodes"
dry_run=true
rm_files=true
year=2017
start_month=01
end_month=11
start_day=     # only used for the first month of the period
end_day=       # only used for the last month of the period
machine="JUNO"

# if start_day is not set, default to 01
if [ -z "$start_day" ]; then
    start_day=01
fi
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
        case $month in
            01|03|05|07|08|10|12) finish_day=31;;
            04|06|09|11) finish_day=30;;
            02) finish_day=29;; # Not handling leap years for simplicity
        esac
     else
        # if month is the last month, use end_day
        finish_day=$end_day
    fi 
    # Execute the command for the current month
    echo "Executing ""$exp_name" "$dry_run" "$rm_files" "$year" "$year" "$month" "$month" "$begin_day" "$finish_day" "$machine"
    ./archive_out_restart_inflation.sh "$exp_name" "$dry_run" "$rm_files" "$year" "$year" "$month" "$month" "$begin_day" "$finish_day" "$machine" &
    
    # Uncomment the next line if you want to wait for each month to finish before starting the next
    # wait

done

wait
