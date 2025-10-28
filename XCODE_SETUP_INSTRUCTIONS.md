# Xcode Project Setup Instructions

## Overview
The old PBP system has been **completely removed** and replaced with the new system. You need to add the new files to your Xcode project and remove references to old files.

## Files to Remove from Xcode Project

These files have been deleted and need to be removed from Xcode:

1. **SHL/Network/Models/Match/PBPEvents.swift** - ❌ Deleted (old adapter system)
2. **SHL/Components/PBPView.swift** - ❌ Deleted (old view component)

### How to Remove:
1. Open Xcode
2. In Project Navigator, locate these files (they'll appear in red)
3. Right-click each file → "Delete" → "Remove Reference" (NOT "Move to Trash")

## Files to Add to Xcode Project

These new files need to be added:

### PBP Models (4 files)
Location: `SHL/Network/Models/PBP/`

1. ✅ **PBPSupporting.swift**
2. ✅ **PBPEventData.swift**
3. ✅ **PBPEventDTO.swift**
4. ✅ **PBPController.swift**

### View Component (1 file)
Location: `SHL/Components/`

5. ✅ **PBPEventRowView.swift**

## Step-by-Step Instructions

### Step 1: Open Your Project
```bash
open /Users/snow/Documents/xcode/SHL/SHL.xcodeproj
```

### Step 2: Remove Old File References

1. In Project Navigator, expand `SHL → Network → Models → Match`
2. Look for **PBPEvents.swift** (will appear in red/dimmed)
3. Right-click → Delete → **Remove Reference Only**

4. In Project Navigator, expand `SHL → Components`
5. Look for **PBPView.swift** (will appear in red/dimmed)
6. Right-click → Delete → **Remove Reference Only**

### Step 3: Add New PBP Model Files

1. In Project Navigator, right-click on **`SHL/Network/Models/`**
2. Select **"Add Files to 'SHL'..."**
3. Navigate to: `/Users/snow/Documents/xcode/SHL/SHL/Network/Models/PBP/`
4. Select **all 4 files**:
   - PBPSupporting.swift
   - PBPEventData.swift
   - PBPEventDTO.swift
   - PBPController.swift
5. **Important settings**:
   - ✅ **Target: SHL** (make sure it's checked)
   - ❌ **"Copy items if needed"** (UNCHECK - files are already in place)
   - **"Create groups"** (selected by default)
6. Click **"Add"**

### Step 4: Add New View Component

1. In Project Navigator, right-click on **`SHL/Components/`**
2. Select **"Add Files to 'SHL'..."**
3. Navigate to: `/Users/snow/Documents/xcode/SHL/SHL/Components/`
4. Select **PBPEventRowView.swift**
5. **Important settings**:
   - ✅ **Target: SHL** (make sure it's checked)
   - ❌ **"Copy items if needed"** (UNCHECK)
   - **"Create groups"** (selected by default)
6. Click **"Add"**

### Step 5: Verify File Organization

Your project structure should now look like:

```
SHL/
├── Network/
│   ├── Models/
│   │   ├── Match/
│   │   │   ├── Match.swift
│   │   │   ├── LiveMatch.swift
│   │   │   ├── MatchStats.swift
│   │   │   └── (PBPEvents.swift - REMOVED)
│   │   └── PBP/                    ← NEW FOLDER
│   │       ├── PBPSupporting.swift
│   │       ├── PBPEventData.swift
│   │       ├── PBPEventDTO.swift
│   │       └── PBPController.swift
│   └── API/
│       ├── SHLAPIClient.swift      (updated)
│       └── SHLAPIService.swift
├── ViewModels/
│   └── MatchViewModel.swift        (updated)
├── Views/
│   └── MatchView.swift             (updated)
└── Components/
    ├── (PBPView.swift - REMOVED)
    └── PBPEventRowView.swift       ← NEW FILE
```

### Step 6: Clean Build Folder

Before building, clean the build folder:

1. In Xcode menu: **Product → Clean Build Folder** (or ⌘ + Shift + K)
2. Wait for cleaning to complete

### Step 7: Build Project

1. Select your target device/simulator
2. Press **⌘ + B** to build
3. All errors should be resolved!

## Common Issues & Solutions

### Issue: "Cannot find type 'PBPEventDTO' in scope"
**Solution**: Make sure you added all 4 PBP model files and they're in the SHL target.

### Issue: Files appear in red/dimmed in Xcode
**Solution**:
1. Select the file in Project Navigator
2. In File Inspector (right panel), check the file path
3. If wrong, use "Location" dropdown to relocate the file

### Issue: "PBPController" not found
**Solution**:
1. Select PBPController.swift in Project Navigator
2. In File Inspector, verify "Target Membership" includes "SHL" checkbox

### Issue: Build succeeds but app crashes
**Solution**: Make sure your backend API is updated to return the new DTO format. Check the backend branch:
- Repository: `KibbeWater/SHLBackend`
- Branch: `fix/pbp-rework`

## Verification Checklist

After completing all steps, verify:

- [ ] Old files removed from Xcode (not showing in Project Navigator)
- [ ] New PBP folder appears under `Network/Models/`
- [ ] All 4 PBP model files show in Project Navigator (not red)
- [ ] PBPEventRowView.swift shows under Components (not red)
- [ ] Build succeeds without errors (⌘ + B)
- [ ] No import errors for new types
- [ ] MatchView properly references PBPEventRowView

## What Changed

### Removed Files
- `PBPEvents.swift` - Old backend adapter with HockeyKit compatibility layer
- `PBPView.swift` - Old view component rendering events

### Added Files
- `PBPSupporting.swift` - Supporting types (PlayerSummary, TeamSummary, etc.)
- `PBPEventData.swift` - Rich event-specific data structures
- `PBPEventDTO.swift` - Main DTO with dynamic EventData enum
- `PBPController.swift` - Powerful controller with 30+ utility methods
- `PBPEventRowView.swift` - New view component with dedicated row types

### Modified Files
- `SHLAPIClient.swift` - Simplified to only return new DTOs
- `MatchViewModel.swift` - Removed old `pbp` property, only uses `pbpController`
- `MatchView.swift` - Removed all fallback logic, uses new system exclusively

## Next Steps After Setup

1. **Test with Live Data**: Run the app and navigate to a match to see PBP events
2. **Verify Backend**: Ensure your backend API is serving the new format
3. **Review Implementation**: Check `PBP_IMPLEMENTATION_SUMMARY.md` for API usage

## Support

If you encounter issues:
1. Double-check all files are in the correct locations
2. Verify target membership for all new files
3. Clean build folder and try again
4. Check the backend API is returning new format

---

**Setup Time**: ~5 minutes
**Difficulty**: Easy
**Status**: Ready for implementation
