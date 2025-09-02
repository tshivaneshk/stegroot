# Steganography Analysis & Forensic Tool

A comprehensive command-line utility for steganography analysis, data extraction, and forensic investigation. Designed for security professionals, CTF players, and digital forensics experts.

## Key Features

- **Comprehensive Analysis**: Single-command analysis of files for hidden data and steganography
- **Wide Format Support**: Works with images (PNG, JPG, GIF, BMP), audio, video, and general files
- **Advanced Detection**: Multiple steganography detection methods and algorithms
- **Automated Workflow**: Automated analysis pipeline with detailed reporting
- **Modular Design**: Easy to extend with new analysis modules
- **Cross-Platform**: Works on Linux and macOS (with some limitations on Windows through WSL)
- **Security-Focused**: Built with security best practices and safe execution in mind

## Core Capabilities

### Steganography Detection
- LSB (Least Significant Bit) steganography
- DCT (Discrete Cosine Transform) based steganography
- Metadata-based hiding techniques
- Palette manipulation detection
- Audio steganography (LSB, phase coding, spread spectrum)

### File Analysis
- File signature verification
- Magic number analysis
- Entropy analysis
- String extraction
- Binary pattern matching

### Core Analysis Tools

- `exiftool` - Metadata analysis
- `binwalk` - Firmware analysis and file carving
- `foremost` - Data carving and recovery
- `steghide` - Steganography detection and extraction
- `zsteg` - PNG/BMP steganography analysis
- `outguess` - JPEG steganography analysis
- `imagemagick` - Image manipulation and analysis
- `pngcheck` - PNG file validation
- `jpeginfo` - JPEG file validation
- `ent` - Entropy analysis
- `tesseract` - OCR (Optical Character Recognition)
- `ffmpeg` - Audio/Video analysis
- `xxd` - Hexadecimal analysis
- `strings` - Text string extraction
- `file` - File type identification

Each tool is carefully integrated into the analysis workflow to provide maximum insight into potential hidden data and steganographic content.

## Installation

### Prerequisites
- Linux or macOS (Windows via WSL)
- Git
- sudo/administrator privileges (for package installation)

### Step-by-Step Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/sarveshvetrivel/stegroot.git
   cd stegroot
   ```

2. **Make the scripts executable**:
   ```bash
   chmod +x stegtool.sh install_requirements.sh
   ```

3. **Install dependencies**:
   
   For basic functionality (recommended for most users):
   ```bash
   sudo ./install_requirements.sh
   # or explicitly
   sudo ./install_requirements.sh --basic
   ```
   
   For advanced features (requires more disk space):
   ```bash
   sudo ./install_requirements.sh --advanced
   ```

### Installation Features

- Automatic package manager detection (apt, dnf, pacman, brew)
- Dependency resolution
- Progress tracking
- Error reporting
- Clean rollback on failure
- Logging of all operations

### Post-Installation

  Add to PATH (optional):
   ```bash
   echo 'export PATH="$PATH:'$(pwd)'"' >> ~/.bashrc
   source ~/.bashrc
   ```
## Installation Options

#### Basic Installation (`--basic`)
- Core steganography tools
- Essential file analysis
- Basic image processing
- Standard metadata extraction

#### Advanced Installation (`--advanced`)
Additional tools for:
- Advanced stego detection (stegoveritas, stegseek)
- Memory forensics (volatility)
- Deep file carving (bulk-extractor, photorec)
- Advanced metadata analysis (mat2, exiv2)
- Audio steganography tools
- Python-based stego utilities

To see all installation options:
```bash
./install_requirements.sh --help
```

## 🛠️ Usage Guide

### Basic Usage

Analyze a file with default settings:
```bash
./stegtool.sh <path_to_file>
```

Example:
```bash
./stegtool.sh suspicious_image.png
```

### Command-Line Options

```
Usage: ./stegtool.sh [OPTIONS] <file>

Options:
  -i, --interactive    Enable interactive mode
  -b, --batch          Enable batch mode (process multiple files)
  -s, --security LEVEL Set security level (minimal, normal, paranoid)
  -np, --no-progress   Disable progress indicators
  --                   End of options (useful when filenames start with -)

Examples:
  # Basic analysis (single file)
  ./stegtool.sh image.jpg
  
  # Interactive mode
  ./stegtool.sh -i secret_file.png
  
  # Batch process multiple files
  ./stegtool.sh -b file1.jpg file2.png file3.doc
  
  # Set security level
  ./stegtool.sh -s paranoid sensitive_file.jpg
  
  # Disable progress indicators (useful for logging)
  ./stegtool.sh -np document.pdf
