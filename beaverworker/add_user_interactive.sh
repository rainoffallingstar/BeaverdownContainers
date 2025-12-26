#!/bin/bash
# Interactive user management script for beaverworker containers
# Creates users with sudo privileges and complete configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_SHELL="/bin/bash"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Print header
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   Beaverworker User Management - Interactive Setup      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        log_info "Usage: sudo $0"
        exit 1
    fi
}

# Check if user exists
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# Validate username
validate_username() {
    local username="$1"

    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi

    # Check username format (alphanumeric, underscore, hyphen)
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Invalid username format"
        log_info "Username must start with a letter or underscore"
        log_info "Followed by letters, numbers, underscores, or hyphens"
        return 1
    fi

    # Check length
    if [[ ${#username} -gt 32 ]]; then
        log_error "Username too long (max 32 characters)"
        return 1
    fi

    return 0
}

# Prompt for username
prompt_username() {
    while true; do
        echo -e "${BOLD}Enter username:${NC}"
        read -r username

        if validate_username "$username"; then
            if user_exists "$username"; then
                log_warning "User '$username' already exists"
                echo -e "${CYAN}Choose an action:${NC}"
                echo "  1) Update existing user configuration"
                echo "  2) Enter different username"
                echo "  3) Cancel"
                read -r -p "Select option [1-3]: " choice

                case $choice in
                    1)
                        log_info "Will update existing user: $username"
                        return 0
                        ;;
                    2)
                        continue
                        ;;
                    3)
                        log_info "Operation cancelled"
                        exit 0
                        ;;
                    *)
                        log_error "Invalid option"
                        continue
                        ;;
                esac
            else
                return 0
            fi
        fi
    done
}

# Prompt for password
prompt_password() {
    local username="$1"

    echo -e "${BOLD}Set password for user '$username':${NC}"
    echo "(Leave empty to use username as password)"

    while true; do
        read -s -p "Password: " password
        echo

        if [[ -z "$password" ]]; then
            password="$username"
            log_info "Using username as default password"
            return 0
        fi

        read -s -p "Confirm password: " password_confirm
        echo

        if [[ "$password" == "$password_confirm" ]]; then
            return 0
        else
            log_error "Passwords do not match"
            echo "Please try again"
        fi
    done
}

# Prompt for shell
prompt_shell() {
    echo -e "${BOLD}Select shell:${NC}"
    echo "  1) /bin/bash (default)"
    echo "  2) /bin/zsh"
    echo "  3) /bin/sh"

    read -r -p "Select option [1-3, default=1]: " shell_choice

    case $shell_choice in
        2|"zsh")
            USER_SHELL="/bin/zsh"
            ;;
        3|"sh")
            USER_SHELL="/bin/sh"
            ;;
        *)
            USER_SHELL="/bin/bash"
            ;;
    esac

    log_info "Selected shell: $USER_SHELL"
}

# Create user
create_user() {
    local username="$1"
    local password="$2"
    local shell="$3"

    if user_exists "$username"; then
        log_info "User '$username' already exists, updating configuration..."
        echo "$username:$password" | chpasswd
        chsh -s "$shell" "$username" 2>/dev/null || true
    else
        log_step "Creating user: $username"
        useradd -m -s "$shell" "$username"
        echo "$username:$password" | chpasswd
        log_success "User '$username' created successfully"
    fi
}

# Configure sudo
configure_sudo() {
    local username="$1"

    log_step "Configuring sudo access"

    local sudoers_file="/etc/sudoers.d/$username"

    cat > "$sudoers_file" << EOF
$username ALL=(ALL) ALL
EOF

    chmod 0440 "$sudoers_file"
    log_success "Sudo access configured for '$username'"
}

