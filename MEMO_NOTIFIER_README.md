# 🎯 MEMO NOTIFIER v1.0

A high-performance, dual-backend notification system for **Steal a Brainrot** with professional UI, real-time logging, and advanced filtering capabilities.

**Built by:** Guillermo (MemoAML) | **Community:** TITAN.GG & MAJORX

---

## 📋 Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Backends](#backends)
5. [Hotkeys](#hotkeys)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

---

## ✨ Features

### Core Features
- ✅ **Dual Backend Support** - WebSocket (primary) + Firebase (fallback)
- ✅ **Real-time Notifications** - Instant detection of high-value drops
- ✅ **Professional UI** - Clean, modern, draggable interface
- ✅ **Persistent Logging** - Up to 200 log entries with retention
- ✅ **Smart Filtering** - Blacklist, threshold, and value-based filtering
- ✅ **Sound Alerts** - Customizable notification sounds
- ✅ **Admin Panel** - Settings management with live updates
- ✅ **Auto-Join/Force** - Automatic server joining capabilities
- ✅ **Color-Coded Values** - Visual representation of money values

### Backend Features
- **WebSocket (Primary)**
  - Low-latency real-time updates
  - Direct connection to DEX API
  - Fallback to Firebase if disconnected

- **Firebase (Secondary)**
  - Cloud-based logging
  - Automatic retry on connection loss
  - Poll-based updates every 2 seconds

---

## 📥 Installation

### Prerequisites
- Roblox Executor (with WebSocket support recommended)
- Game access to "Steal a Brainrot"

### Step 1: Load the Script
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/memo-notifier/main/memo_notifier.lua"))()
```

### Step 2: Load Admin Panel (Optional)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/memo-notifier/main/memo_notifier_admin.lua"))()
```

### Step 3: First Run
- Script initializes automatically
- Main window appears in center of screen
- Admin panel loads in background
- Backends connect within 2-5 seconds

---

## ⚙️ Configuration

### Config Structure
```lua
CONFIG = {
	backends = {
		primary = {
			type = "websocket",
			url = "wss://dexapi2.up.railway.app/ws",
			enabled = true,
		},
		secondary = {
			type = "firebase",
			url = "https://autojoiner2-2d181-default-rtdb.firebaseio.com/logs.json",
			enabled = true,
		},
	},
	ui = {
		soundEnabled = true,
		soundId = "rbxassetid://4590662766",
		toggleKey = Enum.KeyCode.RightControl,
		updateInterval = 2, -- seconds
	},
	filters = {
		autoJoin = false,
		autoForce = false,
		threshold = 10000000,
		blacklist = {},
	},
	display = {
		maxLogSize = 200,
		logRetentionTime = 600, -- seconds
		animationSpeed = 0.35,
	},
}
```

### Configuration Files
- **Auto-saved location:** `MemoNotifier_Config.json`
- **Save interval:** Every 10 seconds
- **Persists:**
  - Toggle states
  - Backend settings
  - Filter blacklist
  - Custom thresholds

---

## 🌐 Backends

### Primary Backend: WebSocket

**URL:** `wss://dexapi2.up.railway.app/ws`

**Data Format:**
```
{name}|{value}|{players}|{jobId}
```

**Example:**
```
Burguro And Fryuro|50000000|4|7c8d9e0f-1a2b-3c4d
```

**Connection Status:**
- 🟢 **Connected** - Active WebSocket
- 🟡 **Reconnecting** - Attempting to restore
- 🔴 **Disconnected** - Fallback to Firebase

### Secondary Backend: Firebase

**URL:** `https://autojoiner2-2d181-default-rtdb.firebaseio.com/logs.json`

**Data Format (JSON):**
```json
{
  "key_id": {
    "jobId": "7c8d9e0f-1a2b-3c4d",
    "name": "Burguro And Fryuro",
    "numValue": 50000000,
    "players": 4,
    "timestamp": 1698765432
  }
}
```

**Poll Interval:** 2 seconds (configurable)

---

## 🎮 Hotkeys

| Key | Action | Notes |
|-----|--------|-------|
| `RightControl` | Toggle Main Window | Hides/shows log window |
| `LeftAlt` | Toggle Admin Panel | Opens settings menu |

### Customizing Hotkeys
Edit in config:
```lua
ui = {
	toggleKey = Enum.KeyCode.RightControl,  -- Change this
}
```

---

## 🎨 Customization

### Color Scheme

Modify the `COLORS` table in `memo_notifier.lua`:
```lua
COLORS = {
	accent_primary = Color3.fromRGB(110, 80, 255),  -- Purple (Dex)
	accent_secondary = Color3.fromRGB(0, 180, 255), -- Blue
	accent_success = Color3.fromRGB(45, 210, 110),  -- Green
	-- ... more colors
}
```

### Value-Based Coloring

The script automatically colors log entries based on value tiers:

| Value Range | Color | Hex |
|---|---|---|
| ≥ $1T | Orange | `#FF8232` |
| ≥ $1B | Gold | `#FFD700` |
| ≥ $300M | Purple | `#965AFF` |
| ≥ $100M | Red | `#FF5050` |
| ≥ $50M | Light Blue | `#50B4FF` |
| ≥ $10M | Green | `#32DC78` |

### Custom Sound

Replace the sound ID in config:
```lua
ui = {
	soundId = "rbxassetid://YOUR_SOUND_ID",
	soundEnabled = true,
}
```

---

## 📊 Data Management

### Log Retention
- **Max entries:** 200 concurrent logs
- **Auto-cleanup:** After 10 minutes (600 seconds)
- **Memory-safe:** Older entries automatically purged

### Blacklist Management
Blacklist entries in admin panel or directly:
```lua
CONFIG.filters.blacklist["Burguro And Fryuro"] = true
```

Blacklisted items won't appear in logs or trigger notifications.

---

## 🔧 Troubleshooting

### Issue: No logs appearing

**Cause:** Backends not connected

**Solution:**
1. Check `Status: Disconnected` in admin panel
2. Press `LAlt` to open admin
3. Verify both backends are enabled (toggle switches ON)
4. Wait 5-10 seconds for reconnection
5. Check executor console for error messages

### Issue: Sound not playing

**Cause:** Sound disabled or invalid sound ID

**Solution:**
1. Open admin panel (`LAlt`)
2. Enable "Enable Notifications" toggle
3. Verify sound ID is valid (test with known asset)
4. Check system volume

### Issue: High memory usage

**Cause:** Log retention too high or memory leak

**Solution:**
1. Reduce `maxLogSize` in config (default: 200)
2. Reduce `logRetentionTime` (default: 600 seconds)
3. Click "Clear Logs" in admin panel
4. Restart script

### Issue: Executor crash

**Cause:** Malformed data from backend

**Solution:**
1. Disable problematic backend temporarily
2. Check backend URLs are correct
3. Restart executor
4. Report error in Discord

---

## 🐛 Debug Mode

Enable verbose logging:
```lua
DEBUG = true  -- Add to top of script
```

This will print:
- Backend connection attempts
- Data parsing logs
- UI element creation
- Configuration save/load events

---

## 📝 Configuration Examples

### Aggressive Auto-Joiner
```lua
CONFIG.filters = {
	autoJoin = true,
	threshold = 1000000,  -- $1M minimum
}
```

### Chill Monitor (No Auto-Join)
```lua
CONFIG.filters = {
	autoJoin = false,
	autoForce = false,
	soundEnabled = true,
}
```

### Specific Blacklist
```lua
CONFIG.filters.blacklist = {
	["Noobini Pizzanini"] = true,
	["Common Item"] = true,
}
```

---

## 🔐 Privacy & Safety

- ✅ No data collection from your account
- ✅ Runs entirely client-side (except WebSocket/Firebase)
- ✅ No personal information transmitted
- ✅ Config saved locally in executor directory
- ✅ No ban risk (passive monitoring only)

---

## 📞 Support

### Discord Community
- **Server:** [TITAN.GG](https://discord.gg/TITAN-GG)
- **Issues:** Report in #support channel
- **Suggestions:** Post in #feature-requests

### GitHub
- **Repository:** [memo-notifier](https://github.com/YourUsername/memo-notifier)
- **Issues:** Create GitHub issue
- **Discussions:** Start discussion thread

---

## 🎁 Credits & Thanks

- **Developer:** Guillermo (MemoAML)
- **Community:** TITAN.GG Gaming League
- **API Providers:** DEX API, Firebase
- **Inspired by:** Chocola Notifier, DEX Notifier

---

## 📄 License

This script is provided as-is for educational purposes within the Roblox community. Use responsibly and follow Roblox Terms of Service.

---

**Version:** 1.0  
**Last Updated:** January 2026  
**Compatibility:** All major Roblox executors with WebSocket support

---

## 🚀 Roadmap

- [ ] Custom webhook logging
- [ ] Database integration
- [ ] Multi-window support
- [ ] Advanced filtering UI
- [ ] Statistics dashboard
- [ ] Mobile app companion

---

**Enjoy!** 🎉
