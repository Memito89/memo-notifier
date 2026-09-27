-- ============================================================================
--  MEMO NOTIFIER v1.1
--  A high-performance notification system for Steal a Brainrot
--  Built by Guillermo (MemoAML)
--  Discord: https://discord.gg/TITAN-GG
-- ============================================================================

repeat task.wait() until game:IsLoaded()

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")

-- Destroy any previous instance
if CoreGui:FindFirstChild("MemoNotifier_GUI") then
	CoreGui.MemoNotifier_GUI:Destroy()
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	threshold    = 10000000, -- $10M minimum to show
	autoJoin     = false,
	autoForce    = false,
	soundEnabled = true,
	soundId      = "rbxassetid://4590662766",
	toggleKey    = Enum.KeyCode.RightControl,
	pollInterval = 2,
	maxLogs      = 200,
}

-- ============================================================================
-- COLOR PALETTE
-- ============================================================================

local C = {
	bg        = Color3.fromRGB(8, 11, 16),
	bg2       = Color3.fromRGB(14, 18, 28),
	card      = Color3.fromRGB(20, 24, 36),
	accent    = Color3.fromRGB(110, 80, 255),
	blue      = Color3.fromRGB(0, 180, 255),
	green     = Color3.fromRGB(45, 210, 110),
	orange    = Color3.fromRGB(255, 160, 30),
	red       = Color3.fromRGB(240, 70, 90),
	white     = Color3.fromRGB(245, 245, 250),
	grey      = Color3.fromRGB(150, 160, 180),
	muted     = Color3.fromRGB(110, 120, 140),
	stroke    = Color3.fromRGB(40, 46, 66),
}

-- ============================================================================
-- STATE
-- ============================================================================

local STATE = {
	connected    = false,
	detected     = 0,
	history      = {},
	seenIds      = {},
}

-- ============================================================================
-- HELPERS
-- ============================================================================

local function fmt(n)
	n = tonumber(n) or 0
	if n >= 1e12 then return string.format("$%.1fT/s", n/1e12):gsub("%.0T", "T")
	elseif n >= 1e9  then return string.format("$%.1fB/s", n/1e9):gsub("%.0B", "B")
	elseif n >= 1e6  then return string.format("$%.1fM/s", n/1e6):gsub("%.0M", "M")
	elseif n >= 1e3  then return string.format("$%.1fK/s", n/1e3):gsub("%.0K", "K")
	end
	return "$"..tostring(math.floor(n)).."/s"
end

local function colorFor(n)
	n = tonumber(n) or 0
	if n >= 1e12 then return Color3.fromRGB(255, 130, 50)
	elseif n >= 1e9  then return Color3.fromRGB(255, 215, 0)
	elseif n >= 3e8  then return Color3.fromRGB(150, 90, 255)
	elseif n >= 1e8  then return Color3.fromRGB(255, 80, 80)
	elseif n >= 5e7  then return Color3.fromRGB(80, 180, 255)
	elseif n >= 1e7  then return Color3.fromRGB(50, 220, 120)
	end
	return C.blue
end

local function tw(obj, props, t, style, dir)
	TweenService:Create(obj,
		TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

local function getHttp()
	if syn and syn.request   then return syn.request   end
	if http and http.request  then return http.request  end
	if http_request           then return http_request  end
	if request                then return request       end
	return nil
end

local function doGet(url)
	local fn = getHttp()
	if fn then
		local ok, res = pcall(fn, {
			Url = url, Method = "GET",
			Headers = { ["Cache-Control"] = "no-cache", ["User-Agent"] = "Mozilla/5.0" },
		})
		if ok and res and res.Body and res.Body ~= "" then
			return res.Body
		end
	end
	local ok, res = pcall(function() return game:HttpGet(url, true) end)
	if ok and res and res ~= "" then return res end
	return nil
end

local function playSound()
	if not CONFIG.soundEnabled then return end
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId  = CONFIG.soundId
			s.Volume   = 0.3
			s.Parent   = SoundService
			s:Play()
			game:GetService("Debris"):AddItem(s, 3)
		end)
	end)
