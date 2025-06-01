#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# If any command in a pipeline fails, the pipeline's return status is the value of the last command to exit with a non-zero status.
set -o pipefail
# Enable extended debugging output (prints commands as they are executed).
set -x

# --- Configuration ---
GO_VERSION="1.23.9" # Specify Go version
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_DOWNLOAD_URL="https://go.dev/dl/${GO_ARCHIVE}"
GO_INSTALL_DIR="/usr/local/go"
GOPATH_DIR="$HOME/go"
LOG_DIR="$HOME/log"
BIN_DIR="$HOME/bin"
PROJECT_REPO="https://github.com/sei1122/portfolio"
PROJECT_BRANCH="main"
PROJECT_DIR_NAME="portfolio" # Name of the directory after cloning
PROJECT_MAIN_PACKAGE="github.com/sei1122/portfolio" # Go module path

# --- Temporary file/directory ---
# Create a temporary directory for downloads
TMP_DIR=$(mktemp -d)

# --- Cleanup Function ---
# This function will be called on script exit (normal or error) to clean up.
cleanup() {
    echo "Executing cleanup..."
    if [ -d "$TMP_DIR" ]; then
        echo "Removing temporary directory: $TMP_DIR"
        rm -rf "$TMP_DIR"
    fi
    # The go archive is downloaded into TMP_DIR, so it will be removed with TMP_DIR.
    # If you had other temporary files outside TMP_DIR, add rm commands here.
    echo "Cleanup finished."
}

# Register the cleanup function to be called on EXIT signal
trap cleanup EXIT

# --- Helper Functions ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1" >&2
}

# --- Script Start ---
log_info "Starting server setup script..."

# 1. Update package list
log_info "Updating package list..."
sudo apt update

# 2. Install Golang
log_info "Installing Golang ${GO_VERSION}..."
if go version &>/dev/null && [[ $(go version) == *"${GO_VERSION}"* ]]; then
    log_info "Go version ${GO_VERSION} is already installed."
else
    log_info "Downloading Go from ${GO_DOWNLOAD_URL}..."
    wget -P "$TMP_DIR" "${GO_DOWNLOAD_URL}"
    if [ ! -f "${TMP_DIR}/${GO_ARCHIVE}" ]; then
        log_error "Failed to download Go archive."
        exit 1
    fi

    log_info "Removing existing Go installation (if any) from ${GO_INSTALL_DIR}..."
    sudo rm -rf "${GO_INSTALL_DIR}"
    
    log_info "Extracting Go archive to /usr/local..."
    sudo tar -C /usr/local -xzf "${TMP_DIR}/${GO_ARCHIVE}"
    # The archive in TMP_DIR will be removed by the trap cleanup.

    log_info "Configuring Go environment variables in ~/.bashrc..."
    # Note: These exports will apply to new shell sessions.
    # For the current script session, Go paths are set explicitly or sourced if needed.
    # If this script is run with 'sudo', ~/.bashrc refers to /root/.bashrc
    
    # Ensure paths are not added multiple times if script is re-run
    grep -qxF "export GOPATH=${GOPATH_DIR}" ~/.bashrc || echo "export GOPATH=${GOPATH_DIR}" | sudo tee -a ~/.bashrc
    grep -qxF "export PATH=\$PATH:${GO_INSTALL_DIR}/bin:\$GOPATH/bin:${BIN_DIR}" ~/.bashrc || echo "export PATH=\$PATH:${GO_INSTALL_DIR}/bin:\$GOPATH/bin:${BIN_DIR}" | sudo tee -a ~/.bashrc
    grep -qxF "export GOBIN=\$GOPATH/bin" ~/.bashrc || echo "export GOBIN=\$GOPATH/bin" | sudo tee -a ~/.bashrc

    log_info "Applying Go environment variables for the current session..."
    # Set them for the current script execution
    export GOPATH="${GOPATH_DIR}"
    export PATH="${PATH}:${GO_INSTALL_DIR}/bin:${GOPATH_DIR}/bin:${BIN_DIR}"
    export GOBIN="${GOPATH_DIR}/bin"
    # Note: 'source ~/.bashrc' in a script only affects the script's subshell, not the parent shell.
    # The above exports handle it for the current script.
fi

log_info "Creating Go workspace directories..."
mkdir -p "${GOPATH_DIR}/"{bin,src,pkg}
mkdir -p "${LOG_DIR}"
mkdir -p "${BIN_DIR}"

