#!/bin/bash

# Define variables
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="sosreport_summary_$DATE.txt"
FORCE=false
INCLUDE_LOGS=false  # Logs should be included only with --logs

# Enable all sections by default unless specific flags are provided
HOSTINFO=true
IPINFO=true
STORAGEINFO=true
MEMORYINFO=true
CPUINFO=true
DISKUSAGE=true
NETWORKINFO=true

# Flag to track if specific flags were set
SPECIFIC_FLAG_SET=false

# Skip specific sections based on the --skip option
skip_sections() {
    IFS=',' read -r -a SKIP_ARRAY <<< "$1"
    for section in "${SKIP_ARRAY[@]}"; do
        case $section in
            hostinfo) HOSTINFO=false ;;
            ipinfo) IPINFO=false ;;
            storageinfo) STORAGEINFO=false ;;
            memoryinfo) MEMORYINFO=false ;;
            cpuinfo) CPUINFO=false ;;
            diskusage) DISKUSAGE=false ;;
            networkinfo) NETWORKINFO=false ;;
            logs) INCLUDE_LOGS=false ;;
            *) echo "Unknown section in skip: $section"; usage ;;
        esac
    done
}

# Function to display usage
usage() {
    echo "Usage: $0 [options] [archive_files...]"
    echo "Options:"
    echo "  --hostinfo      Include hostname, uptime, and hostnamectl status information"
    echo "  --ipinfo        Include only IP address information"
    echo "  --storageinfo   Include only storage information with I/O stats, ring pages, and commands per disk"
    echo "  --memoryinfo    Include memory utilization"
    echo "  --cpuinfo       Include CPU utilization"
    echo "  --diskusage     Include disk space usage information with df -al/-ali -x autofs"
    echo "  --networkinfo   Include network statistics, link state, dropped rx/tx, and ring buffer"
    echo "  --logs          Include logs, historical data, and security information"
    echo "  --skip <sections> Skip specific sections (comma-separated, e.g., hostinfo,ipinfo)"
    echo "  --force         Force re-extraction of sosreport if folders already exist"
    echo "  [archive_files...]  Optional sosreport archive files to process (multiple files allowed)"
    exit 1
}

# Parse the command-line arguments
ARCHIVE_FILES=()
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --hostinfo) HOSTINFO=true; IPINFO=false; STORAGEINFO=false; MEMORYINFO=false; CPUINFO=false; DISKUSAGE=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --ipinfo) IPINFO=true; HOSTINFO=false; STORAGEINFO=false; MEMORYINFO=false; CPUINFO=false; DISKUSAGE=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --storageinfo) STORAGEINFO=true; HOSTINFO=false; IPINFO=false; MEMORYINFO=false; CPUINFO=false; DISKUSAGE=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --memoryinfo) MEMORYINFO=true; HOSTINFO=false; IPINFO=false; STORAGEINFO=false; CPUINFO=false; DISKUSAGE=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --cpuinfo) CPUINFO=true; HOSTINFO=false; IPINFO=false; STORAGEINFO=false; MEMORYINFO=false; DISKUSAGE=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --diskusage) DISKUSAGE=true; HOSTINFO=false; IPINFO=false; STORAGEINFO=false; MEMORYINFO=false; CPUINFO=false; NETWORKINFO=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --networkinfo) NETWORKINFO=true; HOSTINFO=false; IPINFO=false; STORAGEINFO=false; MEMORYINFO=false; CPUINFO=false; DISKUSAGE=false; INCLUDE_LOGS=false; SPECIFIC_FLAG_SET=true ;;
        --logs) INCLUDE_LOGS=true; SPECIFIC_FLAG_SET=true ;;
        --skip) shift; skip_sections "$1" ;;
        --force) FORCE=true ;;
        *.tar.*) ARCHIVE_FILES+=("$1") ;;  # Handle multiple sosreport archive files
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# If specific flags are set, disable all sections that were not specified
if [ "$SPECIFIC_FLAG_SET" = true ]; then
    if [ "$HOSTINFO" = false ] && [ "$IPINFO" = false ] && [ "$STORAGEINFO" = false ] && \
       [ "$MEMORYINFO" = false ] && [ "$CPUINFO" = false ] && [ "$DISKUSAGE" = false ] && \
       [ "$NETWORKINFO" = false ]; then
        INCLUDE_LOGS=false  # If no section is selected, logs are not included either
    fi
fi

