# Absolute path to your Mod Organizer install directory.
MO = "C:\\Program Files (x86)\\Mod Organizer"

# Path to a temp folder used for copying mods.
# If you change this after running provision_char, make sure you delete the old
# folder.
TEMP = File.join(MO, "temp")

# Mods folder in your Mod Organizer install
MODS = File.join(MO, "mods")

# Profiles folder in your Mod Organizer install
PROFILES = File.join(MO, "profiles")

# Location of the ModOrganizer.ini in your Mod Organizer install.
MO_INI = File.join(MO, "ModOrganizer.ini")

# delete_profile will backup your ModOrganizer.ini to this location.
BACKUP_MO_INI = "#{MO_INI}.backup"

# Base profiles that must be safe to edit. Any profile other than these may
# cause side effects on other profiles when edited.
# May not be safe to change to a profile that has already been merged.
BASE_PROFILES = [
  "SHARED",
  "BASE"
]

# A profile to select when profile selection needs to change. This must always
# exist.
DEFAULT_PROFILE = "BASE"

# Set to true for less reliable, but faster, profile provisioning.
COPY_IF_NEEDED = false

# Default source to provision profiles from.
DEFAULT_SOURCE = "BASE"