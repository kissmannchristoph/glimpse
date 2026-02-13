use colored::*;
use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;

fn get_random_color(text: &str) -> String {
    let color_index = rand::random_range(0..8);

    // let color_index = rng.r(0..8);

    let colored_text = match color_index {
        0 => text.red(),
        1 => text.green(),
        2 => text.yellow(),
        3 => text.blue(),
        4 => text.magenta(),
        5 => text.cyan(),
        6 => text.white(),
        _ => text.bright_purple(),
    };

    format!("{}", colored_text)
}

fn main() {
    // 1. Get the target directory (argument or current dir)
    let args: Vec<String> = env::args().collect();
    let default_path = String::from(".");
    let target_dir = args.get(1).unwrap_or(&default_path);

    let path = Path::new(target_dir);

    // 2. Read the directory
    let paths = match fs::read_dir(path) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Error reading directory: {}", e);
            return;
        }
    };

    println!("{:<30} | {}", "Folder", "Branch");
    println!("{:-<30}-|-{:-<20}", "", "");

    // 3. Iterate over folders
    for entry in paths {
        if let Ok(entry) = entry {
            let path = entry.path();

            // Only check directories
            if path.is_dir() {
                // Check if .git exists in this folder to avoid errors
                let git_dir = path.join(".git");

                if git_dir.exists() {
                    // 4. Run 'git rev-parse --abbrev-ref HEAD'
                    let output = Command::new("git")
                        .arg("rev-parse")
                        .arg("--abbrev-ref")
                        .arg("HEAD")
                        .current_dir(&path)
                        .output();

                    let branch_name = match output {
                        Ok(o) => {
                            if o.status.success() {
                                String::from_utf8_lossy(&o.stdout).trim().to_string()
                            } else {
                                "Error/No Commit".to_string()
                            }
                        }
                        Err(_) => "Git missing?".to_string(),
                    };

                    // Print result
                    let folder_name = path.file_name().unwrap().to_string_lossy();
                    println!("{:<30} | {}", folder_name, get_random_color(branch_name.as_str()));
                }
            }
        }
    }
}
