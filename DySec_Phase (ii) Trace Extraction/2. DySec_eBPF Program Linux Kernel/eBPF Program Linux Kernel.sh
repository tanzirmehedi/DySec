#!/bin/bash

echo "-------------------------------------------Step 0-------------------------------------------------------------"
echo "Updating package list..."
sudo apt-get update

echo "-------------------------------------------Step 1-------------------------------------------------------------"
echo "Installing Python and pip..."
sudo apt-get install -y python3 python3-pip

echo "-------------------------------------------Step 2-------------------------------------------------------------"
echo "Installing BCC and Linux kernel headers..."
sudo apt-get install -y bpfcc-tools linux-headers-$(uname -r)

echo "-------------------------------------------Step 3-------------------------------------------------------------"
echo "Installing Linux kernel tools..."
sudo apt-get install -y linux-tools-$(uname -r)

echo "-------------------------------------------Step 4-------------------------------------------------------------"
echo "Checking BPF tool version and kernel version..."
bpftool --version
uname -r

echo "-------------------------------------------Step 5-------------------------------------------------------------"
echo "Installing bpftrace..."
sudo apt-get install -y bpftrace

echo "-------------------------------------------Step 6-------------------------------------------------------------"
echo "Checking bpftrace version..."
bpftrace --version

echo "-------------------------------------------Step 7-------------------------------------------------------------"
echo "Setting up virtualenv with --break-system-packages option..."
pip3 install virtualenv --break-system-packages

echo "-------------------------------------------Step 8-------------------------------------------------------------"
echo "All prerequisites installed successfully."

#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide a package name as an argument."
    echo "Usage: trace.sh <package_name>"
    exit 1
fi

PACKAGE_NAME=$1

# Define output directories
PackageName="setuptools"
FILETOP_DIR="Filetop Traces"
OPENSNOOP_DIR="Opensnoop Traces"
TCPTRACES_DIR="TCP Traces"
INSTALL_STATUS_DIR="Installation_status"
ENV_DIR="Environments"

VENV_PATH="${ENV_DIR}/${PACKAGE_NAME}_env"

# Function to delete a file or directory if it exists
delete_if_exists() {
    if [ -e "$1" ]; then
        if [ -d "$1" ]; then
            echo "Directory $1 exists. Removing it to create a fresh one."
            rm -rf "$1"
        elif [ -f "$1" ]; then
            echo "File $1 exists. Removing it to create a fresh one."
            rm -f "$1"
        fi
    fi
}

# Function to clear all files and directories related to the package
clear_package_files() {
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "---------------------------------------------------Start-----------------------------------------------------"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Clearing all files and directories for a fresh installation attempt..."
    delete_if_exists "$FILETOP_DIR/${PACKAGE_NAME}_filetop_trace.txt"
    delete_if_exists "$OPENSNOOP_DIR/${PACKAGE_NAME}_opensnoop_trace.txt"
    delete_if_exists "$TCPTRACES_DIR/${PACKAGE_NAME}_tcptraces.txt"
    delete_if_exists "${INSTALL_STATUS_DIR}/${PACKAGE_NAME}_install_log.txt"
    delete_if_exists "$VENV_PATH"
}

# Ensure any previous files or directories are deleted before starting the first attempt
clear_package_files

# Create necessary directories
mkdir -p "$FILETOP_DIR" "$OPENSNOOP_DIR" "$TCPTRACES_DIR" "$INSTALL_STATUS_DIR" "$ENV_DIR"

echo "___________________________________________________Step 0___________________________________________________"
# Check if virtual environment already exists
if [ -d "$VENV_PATH" ]; then
    echo "Virtual environment for $PACKAGE_NAME already exists at $VENV_PATH. Skipping creation."
else
    echo "Creating virtual environment for $PACKAGE_NAME in $VENV_PATH..."
    virtualenv "$VENV_PATH"
fi

echo "___________________________________________________Step 1___________________________________________________"
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"
pip install $PackageName --break-system-packages

echo "___________________________________________________Step 2___________________________________________________"
echo "Running monitoring commands with output files organized under the package name..."
sudo ./monitor.sh "$PACKAGE_NAME" &

