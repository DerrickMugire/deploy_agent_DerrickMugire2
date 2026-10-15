#!/bin/bash
# Main menu
echo "===== Attendance Tracker ====="
echo "1. Deploy a new tracker"
echo "2. Run an existing tracker"
echo "3. Archive attendance logs"
read -r -p "Choose an option (1-3): " menu_choice
case "$menu_choice" in
    1)
        echo "Starting deployment..."
        ;;
   
    2)
       read -r -p "Enter the project identifier to run: " project_id
    project_dir="attendance_tracker_${project_id}"

    if [ ! -f "$project_dir/attendance_checker.py" ]; then
        echo "Error: Attendance checker not found in $project_dir."
        exit 1
    fi

    cd "$project_dir" || exit 1
    python3 attendance_checker.py
    exit $?
    ;;
    3)
        read -r -p "Enter the project identifier to archive: " project_id
    project_dir="attendance_tracker_${project_id}"
    timestamp=$(date +"%Y%m%d_%H%M%S")

    for log_name in attendance absent; do
        log_file="$project_dir/reports/${log_name}.log"
        archive_dir="$project_dir/archives/$log_name"

        if [ -f "$log_file" ]; then
            mkdir -p "$archive_dir"
            cp "$log_file" "$archive_dir/${log_name}_${timestamp}.log"
            echo "Archived $log_file"
        else
            echo "No $log_name log found; skipping."
        fi
    done
    exit 0
    ;;
    *)
        echo "Error: Choose 1, 2, or 3."
        exit 1
        ;;
esac
# Check that Python 3 is installed

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 to continue."
    exit 1
fi

# Check that zip is installed
if ! command -v zip &> /dev/null; then
    echo "Error: zip is not installed. Please install zip to continue."
    exit 1
fi

# Check that the Python template exists
if [ ! -f "templates/attendance_checker.py" ]; then
    echo "Error: attendance_checker.py template is missing."
    exit 1
fi
# Check that the roster template exists
if [ ! -f "templates/assets.csv" ]; then
    echo "Error: assets.csv template is missing."
    exit 1
fi
# Check that the configuration template exists
if [ ! -f "templates/config.json" ]; then
    echo "Error: config.json template is missing."
    exit 1
fi

# Ask the user for a project identifier
read -r -p "Enter a project identifier: " project_id
if [ -z "$project_id" ]; then
    echo "Error: Project identifier cannot be empty."
    exit 1
fi
# Validate the project identifier
case "$project_id" in
    *" "*|*/*|*\\*)
        echo "Error: Identifier cannot contain spaces or path separators."
        exit 1
        ;;
    *)
        echo "Project identifier is valid."
        ;;
esac



# Create the project directory name
project_dir="attendance_tracker_${project_id}"
# Check whether the project directory already exists
if [ -d "$project_dir" ]; then
 read -r -p "Directory exists. Overwrite it? (y/n): " answer
   case "$answer" in
        [yY])
    echo "Overwrite confirmed."
    rm -r "$project_dir"
    ;;
        *)
            echo "Deployment cancelled."
            exit 1
            ;;
    esac
fi

# Create the project directory structure
mkdir -p "$project_dir/Helpers" "$project_dir/reports"%  
# Handle Ctrl+C and Ctrl+Z during deployment
handle_interrupt() {
    echo
    echo "Deployment interrupted. Archiving incomplete project..."

    if [ -d "$project_dir" ]; then
        zip -r "${project_dir}_archive.zip" "$project_dir"
        rm -rf "$project_dir"
        echo "Incomplete project archived and removed."
    fi

    exit 130
}

trap handle_interrupt INT TSTP                                                   
# Copy the template files into the project
cp "templates/attendance_checker.py" "$project_dir/attendance_checker.py"
cp "templates/assets.csv" "$project_dir/Helpers/assets.csv"
cp "templates/config.json" "$project_dir/Helpers/config.json"

# Set the required file permissions
chmod +x "$project_dir/attendance_checker.py"
chmod 600 "$project_dir/Helpers/config.json"
# Ask the user how to create the roster
echo "Choose a roster option:"
echo "1. Use sample student data"
echo "2. Generate a fresh roster"
read -r -p "Enter choice (1 or 2): " roster_choice
case "$roster_choice" in
    1)
       echo "Sample roster selected."
        read -r -p "How many students do you want (1-10)? " student_count

        if ! [[ "$student_count" =~ ^[0-9]+$ ]] || [ "$student_count" -lt 1 ] || [ "$student_count" -gt 10 ]; then
            echo "Error: Enter a number from 1 to 10."
            exit 1
        fi

        head -n 1 "templates/assets.csv" > "$project_dir/Helpers/assets.csv"
        tail -n +2 "templates/assets.csv" | head -n "$student_count" >> "$project_dir/Helpers/assets.csv"
        ;;
    2)
        echo "Fresh roster selected."

        names=("Alice" "Bob" "Charlie" "Diana" "Eve")
        emails=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "eve@example.com")

        read -r -p "How many students do you want (1-5)? " student_count

        if ! [[ "$student_count" =~ ^[0-9]+$ ]] || [ "$student_count" -lt 1 ] || [ "$student_count" -gt 5 ]; then
            echo "Error: Enter a number from 1 to 5."
            exit 1
        fi

       printf "Email,Names,Attendance Count,Absence Count\n" > "$project_dir/Helpers/assets.csv"

        for ((i=0; i<student_count; i++)); do
            printf "%s,%s,0,0\n" "${emails[$i]}" "${names[$i]}" >> "$project_dir/Helpers/assets.csv"
        done
        sed -i '' 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$project_dir/Helpers/config.json"
        ;;
    *)
        echo "Error: Invalid roster choice."
        exit 1
        ;;
esac
# Ask whether the user wants to update attendance thresholds
read -r -p "Do you want to update attendance thresholds? (y/n): " update_thresholds

case "$update_thresholds" in
    [yY])
        echo "Default warning threshold: 75"
        echo "Default failure threshold: 50"

        read -r -p "Enter warning threshold (0-100): " warning
        read -r -p "Enter failure threshold (0-100): " failure
         if ! [[ "$warning" =~ ^[0-9]+$ ]] || [ "$warning" -gt 100 ]; then
            echo "Error: Warning threshold must be a whole number from 0 to 100."
            exit 1
        fi

        if ! [[ "$failure" =~ ^[0-9]+$ ]] || [ "$failure" -gt 100 ]; then
            echo "Error: Failure threshold must be a whole number from 0 to 100."
            exit 1
        fi
         sed -i '' "s/\"warning\": [0-9]*/\"warning\": $warning/" "$project_dir/Helpers/config.json"
        sed -i '' "s/\"failure\": [0-9]*/\"failure\": $failure/" "$project_dir/Helpers/config.json"

        echo "Attendance thresholds updated."
        ;;
    [nN])
        echo "Keeping default thresholds."
        ;;
    *)
        echo "Error: Please enter y or n."
        exit 1
        ;;
esac
# Confirm successful deployment
echo "Deployment completed successfully!"
echo "Project directory: $project_dir"
# Launch the attendance checker after deployment
cd "$project_dir" || exit 1
python3 attendance_checker.py

