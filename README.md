# 🕵️‍♂️ Steganography Analysis & Forensic Tool

A comprehensive command-line utility for steganography analysis, data extraction, and forensic investigation. Designed for security professionals, CTF players, and digital forensics experts.

## 🚀 Key Features

- **Comprehensive Analysis**: Single-command analysis of files for hidden data and steganography
- **Wide Format Support**: Works with images (PNG, JPG, GIF, BMP), audio, video, and general files
- **Advanced Detection**: Multiple steganography detection methods and algorithms
- **Automated Workflow**: Automated analysis pipeline with detailed reporting
- **Modular Design**: Easy to extend with new analysis modules
- **Cross-Platform**: Works on Linux and macOS (with some limitations on Windows through WSL)
- **Security-Focused**: Built with security best practices and safe execution in mind

## 🔍 Core Capabilities

### 🔎 Steganography Detection
- LSB (Least Significant Bit) steganography
- DCT (Discrete Cosine Transform) based steganography
- Metadata-based hiding techniques
- Palette manipulation detection
- Audio steganography (LSB, phase coding, spread spectrum)

### 📊 File Analysis
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

## 🚀 Installation

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
## 📦 Installation Options

### Basic Installation (`--basic`)
- Core steganography tools
- Essential file analysis
- Basic image processing
- Standard metadata extraction

### Advanced Installation (`--advanced`)
- All basic features plus:
- Advanced stego detection (stegoveritas, stegseek)
- Memory forensics (volatility)
- Deep file carving (bulk-extractor, photorec)
- Advanced metadata analysis (mat2, exiv2)
- Audio steganography tools
- Python-based stego utilities

### Installation Options

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

### Batch Mode

When using batch mode (`-b` or `--batch`), you can process multiple files at once:

```bash
# Process all images in the current directory
./stegtool.sh -b *.jpg *.png

# Process specific files with full paths
./stegtool.sh -b /path/to/file1.jpg /path/to/file2.pdf

# Process files from a list (one file per line)
./stegtool.sh -b $(cat analysis_list.txt)
```

Batch mode behavior:
- Processes files one at a time
- Creates timestamped output directories for each file
- Logs all output to individual log files
- Continues with next file if one fails (in batch mode)
- Shows progress for the current file being processed

**Note:** In batch mode, the script will process all specified files regardless of any individual failures. Check the log files in each output directory for detailed results.

### Security Levels

The security level affects how the tool handles potentially dangerous operations:

- `minimal`: Basic checks only (fastest)
- `normal`: Standard security checks (default)
- `paranoid`: Maximum security checks (slowest)

Example:
```bash
./stegtool.sh -s paranoid sensitive_file.jpg
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

When the analysis is complete, you'll be given options to:
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

### Output

For each analysis, the tool creates a structured output directory:

```
outputs/
└── filename_YYYYMMDD_HHMMSS/
    ├── analysis_summary.txt    # Summary of findings
    ├── analysis_log.txt        # Detailed analysis log
    ├── metadata/               # Extracted metadata
    ├── extracted/              # Any extracted content
    ├── images/                 # Generated analysis images
    ├── reports/                # HTML/PDF reports
    └── logs/                   # Tool-specific logs
```

### Understanding the Output

1. **analysis_summary.txt** - Quick overview of findings
2. **analysis_log.txt** - Detailed log of all operations
3. **metadata/** - Extracted metadata in various formats
4. **extracted/** - Any files or data extracted during analysis
5. **images/** - Visual representations of the analysis
6. **reports/** - Formatted reports in HTML/PDF
7. **logs/** - Debug logs for each tool used

## 📁 Supported File Types

### 🖼️ Image Files

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

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- All the amazing open-source tools that make this project possible
- The digital forensics and security community
- Everyone who has contributed to this project

## 📚 Additional Resources

- [Steganography Techniques](https://en.wikipedia.org/wiki/Steganography)
- [CTF Challenges](https://ctftime.org/)
- [Security Tools Guide](https://tools.kali.org/)

### Understanding Results

The tool creates a timestamped directory for each analysis:
```
outputs/filename_YYYYMMDD_HHMMSS/
```

Key output files:
- `analysis_log.txt`: Complete analysis log
- `*_output.txt`: Individual tool results
- `channels/`: Image channel analysis
- `extracted/`: Any extracted hidden data

### Best Practices

1. Start with basic analysis:
   ```bash
   ./stegtool.sh suspicious_file
   ```

2. Check the analysis_log.txt for findings:
   ```bash
   cat outputs/latest/analysis_log.txt
   ```

3. Review specific tool outputs based on file type:
   - Images: Check steghide, zsteg outputs
   - Audio: Review waveform analysis
   - General: Examine strings, hexdump results

4. For advanced analysis:
   - Install advanced tools first
   - Use tool-specific outputs in the results directory
   - Review all extracted files carefully

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

### Code of Conduct

We are committed to providing a welcoming and inclusive experience for everyone:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Security

To report security vulnerabilities:

1. **DO NOT** open public issues for security vulnerabilities
2. Email the maintainers directly
3. Include detailed descriptions and steps to reproduce
4. We will respond within 48 hours with next steps

We appreciate your help in making this tool secure for everyone.

## Best Practices for CTF and Forensic Analysis

### Image Analysis Commands
```bash
# Basic file information
file image.jpg
exiftool image.jpg
binwalk -e image.jpg

# Strings analysis
strings -n 8 image.jpg
strings -el image.jpg  # Unicode strings

# Hex analysis
xxd image.jpg | less

# Steganography
steghide extract -sf image.jpg
zsteg -a image.png
outguess -r image.jpg output.txt

# Image validation
pngcheck -vtp7f image.png
jpeginfo -c image.jpg

# Entropy analysis
ent image.jpg
```

### Audio Analysis Commands
```bash
# Audio metadata
exiftool audio.wav
ffmpeg -i audio.wav

# Generate spectrograms and waveforms
ffmpeg -i audio.wav -filter_complex 'showwavespic=s=1000x200' -frames:v 1 waveform.png

# Extract hidden data
steghide extract -sf audio.wav
```

### Advanced Techniques

1. LSB Analysis:
   ```bash
   zsteg -a image.png | grep -i "text"
   ```

2. Metadata Manipulation:
   ```bash
   exiftool -all= image.jpg  # Remove all metadata
   ```

3. File Carving:
   ```bash
   foremost -i disk.img -t all
   binwalk -Me firmware.bin
   ```

4. Hash Analysis:
   ```bash
   sha256sum file
   md5sum file
   ```

## Common CTF Steganography Techniques

1. Image Steganography:
   - LSB (Least Significant Bit)
   - DCT (Discrete Cosine Transform)
   - Metadata hiding
   - Color palette manipulation

2. Audio Steganography:
   - Spectral analysis
   - LSB in audio samples
   - Echo hiding

3. File Structure Analysis:
   - Hidden files in archives
   - Alternate data streams
   - File header manipulation

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Credits

- Inspired by various CTF tools and forensic analysis techniques
- Thanks to all contributors and tool maintainers
- Special thanks to the open-source community

## Support

For issues, feature requests, or questions:
1. Check the [Issues](https://github.com/sarveshvetrivel/stegroot/issues) page
2. Create a new issue with a detailed description
3. Follow the issue template guidelines
