# Copilot Instructions for ConVarSuppression SourceMod Plugin

## Repository Overview

This repository contains **ConVarSuppression**, a SourceMod plugin that allows server administrators to suppress console variable (ConVar) change notifications from being displayed to clients. The plugin provides commands to selectively hide specific ConVar changes while still allowing the changes to take effect on the server.

**Key Purpose**: Prevent spam from ConVar changes in client consoles while maintaining server functionality.

## Technical Environment

- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11+ (as specified in sourceknight.yaml)
- **Build System**: SourceKnight (Python-based SourceMod build tool)
- **Compiler**: SourcePawn Compiler (spcomp) via SourceKnight
- **Dependencies**: 
  - SourceMod 1.11.0-git6934+
  - MultiColors plugin for colored chat output

## Project Structure

```
/
├── .github/
│   ├── workflows/ci.yml          # GitHub Actions CI/CD pipeline
│   └── dependabot.yml           # Dependency update automation
├── addons/sourcemod/scripting/
│   └── ConVarSuppression.sp     # Main plugin source code
├── sourceknight.yaml           # Build configuration
└── .gitignore                  # Git ignore rules
```

## Build System & Workflow

### SourceKnight Configuration
The project uses SourceKnight (configured in `sourceknight.yaml`) which:
- Downloads SourceMod 1.11.0-git6934 automatically
- Downloads MultiColors dependency from GitHub
- Compiles the plugin to `/addons/sourcemod/plugins`
- Manages dependencies and build artifacts

### Building the Plugin
```bash
# Install SourceKnight (Python package)
pip install sourceknight

# Build the plugin
sourceknight build

# Output will be in .sourceknight/package/addons/sourcemod/plugins/
```

### CI/CD Pipeline
- **Trigger**: Push, PR, or manual dispatch
- **Process**: Build → Package → Create release artifacts
- **Artifacts**: Compiled .smx files packaged as tar.gz
- **Releases**: Automatic release creation for tags and latest commits

## Code Style & Standards

### SourcePawn Best Practices for This Project
```sourcepawn
#pragma semicolon 1
#pragma newdecls required

// Use StringMap instead of Handle/CreateTrie()
StringMap g_MapConVars;

// Prefer delete over CloseHandle() and set to null
delete g_MapConVars;
g_MapConVars = new StringMap();

// Global variable naming
Handle g_hGlobalTrie = INVALID_HANDLE;  // Current (legacy)
StringMap g_MapConVars;                 // Preferred

// Function naming: PascalCase
public Action OnSupressConVar(int client, int argc)

// Local variables: camelCase  
char sCommand[256];
int iValue;
```

### Memory Management Rules
- **CRITICAL**: Never use `.Clear()` on StringMap/ArrayList - creates memory leaks
- Always use `delete` to properly free memory, then create new instances
- No need to check for null before using `delete`
- Use `delete` instead of `CloseHandle()` for modern SourceMod

### String and Data Handling
- Use `StringMap` instead of deprecated `Trie` functions
- Escape all SQL strings if database functionality is added
- Use translation files for user-facing messages
- Implement proper error handling for all API calls

## Plugin Architecture

### Core Components
1. **Event Handling**: Hooks `server_cvar` event to intercept ConVar changes
2. **Storage**: Uses Handle/Trie (should be upgraded to StringMap)
3. **Commands**: Admin commands for managing suppressed ConVars
4. **Logging**: Action logging for administrative changes

### Key Functions
- `OnPluginStart()`: Initialize storage and register commands/events
- `Event_ServerCvar()`: Core logic to suppress ConVar notifications
- `OnSupressConVar()`: Admin command to add/remove ConVar suppression
- `OnResetConVar()`: Admin command to clear all suppressions

### Current Architecture Issues to Address
```sourcepawn
// Current (problematic):
Handle g_hGlobalTrie = INVALID_HANDLE;
g_hGlobalTrie = CreateTrie();
ClearTrie(g_hGlobalTrie);  // Memory leak!

// Should be:
StringMap g_ConVarMap;
g_ConVarMap = new StringMap();
delete g_ConVarMap;  // Proper cleanup
g_ConVarMap = new StringMap();  // Recreate
```