# Function to analyze a single sosreport
analyze_sosreport() {
    local SOSREPORT_ARCHIVE=$1
    local SOSREPORT_DIR="./extracted_sosreport_$2"

    # Check if the sosreport has already been extracted
    if [ -d "$SOSREPORT_DIR" ] && [ "$FORCE" = false ]; then
        echo "Sosreport already extracted. Skipping extraction. Use --force to re-extract."
    else
        # Create a directory for extracting the sosreport
        mkdir -p $SOSREPORT_DIR

        # Extract the sosreport
        tar -xf $SOSREPORT_ARCHIVE -C $SOSREPORT_DIR --strip-components=1
        if [ $? -ne 0 ]; then
            echo "Failed to extract the sosreport: $SOSREPORT_ARCHIVE"
            return
        fi
    fi

    # Append the sosreport header to the combined report file
    echo "========================================" >> $OUTPUT_FILE
    echo "SOSReport Summary for $SOSREPORT_ARCHIVE" >> $OUTPUT_FILE
    echo "Generated on: $(date)" >> $OUTPUT_FILE
    echo "========================================" >> $OUTPUT_FILE

    # 1. Extract hostname, uptime, and hostnamectl_status from sos_commands/host if --hostinfo is enabled
    if [ "$HOSTINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "Host Information:" >> $OUTPUT_FILE

        # Extract hostname
        if [ -f "$SOSREPORT_DIR/sos_commands/host/hostname" ]; then
            echo "Hostname:" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/host/hostname >> $OUTPUT_FILE
        else
            echo "Hostname not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Extract uptime
        if [ -f "$SOSREPORT_DIR/sos_commands/host/uptime" ]; then
            echo "Uptime:" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/host/uptime >> $OUTPUT_FILE
        else
            echo "Uptime information not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Extract hostnamectl_status
        if [ -f "$SOSREPORT_DIR/sos_commands/host/hostnamectl_status" ]; then
            echo "Hostnamectl Status:" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/host/hostnamectl_status >> $OUTPUT_FILE
        else
            echo "Hostnamectl status not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 2. Extract only IP address information if --ipinfo is enabled
    if [ "$IPINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "IP Address Information:" >> $OUTPUT_FILE

        # Extract IP address information
        if [ -f "$SOSREPORT_DIR/sos_commands/networking/ip_-d_address" ]; then
            echo "IP address details from 'ip addr':" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/networking/ip_-d_address >> $OUTPUT_FILE
        elif [ -f "$SOSREPORT_DIR/sos_commands/networking/ifconfig" ]; then
            echo "IP address details from 'ifconfig':" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/networking/ifconfig >> $OUTPUT_FILE
        else
            echo "IP address information not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 3. Extract IP address, routing table, network stats, ring buffer/dropped rx/tx if --networkinfo is enabled
    if [ "$NETWORKINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "Network Information (IP address, routing table, dropped rx/tx, ring buffer):" >> $OUTPUT_FILE

        # Interface statistics
        echo "Interface Statistics:" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/proc/net/dev >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Interface link speed and duplex
        echo "Interface Link and Speed Information:" >> $OUTPUT_FILE
        grep -E "Speed|Duplex" $SOSREPORT_DIR/sos_commands/networking/ethtool_* >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Extract IP address information
        if [ -f "$SOSREPORT_DIR/sos_commands/networking/ip_-d_address" ]; then
            echo "IP address details from 'ip addr':" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/networking/ip_-d_address >> $OUTPUT_FILE
        elif [ -f "$SOSREPORT_DIR/sos_commands/networking/ifconfig" ]; then
            echo "IP address details from 'ifconfig':" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/networking/ifconfig >> $OUTPUT_FILE
        else
            echo "IP address information not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Extract routing table information
        if [ -f "$SOSREPORT_DIR/sos_commands/networking/ip_route_show_table_all" ]; then
            echo "Routing table information:" >> $OUTPUT_FILE
            cat $SOSREPORT_DIR/sos_commands/networking/ip_route_show_table_all >> $OUTPUT_FILE
        else
            echo "Routing table not found." >> $OUTPUT_FILE
        fi
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Ring buffer information
        echo "Current Ring Buffer Config:" >> $OUTPUT_FILE
        egrep -A4 "Current hardware settings" $SOSREPORT_DIR/sos_commands/networking/ethtool_-g* >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Is Ring full?
        echo "Is Ring Full?" >> $OUTPUT_FILE
        grep "ring full" $SOSREPORT_DIR/sos_commands/networking/* | grep -v "ring full: 0" >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Dropped rx
        echo "Dropped RX:" >> $OUTPUT_FILE
        grep -i "dropped rx total" $SOSREPORT_DIR/sos_commands/networking/* | grep -v "drv dropped rx total: 0" >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 4. Extract memory information if --memoryinfo is enabled
    if [ "$MEMORYINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "Memory Information:" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/proc/meminfo >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        echo "Swap Usage:" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/proc/swaps >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 5. Extract CPU information if --cpuinfo is enabled
    if [ "$CPUINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "CPU Information (Load Average and per CPU):" >> $OUTPUT_FILE

        # System Load Averages
        echo "System Load Averages:" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/proc/loadavg >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # CPU usage per CPU
        echo "CPU Usage (per CPU):" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/proc/stat | grep '^cpu' >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 6. Extract I/O statistics and disk-related info if --storageinfo is enabled
    if [ "$STORAGEINFO" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "Storage Information (from /etc/fstab):" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/etc/fstab >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Disk I/O statistics
        echo "Disk I/O Statistics:" >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/sos_commands/block/iostat_-x >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Ring pages and commands per disk
        echo "Commands per LUN and Ring Pages Config:" >> $OUTPUT_FILE
        egrep "vmw_pvscsi.cmd_per_lun|vmw_pvscsi.ring_pages" $SOSREPORT_DIR/etc/grub2.cfg >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/sys/module/vmw_pvscsi/parameters/cmd_per_lun >> $OUTPUT_FILE
        cat $SOSREPORT_DIR/sys/module/vmw_pvscsi/parameters/ring_pages >> $OUTPUT_FILE
        egrep "vmw_pvscsi.cmd_per_lun|vmw_pvscsi.ring_pages" $SOSREPORT_DIR/etc/default/grub >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi

    # 7. Include logs and historical information if --logs is enabled
    if [ "$INCLUDE_LOGS" = true ]; then
        echo "----------------------------------------" >> $OUTPUT_FILE
        echo "Logs and Historical Data:" >> $OUTPUT_FILE

        # dmesg log
        echo "dmesg Log (last 100 lines):" >> $OUTPUT_FILE
        tail -n 100 $SOSREPORT_DIR/var/log/dmesg >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # System messages log
        echo "System Messages Log (last 100 lines):" >> $OUTPUT_FILE
        tail -n 100 $SOSREPORT_DIR/var/log/messages >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # SSH logs
        echo "SSH Logs:" >> $OUTPUT_FILE
        grep "sshd" $SOSREPORT_DIR/var/log/secure >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE

        # Specific error patterns
        grep "backlog limit exceeded" $SOSREPORT_DIR/var/log/messages >> $OUTPUT_FILE
        grep "world-inaccessible" $SOSREPORT_DIR/var/log/messages >> $OUTPUT_FILE
        grep "Did not receive identification string from" $SOSREPORT_DIR/var/log/secure >> $OUTPUT_FILE
        grep "File too large" $SOSREPORT_DIR/var/log/maillog >> $OUTPUT_FILE
        echo "----------------------------------------" >> $OUTPUT_FILE
    fi
}

# Main logic to handle multiple sosreport archives or a single specified archive
if [ "${#ARCHIVE_FILES[@]}" -gt 0 ]; then
    # Process specified sosreport archive files
    for ARCHIVE_FILE in "${ARCHIVE_FILES[@]}"; do
        if [ -f "$ARCHIVE_FILE" ]; then
            REPORT_NAME=$(basename "$ARCHIVE_FILE" | sed 's/.tar.*//')
            echo "Processing $ARCHIVE_FILE..."
            analyze_sosreport "$ARCHIVE_FILE" "$REPORT_NAME"
        else
            echo "Specified sosreport archive not found: $ARCHIVE_FILE"
        fi
    done
else
    # Process all sosreport archives in the current directory
    for SOSREPORT_ARCHIVE in sosreport-*.tar.*; do
        if [ -f "$SOSREPORT_ARCHIVE" ]; then
            REPORT_NAME=$(basename "$SOSREPORT_ARCHIVE" | sed 's/.tar.*//')
            echo "Processing $SOSREPORT_ARCHIVE..."
            analyze_sosreport "$SOSREPORT_ARCHIVE" "$REPORT_NAME"
        else
            echo "No sosreport files found in the current directory."
        fi
    done
fi

# Automatically open the generated report using less
echo "Report generated and saved to $OUTPUT_FILE"
less $OUTPUT_FILE