end

-- ============================================================================
-- UI SETUP
-- ============================================================================

local gui = Instance.new("ScreenGui")
gui.Name             = "MemoNotifier_GUI"
gui.ResetOnSpawn     = false
gui.IgnoreGuiInset   = true
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.Parent           = CoreGui

-- Main window
local win = Instance.new("Frame")
win.Name                  = "Window"
win.Size                  = UDim2.new(0, 660, 0, 420)
win.Position              = UDim2.new(0.5,-330, 0.5,-210)
win.BackgroundColor3      = C.bg
win.BackgroundTransparency = 0.08
win.BorderSizePixel       = 0
win.ClipsDescendants      = true
win.Active                = true
win.Draggable             = true
win.Parent                = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0,14)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color       = C.accent
winStroke.Thickness   = 1.5
winStroke.Transparency = 0.35

-- Header
local header = Instance.new("Frame")
header.Size             = UDim2.new(1,0,0,56)
header.BackgroundColor3 = C.bg2
header.BorderSizePixel  = 0
header.Parent           = win
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)
-- cover bottom-rounded corners of header
local hFill = Instance.new("Frame")
hFill.Size             = UDim2.new(1,0,0,14)
hFill.Position         = UDim2.new(0,0,1,-14)
hFill.BackgroundColor3 = C.bg2
hFill.BorderSizePixel  = 0
hFill.Parent           = header

-- Title
local t1 = Instance.new("TextLabel")
t1.Size                  = UDim2.new(0,60,1,0)
t1.Position              = UDim2.new(0,16,0,0)
t1.BackgroundTransparency = 1
t1.Text                  = "MEMO"
t1.TextSize              = 22
t1.Font                  = Enum.Font.GothamBold
t1.TextColor3            = C.accent
t1.TextXAlignment        = Enum.TextXAlignment.Left
t1.Parent                = header

local t2 = Instance.new("TextLabel")
t2.Size                  = UDim2.new(0,120,1,0)
t2.Position              = UDim2.new(0,76,0,0)
t2.BackgroundTransparency = 1
t2.Text                  = "NOTIFIER"
t2.TextSize              = 22
t2.Font                  = Enum.Font.GothamBold
t2.TextColor3            = C.white
t2.TextXAlignment        = Enum.TextXAlignment.Left
t2.Parent                = header

-- Status dot
local dot = Instance.new("Frame")
dot.Size             = UDim2.new(0,8,0,8)
dot.Position         = UDim2.new(1,-16,0.5,-4)
dot.BackgroundColor3 = C.red
dot.BorderSizePixel  = 0
dot.Parent           = header
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

-- Status label
local statusLbl = Instance.new("TextLabel")
statusLbl.Size                  = UDim2.new(0,140,0,20)
statusLbl.Position              = UDim2.new(1,-158,0.5,-10)
statusLbl.BackgroundTransparency = 1
statusLbl.Text                  = "Disconnected"
statusLbl.TextSize              = 11
statusLbl.Font                  = Enum.Font.GothamMedium
statusLbl.TextColor3            = C.muted
statusLbl.TextXAlignment        = Enum.TextXAlignment.Right
statusLbl.Parent                = header

-- Detected count label
local countLbl = Instance.new("TextLabel")
countLbl.Size                  = UDim2.new(0,120,0,20)
countLbl.Position              = UDim2.new(0,200,0.5,-10)
countLbl.BackgroundTransparency = 1
countLbl.Text                  = "0 detected"
countLbl.TextSize              = 11
countLbl.Font                  = Enum.Font.GothamMedium
countLbl.TextColor3            = C.muted
countLbl.TextXAlignment        = Enum.TextXAlignment.Left
countLbl.Parent                = header

