#!/bin/bash

set -e

GITHUB_REPO="webwizards-team/Phantom-Tunnel"
ASSET_NAME="phantom"

EXECUTABLE_NAME="phantom"
INSTALL_PATH="/usr/local/bin"
SERVICE_NAME="phantom.service"
WORKING_DIR="/etc/phantom"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/3.0.0/${ASSET_NAME}"


print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; exit 1; }

print_info "Starting Phantom Tunnel Installation..."

if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root. Please use 'sudo'."
fi

print_info "Checking for curl..."
if ! command -v curl &> /dev/null; then
    print_info "curl is not installed. Attempting to install..."
    if command -v apt-get &> /dev/null; then
        apt-get update -y -qq && apt-get install -y curl -qq
    elif command -v yum &> /dev/null; then
        yum install -y curl -q
    else
        print_error "Unsupported package manager. Please install 'curl' manually."
    fi
else
    print_success "curl is already installed."
fi

print_info "Download and Install the latest version of $EXECUTABLE_NAME from: ${DOWNLOAD_URL}"
if ! curl -sSkLf -o "$INSTALL_PATH/$EXECUTABLE_NAME" "$DOWNLOAD_URL"; then
    print_error "Download failed. Please check the repository name and asset name in the script, and ensure the asset exists in the latest GitHub release."
    rm -f "$INSTALL_PATH/$EXECUTABLE_NAME" || true
    exit 1
fi

chmod +x "$INSTALL_PATH/$EXECUTABLE_NAME"
mkdir -p "$WORKING_DIR"
print_success "Phantom application binary installed."

print_info "Configuring systemd service for reliable automatic startup..."
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Phantom Tunnel Panel Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 10
ExecStart=${INSTALL_PATH}/${EXECUTABLE_NAME} --start-panel
WorkingDirectory=${WORKING_DIR}
Restart=always
RestartSec=5
LimitNOFILE=65536
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

print_info "Reloading systemd and enabling the service..."
systemctl daemon-reload && systemctl enable "$SERVICE_NAME"
print_info "Starting the service now..."
systemctl restart "$SERVICE_NAME"

echo ""
print_success "Installation complete!"
echo "--------------------------------------------------"
print_info "Phantom Panel is now installed and configured to start automatically on boot."
echo ""
print_info "Useful commands to manage the service:"
echo "  sudo systemctl start ${SERVICE_NAME}    (to start)"
echo "  sudo systemctl stop ${SERVICE_NAME}     (to stop)"
echo "  sudo systemctl restart ${SERVICE_NAME}  (to restart)"
echo "  sudo systemctl status ${SERVICE_NAME}   (to check status)"
echo ""
print_info "Configuration files are in: ${WORKING_DIR}"
echo "--------------------------------------------------"

sleep 2
if systemctl is-active --quiet "$SERVICE_NAME"; then
    print_success "Phantom Panel service is now running!"
fi

exit 0
