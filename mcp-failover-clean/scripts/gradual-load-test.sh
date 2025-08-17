#!/bin/bash

# Gradual Load Test Script for AI Agent Demonstration
# This script gradually increases load to show predictive scaling capabilities

set -e

# Configuration
DURATION=${1:-300}  # Total test duration in seconds (default: 5 minutes)
NAMESPACE="mcp-failover-clean"
SERVICE_NAME="web"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Function to get service URL
get_service_url() {
    local url
    url=$(minikube service $SERVICE_NAME -n $NAMESPACE --url 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$url" ]; then
        echo "$url"
    else
        log "${RED}Error: Could not get service URL${NC}"
        exit 1
    fi
}

# Function to make HTTP requests
make_requests() {
    local url=$1
    local count=$2
    local concurrent=$3
    
    for ((i=1; i<=count; i++)); do
        if [ $((i % concurrent)) -eq 0 ]; then
            wait  # Wait for previous batch to complete
        fi
        curl -s "$url" > /dev/null 2>&1 &
    done
    wait  # Wait for final batch
}

# Function to calculate load phase
calculate_load_phase() {
    local elapsed=$1
    local total_duration=$2
    
    # Phase 1 (0-25%): Light load - 2-5 requests/second
    if [ $elapsed -lt $((total_duration / 4)) ]; then
        echo "light"
    # Phase 2 (25-50%): Moderate load - 5-15 requests/second  
    elif [ $elapsed -lt $((total_duration / 2)) ]; then
        echo "moderate"
    # Phase 3 (50-75%): Heavy load - 15-30 requests/second
    elif [ $elapsed -lt $((total_duration * 3 / 4)) ]; then
        echo "heavy"
    # Phase 4 (75-100%): Peak load - 30-50 requests/second
    else
        echo "peak"
    fi
}

# Function to get requests per second for phase
get_rps_for_phase() {
    local phase=$1
    case $phase in
        "light")   echo "3" ;;
        "moderate") echo "10" ;;
        "heavy")   echo "22" ;;
        "peak")    echo "40" ;;
        *)         echo "5" ;;
    esac
}

# Main execution
main() {
    log "${GREEN}Starting gradual load test${NC}"
    log "Duration: ${DURATION} seconds"
    log "Target namespace: ${NAMESPACE}"
    log "Target service: ${SERVICE_NAME}"
    
    # Get service URL
    SERVICE_URL=$(get_service_url)
    log "Service URL: ${SERVICE_URL}"
    
    # Verify service is accessible
    if ! curl -s --connect-timeout 5 "$SERVICE_URL" > /dev/null; then
        log "${RED}Error: Service not accessible at $SERVICE_URL${NC}"
        exit 1
    fi
    
    log "${GREEN}Service verified - starting load test${NC}"
    echo ""
    
    # Track test progress
    START_TIME=$(date +%s)
    LAST_PHASE=""
    
    # Main load generation loop
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        
        # Check if test duration completed
        if [ $ELAPSED -ge $DURATION ]; then
            break
        fi
        
        # Calculate current phase and load
        PHASE=$(calculate_load_phase $ELAPSED $DURATION)
        RPS=$(get_rps_for_phase $PHASE)
        
        # Log phase transitions
        if [ "$PHASE" != "$LAST_PHASE" ]; then
            PROGRESS=$((ELAPSED * 100 / DURATION))
            log "${YELLOW}Phase transition: $LAST_PHASE → $PHASE (${PROGRESS}% complete)${NC}"
            log "Target RPS: $RPS"
            LAST_PHASE=$PHASE
        fi
        
        # Generate load for this second
        make_requests "$SERVICE_URL" $RPS 5
        
        # Display progress every 30 seconds
        if [ $((ELAPSED % 30)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
            PROGRESS=$((ELAPSED * 100 / DURATION))
            REMAINING=$((DURATION - ELAPSED))
            log "Progress: ${PROGRESS}% complete, ${REMAINING}s remaining, Current RPS: $RPS"
        fi
        
        # Wait for next second (accounting for execution time)
        EXEC_TIME=$(($(date +%s) - CURRENT_TIME))
        SLEEP_TIME=$((1 - EXEC_TIME))
        if [ $SLEEP_TIME -gt 0 ]; then
            sleep $SLEEP_TIME
        fi
    done
    
    # Test completion
    log "${GREEN}Gradual load test completed!${NC}"
    log "Total duration: ${DURATION} seconds"
    log "Final phase: $PHASE"
    log "Peak RPS achieved: $(get_rps_for_phase peak)"
    
    # Cool down period
    log "${YELLOW}Starting 30-second cool-down period...${NC}"
    sleep 30
    log "${GREEN}Load test fully completed${NC}"
}

# Trap to handle script interruption
cleanup() {
    log "${YELLOW}Load test interrupted - cleaning up background processes${NC}"
    jobs -p | xargs -r kill 2>/dev/null
    exit 0
}

trap cleanup INT TERM

# Validate inputs
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 60 ]; then
    log "${RED}Error: Duration must be a number >= 60 seconds${NC}"
    exit 1
fi

# Check if running in Kubernetes environment
if ! command -v kubectl &> /dev/null; then
    log "${RED}Error: kubectl not found${NC}"
    exit 1
fi

if ! command -v minikube &> /dev/null; then
    log "${RED}Error: minikube not found${NC}"
    exit 1
fi

# Execute main function
main