# Configure SSH
configure_ssh() {
    local username="$1"

    log_step "Configuring SSH access"

    local ssh_dir="/home/$username/.ssh"
    mkdir -p "$ssh_dir"
    chown -R "$username:$username" "$ssh_dir"
    chmod 700 "$ssh_dir"

    local authorized_keys="$ssh_dir/authorized_keys"

    if [[ ! -f "$authorized_keys" ]]; then
        cat > "$authorized_keys" << 'EOF'
# Add your SSH public keys here
# Format: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
EOF
    fi

    chown "$username:$username" "$authorized_keys"
    chmod 600 "$authorized_keys"

    log_success "SSH configuration completed"
    log_info "Add SSH public keys to: $authorized_keys"
}

# Configure bashrc
configure_bashrc() {
    local username="$1"

    log_step "Configuring user environment"

    local bashrc="/home/$username/.bashrc"

    # Add PATH configurations
    cat >> "$bashrc" << 'EOF'

# Beaverworker environment
export PATH=/opt/micromamba/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/go/bin:$PATH
export GOPATH=$HOME/go
source /opt/micromamba/etc/profile.d/micromamba.sh

# Note: Rust environment needs manual initialization
# Run: source ~/.cargo/env when needed
EOF

    chown "$username:$username" "$bashrc"
    log_success "User environment configured"
}

# Validate configuration
validate_configuration() {
    local username="$1"

    log_step "Validating user configuration"

    local errors=0

    # Check user exists
    if ! user_exists "$username"; then
        log_error "User '$username' does not exist"
        ((errors++))
    fi

    # Check home directory
    if [[ ! -d "/home/$username" ]]; then
        log_error "Home directory does not exist"
        ((errors++))
    fi

    # Check sudoers file
    if [[ ! -f "/etc/sudoers.d/$username" ]]; then
        log_warning "Sudoers file not found"
    fi

    # Check SSH directory
    if [[ -d "/home/$username/.ssh" ]]; then
        local ssh_perms=$(stat -c %a "/home/$username/.ssh" 2>/dev/null || echo "000")
        if [[ "$ssh_perms" != "700" ]]; then
            log_warning "SSH directory has incorrect permissions: $ssh_perms"
        fi
    else
        log_warning "SSH directory not found"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All validations passed"
        return 0
    else
        log_error "Validation failed with $errors error(s)"
        return 1
    fi
}

# Display summary
display_summary() {
    local username="$1"

    echo
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}           User Configuration Summary${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BOLD}Username:${NC}     $username"
    echo -e "${BOLD}Home:${NC}         /home/$username"
    echo -e "${BOLD}Shell:${NC}        $USER_SHELL"
    echo -e "${BOLD}Sudo:${NC}         Enabled"
    echo -e "${BOLD}SSH:${NC}          Configured"
    echo
    echo -e "${BOLD}${CYAN}Access Information:${NC}"
    echo -e "  SSH:     ${YELLOW}ssh $username@localhost -p 2222${NC}"
    echo
    echo -e "${BOLD}${CYAN}Next Steps:${NC}"
    echo -e "  1. Add SSH public keys to: ${CYAN}/home/$username/.ssh/authorized_keys${NC}"
    echo -e "  2. Test SSH access: ${CYAN}ssh $username@localhost -p 2222${NC}"
    echo -e "  3. For Rust development, run: ${CYAN}source ~/.cargo/env${NC}"
    echo
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
    echo
}

# Main execution
main() {
    print_header
    check_root

    # Prompt for username
    prompt_username

    # Prompt for password
    prompt_password "$username"

    # Prompt for shell
    prompt_shell

    echo
    log_info "Creating user with the following configuration:"
    echo "  Username: $username"
    echo "  Shell: $USER_SHELL"
    echo

    read -r -p "Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi

    echo

    # Create user
    create_user "$username" "$password" "$USER_SHELL"

    # Configure sudo
    configure_sudo "$username"

    # Configure SSH
    configure_ssh "$username"

    # Configure bashrc
    configure_bashrc "$username"

    # Validate
    validate_configuration "$username"

    # Display summary
    display_summary "$username"

    log_success "User configuration completed!"
}

# Run main function
main "$@"
