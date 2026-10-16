# Attendance Tracker Deployment Agent

## Overview

This project contains a Bash deployment agent that automates the setup and management of an attendance-tracking application. It provides three main features:

1. **Deploy:** Creates a new attendance tracker project and configures its files.
2. **Run:** Launches an existing attendance tracker.
3. **Archive:** Archives attendance and absence logs using timestamped filenames.

The script also handles Ctrl+C and Ctrl+Z interruptions during deployment by attempting to create a ZIP archive of the incomplete project and remove the project directory.

## Repository Structure

```text
deploy_agent_DerrickMugire/
├── deploy_agent.sh
├── README.md
└── templates/
    ├── assets.csv
    ├── attendance_checker.py
    └── config.json
```

After a successful deployment, the generated project has a structure similar to:

```text
attendance_tracker_<identifier>/
├── Helpers/
│   ├── assets.csv
│   ├── attendance_checker.py
│   └── config.json
└── reports/
```

The exact report files created depend on the attendance checker's execution.

## Requirements

- macOS or a compatible Unix-like environment
- Bash
- Python 3
- The `zip` utility
- The three source files inside the `templates/` directory

## How to Run the Script

Open a terminal and navigate to the repository directory:

```bash
cd ~/deploy_agent_DerrickMugire2
```

Make the script executable if necessary:

```bash
chmod +x deploy_agent.sh
```

Run the deployment agent:

```bash
./deploy_agent.sh
```

The script displays a menu:

1. Deploy a new tracker
2. Run an existing tracker
3. Archive attendance logs

Enter the corresponding number and follow the prompts.

## Feature 1: Deploy a New Tracker

Select option `1`.

The script checks its required dependencies and template files, requests a project identifier, and creates a project directory named:

`attendance_tracker_<identifier>`

It creates the `Helpers/` and `reports/` directories and copies the source files from `templates/` into `Helpers/`.

During setup, the user selects a roster option and configures the attendance thresholds when prompted. The script validates the threshold inputs before updating the configuration.

The attendance checker is launched after deployment.

### Threshold Updates

The configuration file contains warning and failure thresholds under the `thresholds` object.

When threshold updates are enabled, the script requests numeric values between 0 and 100 and updates the corresponding values in `Helpers/config.json`.

If threshold updates are declined, the existing configuration values are retained.

## Feature 2: Run an Existing Tracker

Select option `2` and enter the identifier of an existing deployed project.

The script checks that the project's `attendance_checker.py` exists. If found, it launches the application using Python 3. If the file is missing, the script reports an error.

## Feature 3: Archive Attendance Logs

Select option `3` and enter the identifier of the project to archive.

The script looks for these report files:

- `reports/attendance.log`
- `reports/absent.log`

For each log file that exists, the script creates a corresponding archive directory and copies the log using a timestamped filename.

The archive layout is:

```text
attendance_tracker_<identifier>/
└── archives/
    ├── attendance/
    │   └── attendance_<timestamp>.log
    └── absent/
        └── absent_<timestamp>.log
```

The timestamp uses the `YYYYMMDD_HHMMSS` format. The original report files are retained; the script copies them into the archive directories. Missing logs are reported and skipped.

## Ctrl+C and Ctrl+Z Interruption Handling

The deployment script registers a signal handler for `INT` and `TSTP`, corresponding to Ctrl+C and Ctrl+Z in the intended terminal workflow.

When the handler runs during deployment, it attempts to:

1. Display an interruption message.
2. Create a ZIP archive named `attendance_tracker_<identifier>_archive.zip`.
3. Remove the incomplete project directory.
4. Exit with status code 130.

### How to Test Interruption Handling

1. Start the script using `./deploy_agent.sh`.
2. Select deployment.
3. Enter a temporary identifier such as `interruptcheck`.
4. Interrupt the deployment at a prompt after the project directory has been created.
5. Confirm that the interruption message appears.
6. Check whether the ZIP file exists and whether the incomplete directory has been removed.

Use a different temporary identifier for the Ctrl+Z test.

Check the results with:

```bash
ls -lh attendance_tracker_interruptcheck_archive.zip
ls -ld attendance_tracker_interruptcheck
```

Repeat the checks using the identifier chosen for the Ctrl+Z test.

The ZIP archive is intended to contain the incomplete project directory and its contents as they existed when the handler ran. Verify the archive contents before relying on it as a backup.

## Testing the Deployed Application Structure

The project was tested by deploying a tracker, running the attendance checker, exercising the log archiving feature, and testing interruption handling.

To inspect a deployed project, use:

```bash
find attendance_tracker_<identifier> -print
```

Replace `<identifier>` with the identifier used during deployment.

Check that the `Helpers/` directory contains the copied application, CSV, and configuration files. Confirm that the `reports/` directory exists and that generated logs are handled as expected.

The script's Bash syntax can be checked with:

```bash
bash -n deploy_agent.sh
```

No output indicates that Bash did not report a syntax error.

## Run-Through Video

**Video link:** (https://drive.google.com/file/d/1vphsulCGU-p1FEjh_98HuQjhpVBaEwzs/view?usp=drive_link)

The demonstration should cover:

- The purpose and structure of the deployment agent.
- The logic behind each of the three menu options.
- How roster and threshold configuration work.
- How timestamped log archiving works.
- A live demonstration of interrupting deployment with Ctrl+C and Ctrl+Z.
- Verification of the ZIP archive and cleanup behavior.
- A short live marking session showing the deployed application structure.

## Author

Derrick Mugire

GitHub: [DerrickMugire](https://github.com/DerrickMugire)
