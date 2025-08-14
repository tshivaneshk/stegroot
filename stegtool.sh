#!/usr/bin/env bash

# stegtool.sh - Comprehensive Steganography & Forensic Analysis Tool
# Author: Sarvesh Vetrivel
# License: Apache 2.0
# Version: 1.1.0 - Fixed with proper error handling

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# Ensure the script can be run from any directory
cd "$(dirname "$0")"

# Globals
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR=""  # Initialize to prevent unbound variable errors
ERRORS_COUNT=0
WARNINGS_COUNT=0
MAX_RETRIES=3
INTERACTIVE=false
BACKUP_DIR="${SCRIPT_DIR}/backups"
MAX_FILE_SIZE=10737418240  # 10GB
MAX_MEMORY_USAGE=8589934592  # 8GB
PROGRESS_ENABLED=true
BATCH_MODE=false
SECURITY_LEVEL="normal"  # Can be: minimal, normal, paranoid

# Core required tools
REQUIRED_TOOLS=(
    "exiftool"      # Metadata analysis
    "binwalk"       # Firmware analysis and file carving
    "foremost"      # Data carving
    "steghide"      # Image/audio steganography
    "zsteg"         # PNG/BMP steganography
    "outguess"      # JPEG steganography
    "convert"       # ImageMagick for image manipulation
    "pngcheck"      # PNG analysis
    "jpeginfo"      # JPEG analysis
    "ent"           # Entropy analysis
    "tesseract"     # OCR analysis
    "ffmpeg"        # Audio/video analysis
    "xxd"           # Hex analysis
    "strings"       # String extraction
    "file"          # File type detection
    "identify"      # ImageMagick identify tool
)

# Optional advanced tools
OPTIONAL_TOOLS=(
    # Image Steganography
    "stegoveritas"  # Comprehensive stego analysis
    "stegseek"      # Fast steghide cracker
    "jsteg"         # JPEG steganography
    "stegdetect"    # Automated stego detection
    "openstego"     # Java-based stego tool
    
    # Audio Analysis
    "sox"           # Sound processing
    "wavsteg"       # WAV steganography
    "mp3stego"      # MP3 steganography
    
    # Advanced Forensics
    "volatility"    # Memory forensics
    "scalpel"       # Precise file carving
    "bulk_extractor" # Feature extraction
    "photorec"      # File recovery
    "hashdeep"      # Recursive hashing
    
    # Metadata Tools
    "mat2"          # Metadata removal
    "exiv2"         # Image metadata
    "mediainfo"     # Media file metadata
    "hachoir-metadata" # Advanced metadata extraction
)

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show progress spinner
show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        if [ "$PROGRESS_ENABLED" = true ]; then
            local temp=${spinstr#?}
            printf " [%c]  " "$spinstr"
            spinstr=$temp${spinstr%"$temp"}
            sleep $delay
            printf "\b\b\b\b\b\b"
        fi
    done
    printf "    \b\b\b\b"
}

# Function to print colored output with error handling
print_colored() {
    local color=$1
    shift
    if [ $# -eq 0 ]; then
        echo -e "${color}[No message provided]${NC}" >&2
        return 1
    fi
    if [ "$PROGRESS_ENABLED" = true ]; then
        echo -e "${color}$*${NC}"
    fi
}

# Enhanced logging function with error levels
log() {
    local level="${1:-INFO}"
    shift
    local message="$*"
    local timestamp="[$(date +'%Y-%m-%d %H:%M:%S')]"
    
    # Ensure OUTPUT_DIR is set before logging to file
    if [ -n "${OUTPUT_DIR:-}" ] && [ -d "$OUTPUT_DIR" ]; then
        echo "$timestamp [$level] $message" | tee -a "${OUTPUT_DIR}/analysis_log.txt"
    else
        echo "$timestamp [$level] $message"
    fi
    
    # Update counters
    case "$level" in
        "ERROR") ((ERRORS_COUNT++)) ;;
        "WARN"|"WARNING") ((WARNINGS_COUNT++)) ;;
    esac
}

# Function to safely create directories
safe_mkdir() {
    local dir="$1"
    if ! mkdir -p "$dir" 2>/dev/null; then
        log "ERROR" "Failed to create directory: $dir"
        return 1
    fi
    return 0
}