log_info "Verifying Go installation..."
if ! go version; then
    log_error "Go installation failed or Go is not in PATH."
    exit 1
fi
log_info "$(go version) installed successfully."

# 3. Uninstall Apache2 (if present)
log_info "Checking for and uninstalling Apache2..."
if dpkg -s apache2 &>/dev/null; then
    log_info "Apache2 found. Stopping and purging..."
    sudo systemctl stop apache2 || log_info "Apache2 already stopped or failed to stop."
    sudo systemctl disable apache2 || log_info "Failed to disable Apache2 service."
    # Purge attempts. The two lines in original script were slightly different; combining logic.
    sudo apt-get purge -y apache2 apache2-utils apache2.2-bin apache2-common apache2-bin
    sudo apt-get autoremove -y
    log_info "Apache2 purged."
else
    log_info "Apache2 not found. Skipping uninstallation."
fi

if command -v apache2 &>/dev/null; then
    log_warning "apache2 command still found after purge attempt. Manual check might be needed."
else
    log_info "apache2 command not found, successfully uninstalled."
fi


# 4. Install prerequisite tools
log_info "Installing prerequisite tools: unzip, rsync, git, psmisc..."
sudo apt install -y unzip rsync git-all psmisc

# 5. Clone and build website from Git
log_info "Cloning website from ${PROJECT_REPO} (branch: ${PROJECT_BRANCH})..."

# Kill existing 'portfolio' process if it's running
log_info "Attempting to kill any existing '${PROJECT_DIR_NAME}' processes..."
if pgrep -x "${PROJECT_DIR_NAME}" > /dev/null; then
    sudo killall "${PROJECT_DIR_NAME}"
    log_info "'${PROJECT_DIR_NAME}' processes killed."
else
    log_info "No '${PROJECT_DIR_NAME}' processes found running."
fi

# Check process list (optional, for verification)
log_info "Current processes (filtered for '${PROJECT_DIR_NAME}'):"
ps aux | grep "[p]ortfolio" || log_info "No portfolio process found in ps aux."

log_info "Removing existing project directory '${PROJECT_DIR_NAME}' (if any)..."
sudo rm -rf "${PROJECT_DIR_NAME}" # Assumes this script runs in a directory where it's safe to remove this.
                                # Consider cloning into a specific parent directory, e.g., $HOME/src or /var/www

log_info "Cloning repository..."
git clone -b "${PROJECT_BRANCH}" "${PROJECT_REPO}"
if [ ! -d "${PROJECT_DIR_NAME}" ]; then
    log_error "Failed to clone repository into '${PROJECT_DIR_NAME}'."
    exit 1
fi

cd "${PROJECT_DIR_NAME}"
log_info "Changed directory to $(pwd)"

# Initialize Go module if go.mod doesn't exist.
# If go.mod is already in the repository, this might not be needed or could error.
# Consider checking for go.mod before running init.
if [ ! -f "go.mod" ]; then
    log_info "Initializing Go module: ${PROJECT_MAIN_PACKAGE}..."
    go mod init "${PROJECT_MAIN_PACKAGE}"
else
    log_info "go.mod file already exists. Skipping 'go mod init'."
fi

log_info "Tidying Go modules..."
go mod tidy

log_info "Building Go project..."
go build
if [ ! -f "${PROJECT_DIR_NAME}" ]; then # Assuming the binary is named after the directory/project
    log_error "Go build failed or output binary '${PROJECT_DIR_NAME}' not found."
    exit 1
fi

log_info "Creating 'certs' directory..."
mkdir -p certs
log_info "Setting permissions for 'certs' directory..."
chmod 766 certs

# 7. Run the server in the background
log_info "Starting the portfolio server in the background..."
# Ensure the built executable is in the current directory (./portfolio)
# The script runs this with sudo, so PORT=80 is fine.
# PROJECT_ID is an environment variable for the application.
nohup sudo PORT=80 PROJECT_ID=831860464490 ./"${PROJECT_DIR_NAME}" &

# Check if the process started (basic check)
# A more robust check would involve querying the port or checking logs.
if pgrep -f "${PROJECT_DIR_NAME}" > /dev/null; then
    log_info "'${PROJECT_DIR_NAME}' server started successfully in the background. PID: $(pgrep -f "${PROJECT_DIR_NAME}")"
else
    log_warning "'${PROJECT_DIR_NAME}' server might not have started correctly. Check logs."
fi

# Disable extended debugging output before exiting.
set +x

log_info "Server setup script finished."
exit 0
