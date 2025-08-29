#!/bin/bash
#BSUB -P 0575
#BSUB -q s_download
#BSUB -J rsync_archive_from_atos
#BSUB -W 23:59
#BSUB -n 1
#BSUB -R "rusage[mem=2048]"


# === Parameters from environment ===
SRC_USER="${SRC_USER:-ita6760}"
SRC_HOST="${SRC_HOST:-hpc-login}"
EXP="${EXP:-d4o_all30_CERI5B}"
PARALLEL_COPIES_NUM="${PARALLEL_COPIES_NUM:-4}"   # safer default
# ===================================


LOG="rsync_${SRC_USER}_${SRC_HOST}_${EXP}_${PARALLEL_COPIES_NUM}_$(date +%Y%m%d%H%M).log"


echo "Beginning rsync at $(date)" >> "$LOG"

SRC_BASE="/ec/res4/scratch/${SRC_USER}/land/archive/${EXP}/"
DST_BASE="/work/cmcc/spreads-lnd/land/archive/${EXP}/"

# Unique control socket per job
CTL_PATH="/tmp/ssh_mux_${LSB_JOBID}_${SRC_HOST}"

# Open persistent SSH connection
echo "Opening persistent SSH connection ..." >> "$LOG"
ssh -MNf \
    -o ControlMaster=yes \
    -o ControlPath=$CTL_PATH \
    -o ControlPersist=600 \
    ${SRC_USER}@${SRC_HOST} 2>>"$LOG"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to establish persistent SSH connection" >> "$LOG"
    exit 1
fi

echo "Listing directories in remote host ..." >> "$LOG"
DIRS=$(ssh -o ControlPath=$CTL_PATH ${SRC_USER}@${SRC_HOST} \
        "ls -1d ${SRC_BASE}/* 2>/dev/null")

# Convert to array
readarray -t DIR_ARRAY <<< "$DIRS"

# Counter for parallel jobs
count=0

for dir in "${DIR_ARRAY[@]}"; do
    echo "======================== processing dir = $dir" >> "$LOG"

    rel_dir="${dir#$SRC_BASE}"
    mkdir -p "${DST_BASE}/${rel_dir}" >> "$LOG" 2>&1

    # rsync using the multiplexed connection
    stdbuf -oL rsync -e "ssh -o ControlPath=$CTL_PATH" \
        -rtvhz "${SRC_USER}@${SRC_HOST}:/${dir}/" "${DST_BASE}/${rel_dir}/" \
        >> "$LOG" 2>&1 &

    ((count++))
    if (( count % PARALLEL_COPIES_NUM == 0 )); then
        wait
    fi
done

wait

# Close the master connection
ssh -S $CTL_PATH -O exit ${SRC_USER}@${SRC_HOST} 2>>"$LOG"

echo "Copy ended at: $(date)" >> "$LOG"
