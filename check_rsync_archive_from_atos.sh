#!/bin/bash
#BSUB -P 0575
#BSUB -q s_download
#BSUB -J check_rsync_archive_from_atos
#BSUB -W 23:59
#BSUB -n 1
#BSUB -R "rusage[mem=1024]"


# This script does does a rsync without paralelization from ATOS to JUNO. The parameter fix indicates dryrun or not.
# Use it at the end of runs using rsync_archive_from_atos.sh, to check/fix errors.

# === Parameters from environment ===
SRC_USER="${SRC_USER:-ita6760}"
SRC_HOST="${SRC_HOST:-hpc-login}"
EXP="${EXP:-d4o_all30_CERI5B}"
EXP_USER="${EXP_USER:-ita6760}"
FIX="${FIX:-n}" # n=dryrun = do not fix. Pass "v"  fix (just verbose flag again)
# ===================================

LOG="check_rsync_${FIX}_${SRC_USER}_${SRC_HOST}_${EXP}_${EXP_USER}_$(date +%Y%m%d%H%M).log"

echo "Beginning checking rsync at $(date)" >> "$LOG"

SRC_BASE="/ec/res4/scratch/${EXP_USER}/land/archive/${EXP}/"
DST_BASE="/work/cmcc/spreads-lnd/land/archive/${EXP}/"

# Unique control socket per job
CTL_PATH="/tmp/ssh_mux_${LSB_JOBID}_${SRC_HOST}"

# --- function to ensure ssh control master is alive ---
ensure_ssh_connection() {
    local retries=5
    local delay=10
    for ((i=1; i<=retries; i++)); do
        ssh -S "$CTL_PATH" -O check ${SRC_USER}@${SRC_HOST} 2>/dev/null
        if [ $? -eq 0 ]; then
            return 0
        fi
        echo "[$(date)] SSH control connection lost. Reconnecting (attempt $i/$retries)..." >> "$LOG"
        ssh -MNf \
            -o ControlMaster=yes \
            -o ControlPath=$CTL_PATH \
            -o ControlPersist=600 \
            ${SRC_USER}@${SRC_HOST} 2>>"$LOG"
        if [ $? -eq 0 ]; then
            echo "[$(date)] SSH reconnected successfully." >> "$LOG"
            return 0
        fi
        sleep $delay
    done
    echo "[$(date)] ERROR: Failed to re-establish SSH connection after $retries attempts." >> "$LOG"
    exit 1
}

ensure_ssh_connection

rsync -rvhz${FIX} --delete -e "ssh -o ControlPath=$CTL_PATH" \
"${SRC_USER}@${SRC_HOST}:/${SRC_BASE}/" "${DST_BASE}/" >> "$LOG" 2>&1

# Close the master connection
ssh -S $CTL_PATH -O exit ${SRC_USER}@${SRC_HOST} 2>>"$LOG"

echo "Check ended at: $(date)" >> "$LOG"
