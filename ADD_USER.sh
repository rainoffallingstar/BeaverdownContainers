#!/bin/bash
# Comprehensive user management script for beaverstudio containers
# Replicates all aspects of fallingstar10 user configuration
# Usage: ./ADD_USER.sh [OPTIONS] <username>

set -euo pipefail

# Constants
SCRIPT_NAME="$(basename "$0")"
RSTUDIO_GROUP="rstudio-server"
DEFAULT_SHELL="/bin/bash"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CREATE_USER=false
SET_PASSWORD=""
USER_SHELL="$DEFAULT_SHELL"
GRANT_SUDO=true
CONFIGURE_SSH=true
CREATE_HOME=true
FORCE=false
USERNAME=""

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

# Usage information
show_usage() {
    cat << EOF
$SCRIPT_NAME - Comprehensive user management for beaverstudio containers

USAGE:
    $SCRIPT_NAME [OPTIONS] <username>

OPTIONS:
    -c, --create         Create new user if doesn't exist
    -p, --password PASS  Set password (default: same as username)
    -s, --shell SHELL    Set shell (default: $DEFAULT_SHELL)
    --no-sudo           Don't grant sudo access
    --no-ssh            Don't configure SSH access
    --no-home           Don't create home directory structure
    -f, --force         Overwrite existing configurations
    -h, --help          Show this help message

EXAMPLES:
    # Create new user with full configuration
    $SCRIPT_NAME -c newuser

    # Add existing user to RStudio only
    $SCRIPT_NAME existinguser

    # Create user without sudo
    $SCRIPT_NAME -c --no-sudo limiteduser

    # Create user with custom password
    $SCRIPT_NAME -c -p MySecurePass123 secureuser

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--create)
                CREATE_USER=true
                shift
                ;;
            -p|--password)
                SET_PASSWORD="$2"
                shift 2
                ;;
            -s|--shell)
                USER_SHELL="$2"
                shift 2
                ;;
            --no-sudo)
                GRANT_SUDO=false
                shift
                ;;
            --no-ssh)
                CONFIGURE_SSH=false
                shift
                ;;
            --no-home)
                CREATE_HOME=false
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$USERNAME" ]]; then
                    USERNAME="$1"
                else
                    log_error "Multiple usernames specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$USERNAME" ]]; then
        log_error "Username is required"
        show_usage
        exit 1
    fi

    # Set default password if creating new user and password not specified
    if [[ -z "$SET_PASSWORD" && "$CREATE_USER" == true ]]; then
        SET_PASSWORD="$USERNAME"
    fi
}

# Validation functions
validate_environment() {
    log_info "Validating environment..."

    # Check running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi

    # Check if we're in a beaverstudio container
    if ! getent group "$RSTUDIO_GROUP" >/dev/null 2>&1; then
        log_error "rstudio-server group does not exist"
        log_error "Make sure you are running this in a beaverstudio container"
        exit 1
    fi

    # Validate username format
    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Invalid username format: $USERNAME"
        log_error "Username must start with a letter or underscore, and contain only letters, numbers, underscores, and hyphens"
        exit 1
    fi

    # Validate shell exists
    if [[ ! -f "$USER_SHELL" ]]; then
        log_error "Shell does not exist: $USER_SHELL"
        exit 1
    fi

    log_success "Environment validation passed"
}

# User management functions
create_user() {
    log_info "Creating user: $USERNAME"

    # Check if user already exists
    if getent passwd "$USERNAME" >/dev/null 2>&1; then
        if [[ "$FORCE" == false ]]; then
            log_error "User '$USERNAME' already exists. Use --force to update configuration."
            exit 1
        else
            log_warning "User '$USERNAME' already exists. Updating configuration..."
        fi
    else
        # Create new user exactly like fallingstar10
        useradd -m -s "$USER_SHELL" "$USERNAME" || {
            log_error "Failed to create user: $USERNAME"
            exit 1
        }
        log_success "User '$USERNAME' created successfully"
    fi
}

