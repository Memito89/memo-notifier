-- ============================================================================
--  MEMO NOTIFIER ADMIN PANEL v1.0
--  Settings management and backend configuration
--  Built by Guillermo (MemoAML)
-- ============================================================================

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Import main notifier
local MemoNotifier = require(script.Parent:WaitForChild("memo_notifier"))
local CONFIG = MemoNotifier.CONFIG
local STATE = MemoNotifier.STATE

-- ============================================================================
-- ADMIN PANEL COLOR SCHEME
-- ============================================================================

local ADMIN_COLORS = {
	panel_bg = Color3.fromRGB(10, 12, 18),
	panel_accent = Color3.fromRGB(150, 80, 255),
	success = Color3.fromRGB(45, 210, 110),
	warning = Color3.fromRGB(255, 160, 30),
	error = Color3.fromRGB(240, 70, 90),
	text_main = Color3.fromRGB(245, 245, 250),
	text_secondary = Color3.fromRGB(150, 160, 180),
}

-- ============================================================================
-- SETTINGS PANEL UI
-- ============================================================================

local AdminPanel = Instance.new("ScreenGui")
AdminPanel.Name = "MemoNotifier_AdminPanel"
AdminPanel.ResetOnSpawn = false
AdminPanel.IgnoreGuiInset = true
AdminPanel.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AdminPanel.Parent = CoreGui

local PanelFrame = Instance.new("Frame")
PanelFrame.Size = UDim2.new(0, 400, 0, 500)
PanelFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
PanelFrame.BackgroundColor3 = ADMIN_COLORS.panel_bg
PanelFrame.BorderSizePixel = 0
PanelFrame.ClipsDescendants = true
PanelFrame.Parent = AdminPanel
Instance.new("UICorner", PanelFrame).CornerRadius = UDim.new(0, 12)

-- Header
local HeaderLabel = Instance.new("TextLabel")
HeaderLabel.Size = UDim2.new(1, 0, 0, 50)
HeaderLabel.BackgroundColor3 = ADMIN_COLORS.panel_accent
HeaderLabel.BackgroundTransparency = 0.2
HeaderLabel.Text = "⚙️ MEMO NOTIFIER SETTINGS"
HeaderLabel.TextSize = 16
HeaderLabel.Font = Enum.Font.GothamBold
HeaderLabel.TextColor3 = ADMIN_COLORS.panel_accent
HeaderLabel.BorderSizePixel = 0
HeaderLabel.Parent = PanelFrame

-- ScrollingFrame for settings
local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, -16, 1, -66)
SettingsScroll.Position = UDim2.new(0, 8, 0, 58)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = ADMIN_COLORS.panel_accent
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.Parent = PanelFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = SettingsScroll
Instance.new("UIPadding", SettingsScroll).PaddingTop = UDim.new(0, 8)

-- ============================================================================
-- SETTING TOGGLES
-- ============================================================================

local function createToggleSetting(parent, label, configKey, configSection)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	container.BorderSizePixel = 0
	container.Parent = parent
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

	-- Label
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.7, 0, 1, 0)
	labelText.BackgroundTransparency = 1
	labelText.Text = label
	labelText.TextSize = 12
	labelText.Font = Enum.Font.GothamMedium
	labelText.TextColor3 = ADMIN_COLORS.text_main
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = container

	-- Toggle Button
	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 50, 0, 24)
	toggleBg.Position = UDim2.new(1, -58, 0.5, -12)
	toggleBg.AnchorPoint = Vector2.new(1, 0.5)
	toggleBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 18, 0, 18)
	toggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)

	local currentValue = CONFIG[configSection][configKey]

	local function updateToggle(value)
		CONFIG[configSection][configKey] = value
		if value then
			toggleBg.BackgroundColor3 = ADMIN_COLORS.success
			TweenService:Create(
				toggleCircle,
				TweenInfo.new(0.2),
				{ Position = UDim2.new(0, 29, 0.5, -9) }
			):Play()
		else
			toggleBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
			TweenService:Create(
				toggleCircle,
				TweenInfo.new(0.2),
				{ Position = UDim2.new(0, 3, 0.5, -9) }
			):Play()
		end
	end

	updateToggle(currentValue)

	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = container
	clickButton.MouseButton1Click:Connect(function()
		updateToggle(not CONFIG[configSection][configKey])
	end)

	return container
end

-- ============================================================================
-- SETTINGS CREATION
-- ============================================================================

-- Audio Settings
local audioLabel = Instance.new("TextLabel")
audioLabel.Size = UDim2.new(1, 0, 0, 24)
audioLabel.BackgroundTransparency = 1
audioLabel.Text = "🔊 Audio"
audioLabel.TextSize = 13
audioLabel.Font = Enum.Font.GothamBold
audioLabel.TextColor3 = ADMIN_COLORS.panel_accent
audioLabel.TextXAlignment = Enum.TextXAlignment.Left
audioLabel.Parent = SettingsScroll

createToggleSetting(SettingsScroll, "Enable Notifications", "soundEnabled", "ui")

-- Backend Settings
local backendLabel = Instance.new("TextLabel")
backendLabel.Size = UDim2.new(1, 0, 0, 24)
backendLabel.BackgroundTransparency = 1
backendLabel.Text = "🌐 Backends"
backendLabel.TextSize = 13
backendLabel.Font = Enum.Font.GothamBold
backendLabel.TextColor3 = ADMIN_COLORS.panel_accent
backendLabel.TextXAlignment = Enum.TextXAlignment.Left
backendLabel.Parent = SettingsScroll

