-- ============================================================================
--  MEMO NOTIFIER v1.0
--  A high-performance notification system for Steal a Brainrot
--  Built by Guillermo (MemoAML)
--  Discord: https://discord.gg/TITAN-GG
-- ============================================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Backend APIs
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

	-- UI Settings
	ui = {
		theme = "dark",
		soundEnabled = true,
		soundId = "rbxassetid://4590662766",
		toggleKey = Enum.KeyCode.RightControl,
		updateInterval = 2,
	},

	-- Filter Settings
	filters = {
		autoJoin = false,
		autoForce = false,
		threshold = 10000000,
		blacklist = {},
	},

	-- Display Settings
	display = {
		maxLogSize = 200,
		logRetentionTime = 600, -- seconds
		animationSpeed = 0.35,
	},
}

-- ============================================================================
-- COLOR PALETTE
-- ============================================================================

local COLORS = {
	-- Background
	bg_dark = Color3.fromRGB(8, 11, 16),
	bg_mid = Color3.fromRGB(12, 16, 24),
	bg_card = Color3.fromRGB(18, 22, 32),

	-- Accents
	accent_primary = Color3.fromRGB(110, 80, 255), -- Dex Purple
	accent_secondary = Color3.fromRGB(0, 180, 255), -- Neon Blue
	accent_success = Color3.fromRGB(45, 210, 110),
	accent_warning = Color3.fromRGB(255, 160, 30),
	accent_danger = Color3.fromRGB(240, 70, 90),

	-- Text
	text_primary = Color3.fromRGB(245, 245, 250),
	text_secondary = Color3.fromRGB(150, 160, 180),
	text_muted = Color3.fromRGB(110, 120, 140),

	-- Borders
	border_normal = Color3.fromRGB(35, 40, 55),
	border_hover = Color3.fromRGB(55, 65, 90),
}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local STATE = {
	isConnected = false,
	connectionStatus = "Idle",
	totalDetected = 0,
	history = {},
	users = {},
	blacklist = {},
	activeBackend = nil,
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function formatNumber(num)
	num = tonumber(num) or 0
	if num >= 1e9 then
		return string.format("%.1fB", num / 1e9):gsub("%.0B", "B")
	elseif num >= 1e6 then
		return string.format("%.1fM", num / 1e6):gsub("%.0M", "M")
	elseif num >= 1e3 then
		return string.format("%.1fK", num / 1e3):gsub("%.0K", "K")
	end
	return tostring(math.floor(num))
end

local function getColorForValue(value)
	value = tonumber(value) or 0
	if value >= 1e12 then
		return Color3.fromRGB(255, 130, 50)
	elseif value >= 1e9 then
		return Color3.fromRGB(255, 215, 0)
	elseif value >= 300000000 then
		return Color3.fromRGB(150, 90, 255)
	elseif value >= 100000000 then
		return Color3.fromRGB(255, 80, 80)
	elseif value >= 50000000 then
		return Color3.fromRGB(80, 180, 255)
	elseif value >= 10000000 then
		return Color3.fromRGB(50, 220, 120)
	end
	return COLORS.accent_secondary
end

local function playNotificationSound()
	if not CONFIG.ui.soundEnabled then return end
	
	task.spawn(function()
		pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = CONFIG.ui.soundId
			sound.Volume = 0.3
			sound.Parent = SoundService
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 2)
		end)
	end)
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MemoNotifier_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local function createLabel(parent, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextSize = props.size or 12
	label.Font = props.font or Enum.Font.GothamMedium
	label.TextColor3 = props.color or COLORS.text_primary
	
	for key, value in pairs(props) do
		if key ~= "size" and key ~= "font" and key ~= "color" then
			pcall(function()
				label[key] = value
			end)
		end
	end
	
	label.Parent = parent
	return label
end

local function createFrame(parent, props)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = props.color or COLORS.bg_card
	frame.BackgroundTransparency = props.transparency or 0.1
	
	for key, value in pairs(props) do
		if key ~= "color" and key ~= "transparency" then
			pcall(function()
				frame[key] = value
			end)
		end
	end
	
	frame.Parent = parent
	return frame
end

local function tween(object, props, duration)
	local tweenInfo = TweenInfo.new(
		duration or CONFIG.display.animationSpeed,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(object, tweenInfo, props)
	tween:Play()
	return tween
end

-- ============================================================================
-- MAIN UI WINDOW
-- ============================================================================

local MainFrame = createFrame(ScreenGui, {
	Name = "MainFrame",
	Size = UDim2.new(0, 680, 0, 440),
	Position = UDim2.new(0.5, -340, 0.5, -220),
	color = COLORS.bg_dark,
	transparency = 0.15,
	Active = true,
	Draggable = true,
	ClipsDescendants = true,
})

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", MainFrame).Color = COLORS.accent_primary
Instance.new("UIStroke", MainFrame).Transparency = 0.4
Instance.new("UIStroke", MainFrame).Thickness = 1.5

-- Header
local HeaderFrame = createFrame(MainFrame, {
	Size = UDim2.new(1, 0, 0, 60),
	color = COLORS.bg_mid,
})

createLabel(HeaderFrame, {
	Text = "MEMO",
	Size = 24,
	Font = Enum.Font.GothamBold,
	Color = COLORS.accent_primary,
	Position = UDim2.new(0, 16, 0, 12),
	TextXAlignment = Enum.TextXAlignment.Left,
})

createLabel(HeaderFrame, {
	Text = "NOTIFIER",
	Size = 24,
	Font = Enum.Font.GothamBold,
	Color = COLORS.text_primary,
	Position = UDim2.new(0, 90, 0, 12),
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Status Indicator
local StatusIndicator = createFrame(HeaderFrame, {
	Size = UDim2.new(0, 8, 0, 8),
	Position = UDim2.new(1, -24, 0, 26),
	color = COLORS.accent_danger,
	AnchorPoint = Vector2.new(1, 0.5),
})
Instance.new("UICorner", StatusIndicator).CornerRadius = UDim.new(1, 0)

local StatusLabel = createLabel(HeaderFrame, {
	Text = "Disconnected",
	Size = 11,
	Color = COLORS.text_muted,
	Position = UDim2.new(1, -120, 0, 20),
	AnchorPoint = Vector2.new(1, 0),
})

-- ============================================================================
-- LOGS SECTION
-- ============================================================================

local LogsFrame = createFrame(MainFrame, {
	Size = UDim2.new(1, -32, 1, -92),
	Position = UDim2.new(0, 16, 0, 76),
	color = COLORS.bg_mid,
	transparency = 0.3,
})
Instance.new("UICorner", LogsFrame).CornerRadius = UDim.new(0, 12)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = COLORS.accent_primary
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = LogsFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ScrollingFrame

Instance.new("UIPadding", ScrollingFrame).PaddingTop = UDim.new(0, 8)

-- ============================================================================
-- FOOTER
-- ============================================================================

local FooterFrame = createFrame(MainFrame, {
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -32),
	color = COLORS.bg_dark,
})

createLabel(FooterFrame, {
	Text = "Detected: 0",
	Size = 11,
	Color = COLORS.text_muted,
	Position = UDim2.new(0, 16, 0, 8),
	AnchorPoint = Vector2.new(0, 0.5),
})

-- ============================================================================
-- LOG ENTRY CREATION
-- ============================================================================

local function createLogEntry(data)
	local entryFrame = createFrame(ScrollingFrame, {
		Size = UDim2.new(1, -8, 0, 60),
		color = getColorForValue(data.value),
		transparency = 0.8,
	})
	Instance.new("UICorner", entryFrame).CornerRadius = UDim.new(0, 8)

	local nameLabel = createLabel(entryFrame, {
		Text = data.name or "Unknown",
		Size = 14,
		Font = Enum.Font.GothamBold,
		Color = COLORS.text_primary,
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -24, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	createLabel(entryFrame, {
		Text = "$" .. formatNumber(data.value) .. "/s",
		Size = 12,
		Font = Enum.Font.GothamBold,
		Color = getColorForValue(data.value),
		Position = UDim2.new(0, 12, 0, 26),
		Size = UDim2.new(0.5, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if data.players then
		createLabel(entryFrame, {
			Text = "Players: " .. tostring(data.players),
			Size = 10,
			Color = COLORS.text_muted,
			Position = UDim2.new(0, 12, 0, 44),
			Size = UDim2.new(0.5, 0, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	-- Join Button
	local joinButton = Instance.new("TextButton")
	joinButton.Size = UDim2.new(0, 50, 0, 24)
	joinButton.Position = UDim2.new(1, -60, 0.5, -12)
	joinButton.AnchorPoint = Vector2.new(1, 0.5)
	joinButton.BackgroundColor3 = COLORS.accent_primary
	joinButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	joinButton.TextSize = 10
	joinButton.Font = Enum.Font.GothamBold
	joinButton.Text = "JOIN"
	joinButton.Parent = entryFrame
	Instance.new("UICorner", joinButton).CornerRadius = UDim.new(0, 6)

	joinButton.MouseButton1Click:Connect(function()
		if data.jobId then
			pcall(function()
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, data.jobId)
			end)
		end
	end)

	tween(entryFrame, { Size = UDim2.new(1, -8, 0, 60) }, 0.3)

	table.insert(STATE.history, {
		frame = entryFrame,
		data = data,
		createdAt = tick(),
	})

	if #STATE.history > CONFIG.display.maxLogSize then
		local old = table.remove(STATE.history, 1)
		if old.frame and old.frame.Parent then
			old.frame:Destroy()
		end
	end

	STATE.totalDetected = STATE.totalDetected + 1
	FooterFrame:FindFirstChild("TextLabel").Text = "Detected: " .. STATE.totalDetected

	playNotificationSound()
end

-- ============================================================================
-- BACKEND MANAGEMENT
-- ============================================================================

local BackendManager = {}

function BackendManager:connectWebSocket()
	local success = false
	task.spawn(function()
		while CONFIG.backends.primary.enabled and not success do
			pcall(function()
				local ws = syn and syn.websocket or nil
				if not ws then
					warn("[MemoNotifier] WebSocket not available")
					return
				end

				local client = ws.connect(CONFIG.backends.primary.url)
				
				client.OnMessage:Connect(function(msg)
					pcall(function()
						local parts = msg:split("|")
						if #parts >= 3 then
							createLogEntry({
								name = parts[1],
								value = tonumber(parts[2]) or 0,
								players = parts[3] or "?",
								jobId = parts[4] or "",
							})
						end
					end)
				end)

				client.OnClose:Connect(function()
					STATE.isConnected = false
					StatusIndicator.BackgroundColor3 = COLORS.accent_danger
					StatusLabel.Text = "Reconnecting..."
					success = false
				end)

				STATE.isConnected = true
				STATE.activeBackend = "WebSocket"
				StatusIndicator.BackgroundColor3 = COLORS.accent_success
				StatusLabel.Text = "Connected (WS)"
				success = true
			end)

			if not success then
				task.wait(5)
			end
		end
	end)
end

function BackendManager:connectFirebase()
	task.spawn(function()
		local lastFetch = 0
		while CONFIG.backends.secondary.enabled do
			pcall(function()
				local now = tick()
				if now - lastFetch < CONFIG.ui.updateInterval then
					task.wait(CONFIG.ui.updateInterval)
					return
				end

				local url = CONFIG.backends.secondary.url .. "?orderBy=\"timestamp\"&limitToLast=30&t=" .. tostring(now)
				local response = game:HttpGet(url, true)
				lastFetch = now

				if response then
					local data = HttpService:JSONDecode(response)
					if data and type(data) == "table" then
						for k, v in pairs(data) do
							if type(v) == "table" and v.jobId then
								createLogEntry({
									name = v.name or "Unknown",
									value = tonumber(v.numValue) or 0,
									players = v.players or "?",
									jobId = v.jobId,
								})
							end
						end
					end
				end
			end)

			task.wait(CONFIG.ui.updateInterval)
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initialize()
	-- Load config from file if available
	pcall(function()
		if isfile and readfile and isfile("MemoNotifier_Config.json") then
			local saved = HttpService:JSONDecode(readfile("MemoNotifier_Config.json"))
			if type(saved) == "table" then
				for k, v in pairs(saved) do
					if type(CONFIG[k]) == "table" then
						for k2, v2 in pairs(v) do
							CONFIG[k][k2] = v2
						end
					else
						CONFIG[k] = v
					end
				end
			end
		end
	end)

	-- Save config periodically
	task.spawn(function()
		while true do
			task.wait(10)
			pcall(function()
				if writefile then
					writefile("MemoNotifier_Config.json", HttpService:JSONEncode(CONFIG))
				end
			end)
		end
	end)

	-- Connect backends
	if CONFIG.backends.primary.enabled then
		BackendManager:connectWebSocket()
	end
	if CONFIG.backends.secondary.enabled then
		BackendManager:connectFirebase()
	end

	-- Toggle keybind
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == CONFIG.ui.toggleKey then
			local visible = MainFrame.Visible
			MainFrame.Visible = not visible
		end
	end)

	print("[MemoNotifier] Initialized successfully!")
end

initialize()

-- Cleanup old logs periodically
task.spawn(function()
	while true do
		task.wait(30)
		local now = tick()
		for i = #STATE.history, 1, -1 do
			if now - STATE.history[i].createdAt > CONFIG.display.logRetentionTime then
				if STATE.history[i].frame then
					STATE.history[i].frame:Destroy()
				end
				table.remove(STATE.history, i)
			end
		end
	end
end)

return {
	CONFIG = CONFIG,
	STATE = STATE,
	createLogEntry = createLogEntry,
}
