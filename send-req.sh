#!/bin/bash

send_requests() {
    local request_count=0
    while true; do
        # Envoyez plusieurs requêtes rapidement pour augmenter le taux
        for ((i=1; i<=20; i++)); do
            curl -s --connect-timeout 5 http://3.92.126.230:31860/en-us/auth/signin > /dev/null
            ((request_count++))
            echo "Request $request_count sent at $(date)"
        done
        
        # Pause plus courte entre les rafales
        sleep 0.1
    done
}

# Trap SIGINT (Ctrl+C) to exit gracefully
trap 'echo "Exiting..."; exit 0' INT

# Start sending requests
send_requests