## Development Guidelines

### Making Changes
1. **Minimal Modifications**: Only change what's necessary for the specific issue
2. **Test Locally**: Use a SourceMod development server for testing
3. **Memory Safety**: Always consider memory allocation/deallocation
4. **Performance**: Plugin runs on game server tick - optimize accordingly

### Adding Features
- New ConVar suppression features should follow the existing pattern
- Add proper admin permission checks (ADMFLAG_ROOT)
- Include comprehensive error handling
- Log administrative actions for audit trails
- Use translation files for any new user messages

### Code Review Checklist
- [ ] No memory leaks (proper delete usage)
- [ ] No hardcoded strings (use #define or translations)
- [ ] Proper error handling for all API calls
- [ ] Admin permission checks for sensitive operations
- [ ] Action logging for administrative changes
- [ ] Performance impact consideration

## Dependencies & Integration

### MultiColors Plugin
- Provides colored chat functionality via `CReplyToCommand()`
- Required for proper message formatting
- Automatically downloaded by SourceKnight

### SourceMod Integration
- Hooks into SourceMod's event system
- Uses SourceMod's admin system for permissions
- Integrates with SourceMod's logging system

## Testing & Validation

### Local Testing Setup
1. Set up a local Source engine game server
2. Install SourceMod 1.11+
3. Install MultiColors plugin
4. Load the compiled ConVarSuppression plugin
5. Test admin commands and ConVar suppression functionality

### Test Cases
- Verify ConVar suppression works for added ConVars
- Test admin command permissions and error handling
- Validate memory management (no leaks during suppression operations)
- Check logging functionality for audit compliance

## Common Patterns & Solutions

### Adding New ConVar to Suppress
```sourcepawn
// In OnSupressConVar command:
SetTrieValue(g_hGlobalTrie, sConVarName, 1, true);
// Should be updated to:
g_ConVarMap.SetValue(sConVarName, true, true);
```

### Checking if ConVar is Suppressed
```sourcepawn
// Current pattern:
return (GetTrieValue(g_hGlobalTrie, sConVarName, iValue) && iValue) ? Plugin_Handled : Plugin_Continue;
// Should be updated to:
bool bSuppressed;
return (g_ConVarMap.GetValue(sConVarName, bSuppressed) && bSuppressed) ? Plugin_Handled : Plugin_Continue;
```

### Error Handling Pattern
```sourcepawn
if (!GetCmdArg(argNum, buffer, sizeof(buffer))) {
    CReplyToCommand(client, "%s Error retrieving argument", PLUGIN_PREFIX);
    return Plugin_Handled;
}
```

## Troubleshooting

### Common Build Issues
- **SourceKnight not found**: Install with `pip install sourceknight`
- **Missing dependencies**: SourceKnight handles automatic dependency download
- **Compilation errors**: Check SourcePawn syntax and SourceMod version compatibility

### Runtime Issues
- **Plugin not loading**: Verify SourceMod version (1.11+) and dependencies
- **ConVar suppression not working**: Check event hook registration and Trie operations
- **Admin commands not accessible**: Verify admin permissions (ADMFLAG_ROOT required)

### Memory-Related Issues
- **Server performance degradation**: Check for memory leaks, update to StringMap
- **Plugin unload errors**: Ensure proper cleanup in OnPluginEnd()

## Version Control & Releases

### Semantic Versioning
- Follow format: MAJOR.MINOR.PATCH
- Update `PLUGIN_VERSION` in source code
- Create git tags for releases
- CI automatically creates release artifacts

### Contributing
- Make minimal, focused changes
- Test thoroughly on development server
- Follow existing code style and patterns
- Update documentation if adding new features

## Performance Considerations

### Critical Performance Areas
- `Event_ServerCvar()`: Called for every ConVar change - must be optimized
- StringMap operations: Use proper key types and avoid unnecessary operations
- Memory allocation: Minimize allocations in frequently called functions

### Optimization Guidelines
- Cache frequently accessed data
- Use efficient data structures (StringMap over Handle/Trie)
- Avoid string operations in tight loops
- Consider the impact on server tick rate (64+ tick servers)