-- Scroll area background
local listBg = Instance.new("Frame")
listBg.Size             = UDim2.new(1,-24,1,-72)
listBg.Position         = UDim2.new(0,12,0,60)
listBg.BackgroundColor3 = C.bg2
listBg.BackgroundTransparency = 0.4
listBg.BorderSizePixel  = 0
listBg.Parent           = win
Instance.new("UICorner", listBg).CornerRadius = UDim.new(0,10)
local listStroke = Instance.new("UIStroke", listBg)
listStroke.Color       = C.stroke
listStroke.Thickness   = 1
listStroke.Transparency = 0.4

-- ScrollingFrame
local scroll = Instance.new("ScrollingFrame")
scroll.Size                  = UDim2.new(1,-8,1,-8)
scroll.Position              = UDim2.new(0,4,0,4)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel       = 0
scroll.ScrollBarThickness    = 3
scroll.ScrollBarImageColor3  = C.accent
scroll.CanvasSize            = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
scroll.Parent                = listBg

local list = Instance.new("UIListLayout", scroll)
list.Padding         = UDim.new(0,6)
list.SortOrder       = Enum.SortOrder.LayoutOrder
local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop    = UDim.new(0,6)
pad.PaddingBottom = UDim.new(0,6)
pad.PaddingLeft   = UDim.new(0,4)
pad.PaddingRight  = UDim.new(0,4)

-- ============================================================================
-- LOG ENTRY
-- ============================================================================

local layoutOrder = 0

local function addLog(data)
	layoutOrder -= 1 -- newest on top

	local color = colorFor(data.value)

	local card = Instance.new("Frame")
	card.Name             = "LogCard"
	card.Size             = UDim2.new(1,0,0,54)
	card.BackgroundColor3 = C.card
	card.BackgroundTransparency = 0.25
	card.BorderSizePixel  = 0
	card.LayoutOrder      = layoutOrder
	card.Parent           = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
	local cs = Instance.new("UIStroke", card)
	cs.Color       = color
	cs.Thickness   = 1
	cs.Transparency = 0.6

	-- Side accent bar
	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(0,4,1,-12)
	bar.Position         = UDim2.new(0,6,0,6)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel  = 0
	bar.Parent           = card
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

	-- Name
	local name = Instance.new("TextLabel")
	name.Size                  = UDim2.new(1,-170,0,20)
	name.Position              = UDim2.new(0,18,0,8)
	name.BackgroundTransparency = 1
	name.Text                  = data.name or "Unknown"
	name.TextSize              = 13
	name.Font                  = Enum.Font.GothamBold
	name.TextColor3            = C.white
	name.TextXAlignment        = Enum.TextXAlignment.Left
	name.TextTruncate          = Enum.TextTruncate.AtEnd
	name.Parent                = card

	-- Value
	local val = Instance.new("TextLabel")
	val.Size                  = UDim2.new(1,-170,0,16)
	val.Position              = UDim2.new(0,18,0,29)
	val.BackgroundTransparency = 1
	val.Text                  = fmt(data.value) .. (data.players and ("  •  " .. data.players .. " players") or "")
	val.TextSize              = 11
	val.Font                  = Enum.Font.GothamMedium
	val.TextColor3            = color
	val.TextXAlignment        = Enum.TextXAlignment.Left
	val.Parent                = card

	-- JOIN button
	local joinBtn = Instance.new("TextButton")
	joinBtn.Size             = UDim2.new(0,46,0,22)
	joinBtn.Position         = UDim2.new(1,-56,0.5,-11)
	joinBtn.BackgroundColor3 = C.accent
	joinBtn.Text             = "JOIN"
	joinBtn.TextSize         = 10
	joinBtn.Font             = Enum.Font.GothamBold
	joinBtn.TextColor3       = Color3.new(1,1,1)
	joinBtn.AutoButtonColor  = false
	joinBtn.Parent           = card
	Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0,6)

	joinBtn.MouseButton1Click:Connect(function()
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, data.jobId)
		end)
	end)

	joinBtn.MouseEnter:Connect(function()
		tw(joinBtn, { BackgroundColor3 = Color3.fromRGB(140,110,255) })
	end)
	joinBtn.MouseLeave:Connect(function()
		tw(joinBtn, { BackgroundColor3 = C.accent })
	end)

	-- Animate in
	card.Size = UDim2.new(1,0,0,0)
	card.BackgroundTransparency = 1
	tw(card, { Size = UDim2.new(1,0,0,54), BackgroundTransparency = 0.25 }, 0.35, Enum.EasingStyle.Back)

	-- Track
	STATE.detected += 1
	countLbl.Text = STATE.detected .. " detected"
	table.insert(STATE.history, 1, { card = card, data = data })

	-- Trim old
	if #STATE.history > CONFIG.maxLogs then
		local old = table.remove(STATE.history)
		if old.card and old.card.Parent then old.card:Destroy() end
	end

	playSound()