createToggleSetting(SettingsScroll, "Primary (WebSocket)", "enabled", "backends.primary")
createToggleSetting(SettingsScroll, "Secondary (Firebase)", "enabled", "backends.secondary")

-- Filter Settings
local filterLabel = Instance.new("TextLabel")
filterLabel.Size = UDim2.new(1, 0, 0, 24)
filterLabel.BackgroundTransparency = 1
filterLabel.Text = "🎯 Filters"
filterLabel.TextSize = 13
filterLabel.Font = Enum.Font.GothamBold
filterLabel.TextColor3 = ADMIN_COLORS.panel_accent
filterLabel.TextXAlignment = Enum.TextXAlignment.Left
filterLabel.Parent = SettingsScroll

createToggleSetting(SettingsScroll, "Auto-Join", "autoJoin", "filters")
createToggleSetting(SettingsScroll, "Auto-Force", "autoForce", "filters")

-- Display Settings
local displayLabel = Instance.new("TextLabel")
displayLabel.Size = UDim2.new(1, 0, 0, 24)
displayLabel.BackgroundTransparency = 1
displayLabel.Text = "🎨 Display"
displayLabel.TextSize = 13
displayLabel.Font = Enum.Font.GothamBold
displayLabel.TextColor3 = ADMIN_COLORS.panel_accent
displayLabel.TextXAlignment = Enum.TextXAlignment.Left
displayLabel.Parent = SettingsScroll

-- Status Info
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(1, 0, 0, 60)
statusContainer.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
statusContainer.BorderSizePixel = 0
statusContainer.Parent = SettingsScroll
Instance.new("UICorner", statusContainer).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0.5, 0)
statusLabel.Position = UDim2.new(0, 8, 0, 6)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: " .. (STATE.isConnected and "✅ Connected" or "❌ Disconnected")
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextColor3 = STATE.isConnected and Color3.fromRGB(45, 210, 110) or Color3.fromRGB(240, 70, 90)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusContainer

local detectedLabel = Instance.new("TextLabel")
detectedLabel.Size = UDim2.new(1, -16, 0.5, 0)
detectedLabel.Position = UDim2.new(0, 8, 0.5, 0)
detectedLabel.BackgroundTransparency = 1
detectedLabel.Text = "Detected: " .. STATE.totalDetected
detectedLabel.TextSize = 12
detectedLabel.Font = Enum.Font.GothamMedium
detectedLabel.TextColor3 = ADMIN_COLORS.text_secondary
detectedLabel.TextXAlignment = Enum.TextXAlignment.Left
detectedLabel.Parent = statusContainer

-- ============================================================================
-- FOOTER BUTTONS
-- ============================================================================

local footerFrame = Instance.new("Frame")
footerFrame.Size = UDim2.new(1, 0, 0, 42)
footerFrame.Position = UDim2.new(0, 0, 1, -42)
footerFrame.BackgroundColor3 = ADMIN_COLORS.panel_bg
footerFrame.BorderSizePixel = 0
footerFrame.Parent = PanelFrame

-- Clear Logs Button
local clearButton = Instance.new("TextButton")
clearButton.Size = UDim2.new(0.48, 0, 1, -8)
clearButton.Position = UDim2.new(0, 8, 0, 4)
clearButton.BackgroundColor3 = ADMIN_COLORS.error
clearButton.BackgroundTransparency = 0.7
clearButton.Text = "Clear Logs"
clearButton.TextSize = 11
clearButton.Font = Enum.Font.GothamBold
clearButton.TextColor3 = ADMIN_COLORS.error
clearButton.BorderSizePixel = 0
clearButton.Parent = footerFrame
Instance.new("UICorner", clearButton).CornerRadius = UDim.new(0, 6)

clearButton.MouseButton1Click:Connect(function()
	for i = #STATE.history, 1, -1 do
		if STATE.history[i].frame then
			STATE.history[i].frame:Destroy()
		end
		table.remove(STATE.history, i)
	end
	STATE.totalDetected = 0
end)

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.48, 0, 1, -8)
closeButton.Position = UDim2.new(1, -56, 0, 4)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = ADMIN_COLORS.panel_accent
closeButton.BackgroundTransparency = 0.7
closeButton.Text = "Close"
closeButton.TextSize = 11
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = ADMIN_COLORS.panel_accent
closeButton.BorderSizePixel = 0
closeButton.Parent = footerFrame
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

closeButton.MouseButton1Click:Connect(function()
	AdminPanel:Destroy()
end)

-- ============================================================================
-- HOTKEY TO OPEN ADMIN
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		PanelFrame.Visible = not PanelFrame.Visible
	end
end)

-- ============================================================================
-- PERIODIC UPDATES
-- ============================================================================

task.spawn(function()
	while AdminPanel and AdminPanel.Parent do
		pcall(function()
			statusLabel.Text = "Status: " .. (STATE.isConnected and "✅ Connected" or "❌ Disconnected")
			statusLabel.TextColor3 = STATE.isConnected and Color3.fromRGB(45, 210, 110) or Color3.fromRGB(240, 70, 90)
			detectedLabel.Text = "Detected: " .. STATE.totalDetected
		end)
		task.wait(1)
	end
end)

print("[MemoNotifier Admin] Panel loaded! Press LAlt to toggle")

return {
	Panel = AdminPanel,
	PanelFrame = PanelFrame,
}