```

### Interactive Mode

Start interactive mode for a guided analysis experience:
```bash
./stegtool.sh -i file_to_analyze
```

In interactive mode, the tool will:
1. Prompt you before running each analysis phase
2. Show real-time progress and results
3. Allow you to skip or retry analysis steps
4. Provide contextual help when needed
5. Dynamically adjust options based on file type and installed tools (**Smart Mode**)
6. Let you view results at any time without exiting

**New Enhancements:**

- **Phase-Based Execution** – Run specific phases individually:
  - Basic File Analysis
  - Metadata Analysis
  - File Carving
  - Image-Specific Analysis
  - Audio/Video Analysis
  - Advanced File Carving
- **Run All Phases with Auto-Summary** – When you choose “Run All Phases,” the tool:
  - Executes the complete `analyze_file` pipeline
  - Immediately shows the generated `analysis_summary.txt` for quick review
- **On-Demand Summary View** – Check results mid-session without restarting
- **Smart Tool Detection** – Hides irrelevant options for your file type and installed tools
- **No Restart Needed** – Skip, repeat, or run different phases in one session

**Example Menu:**
```
===== Interactive Analysis Menu =====
1) Basic File Analysis
2) Metadata Analysis
3) File Carving
4) Image-Specific Analysis
5) Audio/Video Analysis
6) Advanced File Carving
7) Run All Phases
8) View Analysis Summary
9) Exit Interactive Mode
```

When the analysis is complete, you’ll be given options to:
- View the full analysis log
- Open the output directory
- Try additional analysis steps
- Exit the program

### Batch Processing

Process multiple files:
```bash
for file in *.jpg; do
    ./stegtool.sh "$file"
done
```

## Supported File Types

### Image Files

#### Supported Formats
- **Raster Images**: PNG, JPG/JPEG, GIF, BMP, TIFF, WebP
- **Vector Graphics**: SVG (converted to raster for analysis)
- **Raw Formats**: CR2, NEF, ARW (camera raw formats)

#### Image Analysis Features
- **Basic Analysis**
  - File signature validation
  - Magic number verification
  - Header/footer analysis
  - File integrity checks

- **Metadata Extraction**
  - EXIF data extraction
  - XMP data parsing
  - IPTC information
  - GPS data (if present)
  - Thumbnail analysis

- **Steganography Detection**
  - LSB (Least Significant Bit) analysis
  - DCT coefficient analysis (JPEG)
  - Palette-based steganography
  - EOF (End of File) analysis
  - Hidden file detection

- **Advanced Analysis**
  - Error level analysis (ELA)
  - Noise analysis
  - Color channel manipulation detection
  - Statistical analysis
  - Bit plane analysis
  - Histogram analysis

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- All the amazing open-source tools that make this project possible
- The digital forensics and security community
- Everyone who has contributed to this project

### Output Structure

The tool creates an organized output structure for each analysis:

```
outputs/
└── filename_YYYYMMDD_HHMMSS/
    ├── analysis_log.txt         # Complete analysis log with findings
    ├── missing_tools.txt        # List of unavailable tools (if any)
    │
    ├── Basic Analysis/
    │   ├── file_output.txt     # File type and basic info
    │   ├── strings_output.txt  # ASCII strings found
    │   ├── strings-utf_output.txt  # UTF-16 strings
    │   ├── xxd_output.txt     # Hex dump analysis
    │   └── ent_output.txt     # Entropy analysis results
    │
    ├── Metadata/
    │   ├── exiftool_output.txt # Detailed metadata
    │   └── [Advanced]/         # If advanced tools installed
    │       ├── mat2_output.txt    # Additional metadata
    │       └── exiv2_output.txt   # Extended image metadata
    │
    ├── Steganography/
    │   ├── steghide_output.txt  # Basic stego analysis
    │   ├── zsteg_output.txt    # PNG/BMP stego results
    │   ├── outguess_output.txt # JPEG stego analysis
    │   └── [Advanced]/         # If advanced tools installed
    │       └── stegoveritas/   # Deep stego analysis
    │
    ├── Image Analysis/         # For image files
    │   ├── channels/          # Color channel analysis
    │   │   └── channel_*.png  # Individual channels
    │   ├── bitplanes/         # Bit plane analysis
    │   │   └── bitplane_*.png # Individual bit planes
    │   ├── alpha_channel.png  # Extracted alpha channel
    │   ├── inverted.png      # Inverted image
    │   └── ocr_output.txt    # Text found in image
    │
    ├── Audio Analysis/         # For audio files
    │   ├── waveform.png       # Visual waveform
    │   ├── spectrum.png       # Frequency analysis
    │   └── extracted/         # Extracted hidden data
    │
    ├── Video Analysis/         # For video files
    │   ├── frames/           # Extracted frames
    │   ├── audio.wav         # Extracted audio
    │   └── subtitles.srt     # Extracted subtitles
    │
    └── Extracted/             # Any recovered files
        ├── foremost/         # Files carved by foremost
        └── binwalk/         # Files extracted by binwalk
```

**Note:** Advanced analysis directories will only be present if you installed the tool with the `--advanced` option.
```

## Contributing, Code of Conduct, and Security

### Contributing

We welcome contributions! Please follow these guidelines:

1. Fork and Clone:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Development:
   - Use `shellcheck` for code quality
   - Follow POSIX shell standards
   - Add proper error handling and comments
   - Test thoroughly with different file types
   - Update documentation as needed

3. Submit Changes:
   ```bash
   git commit -m "feat: add new stego detection method"
   git push origin feature/your-feature-name
   ```
   Create a Pull Request with clear descriptions and test results.

### Security

To report security vulnerabilities:

1. **DO NOT** open public issues for security vulnerabilities
2. Email the maintainers directly
3. Include detailed descriptions and steps to reproduce
4. We will respond within 48 hours with next steps

We appreciate your help in making this tool secure for everyone.

## Support

For issues, feature requests, or questions:
1. Check the [Issues](https://github.com/sarveshvetrivel/stegroot/issues) page
2. Create a new issue with a detailed description
3. Follow the issue template guidelines
