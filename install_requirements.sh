#!/usr/bin/env bash

# install_requirements.sh - Install required tools for stegtool.sh
# Author: Your Name
# License: Apache 2.0
# Version: 1.0.0

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message"
    echo "  -a, --advanced         Install advanced analysis tools"
    echo "  -b, --basic            Install basic tools only (default)"
    echo ""
    echo "Example:"
    echo "  $0 --advanced          # Install all tools including advanced ones"
    echo "  $0 --basic            # Install basic tools only"
    echo "  $0                    # Same as --basic"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Function to install packages using apt
install_apt() {
    local mode=$1
    print_colored "$GREEN" "Installing packages using apt..."
    
    # Update package lists
    sudo apt-get update

    # Install basic tools
    print_colored "$BLUE" "Installing basic analysis tools..."
    sudo apt-get install -y \
        libimage-exiftool-perl \
        binwalk \
        foremost \
        steghide \
        ruby \
        ruby-dev \
        outguess \
        imagemagick \
        pngcheck \
        jpeginfo \
        ent \
        tesseract-ocr \
        tesseract-ocr-eng \
        ffmpeg \
        xxd

    # Install zsteg using gem
    sudo gem install zsteg

    # Install advanced tools if requested
    if [ "$mode" = "advanced" ]; then
        print_colored "$BLUE" "Installing advanced analysis tools..."
        sudo apt-get install -y \
            stegoveritas \
            stegseek \
            volatility \
            scalpel \
            bulk-extractor \
            testdisk \
            mat2 \
            exiv2 \
            mediainfo \
            sox \
            python3-pip \
            hachoir-metadata

        # Install Python-based tools
        pip3 install stegoveritas-binwalk stegano
        
        # Install additional tools from other sources if available
        if command -v "cargo" &> /dev/null; then
            cargo install ripgrep
        fi

        print_colored "$GREEN" "✓ Advanced tools installation complete"
    fi
}

# Function to install packages using dnf
install_dnf() {
    local mode=$1
    print_colored "$GREEN" "Installing packages using dnf..."
    
    # Update system
    sudo dnf update -y

    # Install basic tools
    print_colored "$BLUE" "Installing basic analysis tools..."
    sudo dnf install -y \
        perl-Image-ExifTool \
        binwalk \
        foremost \
        steghide \
        ruby \
        ruby-devel \
        outguess \
        ImageMagick \
        pngcheck \
        jpeginfo \
        ent \
        tesseract \
        tesseract-langpack-eng \
        ffmpeg \
        vim-common

    # Install zsteg using gem
    sudo gem install zsteg

    # Install advanced tools if requested
    if [ "$mode" = "advanced" ]; then
        print_colored "$BLUE" "Installing advanced analysis tools..."
        sudo dnf install -y \
            stegoveritas \
            volatility \
            scalpel \
            bulk-extractor \
            testdisk \
            mat2 \
            exiv2 \
            mediainfo \
            sox \
            python3-pip \
            hachoir-metadata

        # Enable EPEL repository for additional tools
        sudo dnf install -y epel-release
        sudo dnf config-manager --set-enabled PowerTools

        # Install Python-based tools
        pip3 install stegoveritas-binwalk stegano

        # Install additional forensics tools
        sudo dnf install -y sleuthkit autopsy

        print_colored "$GREEN" "✓ Advanced tools installation complete"
    fi
}

# Function to install packages using pacman
install_pacman() {
    local mode=$1
    print_colored "$GREEN" "Installing packages using pacman..."
    
    # Update system
    sudo pacman -Syu --noconfirm

    # Install basic tools
    print_colored "$BLUE" "Installing basic analysis tools..."
    sudo pacman -S --noconfirm \
        perl-image-exiftool \
        binwalk \
        foremost \
        steghide \
        ruby \
        outguess \
        imagemagick \
        pngcheck \
        jpeginfo \
        ent \
        tesseract \
        tesseract-data-eng \
        ffmpeg \
        vim

    # Install zsteg using gem
    sudo gem install zsteg

    # Install advanced tools if requested
    if [ "$mode" = "advanced" ]; then
        print_colored "$BLUE" "Installing advanced analysis tools..."
        
        # Install from official repositories
        sudo pacman -S --noconfirm \
            volatility \
            scalpel \
            testdisk \
            mat2 \
            exiv2 \
            mediainfo \
            sox \
            python-pip \
            hachoir

        # Install from AUR (requires yay)
        if command -v "yay" &> /dev/null; then
            print_colored "$BLUE" "Installing AUR packages..."
            yay -S --noconfirm \
                stegoveritas \
                bulk-extractor \
                stegseek

            print_colored "$GREEN" "✓ AUR packages installed"
        else
            print_colored "$YELLOW" "Warning: yay not found. Some advanced tools cannot be installed automatically."
            print_colored "$YELLOW" "To install AUR packages, install yay first:"
            echo "git clone https://aur.archlinux.org/yay.git"
            echo "cd yay"
            echo "makepkg -si"
        fi

        # Install Python-based tools
        pip install stegoveritas-binwalk stegano

        print_colored "$GREEN" "✓ Advanced tools installation complete"
    fi
}

# Main script execution
main() {
    if [ "$(id -u)" -ne 0 ] && [ -z "${SUDO_USER:-}" ]; then
        print_colored "$RED" "This script must be run with sudo privileges"
        exit 1
    fi

    # Parse command line arguments
    local mode="basic"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--advanced)
                mode="advanced"
                shift
                ;;
            -b|--basic)
                mode="basic"
                shift
                ;;
            *)
                print_colored "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    local pkg_manager=$(detect_package_manager)
    
    # Show installation mode
    if [ "$mode" = "advanced" ]; then
        print_colored "$BLUE" "Installing in advanced mode (all tools)..."
    else
        print_colored "$BLUE" "Installing in basic mode (core tools only)..."
    fi
    
    case $pkg_manager in
        apt)
            install_apt "$mode"
            ;;
        dnf)
            install_dnf "$mode"
            ;;
        pacman)
            install_pacman "$mode"
            ;;
        *)
            print_colored "$RED" "Unsupported package manager. Please install dependencies manually."
            exit 1
            ;;
    esac
    
    print_colored "$GREEN" "\nInstallation complete! You can now use stegtool.sh"
    
    if [ "$mode" = "basic" ]; then
        print_colored "$YELLOW" "\nTip: Run with --advanced to install additional analysis tools:"
        echo "    $0 --advanced"
    fi
}

main "$@"
