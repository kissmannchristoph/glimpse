# glimpse

A simple command-line tool to view Git branches across multiple repositories in subfolders.

![glimpse demo](https://raw.githubusercontent.com/yourusername/glimpse/main/demo.png)

## Overview

`glimpse` recursively scans directories for Git repositories and displays the currently checked-out branch for each one in a clean, tabular format. Perfect for managing multiple projects or microservices.

## Features

- 🔍 Recursively finds all Git repositories in subfolders
- 📊 Clean tabular output showing folder names and branches
- ⚡ Fast and lightweight
- 🎨 Color-coded output for better readability

## Installation

```bash
# Clone the repository
git clone https://github.com/kissmannchristoph/glimpse.git
cd glimpse

# Make the script executable (if applicable)
chmod +x glimpse

# Optional: Add to your PATH
sudo cp glimpse /usr/local/bin/
```

## Usage

Navigate to the parent directory containing your Git repositories and run:

```bash
glimpse
```

### Example Output

```
Folder          | Branch
----------------+----------------
A               | branch-a
anc             | master
C               | branch-C
D               | branch-D
B               | branch-b
```

## How It Works

`glimpse` walks through the current directory and its subdirectories, identifies folders containing a `.git` directory, and extracts the current branch name from each repository.

## Requirements

- Git installed on your system
- Unix-like environment (Linux, macOS, WSL)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Your Name (@yourusername)

## Acknowledgments

- Inspired by the need to quickly check branch status across multiple repositories
- Built for developers managing multiple Git projects

---

**Note:** Replace `yourusername` and other placeholder information with your actual GitHub username and details.