set_user_password() {
    if [[ -n "$SET_PASSWORD" ]]; then
        log_info "Setting password for user: $USERNAME"

        # Validate password length
        if [[ ${#SET_PASSWORD} -lt 6 ]]; then
            log_warning "Password is shorter than 6 characters"
        fi

        # Set password using chpasswd like fallingstar10 setup
        echo "$USERNAME:$SET_PASSWORD" | chpasswd || {
            log_error "Failed to set password for user: $USERNAME"
            exit 1
        }
        log_success "Password set successfully"
    fi
}

configure_sudo() {
    if [[ "$GRANT_SUDO" == true ]]; then
        log_info "Configuring sudo access for user: $USERNAME"

        local sudoers_file="/etc/sudoers.d/$USERNAME"

        # Check if sudoers entry already exists
        if [[ -f "$sudoers_file" ]]; then
            if [[ "$FORCE" == false ]]; then
                log_warning "Sudoers entry already exists for $USERNAME. Use --force to overwrite."
                return
            else
                log_warning "Overwriting existing sudoers entry..."
            fi
        fi

        # Create sudoers entry exactly like fallingstar10
        echo "$USERNAME ALL=(ALL) ALL" > "$sudoers_file"

        # Set correct permissions
        chmod 440 "$sudoers_file" || {
            log_error "Failed to set permissions on sudoers file: $sudoers_file"
            exit 1
        }

        # Validate sudoers file
        if ! visudo -cf "$sudoers_file" 2>/dev/null; then
            log_error "Invalid sudoers file syntax: $sudoers_file"
            rm -f "$sudoers_file"
            exit 1
        fi

        log_success "Sudo access configured successfully"
    fi
}

add_to_rstudio_group() {
    log_info "Adding user '$USERNAME' to rstudio-server group"

    # Check if user is already in group
    if groups "$USERNAME" | grep -q "$RSTUDIO_GROUP"; then
        if [[ "$FORCE" == false ]]; then
            log_warning "User '$USERNAME' is already in $RSTUDIO_GROUP group"
            return
        else
            log_warning "User already in group, continuing..."
        fi
    fi

    # Add user to group exactly like fallingstar10
    usermod -a -G "$RSTUDIO_GROUP" "$USERNAME" || {
        log_error "Failed to add user to $RSTUDIO_GROUP group"
        exit 1
    }

    # Verify
    if groups "$USERNAME" | grep -q "$RSTUDIO_GROUP"; then
        log_success "User '$USERNAME' added to $RSTUDIO_GROUP group successfully"
    else
        log_error "Failed to verify group membership"
        exit 1
    fi
}

configure_ssh() {
    if [[ "$CONFIGURE_SSH" == true ]]; then
        log_info "Configuring SSH access for user: $USERNAME"

        local ssh_dir="/home/$USERNAME/.ssh"
        local home_dir="/home/$USERNAME"

        # Create SSH directory structure
        mkdir -p "$ssh_dir" || {
            log_error "Failed to create SSH directory: $ssh_dir"
            exit 1
        }

        # Set ownership and permissions exactly like fallingstar10 setup
        chown -R "$USERNAME:$USERNAME" "$ssh_dir" || {
            log_error "Failed to set ownership for SSH directory"
            exit 1
        }

        chmod 700 "$ssh_dir" || {
            log_error "Failed to set permissions on SSH directory"
            exit 1
        }

        # Create authorized_keys file
        local authorized_keys="$ssh_dir/authorized_keys"

        if [[ -f "$authorized_keys" && "$FORCE" == false ]]; then
            log_warning "authorized_keys already exists. Use --force to overwrite."
        else
            # Create authorized_keys with same template as fallingstar10
            cat > "$authorized_keys" << 'EOF'
# 在这里添加您的公钥
# 您可以在这个文件中添加您的 SSH 公钥
# 格式: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
EOF

            # Set permissions exactly like fallingstar10 setup
            chown "$USERNAME:$USERNAME" "$authorized_keys" || {
                log_error "Failed to set ownership for authorized_keys"
                exit 1
            }

            chmod 600 "$authorized_keys" || {
                log_error "Failed to set permissions on authorized_keys"
                exit 1
            }

            log_success "SSH configuration completed"
            log_info "Remember to add your SSH public keys to: $authorized_keys"
        fi
    fi
}

setup_home_directory() {
    if [[ "$CREATE_HOME" == true ]]; then
        log_info "Setting up home directory for user: $USERNAME"

        local home_dir="/home/$USERNAME"

        # Ensure home directory exists
        if [[ ! -d "$home_dir" ]]; then
            mkdir -p "$home_dir" || {
                log_error "Failed to create home directory: $home_dir"
                exit 1
            }
        fi

        # Set ownership
        chown -R "$USERNAME:$USERNAME" "$home_dir" || {
            log_error "Failed to set ownership for home directory"
            exit 1
        }

        # Create basic directory structure like fallingstar10 might have
        mkdir -p "$home_dir/Documents" "$home_dir/Downloads" "$home_dir/Desktop"

        # Create .bashrc with conda environment activation (from beaverworker)
        local bash_profile="$home_dir/.bashrc"
        if [[ ! -f "$bash_profile" ]]; then
            cat > "$bash_profile" << 'EOF'
# Source global bashrc
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# Auto-activate conda environments (from beaverworker)
__conda_activate() {
    local envs="py27 pyfastx clubcpg multiqc star htseq rmats bwtool scanpy"
    for env in $envs; do
        if [ -d "/opt/conda/envs/$env" ]; then
            conda activate "$env" 2>/dev/null && break
        fi
    done
}

# Custom prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Custom welcome message
echo "Welcome to beaverstudio container!"
echo "RStudio Server: http://localhost:8787"
echo "SSH Access: ssh $USER@localhost -p 2222"

# Auto-activate conda on login
__conda_activate
EOF

            chown "$USERNAME:$USERNAME" "$bash_profile"
        fi

        log_success "Home directory setup completed"
    fi
}

validate_configuration() {
    log_info "Validating user configuration..."

    local errors=0

    # Check user exists
    if ! getent passwd "$USERNAME" >/dev/null 2>&1; then
        log_error "User validation failed: User does not exist"
        ((errors++))
    else
        log_success "User account exists"
    fi

    # Check home directory
    if [[ ! -d "/home/$USERNAME" ]]; then
        log_error "Home directory validation failed: Directory does not exist"
        ((errors++))
    else
        log_success "Home directory exists"
    fi

    # Check group membership
    if groups "$USERNAME" | grep -q "$RSTUDIO_GROUP"; then
        log_success "User in rstudio-server group"
    else
        log_error "Group validation failed: User not in $RSTUDIO_GROUP group"
        ((errors++))
    fi

    # Check SSH configuration if enabled
    if [[ "$CONFIGURE_SSH" == true ]]; then
        local ssh_dir="/home/$USERNAME/.ssh"
        if [[ ! -d "$ssh_dir" ]]; then
            log_error "SSH validation failed: SSH directory does not exist"
            ((errors++))
        else
            local ssh_perms=$(stat -c "%a" "$ssh_dir" 2>/dev/null || echo "000")
            if [[ "$ssh_perms" == "700" ]]; then
                log_success "SSH directory permissions correct (700)"
            else
                log_warning "SSH directory has incorrect permissions: $ssh_perms (should be 700)"
            fi
        fi

        if [[ ! -f "$ssh_dir/authorized_keys" ]]; then
            log_error "SSH validation failed: authorized_keys does not exist"
            ((errors++))
        else
            local auth_keys_perms=$(stat -c "%a" "$ssh_dir/authorized_keys" 2>/dev/null || echo "000")
            if [[ "$auth_keys_perms" == "600" ]]; then
                log_success "SSH authorized_keys permissions correct (600)"
            else
                log_warning "authorized_keys has incorrect permissions: $auth_keys_perms (should be 600)"
            fi
        fi
    fi

    # Check sudo configuration if enabled
    if [[ "$GRANT_SUDO" == true ]]; then
        if [[ ! -f "/etc/sudoers.d/$USERNAME" ]]; then
            log_error "Sudo validation failed: Sudoers file does not exist"
            ((errors++))
        else
            if visudo -cf "/etc/sudoers.d/$USERNAME" 2>/dev/null; then
                log_success "Sudo configuration valid"
            else
                log_error "Sudo validation failed: Invalid sudoers configuration"
                ((errors++))
            fi
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All validations passed successfully"
        return 0
    else
        log_error "Configuration validation failed with $errors errors"
        return 1
    fi
}

print_summary() {
    cat << EOF

${GREEN}=== User Configuration Summary ===${NC}

Username: $USERNAME
Home Directory: /home/$USERNAME
Shell: $USER_SHELL

Configuration Status:
✓ User creation: $([ "$CREATE_USER" == true ] && echo "Completed" || echo "Skipped")
✓ Password setting: $([ -n "$SET_PASSWORD" ] && echo "Completed" || echo "Skipped")
✓ Sudo access: $([ "$GRANT_SUDO" == true ] && echo "Enabled" || echo "Disabled")
✓ RStudio access: Enabled
✓ SSH configuration: $([ "$CONFIGURE_SSH" == true ] && echo "Enabled" || echo "Disabled")
✓ Home directory: $([ "$CREATE_HOME" == true ] && echo "Setup completed" || echo "Skipped")

Access Information:
- RStudio Server: http://localhost:8787
- SSH Access: ssh $USERNAME@localhost -p 2222

Next Steps:
1. Add SSH public keys to: /home/$USERNAME/.ssh/authorized_keys
2. Test RStudio access at: http://localhost:8787
3. Test SSH access: ssh $USERNAME@localhost -p 2222

${GREEN}=== Configuration Complete ===${NC}

EOF
}

# Main execution function
main() {
    echo "=== Enhanced User Management for Beaverstudio ==="
    echo "Creating user with identical configuration to fallingstar10"
    echo ""

    log_info "Starting user configuration process..."

    parse_args "$@"
    validate_environment

    # Execute configuration steps in the same order as Dockerfile
    if [[ "$CREATE_USER" == true ]]; then
        create_user
        set_user_password
    fi

    configure_sudo
    add_to_rstudio_group

    if [[ "$CREATE_USER" == true || "$FORCE" == true ]]; then
        configure_ssh
        setup_home_directory
    fi

    validate_configuration
    print_summary

    log_success "User configuration completed successfully!"
}

# Error handling
trap 'log_error "Script failed at line $LINENO"' ERR

# Run main function with all arguments
main "$@"