echo "___________________________________________________Step 3___________________________________________________"
echo "Running BPF monitoring commands and saving output..."
sudo filetop-bpfcc 5 > "${FILETOP_DIR}/${PACKAGE_NAME}_filetop_trace.txt" &
sudo opensnoop-bpfcc -d 10 > "${OPENSNOOP_DIR}/${PACKAGE_NAME}_opensnoop_trace.txt" &
sudo tcpstates-bpfcc > "${TCPTRACES_DIR}/${PACKAGE_NAME}_tcptraces.txt" &

sleep 5

echo "___________________________________________________Step 4___________________________________________________"
echo "Installing $PACKAGE_NAME in the virtual environment and displaying installation status..."

# Define the installation log file path
install_log="${INSTALL_STATUS_DIR}/${PACKAGE_NAME}_install_log.txt"

# First attempt with pip
if ! "${VENV_PATH}/bin/pip" install "$PACKAGE_NAME" --break-system-packages --no-build-isolation --no-cache-dir 2>&1 | tee "$install_log"; then
    echo "First attempt failed. Clearing all files and retrying..."
    clear_package_files  # Clear before the next attempt

    # Skip virtual environment creation if it already exists
    if [ ! -d "$VENV_PATH" ]; then
        virtualenv "$VENV_PATH"
    fi
    source "$VENV_PATH/bin/activate"

    # Second attempt with pip3
    if ! "${VENV_PATH}/bin/pip3" install "$PACKAGE_NAME" 2>&1 | tee "$install_log"; then
        echo "Second attempt failed. Clearing all files and retrying..."
        clear_package_files  # Clear before the final attempt

        # Skip virtual environment creation if it already exists
        if [ ! -d "$VENV_PATH" ]; then
            virtualenv "$VENV_PATH"
        fi
        source "$VENV_PATH/bin/activate"

        # Third attempt with --break-system-packages
        if ! "${VENV_PATH}/bin/pip" install "$PACKAGE_NAME" --break-system-packages 2>&1 | tee "$install_log"; then
            echo "All installation attempts failed for $PACKAGE_NAME."
            deactivate
            exit 1  # Exit with a non-zero status to indicate failure
        fi
    fi
fi

echo "___________________________________________________Step 5___________________________________________________"
echo "Deactivating virtual environment..."
deactivate

echo "___________________________________________________Step 6___________________________________________________"
echo "Please check for errors. If unsuccessful, install dependencies and try again."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "-----------------------------------------------------End-----------------------------------------------------"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide a package name as an argument."
    echo "Usage: monitor.sh <package_name>"
    exit 1
fi

PACKAGE_NAME=$1

delete_if_exists() {
    if [ -e "$1" ]; then
        if [ -d "$1" ]; then
            echo "Directory $1 exists. Removing it to create a fresh one."
            rm -rf "$1"
        elif [ -f "$1" ]; then
            echo "File $1 exists. Removing it to create a fresh one."
            rm -f "$1"
        fi
    fi
}

echo "___________________________________________________In Step 0___________________________________________________"
echo "Setting up directories for output and PID tracking..."

output_dir="Trace_Outputs/${PACKAGE_NAME}"
delete_if_exists "$output_dir" 
mkdir -p "$output_dir"
echo "Created output directory: $output_dir"

pids_dir="PIDs"
mkdir -p "$pids_dir"
echo "Created separate PID tracking directory: $pids_dir"

traced_pids_file="${pids_dir}/traced_pids_${PACKAGE_NAME}.txt"
delete_if_exists "$traced_pids_file" 
touch "$traced_pids_file"
echo "Created PID tracking file: $traced_pids_file"

echo "___________________________________________________In Step 1___________________________________________________"
echo "Starting to monitor and trace processes for package $PACKAGE_NAME..."

trace_process() {
    local pid=$1
    echo "Tracing process $pid and its children for package $PACKAGE_NAME ..."
    sudo strace -f -ff -o "${output_dir}/strace_output_${pid}" -s 4096 -t -v -p "$pid"
    echo $pid >> "$traced_pids_file"
}

is_traced() {
    local pid=$1
    grep -q "^$pid$" "$traced_pids_file"
    return $?
}

echo "___________________________________________________In Step 2___________________________________________________"
echo "Entering continuous monitoring loop..."

while true; do
    for proc in python python3 pip pip3; do
        for pid in $(pgrep -x $proc); do
            if ! is_traced $pid; then
                trace_process $pid
                echo "Started tracing for process $proc with PID $pid."
            fi
        done
    done
    sleep 1 
done

trap 'rm -f "$traced_pids_file"; echo "Cleaned up PID tracking file and exiting."; exit 0' INT TERM
