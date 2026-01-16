import sys
import os
import logging
import json
import shutil

# Setup logging
log_file_path = os.path.join(os.path.dirname(__file__), 'app_sealing.log')
logging.basicConfig(
    filename=log_file_path,
    filemode='a',
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def log_and_print(msg, level='info'):
    print(msg)
    getattr(logging, level)(msg)

def revert_project(original, backup):
    if os.path.isfile(backup):
        shutil.copyfile(backup, original)
        log_and_print("🔁 Project reverted to original state due to failure.", level='warning')

# Add integrate_script path for local mod-pbxproj if used
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'integrate_script'))

vendor_path = os.path.join(os.path.dirname(__file__), 'integrate_script/vendor')
if vendor_path not in sys.path:
    sys.path.insert(0, vendor_path)

from pbxproj import XcodeProject
from pbxproj.pbxextensions import FileOptions
from pbxproj.pbxsections import PBXNativeTarget

# --- Load path.config
config_path = os.path.join(os.path.dirname(__file__), 'integrate_script', 'path.config')
try:
    with open(config_path, 'r') as f:
        paths = json.load(f)
        log_and_print("✅ Loaded path.config from integrate_script/")
except Exception as e:
    log_and_print(f"❌ Failed to load path.config: {e}", level='error')
    sys.exit(1)

# --- Get project.pbxproj path from command line
if len(sys.argv) < 2:
    log_and_print("❌ Usage: python install.py <project.pbxproj path>", level='error')
    sys.exit(1)

pbxproj_path = sys.argv[1]
if not os.path.isfile(pbxproj_path):
    log_and_print(f"❌ File not found: {pbxproj_path}", level='error')
    sys.exit(1)

# --- Create backup
backup_path = pbxproj_path + '.bak'
try:
    shutil.copyfile(pbxproj_path, backup_path)
    log_and_print("📦 Backup created for project.pbxproj")
except Exception as e:
    log_and_print(f"❌ Failed to create backup: {e}", level='error')
    sys.exit(1)

# --- Load Xcode project
try:
    project = XcodeProject.load(pbxproj_path)
    log_and_print("✅ Project loaded successfully.")
except Exception as e:
    log_and_print(f"❌ Failed to load project: {e}", level='error')
    sys.exit(1)

# --- List available targets
targets = project.objects.get_objects_in_section('PBXNativeTarget')
if not targets:
    log_and_print("❌ No targets found in PBXNativeTarget section. Exiting.", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

print("\n" + "*" * 60)
print("🌟 AVAILABLE TARGETS 🌟".center(60))
print("*" * 60)

for i, target in enumerate(targets):
    name = target.get('name', 'Unknown Target').strip('"')
    print(f"{i + 1}. {name}")
print("*" * 60)

# --- Select a target
try:
    choice = int(input("➡️  Select the target number to apply 'App Sealing' to: ")) - 1
    if choice < 0 or choice >= len(targets):
        raise ValueError()
except ValueError:
    log_and_print("❌ Invalid selection. Exiting.", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

target_obj = targets[choice]
target_name = target_obj.get('name', 'Unnamed Target').strip('"')
log_and_print(f"🎯 Selected target: {target_name}")

# --- Add AppSealing framework
framework_group = project.get_or_create_group('Frameworks')
try:
    project.add_file(paths["framework_release"], parent=framework_group, force=False,
                     file_options=FileOptions(
                         create_build_files=True,
                         weak=True,
                         embed_framework=True,
                         code_sign_on_copy=True
                     ),
                     target_name=target_name)
    log_and_print("✅ AppSealing framework added.")
except Exception as e:
    log_and_print(f"❌ Failed to add framework: {e}", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

# --- Add LEASection.mm
try:
    project.add_file(paths["lea_section"], force=False,
                     file_options=FileOptions(create_build_files=True, weak=True),
                     target_name=target_name)
    log_and_print("✅ LEASection.mm added.")
except Exception as e:
    log_and_print(f"❌ Failed to add LEASection.mm: {e}", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

# --- Add or update shell script phase
sealing_script = """if [ "${CONFIGURATION}" == "Debug" ]; then
    rm -R "${TARGET_BUILD_DIR}/AppSealingFramework.framework"
    if [[ "${SDKROOT}" == *"Simulator"* ]]; then
        cp -R "${SRCROOT}/AppSealingSDK/Libraries/Debug/AppSealingFramework.xcframework/ios-arm64_x86_64-simulator/AppSealingFramework.framework" "${TARGET_BUILD_DIR}/"
    else
        cp -R "${SRCROOT}/AppSealingSDK/Libraries/Debug/AppSealingFramework.xcframework/ios-arm64/AppSealingFramework.framework" "${TARGET_BUILD_DIR}/"
    fi
fi"""

try:
    found_existing = False
    for phase_id in target_obj.get('buildPhases', []):
        phase = project.objects[phase_id]
        if (phase.get('isa', '') == 'PBXShellScriptBuildPhase' and
            phase.get('name', '').strip('"') == 'AppSealing'):
            phase['shellScript'] = sealing_script
            found_existing = True
            log_and_print("✅ Existing 'AppSealing' run script updated.")
            break

    if not found_existing:
        project.add_run_script(script=sealing_script, target_name=target_name, insert_before_compile=True)
        log_and_print("✅ New 'AppSealing' run script added.")
except Exception as e:
    log_and_print(f"❌ Failed to configure run script: {e}", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

# --- Rename if necessary
for phase in project.objects.get_objects_in_section('PBXShellScriptBuildPhase'):
    if sealing_script in phase.get('shellScript', ''):
        phase['name'] = 'AppSealing'

# --- Build flags
try:
    project.set_flags('ENABLE_USER_SCRIPT_SANDBOXING', 'NO', target_name=target_name)
    project.set_flags('COMBINE_C_AND_OBJC', 'YES', target_name=target_name)
    log_and_print("✅ Xcode build flags updated.")
except Exception as e:
    log_and_print(f"❌ Failed to set build flags: {e}", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)

# --- Ask to add bridging header
print("\n*************************************")
print("📎 Do you want to add the bridging header for Swift?")
print("*************************************")
print("1. Yes")
print("2. No")
print("*************************************")

if input("➡️  Enter your choice (1/2): ").strip() == "1":
    try:
        project.set_flags('SWIFT_OBJC_BRIDGING_HEADER', paths["bridging_header"], target_name=target_name)
        log_and_print(f"✅ Bridging header flag set to: {paths['bridging_header']}")
    except Exception as e:
        log_and_print(f"❌ Failed to set bridging header flag: {e}", level='error')
        revert_project(pbxproj_path, backup_path)
        sys.exit(1)

# --- Save project
try:
    project.save()
    log_and_print(f"✅ Project saved. AppSealing setup complete for target: {target_name}")
    os.remove(backup_path)  # cleanup backup on success
except Exception as e:
    log_and_print(f"❌ Failed to save project: {e}", level='error')
    revert_project(pbxproj_path, backup_path)
    sys.exit(1)
