# 🌐 Memo Notifier - Backend Integration Guide

Complete reference for integrating Memo Notifier with custom backends and APIs.

---

## 📡 Supported Backend Types

### 1. WebSocket (Primary)
**Best for:** Real-time, low-latency updates

```lua
backends = {
	primary = {
		type = "websocket",
		url = "wss://dexapi2.up.railway.app/ws",
		enabled = true,
	}
}
```

**Message Format:**
```
{brainrot_name}|{money_value}|{players_count}|{job_id}
```

**Example Messages:**
```
Burguro And Fryuro|50000000|4|7c8d9e0f-1a2b-3c4d
Dragon Cannelloni|300000000|8|a1b2c3d4-e5f6-7890
La Supreme Combinasion|1000000000|12|x9y8z7w6-v5u4-t3s2
```

**Connection Handling:**
```lua
-- The script auto-reconnects every 5 seconds on failure
-- Status updates in admin panel (LAlt)
```

---

### 2. Firebase Realtime Database (Secondary/Fallback)
**Best for:** Cloud persistence, automatic failover

```lua
backends = {
	secondary = {
		type = "firebase",
		url = "https://autojoiner2-2d181-default-rtdb.firebaseio.com/logs.json",
		enabled = true,
	}
}
```

**Polling Interval:** 2 seconds (configurable via `ui.updateInterval`)

**JSON Response Structure:**
```json
{
  "log_id_1": {
    "jobId": "7c8d9e0f-1a2b-3c4d",
    "name": "Burguro And Fryuro",
    "numValue": 50000000,
    "players": 4,
    "timestamp": 1698765432,
    "placeId": 99606176102979
  },
  "log_id_2": {
    "jobId": "a1b2c3d4-e5f6-7890",
    "name": "Dragon Cannelloni",
    "numValue": 300000000,
    "players": 8,
    "timestamp": 1698765445,
    "placeId": 109983668079237
  }
}
```

---

## 🔗 Adding a Custom Backend

### Step 1: Define Backend in Config
```lua
CONFIG.backends.custom = {
	type = "http",  -- or "websocket" or "firebase"
	url = "https://your-api.com/logs",
	enabled = true,
	authToken = "optional-auth-token",
	headers = {
		["Authorization"] = "Bearer YOUR_TOKEN",
	}
}
```

### Step 2: Create Connection Handler
```lua
function BackendManager:connectCustom()
	task.spawn(function()
		while CONFIG.backends.custom.enabled do
			pcall(function()
				-- Your API call logic here
				local response = game:HttpGet(
					CONFIG.backends.custom.url .. "?t=" .. tick(),
					true
				)
				local data = HttpService:JSONDecode(response)
				
				-- Process data
				if data and type(data) == "table" then
					for k, entry in pairs(data) do
						createLogEntry({
							name = entry.name,
							value = tonumber(entry.value),
							players = entry.players,
							jobId = entry.jobId,
						})
					end
				end
			end)
			
			task.wait(CONFIG.ui.updateInterval)
		end
	end)
end
```

### Step 3: Initialize in Main Script
```lua
if CONFIG.backends.custom.enabled then
	BackendManager:connectCustom()
end
```

---

## 📨 Webhook Integration

### Discord Webhook Logging

Add to Memo Notifier:

```lua
local DISCORD_WEBHOOK = "https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

local function logToDiscord(data)
	task.spawn(function()
		pcall(function()
			local embed = {
				title = "🎯 " .. data.name,
				description = "Value: $" .. formatNumber(data.value) .. "/s",
				color = 11090175, -- Purple
				fields = {
					{
						name = "Players",
						value = tostring(data.players),
						inline = true,
					},
					{
						name = "Job ID",
						value = "`" .. data.jobId .. "`",
						inline = false,
					},
					{
						name = "Timestamp",
						value = "<t:" .. tostring(math.floor(tick())) .. ":F>",
						inline = true,
					},
				},
				footer = {
					text = "Memo Notifier v1.0 | MemoAML",
				},
			}
			
			local payload = HttpService:JSONEncode({
				embeds = { embed }
			})
			
			local request = syn.request or http.request or http_request
			if request then
				request({
					Url = DISCORD_WEBHOOK,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = payload,
				})
			end
		end)
	end)
end

-- Call in createLogEntry:
logToDiscord(data)
```

---

## 🔄 Data Transformation

### From WebSocket to Standardized Format
```lua
local function transformWebSocketData(message)
	local parts = message:split("|")
	return {
		name = parts[1] or "Unknown",
		value = tonumber(parts[2]) or 0,
		players = tonumber(parts[3]) or 0,
		jobId = parts[4] or "",
		timestamp = tick(),
	}
end
```

### From Firebase to Standardized Format
```lua
local function transformFirebaseData(entry)
	return {
		name = entry.name or "Unknown",
		value = tonumber(entry.numValue) or 0,
		players = entry.players or 0,
		jobId = entry.job_id or "",
		timestamp = entry.timestamp or tick(),
	}
end
```

