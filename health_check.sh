#!/bin/bash
# Bash script to rotate MongoDB log files
# Author: Anban Malarvendan
# License: GNU GENERAL PUBLIC LICENSE Version 3 + 
#          Sectoion 7: Redistribution/Reuse of this code is permitted under the 
#          GNU v3 license, as an additional term ALL code must carry the 
#          original Author(s) credit in comment form.

# Define an array of servers, usernames, and port numbers
declare -a servers=("10.12.1.1" "10.12.1.2" "10.12.1.3")
declare -a usernames=("monitor_user" "monitor_user" "monitor_user")
declare -a portnos=("11" "3016" "2019")

# Function to perform a health check on a server
perform_health_check() {
    local server_ip="$1"
    local username="$2"
    local port="$3"
    local output_file="/scripts/HealthCheck/health_check_${server_ip}.txt"

    echo -e "\n\nHealth check for server $server_ip" >> "$output_file"
    echo " - - - - - - - - - - - - - - - - - - - - " >> "$output_file"

    ssh "$username@$server_ip" -p "$port" df -h >> "$output_file"
    echo " - - - - - - - - - - - - - - - - - - - - " >> "$output_file"

    if [[ "$server_ip" == "192.168.1.2" ]]; then
        ssh -t "$username@$server_ip" -p "$port" sudo systemctl status mysql-server.service >> "$output_file"
    else
        ssh "$username@$server_ip" -p "$port" sudo service mysqld status >> "$output_file"
    fi

    echo " - - - - - - - - - - - - - - - - - - - - " >> "$output_file"
    ssh "$username@$server_ip" -p "$port" top -b -n 1 | grep "Cpu(s)" >> "$output_file"
    echo " - - - - - - - - - - - - - - - - - - - - " >> "$output_file"
}

# Loop through each server and collect the health check information
for ((i = 0; i < ${#servers[@]}; i++)); do
    server_ip="${servers[i]}"
    username="${usernames[i]}"
    port="${portnos[i]}"
    perform_health_check "$server_ip" "$username" "$port"
done

# Mail the report
DT=$(date +%Y-%m-%d)
output_file="/scripts/HealthCheck/health_check_$DT.txt"

echo 'Server health check details attached' | "/bin/mailx 'Server health report' -r 'user1@domain.com' -a '$output_file' user1@domain.com, user2@domain.com, user3@domain.com"