# Function to validate file accessibility
validate_file() {
    local file="$1"
    local retry_count=0
    
    # Check if file exists
    while [ ! -f "$file" ] && [ $retry_count -lt $MAX_RETRIES ]; do
        log "ERROR" "File not found: $file"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Enter correct file path or press Enter to retry: " new_file
            if [ -n "$new_file" ]; then
                file="$new_file"
            fi
        fi
        ((retry_count++))
        sleep 1
    done
    
    if [ ! -f "$file" ]; then
        log "ERROR" "File not found after $MAX_RETRIES attempts: $file"
        return 1
    fi
    
    # Check if file is readable
    if [ ! -r "$file" ]; then
        log "ERROR" "File not readable: $file"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Would you like to fix file permissions? (y/n): " fix_perms
            if [[ "$fix_perms" =~ ^[Yy]$ ]]; then
                chmod +r "$file" || {
                    log "ERROR" "Failed to fix file permissions"
                    return 1
                }
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Check if file is empty
    if [ ! -s "$file" ]; then
        log "WARN" "File is empty: $file"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Continue with empty file? (y/n): " continue_empty
            if [[ ! "$continue_empty" =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
        return 2
    fi
    
    # Check file size and memory requirements
    local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    local available_memory=$(free -b 2>/dev/null | awk '/Mem:/ {print $7}' || echo $MAX_MEMORY_USAGE)
    
    if [ "$file_size" -gt "$MAX_FILE_SIZE" ]; then
        log "ERROR" "File size ($(numfmt --to=iec $file_size)) exceeds maximum allowed size ($(numfmt --to=iec $MAX_FILE_SIZE))"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Continue anyway? This may cause system instability (y/n): " continue_large
            if [[ ! "$continue_large" =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            return 1
        fi
    fi
    
    if [ "$file_size" -gt "$available_memory" ]; then
        log "ERROR" "File size ($(numfmt --to=iec $file_size)) exceeds available memory ($(numfmt --to=iec $available_memory))"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Continue anyway? This may cause system slowdown (y/n): " continue_memory
            if [[ ! "$continue_memory" =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Security checks based on security level
    if [ "$SECURITY_LEVEL" = "paranoid" ]; then
        # Check for suspicious file signatures
        if file "$file" | grep -qi "executable\|script\|binary"; then
            log "ERROR" "Security check failed: File appears to be executable"
            return 1
        fi
        
        # Check for suspicious file extensions
        if [[ "$file" =~ \.(exe|dll|so|sh|bash|cmd|bat|ps1|vbs|js)$ ]]; then
            log "ERROR" "Security check failed: Suspicious file extension"
            return 1
        fi
    fi
    
    # Create backup
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR" || {
            log "ERROR" "Failed to create backup directory"
            return 1
        }
    fi
    
    local backup_file="${BACKUP_DIR}/$(basename "$file").${TIMESTAMP}.bak"
    cp "$file" "$backup_file" || {
        log "ERROR" "Failed to create backup of input file"
        return 1
    }
    log "INFO" "Created backup: $backup_file"
    
    return 0
}

# Function to create output directory with enhanced error handling
setup_output_dir() {
    local filename=$(basename "$1")
    local sanitized_filename=$(echo "$filename" | tr '/' '_' | tr ' ' '_')  # Sanitize filename
    
    OUTPUT_DIR="${SCRIPT_DIR}/outputs/${sanitized_filename}_${TIMESTAMP}"
    
    # Create main output directory with error checking
    if ! safe_mkdir "$OUTPUT_DIR"; then
        print_colored "$RED" "CRITICAL: Cannot create output directory. Exiting."
        exit 1
    fi
    
    # Create organized subdirectories with error handling
    local subdirs=(
        "Basic Analysis"
        "Metadata"
        "Steganography"
        "Image Analysis"
        "Audio Analysis"
        "Video Analysis"
        "Extracted"
        "Logs"
    )
    
    for subdir in "${subdirs[@]}"; do
        if ! safe_mkdir "${OUTPUT_DIR}/${subdir}"; then
            log "WARN" "Failed to create subdirectory: $subdir"
        fi
    done
    
    # Create advanced directories if tools are available
    if command -v "stegoveritas" &> /dev/null || command -v "mat2" &> /dev/null; then
        safe_mkdir "${OUTPUT_DIR}/Metadata/Advanced"
        safe_mkdir "${OUTPUT_DIR}/Steganography/Advanced"
    fi
    
    # Create summary files
    cat > "${OUTPUT_DIR}/analysis_summary.txt" << EOF
# Steganography Analysis Summary
Analysis started: $(date)
Target file: $1
Output directory: $OUTPUT_DIR
Script version: 1.1.0

## Analysis Status
EOF
    
    log "INFO" "Created output directory structure: $OUTPUT_DIR"
    return 0
}

# Enhanced dependency checking with better error handling and tool installation guidance
check_dependencies() {
    local missing_required=()
    local missing_optional=()
    local can_continue=true
    
    log "INFO" "Checking tool dependencies..."
    
    # Check required tools
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_required+=("$tool")
            log "WARN" "Required tool missing: $tool - Some features will be limited"
        else
            log "DEBUG" "Found required tool: $tool"
        fi
    done
    
    # Check optional tools
    for tool in "${OPTIONAL_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_optional+=("$tool")
            log "INFO" "Optional tool missing: $tool - specific features will be skipped"
        else
            log "DEBUG" "Found optional tool: $tool"
        fi
    done
    
    # Report missing tools and provide installation guidance
    if [ ${#missing_required[@]} -gt 0 ] || [ ${#missing_optional[@]} -gt 0 ]; then
        print_colored "$YELLOW" "\n⚠️ Some tools are missing from your system:"
        
        if [ ${#missing_required[@]} -gt 0 ]; then
            print_colored "$YELLOW" "\nRequired tools missing (limited functionality):"
            for tool in "${missing_required[@]}"; do
                print_colored "$YELLOW" "  - $tool"
            done
        fi
        
        if [ ${#missing_optional[@]} -gt 0 ]; then
            print_colored "$CYAN" "\nOptional tools missing (specific features unavailable):"
            for tool in "${missing_optional[@]}"; do
                print_colored "$CYAN" "  - $tool"
            done
        fi
        
        print_colored "$GREEN" "\n💡 You can install missing tools by running:"
        print_colored "$GREEN" "    ./install_requirements.sh"
        
        if [ -n "${OUTPUT_DIR:-}" ]; then
            {
                echo "Missing required tools: ${missing_required[*]}"
                echo "Missing optional tools: ${missing_optional[*]}"
                echo "Run ./install_requirements.sh to install missing tools"
            } > "${OUTPUT_DIR}/Logs/missing_tools.txt"
        fi
    fi
    
    log "INFO" "Dependency check complete. Required: ${#REQUIRED_TOOLS[@]}, Missing required: ${#missing_required[@]}, Missing optional: ${#missing_optional[@]}"
    return 0
}

# Enhanced run_tool function with better error handling and tool validation
run_tool() {
    local tool_name="$1"
    local cmd="$2"
    local category="${3:-Basic Analysis}"
    local check_tool="${4:-$tool_name}"  # Tool to check for availability
    local output_file="${OUTPUT_DIR}/${category}/${tool_name}_output.txt"
    local timeout=300
    
    # Input validation
    if [ -z "$tool_name" ] || [ -z "$cmd" ]; then
        log "ERROR" "Invalid parameters for run_tool function"
        return 1
    fi
    
    # Extract command name for checking
    local check_cmd="${check_tool%% *}"
    
    # Create category directory if it doesn't exist
    if ! safe_mkdir "$(dirname "$output_file")"; then
        log "ERROR" "Cannot create output directory for $tool_name"
        return 1
    fi
    
    # Check if tool is available
    if ! command -v "$check_cmd" &> /dev/null; then
        log "WARN" "Tool not available: $check_cmd - skipping $tool_name analysis"
        echo "Tool not found: $check_cmd ($(date))" >> "${OUTPUT_DIR}/Logs/skipped_tools.txt"
        return 2
    fi
    
    print_colored "$BLUE" "\n🔍 Running $tool_name analysis..."
    log "INFO" "Starting $tool_name analysis with command: $cmd"
    
    # Prepare output file with metadata
    cat > "$output_file" << EOF
=== $tool_name analysis ===
Command: $cmd
Tool check: $check_cmd
Category: $category
Started: $(date)
Timeout: ${timeout}s
===========================

EOF
    
    # Run command with timeout and comprehensive error handling
    local exit_code=0
    local start_time=$(date +%s)
    
    if timeout "$timeout" bash -c "$cmd" >> "$output_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_colored "$GREEN" "✅ $tool_name analysis complete (${duration}s)"
        log "INFO" "$tool_name analysis successful (duration: ${duration}s)"
        
        # Add completion metadata
        echo -e "\n\n=== Analysis Complete ===" >> "$output_file"
        echo "Completed: $(date)" >> "$output_file"
        echo "Duration: ${duration}s" >> "$output_file"
        echo "Status: SUCCESS" >> "$output_file"
        
        # Display preview of results if file has meaningful content
        if [[ -s "$output_file" ]]; then
            local line_count=$(wc -l < "$output_file" 2>/dev/null || echo 0)
            if [ "$line_count" -gt 10 ]; then
                echo "📋 Preview of results (last 5 lines):"
                tail -n 5 "$output_file" | sed 's/^/   /'
            fi
        else
            print_colored "$YELLOW" "⚠️  No output generated"
            log "WARN" "$tool_name produced no output"
        fi
        
        return 0
        
    else
        exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Add failure metadata
        echo -e "\n\n=== Analysis Failed ===" >> "$output_file"
        echo "Failed: $(date)" >> "$output_file"
        echo "Duration: ${duration}s" >> "$output_file"
        echo "Exit code: $exit_code" >> "$output_file"
        
        case $exit_code in
            124)
                print_colored "$YELLOW" "⏰ $tool_name analysis timed out after ${timeout}s"
                log "WARN" "$tool_name timed out (${timeout}s)"
                echo "Status: TIMEOUT" >> "$output_file"
                ;;
            1)
                print_colored "$YELLOW" "⚠️  $tool_name analysis completed with warnings (exit code: $exit_code)"
                log "WARN" "$tool_name completed with warnings (exit code: $exit_code)"
                echo "Status: WARNING" >> "$output_file"
                ;;
            *)
                print_colored "$RED" "❌ $tool_name analysis failed (exit code: $exit_code)"
                log "ERROR" "$tool_name failed (exit code: $exit_code)"
                echo "Status: ERROR" >> "$output_file"
                ;;
        esac
        
        return $exit_code
    fi
}

run_basic_analysis() {
    local file="$1"
    print_colored "$BLUE" "\n📊 Phase 1: Basic File Analysis"
    run_tool "file" "file -b '$file'" "Basic Analysis"
    run_tool "strings" "strings -n 8 -t x '$file'" "Basic Analysis" "strings"
    run_tool "strings-utf" "strings -n 8 -t x -el '$file'" "Basic Analysis" "strings"
    run_tool "xxd" "xxd -g 1 '$file' | head -n 100" "Basic Analysis" "xxd"
    run_tool "ent" "ent -t '$file'" "Basic Analysis" "ent"
}

run_metadata_analysis() {
    local file="$1"
    print_colored "$BLUE" "\n📋 Phase 2: Metadata Analysis"
    run_tool "exiftool" "exiftool -a -u -g1 '$file'" "Metadata" "exiftool"
}

run_file_carving() {
    local file="$1"
    print_colored "$BLUE" "\n🔧 Phase 3: File Carving"
    run_tool "binwalk" "binwalk -BEP '$file'" "Extracted" "binwalk"
}

run_image_analysis() {
    local file="$1"
    local mime_type="$2"
    local output_dir="${OUTPUT_DIR}"

    if [[ $mime_type == image/* ]]; then
        print_colored "$BLUE" "\n🖼️ Phase 4: Image-Specific Analysis"

        run_tool "identify" "identify -verbose '$file'" "Image Analysis" "identify"
        run_tool "steghide" "timeout 30 steghide info '$file' <<< '' 2>/dev/null || echo 'No steganography detected or requires passphrase'" "Steganography" "steghide"

        if command -v "exiv2" &> /dev/null; then
            run_tool "exiv2" "exiv2 -pa '$file'" "Metadata" "exiv2"
        fi
        if command -v "mat2" &> /dev/null; then
            run_tool "mat2" "mat2 --show '$file'" "Metadata" "mat2"
        fi
        if command -v "stegoveritas" &> /dev/null; then
            safe_mkdir "${output_dir}/stegoveritas"
            run_tool "stegoveritas" "stegoveritas -out '${output_dir}/stegoveritas' '$file'" "Steganography" "stegoveritas"
        fi
        if command -v "stegdetect" &> /dev/null; then
            run_tool "stegdetect" "stegdetect -t all '$file'" "Steganography" "stegdetect"
        fi

        if command -v "convert" &> /dev/null; then
            print_colored "$BLUE" "\n🎨 Phase 5: Image Processing"
            safe_mkdir "${output_dir}/channels"
            run_tool "channels" "convert '$file' -separate '${output_dir}/channels/channel_%d.png'" "Image Analysis" "convert"
            run_tool "alpha" "convert '$file' -alpha extract '${output_dir}/alpha_channel.png' 2>/dev/null || echo 'No alpha channel found'" "Image Analysis" "convert"
            run_tool "invert" "convert '$file' -negate '${output_dir}/inverted.png'" "Image Analysis" "convert"
            for i in {0..7}; do
                run_tool "bitplane_$i" "convert '$file' -depth 8 -channel R -threshold $((i * 12))% '${output_dir}/bitplane_$i.png' 2>/dev/null || echo 'Bitplane extraction failed for level $i'" "Image Analysis" "convert"
            done
        else
            log "WARN" "ImageMagick 'convert' not available - skipping image processing"
        fi

        if command -v "photorec" &> /dev/null; then
            safe_mkdir "${output_dir}/photorec"
            run_tool "photorec" "photorec /d '${output_dir}/photorec' /cmd '$file' search" "Extracted" "photorec"
        fi

        print_colored "$BLUE" "\n🔍 Phase 6: Format-Specific Analysis"
        case $mime_type in
            *"png"*)
                run_tool "pngcheck" "pngcheck -vtp7f '$file'" "Image Analysis" "pngcheck"
                run_tool "zsteg" "zsteg -a '$file'" "Steganography" "zsteg"
                run_tool "png_chunks" "hexdump -C '$file' | grep -A 2 'IDAT\|IEND\|PLTE' | head -20" "Image Analysis" "hexdump"
                ;;
            *"jpeg"*|*"jpg"*)
                run_tool "jpeginfo" "jpeginfo -c '$file'" "Image Analysis" "jpeginfo"
                run_tool "outguess" "outguess -r '$file' '${output_dir}/outguess_extracted.txt' 2>/dev/null || echo 'No hidden data found with outguess'" "Steganography" "outguess"
                run_tool "exiftool_thumb" "exiftool -b -ThumbnailImage '$file' > '${output_dir}/thumbnail.jpg' 2>/dev/null || echo 'No thumbnail found'" "Image Analysis" "exiftool"
                ;;
            *"gif"*)
                if command -v "convert" &> /dev/null; then
                    run_tool "gif_frames" "convert '$file' '${output_dir}/frame_%03d.png'" "Image Analysis" "convert"
                    run_tool "gif_info" "identify -format '%f[%s] Canvas=%Wx%H Offset=%X%Y Disposal=%d Delay=%T\n' '$file'" "Image Analysis" "identify"
                fi
                ;;
            *"bmp"*)
                if command -v "stegseek" &> /dev/null; then
                    run_tool "stegseek" "stegseek --crack '$file' /usr/share/wordlists/rockyou.txt -f '${output_dir}/stegseek_output.txt' 2>/dev/null || echo 'No steganography found with stegseek'" "Steganography" "stegseek"
                fi
                ;;
        esac

        run_tool "tesseract" "tesseract '$file' '${output_dir}/ocr_output' -l eng 2>/dev/null || echo 'OCR analysis failed'" "Image Analysis" "tesseract"
    fi
}

run_media_analysis() {
    local file="$1"
    local mime_type="$2"
    local output_dir="${OUTPUT_DIR}"

    if [[ $mime_type == audio/* || $mime_type == video/* ]]; then
        print_colored "$BLUE" "\n🎵 Phase 4: Audio/Video Analysis"

        run_tool "ffmpeg" "ffmpeg -i '$file' -f null - 2>&1 | head -50" "Audio Analysis" "ffmpeg"
        if command -v "mediainfo" &> /dev/null; then
            run_tool "mediainfo" "mediainfo --Full '$file'" "Audio Analysis" "mediainfo"
        fi
        if command -v "hachoir-metadata" &> /dev/null; then
            run_tool "hachoir" "hachoir-metadata '$file'" "Metadata" "hachoir-metadata"
        fi

        if [[ $mime_type == audio/* ]]; then
            safe_mkdir "${output_dir}/audio"
            if command -v "sox" &> /dev/null; then
                run_tool "spectrogram" "sox '$file' -n spectrogram -o '${output_dir}/audio/spectrogram.png' 2>/dev/null || echo 'Spectrogram generation failed'" "Audio Analysis" "sox"
            fi
            if command -v "wavsteg" &> /dev/null; then
                run_tool "wavsteg" "wavsteg -r -s '$file' -o '${output_dir}/audio/wavsteg_output.txt' 2>/dev/null || echo 'No steganography found'" "Steganography" "wavsteg"
            fi
            run_tool "audio_steghide" "steghide extract -sf '$file' -p '' -xf '${output_dir}/audio/steghide_output.txt' 2>/dev/null || echo 'No steganography found or wrong passphrase'" "Steganography" "steghide"
            run_tool "waveform" "ffmpeg -i '$file' -filter_complex 'showwavespic=s=1000x200' -frames:v 1 '${output_dir}/audio/waveform.png' -y 2>/dev/null || echo 'Waveform generation failed'" "Audio Analysis" "ffmpeg"
        fi

        if [[ $mime_type == video/* ]]; then
            safe_mkdir "${output_dir}/video/frames"
            run_tool "extract_frames" "ffmpeg -i '$file' -vf 'select=lt(n\,10)' '${output_dir}/video/frames/frame_%04d.png' -y 2>/dev/null || echo 'Frame extraction failed'" "Video Analysis" "ffmpeg"
            run_tool "extract_audio" "ffmpeg -i '$file' -vn -acodec copy '${output_dir}/video/audio.wav' -y 2>/dev/null || echo 'Audio extraction failed'" "Video Analysis" "ffmpeg"
            run_tool "video_meta" "ffprobe -v quiet -print_format json -show_format -show_streams '$file'" "Video Analysis" "ffprobe"
            run_tool "subtitles" "ffmpeg -i '$file' -map 0:s:0 '${output_dir}/video/subtitles.srt' -y 2>/dev/null || echo 'No subtitles found'" "Video Analysis" "ffmpeg"
        fi
    fi
}

run_advanced_carving() {
    local file="$1"
    print_colored "$BLUE" "\n⚒️ Phase 7: Advanced File Carving"
    if command -v "foremost" &> /dev/null; then
        run_tool "foremost" "foremost -v -t all -i '$file' -o '${OUTPUT_DIR}/foremost_output'" "Extracted" "foremost"
    fi
    if command -v "scalpel" &> /dev/null; then
        run_tool "scalpel" "scalpel '$file' -o '${OUTPUT_DIR}/scalpel_output'" "Extracted" "scalpel"
    fi
}


analyze_file() {
    local file="$1"

    if ! validate_file "$file"; then return 1; fi
    local mime_type
    if ! mime_type=$(file --mime-type -b "$file" 2>/dev/null); then return 1; fi

    run_basic_analysis "$file"
    run_metadata_analysis "$file"
    run_file_carving "$file"
    run_image_analysis "$file" "$mime_type"
    run_media_analysis "$file" "$mime_type"
    run_advanced_carving "$file"

    generate_summary "$file" "$mime_type"
}


# Function to generate analysis summary
generate_summary() {
    local file="$1"
    local mime_type="$2"
    local summary_file="${OUTPUT_DIR}/analysis_summary.txt"
    
    cat >> "$summary_file" << EOF

## Analysis Results Summary
Analysis completed: $(date)
Total errors: $ERRORS_COUNT
Total warnings: $WARNINGS_COUNT

### Files Generated:
EOF
    
    # Count output files
    local total_files=$(find "$OUTPUT_DIR" -type f -name "*.txt" | wc -l)
    echo "Total output files: $total_files" >> "$summary_file"
    
    # List key findings
    echo -e "\n### Key Findings:" >> "$summary_file"
    
    # Check for high entropy
    if [ -f "${OUTPUT_DIR}/Basic Analysis/ent_output.txt" ]; then
        local entropy=$(grep -o '[0-9]\+\.[0-9]\+' "${OUTPUT_DIR}/Basic Analysis/ent_output.txt" | head -1)
        if (( $(echo "$entropy > 7.5" | bc -l 2>/dev/null || echo 0) )); then
            echo "- HIGH ENTROPY DETECTED ($entropy/8.0) - Potential steganography or encryption" >> "$summary_file"
        fi
    fi
    
    # Check for extracted files
    local extracted_count=$(find "${OUTPUT_DIR}/Extracted" -name "*.txt" 2>/dev/null | wc -l)
    if [ "$extracted_count" -gt 0 ]; then
        echo "- Found $extracted_count extracted/carved files" >> "$summary_file"
    fi
    
    # Check for steganography findings
    if [ -d "${OUTPUT_DIR}/Steganography" ]; then
        local stego_files=$(find "${OUTPUT_DIR}/Steganography" -name "*.txt" -exec grep -l "found\|detected\|extracted" {} \; 2>/dev/null | wc -l)
        if [ "$stego_files" -gt 0 ]; then
            echo "- Potential steganography detected in $stego_files analysis files" >> "$summary_file"
        fi
    fi
    
    echo -e "\n### Recommendations:" >> "$summary_file"
    echo "1. Review files in the Steganography directory for hidden content" >> "$summary_file"
    echo "2. Check Extracted directory for carved files" >> "$summary_file"
    echo "3. Examine high-entropy areas manually" >> "$summary_file"
    echo "4. Run specialized tools based on file format findings" >> "$summary_file"
}

# Function to process password attempts for steganography tools
try_passwords() {
    local file="$1"
    local tool="$2"
    local max_attempts=5
    local password_file=""
    local extraction_succeeded=false
    
    # First try with blank password
    log "INFO" "Attempting extraction with blank passphrase first..."
    print_colored "$CYAN" "🔑 Trying blank passphrase..."
    
    case "$tool" in
        "steghide")
            if steghide extract -sf "$file" -p "" -xf "${OUTPUT_DIR}/Steganography/steghide_extracted_blank.bin" 2>/dev/null; then
                log "INFO" "Successfully extracted data with blank passphrase"
                print_colored "$GREEN" "✅ Successfully extracted data with blank passphrase!"
                print_colored "$YELLOW" "💡 If you have the correct password, you may want to try extracting again with it"
                extraction_succeeded=true
            fi
            ;;
        "outguess")
            if outguess -k "" -r "$file" "${OUTPUT_DIR}/Steganography/outguess_extracted_blank.txt" 2>/dev/null; then
                log "INFO" "Successfully extracted data with blank passphrase"
                print_colored "$GREEN" "✅ Successfully extracted data with blank passphrase!"
                print_colored "$YELLOW" "💡 If you have the correct password, you may want to try extracting again with it"
                extraction_succeeded=true
            fi
            ;;
    esac
    
    # If interactive mode and blank password didn't work, try user passwords
    if [ "$INTERACTIVE" = true ] && [ "$extraction_succeeded" = false ]; then
        print_colored "$YELLOW" "\n🔐 Blank passphrase didn't work. You can try entering a password."
        for ((i=1; i<=max_attempts; i++)); do
            read -s -p "Enter password attempt $i/$max_attempts (or press Enter to skip): " password
            echo
            if [ -z "$password" ]; then
                break
            fi
            
            case "$tool" in
                "steghide")
                    if steghide extract -sf "$file" -p "$password" -xf "${OUTPUT_DIR}/Steganography/steghide_extracted_$i.bin" 2>/dev/null; then
                        log "INFO" "Successfully extracted data with password on attempt $i"
                        print_colored "$GREEN" "✅ Successfully extracted data with provided password!"
                        return 0
                    fi
                    ;;
                "outguess")
                    if outguess -k "$password" -r "$file" "${OUTPUT_DIR}/Steganography/outguess_extracted_$i.txt" 2>/dev/null; then
                        log "INFO" "Successfully extracted data with password on attempt $i"
                        print_colored "$GREEN" "✅ Successfully extracted data with provided password!"
                        return 0
                    fi
                    ;;
                *)
                    log "ERROR" "Unsupported steganography tool: $tool"
                    return 1
                    ;;
            esac
            print_colored "$RED" "❌ Password attempt $i failed"
        done
    fi
    
    # If still no success and wordlist exists, try automated cracking
    if [ "$extraction_succeeded" = false ] && [ -f "/usr/share/wordlists/rockyou.txt" ]; then
        password_file="/usr/share/wordlists/rockyou.txt"
        log "INFO" "Attempting password recovery using wordlist"
        print_colored "$CYAN" "🔍 Attempting automated password recovery..."
        
        case "$tool" in
            "steghide")
                if command -v "stegseek" &> /dev/null; then
                    stegseek "$file" "$password_file" "${OUTPUT_DIR}/Steganography/steghide_cracked.txt" || true
                else
                    print_colored "$YELLOW" "💡 Install 'stegseek' for automated password recovery"
                fi
                ;;
            *)
                log "INFO" "Automated password cracking not supported for tool: $tool"
                ;;
        esac
    fi
    
    [ "$extraction_succeeded" = true ] && return 0 || return 1
}

# Function to handle interrupted analysis
handle_interrupt() {
    local stage="$1"
    
    log "WARN" "Analysis interrupted during stage: $stage"
    if [ "$INTERACTIVE" = true ]; then
        read -p "Would you like to (C)ontinue, (R)estart, or (Q)uit? " choice
        case "$choice" in
            [Cc]) return 0 ;;
            [Rr]) return 2 ;;
            *) return 1 ;;
        esac
    else
        return 1
    fi
}

interactive_menu() {
    local file="$1"
    
    # Detect MIME type once for later use
    local mime_type
    mime_type=$(file --mime-type -b "$file" 2>/dev/null)
    
    while true; do
        echo
        print_colored "$PURPLE" "===== Interactive Analysis Menu ====="
        echo "1) Basic File Analysis"
        echo "2) Metadata Analysis"
        echo "3) File Carving"
        echo "4) Image-Specific Analysis"
        echo "5) Audio/Video Analysis"
        echo "6) Advanced File Carving"
        echo "7) Run All Phases"
        echo "8) View Analysis Summary"
        echo "9) Exit Interactive Mode"
        
        read -p "Select an option: " choice
        
        case "$choice" in
            1) run_basic_analysis "$file" ;;
            2) run_metadata_analysis "$file" ;;
            3) run_file_carving "$file" ;;
            4) run_image_analysis "$file" "$mime_type" ;;
            5) run_media_analysis "$file" "$mime_type" ;;
            6) run_advanced_carving "$file" ;;
            7) 
                analyze_file "$file"
                if [ -f "${OUTPUT_DIR}/analysis_summary.txt" ]; then
                    print_colored "$GREEN" "\n📊 Analysis Summary:"
                    less "${OUTPUT_DIR}/analysis_summary.txt"
                else
                    print_colored "$YELLOW" "No summary found."
                fi
                ;;
            8) 
                if [ -f "${OUTPUT_DIR}/analysis_summary.txt" ]; then
                    less "${OUTPUT_DIR}/analysis_summary.txt"
                else
                    print_colored "$YELLOW" "No summary found. Run an analysis phase first."
                fi
                ;;
            9) break ;;
            *) print_colored "$YELLOW" "Invalid choice. Try again." ;;
        esac
    done
}



# Enhanced main function with better error handling
main() {
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -b|--batch)
                BATCH_MODE=true
                shift
                ;;
            -s|--security)
                SECURITY_LEVEL="$2"
                shift 2
                ;;
            -np|--no-progress)
                PROGRESS_ENABLED=false
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                print_colored "$RED" "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Initialize error handling
    trap 'log "ERROR" "Script interrupted by user"; handle_interrupt "main" || { cleanup; exit 130; }' INT TERM
    
    if [ "$BATCH_MODE" = true ] && [ "$#" -eq 0 ]; then
        print_colored "$RED" "No input files provided for batch mode"
        print_colored "$YELLOW" "Usage: $0 [-i|--interactive] [-b|--batch] [-s|--security level] [-np|--no-progress] file [file...]"
        exit 1
    elif [ "$BATCH_MODE" = false ] && [ "$#" -ne 1 ]; then
        print_colored "$RED" "Usage: $0 [-i|--interactive] [-b|--batch] [-s|--security level] [-np|--no-progress] file"
        print_colored "$YELLOW" "Example: $0 -i /path/to/suspicious/file.jpg"
        exit 1
    fi
    
    print_colored "$GREEN" "🚀 Starting Steganography Analysis Tool v1.1.0"
    print_colored "$CYAN" "Mode: $([ "$BATCH_MODE" = true ] && echo "Batch" || echo "Single")"
    print_colored "$CYAN" "Interactive: $([ "$INTERACTIVE" = true ] && echo "Yes" || echo "No")"
    print_colored "$CYAN" "Security Level: $SECURITY_LEVEL"
    
    # Process each input file
    for target_file in "$@"; do
        print_colored "$CYAN" "\nProcessing: $target_file"
        
        # Validate input file first
        if ! validate_file "$target_file"; then
            print_colored "$RED" "Error: File validation failed for: $target_file"
            if [ "$BATCH_MODE" = true ]; then
                continue
            else
                exit 1
            fi
        fi
        
        # Setup output directory first (before any logging)
        if ! setup_output_dir "$target_file"; then
            print_colored "$RED" "CRITICAL: Failed to setup output directory"
            if [ "$BATCH_MODE" = true ]; then
                continue
            else
                exit 1
            fi
        fi
        
        # Check dependencies
        check_dependencies || {
            if [ "$BATCH_MODE" = true ]; then
                continue
            else
                exit 1
            fi
        }
        
        # Perform analysis
        if [ "$INTERACTIVE" = true ]; then
            interactive_menu "$target_file"
        else
            if analyze_file "$target_file"; then
                print_colored "$GREEN" "\n🎉 Analysis Complete!"
                print_colored "$GREEN" "📁 Results saved in: $OUTPUT_DIR"
                print_colored "$CYAN" "📊 Summary: $ERRORS_COUNT errors, $WARNINGS_COUNT warnings"
                
                # Show important files
                echo
                print_colored "$BLUE" "📋 Key Output Files:"
                echo "   📄 Full log: ${OUTPUT_DIR}/analysis_log.txt"
                echo "   📋 Summary: ${OUTPUT_DIR}/analysis_summary.txt"
                if [ -d "${OUTPUT_DIR}/Steganography" ]; then
                    echo "   🔍 Steganography: ${OUTPUT_DIR}/Steganography/"
                fi
                if [ -d "${OUTPUT_DIR}/Extracted" ]; then
                    echo "   📦 Extracted: ${OUTPUT_DIR}/Extracted/"
                fi
                
                # Handle steganography password attempts if needed
                if [ -d "${OUTPUT_DIR}/Steganography" ] && [ "$INTERACTIVE" = true ]; then
                    stego_files=$(find "${OUTPUT_DIR}/Steganography" -type f -name "*_output.txt" -exec grep -l "passphrase\|password required" {} \;)
                    if [ -n "$stego_files" ]; then
                        print_colored "$YELLOW" "\n🔐 Steganography content requiring password detected"
                        read -p "Would you like to attempt password extraction? (y/n): " try_pass
                        if [[ "$try_pass" =~ ^[Yy]$ ]]; then
                            for tool in "steghide" "outguess"; do
                                try_passwords "$target_file" "$tool"
                            done
                        fi
                    fi
                fi

            else
                print_colored "$RED" "❌ Analysis failed!"
                if [ "$BATCH_MODE" = false ]; then
                    exit 1
                fi
            fi
        fi

        if [ "$BATCH_MODE" = true ]; then
            print_colored "$GREEN" "\n📋 Batch processing complete!"
            print_colored "$CYAN" "Total files processed: $#"
        fi
    done
}

# Cleanup function
cleanup() {
    log "INFO" "Cleaning up temporary files..."
    # Add any cleanup tasks here
}

# Execute main function with all arguments
main "$@"