### From Custom API to Standardized Format
```lua
local function transformCustomData(entry)
	return {
		name = entry.brainrot_name or "Unknown",
		value = tonumber(entry.money_per_sec) or 0,
		players = entry.player_count or 0,
		jobId = entry.server_id or "",
		timestamp = tonumber(entry.created_at) or tick(),
	}
end
```

---

## 🔐 Authentication Methods

### API Key Header
```lua
backends = {
	custom = {
		type = "http",
		url = "https://your-api.com/logs",
		headers = {
			["X-API-Key"] = "your-secret-key-here",
		}
	}
}
```

### Bearer Token
```lua
backends = {
	custom = {
		type = "http",
		headers = {
			["Authorization"] = "Bearer eyJhbGc...",
		}
	}
}
```

### Basic Auth
```lua
local username = "admin"
local password = "password"
local encoded = game:GetService("HttpService"):UrlEncode(username .. ":" .. password)

backends = {
	custom = {
		type = "http",
		headers = {
			["Authorization"] = "Basic " .. encoded,
		}
	}
}
```

---

## 📊 Processing Pipeline

```
API Response
    ↓
Transform to Standard Format
    ↓
Apply Filters (blacklist, threshold)
    ↓
Check Duplicates
    ↓
Display in UI
    ↓
Play Sound
    ↓
Log to Discord (optional)
    ↓
Auto-Join (if enabled)
```

---

## 🛡️ Error Handling

### Automatic Fallback
```lua
local function safeHttpGet(url)
	local response = nil
	
	-- Try primary method
	pcall(function()
		response = game:HttpGet(url, true)
	end)
	
	-- Try backup methods
	if not response then
		pcall(function()
			response = syn.request({ Url = url, Method = "GET" }).Body
		end)
	end
	
	if not response then
		pcall(function()
			response = http.request({ Url = url, Method = "GET" }).Body
		end)
	end
	
	return response
end
```

### Rate Limiting
```lua
local lastRequest = 0
local minInterval = 1  -- minimum 1 second between requests

local function throttledRequest(url)
	local now = tick()
	if now - lastRequest < minInterval then
		task.wait(minInterval - (now - lastRequest))
	end
	lastRequest = tick()
	return game:HttpGet(url, true)
end
```

---

## 📈 Performance Optimization

### Connection Pooling
```lua
local connections = {}

local function getConnection(key)
	if not connections[key] then
		connections[key] = {
			created = tick(),
			data = nil,
		}
	end
	return connections[key]
end
```

### Caching Strategy
```lua
local cache = {
	entries = {},
	ttl = 60,  -- 60 seconds
}

local function getCached(key)
	if cache.entries[key] then
		if tick() - cache.entries[key].time < cache.ttl then
			return cache.entries[key].value
		end
	end
	return nil
end

local function setCached(key, value)
	cache.entries[key] = {
		value = value,
		time = tick(),
	}
end
```

### Memory Management
```lua
-- Clean up old connections periodically
task.spawn(function()
	while true do
		task.wait(300)  -- Every 5 minutes
		local now = tick()
		for key, conn in pairs(connections) do
			if now - conn.created > 600 then  -- 10 minute timeout
				connections[key] = nil
			end
		end
	end
end)
```

---

## 🧪 Testing Backends

### Test WebSocket Connection
```lua
local function testWebSocket()
	local success = false
	task.spawn(function()
		pcall(function()
			local ws = syn.websocket.connect("wss://dexapi2.up.railway.app/ws")
			ws.OnMessage:Connect(function(msg)
				print("[WebSocket] Received:", msg)
				success = true
			end)
		end)
	end)
	task.wait(5)
	return success
end

print("WebSocket Test:", testWebSocket() and "✅ PASS" or "❌ FAIL")
```

### Test Firebase Connection
```lua
local function testFirebase()
	local success = false
	pcall(function()
		local url = "https://autojoiner2-2d181-default-rtdb.firebaseio.com/logs.json?limitToLast=1"
		local response = game:HttpGet(url, true)
		if response then
			success = true
		end
	end)
	return success
end

print("Firebase Test:", testFirebase() and "✅ PASS" or "❌ FAIL")
```

---

## 🔌 API Response Examples

### Working WebSocket Message
```
Burguro And Fryuro|50000000|4|7c8d9e0f-1a2b-3c4d
```

### Working Firebase Response
```json
{
  "-abc123": {
    "jobId": "7c8d9e0f-1a2b-3c4d",
    "name": "Burguro And Fryuro",
    "numValue": 50000000,
    "players": 4
  }
}
```

### Error Response
```json
{
  "error": "Permission denied"
}
```

---

## 📚 Additional Resources

- **DEX API Docs:** `https://dexapi.docs/` (if available)
- **Firebase Docs:** `https://firebase.google.com/docs`
- **Roblox HTTP Guide:** Built into Roblox LuaU

---

**Last Updated:** January 2026  
**Memo Notifier Version:** 1.0
