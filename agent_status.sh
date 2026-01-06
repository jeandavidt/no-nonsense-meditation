#!/bin/bash
# agent_status.sh - Checks for stale or crashed subagents

CHECKPOINT_DIR="./checkpoints"

echo "=== Active Agent Health Check ==="
if [ ! -d "$CHECKPOINT_DIR" ]; then
    echo "No checkpoint directory found."
    exit 0
fi

for agent_dir in "$CHECKPOINT_DIR"/*/; do
    agent_name=$(basename "$agent_dir")
    json_file="${agent_dir}checkpoint.json"
    
    if [ -f "$json_file" ]; then
        # Check if the file was modified more than 5 minutes ago
        if [[ $(find "$json_file" -mmin +5) ]]; then
            status="⚠️  STALE (Likely Crashed)"
        else
            status="✅ ACTIVE"
        fi
        
        last_step=$(grep -o '"current_task": "[^"]*"' "$json_file" | cut -d'"' -f4)
        echo "Agent: $agent_name | Status: $status | Task: $last_step"
    else
        echo "Agent: $agent_name | Status: ❌ NO CHECKPOINT"
    fi
done