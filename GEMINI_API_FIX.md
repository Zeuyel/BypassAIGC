# Gemini API Fix - Version 1.32 Update

## Summary

This update addresses critical issues with the Gemini API integration and adds configuration options to prevent API blocking errors.

## Issues Fixed

### 1. Gemini API Streaming Block Error

**Problem**: When using Gemini API in streaming mode, users encountered "Your request was blocked" (PermissionDeniedError) errors, causing processing failures.

**Solution**: 
- Added `USE_STREAMING` configuration option (default: `false`)
- Modified `optimization_service.py` to respect the streaming mode setting
- System now defaults to non-streaming mode to avoid API blocks
- Admin can toggle streaming mode via the admin panel

### 2. Admin Configuration Management

**Problem**: No easy way to switch between streaming and non-streaming modes without editing the `.env` file.

**Solution**:
- Added streaming mode toggle in the ConfigManager component
- Added visual toggle switch in admin dashboard
- Configuration changes apply immediately without server restart

### 3. Documentation Gap

**Problem**: Users weren't aware of the streaming mode issue or how to configure it.

**Solution**:
- Updated README with streaming mode configuration details
- Added troubleshooting section for Gemini API blocking errors
- Added troubleshooting section for login issues
- Updated configuration table with USE_STREAMING setting

## Changes Made

### Backend Changes

#### 1. `/backend/app/config.py`
- Added `USE_STREAMING: bool = False` setting
- Defaults to non-streaming mode to prevent API blocks

#### 2. `/backend/app/services/optimization_service.py`
- Updated `execute_call()` function to use `settings.USE_STREAMING` instead of hardcoded `True`
- Now respects the global streaming configuration
- Comment added explaining the default non-streaming mode

#### 3. `/backend/app/routes/admin.py`
- Added `use_streaming` to the system configuration response
- Exposes streaming mode setting via `/api/admin/config` endpoint

### Frontend Changes

#### 1. `/frontend/src/components/ConfigManager.jsx`
- Added `USE_STREAMING` to form data state
- Added visual toggle switch for streaming mode in the UI
- Added proper handling of boolean value when saving config
- Fixed compression model loading path from API response
- Added helpful description text explaining the setting

### Documentation Changes

#### 1. `/README.md`
- Added `USE_STREAMING=false` to configuration example
- Added note about streaming mode in configuration section
- Added troubleshooting Q&A for "Your request was blocked" error
- Added troubleshooting Q&A for "Not Found" login error
- Updated core configuration table with USE_STREAMING setting
- Added note about streaming mode being disabled by default

## Configuration

### New Environment Variable

```bash
# Flow streaming output configuration (recommended to keep default)
USE_STREAMING=false  # Default: false to avoid API blocking
```

### Admin Panel Configuration

1. Navigate to Admin Dashboard: `http://localhost:3000/admin`
2. Go to "System Configuration" tab
3. Find "流式输出模式" (Streaming Output Mode) toggle
4. Toggle to enable/disable streaming mode
5. Click "Save Configuration"

## Usage Recommendations

### For Gemini API Users (Recommended)
- Keep `USE_STREAMING=false` (default)
- This prevents "Your request was blocked" errors
- Processing will complete successfully without streaming

### For Other OpenAI-Compatible APIs
- Can set `USE_STREAMING=true` if the API supports streaming
- Streaming provides real-time progress updates
- Better user experience with live text generation

## Migration Guide

### For Existing Users

No migration needed! The default configuration is already set to prevent issues:

1. **If you're using Gemini API**: No action required. The system defaults to non-streaming mode.

2. **If you want to enable streaming** (for compatible APIs):
   - Option A: Add `USE_STREAMING=true` to your `.env` file
   - Option B: Enable via admin panel (System Configuration → Streaming Output Mode)

### For New Installations

Simply follow the standard installation process. The new default configuration will work out of the box.

## Technical Details

### How It Works

1. **Configuration Loading**:
   - Settings loaded from `.env` file via pydantic-settings
   - `USE_STREAMING` defaults to `False` if not specified

2. **Runtime Behavior**:
   - `OptimizationService._process_stage()` checks `settings.USE_STREAMING`
   - If `False`: Uses `ai_service.complete()` (non-streaming)
   - If `True`: Uses `ai_service.stream_complete()` (streaming)

3. **Admin Configuration**:
   - Admin can change setting via API endpoint
   - Changes saved to `.env` file
   - Settings reloaded automatically using `reload_settings()`

### Compatibility

- ✅ Gemini API (2.5 Pro) - Works with `USE_STREAMING=false`
- ✅ OpenAI API - Works with both modes
- ✅ Other OpenAI-compatible APIs - Varies by implementation

## Testing

### To Test Non-Streaming Mode (Default)
1. Ensure `.env` has `USE_STREAMING=false` or omit the setting
2. Start a text optimization task
3. Verify no "Your request was blocked" errors occur
4. Task should complete successfully

### To Test Streaming Mode
1. Set `USE_STREAMING=true` in `.env` or admin panel
2. Start a text optimization task
3. If using compatible API, should see real-time updates
4. If using Gemini, may encounter blocking errors (as expected)

## Known Issues & Limitations

### Login "Not Found" Error
This issue is mentioned in the problem statement but appears to be environmental rather than code-related. The login route is correctly configured:
- Route: `/api/admin/login` (POST)
- Properly registered in `main.py`
- Uses standard FastAPI authentication

**Troubleshooting Steps**:
1. Verify backend is running: Check `http://localhost:8000/health`
2. Check frontend API configuration points to correct backend
3. Clear browser cache
4. Verify `.env` file has correct `SECRET_KEY`
5. Check browser console for detailed error messages

## Future Improvements

1. Per-session streaming mode selection
2. Automatic detection of API streaming support
3. Fallback mechanism when streaming fails
4. More granular streaming configuration per model type

## Support

If you encounter issues:
1. Check the troubleshooting section in README.md
2. Verify your configuration matches the recommendations
3. Check backend logs for detailed error messages
4. Open an issue on GitHub with:
   - Your configuration (API type, streaming mode)
   - Error messages from backend logs
   - Steps to reproduce

## Version Information

- **Version**: 1.32+
- **Date**: 2024-12-08
- **Compatibility**: Backward compatible with version 1.31 and earlier