end

-- ============================================================================
-- STATUS HELPERS
-- ============================================================================

local function setStatus(text, color)
	statusLbl.Text   = text
	statusLbl.TextColor3 = color or C.muted
	dot.BackgroundColor3 = color or C.red
	STATE.connected  = (color == C.green)
end

-- ============================================================================
-- BACKEND: DEX API (HTTP poll — works on Delta)
-- ============================================================================

task.spawn(function()
	local DEX_URL = "https://dexapi1.up.railway.app/logs"

	while true do
		local ok = pcall(function()
			local body = doGet(DEX_URL .. "?t=" .. tostring(tick()))
			if not body or body == "" then
				setStatus("No data (DEX)", C.orange)
				return
			end

			-- Each line: name|mps|players|jobId
			for line in body:gmatch("[^\r\n]+") do
				local parts = line:split("|")
				if #parts >= 2 then
					local name   = (parts[1] or ""):match("^%s*(.-)%s*$")
					local value  = tonumber(parts[2]) or 0
					local players = parts[3] or "?"
					local jobId  = parts[4] or ""
					local uid    = name .. "|" .. jobId

					if name ~= "" and value >= CONFIG.threshold and not STATE.seenIds[uid] then
						STATE.seenIds[uid] = true
						task.delay(300, function() STATE.seenIds[uid] = nil end)
						setStatus("Connected (DEX)", C.green)
						addLog({ name = name, value = value, players = players, jobId = jobId })

						if CONFIG.autoJoin and jobId ~= "" then
							pcall(function()
								TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId)
							end)
						end
					end
				end
			end

			setStatus("Connected (DEX)", C.green)
		end)

		if not ok then
			setStatus("DEX error — retrying", C.red)
		end

		task.wait(CONFIG.pollInterval)
	end
end)

-- ============================================================================
-- BACKEND: Firebase (secondary)
-- ============================================================================

task.spawn(function()
	local FB_URL = "https://autojoiner2-2d181-default-rtdb.firebaseio.com/logs.json"

	while true do
		pcall(function()
			local body = doGet(FB_URL .. "?orderBy=%22%24key%22&limitToLast=30&t=" .. tostring(tick()))
			if not body or body == "" then return end

			local ok2, data = pcall(HttpService.JSONDecode, HttpService, body)
			if not ok2 or type(data) ~= "table" then return end

			for k, v in pairs(data) do
				if type(v) == "table" and v.jobId then
					local name  = tostring(v.name or "Unknown")
					local value = tonumber(v.numValue) or 0
					local jobId = tostring(v.jobId)
					local uid   = k -- Firebase key is unique

					if value >= CONFIG.threshold and not STATE.seenIds[uid] then
						STATE.seenIds[uid] = true
						task.delay(300, function() STATE.seenIds[uid] = nil end)

						if not STATE.connected then
							setStatus("Connected (FB)", C.green)
						end

						addLog({
							name    = name,
							value   = value,
							players = tostring(v.players or "?"),
							jobId   = jobId,
						})
					end
				end
			end
		end)

		task.wait(CONFIG.pollInterval)
	end
end)

-- ============================================================================
-- TOGGLE KEYBIND
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CONFIG.toggleKey then
		win.Visible = not win.Visible
	end
end)

print("[MemoNotifier] Loaded! Press RightControl to toggle.")
