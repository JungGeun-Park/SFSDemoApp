#!/bin/bash

workspaceFile="xcworkspace"
projectFile="xcodeproj"
project=""

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Script is expected to be at "AppSealingSDK/Tools"
path="${SCRIPT_DIR}/../.."
fileList=()

projectList () {
    for name in "$path"/*; do
        if [ -d "$name" ] && [ "${name##*.}"x = ${workspaceFile}x ]; then
            fileList+=(${name})
        elif [ -d "$name" ] && [ "${name##*.}"x = ${projectFile}x ]; then
            fileList+=(${name})
        elif [ -d "$name" ]; then
            path=$name
            projectList
        fi
    done
}


projectList
number=${#fileList[@]}


# 🎯 Auto-select if only one
if [ "$number" -eq 1 ]; then
    project="${fileList[0]}"
    echo "✅ Automatically selected project: $project"
else
    echo ""
    echo "****************************************************"
    echo "📦 Multiple Xcode projects found. Please select one:"
    echo "****************************************************"
    for i in "${!fileList[@]}"; do
        echo "$((i+1)). ${fileList[$i]}"
    done
    echo "****************************************************"
    read -p "➡️  Enter the number of the project to use: " choice

    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$number" ]; then
        echo "❌ Invalid selection. Exiting."
        exit 1
    fi

    project="${fileList[$((choice - 1))]}"
    echo "✅ You selected: $project"
fi

project_file=$project/project.pbxproj
echo "Selected project: $project_file"

python3 "${SCRIPT_DIR}/FrameworkIntegrator.py" "$project_file"

echo ""
echo "*************************************"
echo "To Copy and paste Sample code"
echo "*************************************"
echo "🔧 Select a UI framework:"
echo "*************************************"
echo "1. SwiftUI"
echo "2. Swift UIKit"
echo "3. Objective-C UIKit"
echo "*************************************"
read -p "➡️  Enter your choice (1/2/3): " choice

# 🎯 Set file path based on selection
case $choice in
  1)
    file="${SCRIPT_DIR}/integrate_script/Samples/swiftui_template.rtf"
    ;;
  2)
    file="${SCRIPT_DIR}/integrate_script/Samples/swift_uikit_template.rtf"
    ;;
  3)
    file="${SCRIPT_DIR}/integrate_script/Samples/objective-c_uikit_template.rtf"
    ;;
  *)
    echo "❌ Invalid selection. Exiting."
    exit 1
    ;;
esac

# 🎯 Check if file exists
if [ ! -f "$file" ]; then
  echo "📄 File not found: $file"
  exit 1
fi

# ✅ Open the file in TextEdit
open -a TextEdit "$file"
