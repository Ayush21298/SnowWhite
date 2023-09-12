#!/bin/bash

function delete_qdiscs_filters() {
    # Delete previous tc filters
    echo "Deleting previous tc filters..."

    # Deleting the ingress qdisc on the iface interface
    echo "tc qdisc del dev $iface handle ffff: ingress"
    tc qdisc del dev $iface handle ffff: ingress
    
    # Deleting the ingress qdisc on the lo interface
    echo "tc qdisc del dev lo parent ffff: "
    tc qdisc del dev lo parent ffff:

    # Deleting the prio qdisc on the iface interface
    echo "tc qdisc del dev $iface handle 1: root"
    tc qdisc del dev $iface handle 1: root
    
    echo "Completed deleting previous tc qdiscs and filters"
}

function my_function() {
    # Received filters
    echo "Running my_function with the following parameters:"
    echo "src_ip: $src_ip"
    echo "dst_ip: $dst_ip"
    echo "src_port: $src_port"
    echo "dst_port: $dst_port"
    echo "proto: $proto"
    echo "iface: $iface"
    echo "dst_iface: $dst_iface"

    ip_address=$(ip -o -4 addr show "$iface" | awk '{print $4}' | cut -d '/' -f 1)
    ip_address+="/24"

    echo "ip_address is $ip_address"

    # Check if iface is available
    if [[ -z $iface ]]; then
        echo "Please provide interface to capture packets on"
        return
    fi

    # Check if dst_iface is available
    if [[ -z $dst_iface ]]; then
        echo "Please provide interface to mirror the packets to"
        return
    fi
    
    echo "Cleaning up the slate. "
    delete_qdiscs_filters

    # Check for empty variables
    if [[ -z $src_ip ]] && [[ -z $dst_ip ]] && [[ -z $src_port ]] && [[ -z $dst_port ]] && [[ -z $proto ]]; then
        
        echo "No filtering variables provided. Mirroring all packets from $iface to $dst_iface."

        # creating ingress qdisc on the iface interface
        echo "tc qdisc add dev $iface handle ffff: ingress"
        tc qdisc add dev $iface handle ffff: ingress

        # adding filter to match all the traffic received on the iface interface to the dst_iface
        echo "tc filter add dev $iface parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface"
        tc filter add dev $iface parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface

        # creating egress prio type qdisc on the iface interface
        echo "tc qdisc add dev $iface handle 1: root prio"
        tc qdisc add dev $iface handle 1: root prio

        # creating an ingress qdisc on the lo interface to get the egress traffic
        echo "tc qdisc add dev lo handle ffff: ingress"
        tc qdisc add dev lo handle ffff: ingress

        # adding filter to mirror all the traffic from the egress iface to the ingress of lo interface
        echo "tc filter add dev $iface parent 1: protocol all u32 match u32 0 0 action mirred egress mirror dev lo"
        tc filter add dev $iface parent 1: protocol all u32 match u32 0 0 action mirred egress mirror dev lo

        #adding filter to mirror all the traffic from the ingress lo interface to the dst_iface
        echo "tc filter add dev lo parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface"
        tc filter add dev lo parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface

        # adding filter to exclude loopback traffic
        echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip src 127.0.0.1 action pass"
        tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip src 127.0.0.1 action pass
        echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst 127.0.0.1 action pass"
        tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst 127.0.0.1 action pass
        echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip protocol 47 0xff action pass"
        tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip protocol 47 0xff action pass
        echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst $ip_address action pass"
        tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst $ip_address action pass

        return
    fi

    # Create a tc filter rule based on non-empty variables
    tc_filter=""

    if [[ -n $src_ip ]]; then
        tc_filter+="match ip src $src_ip "
    fi

    if [[ -n $dst_ip ]]; then
        tc_filter+="match ip dst $dst_ip "
    fi

    if [[ -n $src_port ]]; then
        tc_filter+="match ip sport $src_port 0xffff "
    fi

    if [[ -n $dst_port ]]; then
        tc_filter+="match ip dport $dst_port 0xffff "
    fi

    if [[ -n $proto ]]; then
        tc_filter+="match ip protocol $proto 0xff"
    fi

    
    echo "Applying packet filtering using tc:"

    # creating ingress qdisc on the iface interface
    echo "tc qdisc add dev $iface handle ffff: ingress"
    tc qdisc add dev $iface handle ffff: ingress

    # adding filter to match all the traffic received on the iface interface to the dst_iface
    echo "tc filter add dev $iface parent ffff: protocol ip u32 $tc_filter action mirred egress mirror dev $dst_iface"
    tc filter add dev $iface parent ffff: protocol ip u32 $tc_filter action mirred egress mirror dev $dst_iface

    # creating egress prio type qdisc on the iface interface
    echo "tc qdisc add dev $iface handle 1: root prio"
    tc qdisc add dev $iface handle 1: root prio

    # creating an ingress qdisc on the lo interface to get the egress traffic
    echo "tc qdisc add dev lo handle ffff: ingress"
    tc qdisc add dev lo handle ffff: ingress

    # adding filter to mirror all the traffic from the egress iface to the ingress of lo interface
    echo "tc filter add dev $iface parent 1: protocol ip u32 $tc_filter action mirred egress mirror dev lo"
    tc filter add dev $iface parent 1: protocol ip u32 $tc_filter action mirred egress mirror dev lo

    #adding filter to mirror all the traffic from the ingress lo interface to the dst_iface
    echo "tc filter add dev lo parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface"
    tc filter add dev lo parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev $dst_iface

    # adding filter to exclude loopback traffic
    echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip src 127.0.0.1/8 action pass"
    tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip src 127.0.0.1/8 action pass
    echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst 127.0.0.1/8 action pass"
    tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst 127.0.0.1/8 action pass
    echo "tc filter add dev $iface parent 1: protocol ip prio 1 u32 match ip protocol 47 0xff action pass"
    tc filter add dev $iface parent 1: protocol ip prio 1 u32 match ip protocol 47 0xff action pass
    echo "tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst $ip_address action pass"
    tc filter add dev lo parent ffff: protocol ip prio 1 u32 match ip dst $ip_address action pass
}

# Read variables from the text file
read_variables() {
    source_file="variables.txt"
    while IFS= read -r line; do
        eval "$line"
    done < "$source_file"
}

# Run the function initially
read_variables
my_function

# Continuously check for changes in the text file
while true; do
    # Capture the current checksum of the text file
    current_checksum=$(md5sum "$source_file")

    # Wait for changes in the text file
    inotifywait -e modify "$source_file"

    # Capture the new checksum after modification
    new_checksum=$(md5sum "$source_file")

    # Compare the checksums to detect changes
    if [[ "$current_checksum" != "$new_checksum" ]]; then
        echo "Detected changes in the variables. Rerunning the function..."
        read_variables
        my_function
    fi
done

