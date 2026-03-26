--!strict
-- WasUI - 完整的 Roblox UI 库
-- 版本 2.0
-- 特性：窗口系统、选项卡、多种控件、配置管理、图标库支持、右上角状态指示器

-- ============================================================
-- 服务引用
-- ============================================================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- ============================================================
-- 图标库支持（模仿 WindUI）
-- ============================================================
local IconLibrary = nil
local DEFAULT_ICON_URL = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"

-- 加载远程图标库
local function loadIconLibrary(url)
    url = url or DEFAULT_ICON_URL
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        IconLibrary = result
        if IconLibrary.SetIconsType then
            IconLibrary.SetIconsType("lucide")
        end
        return true
    else
        warn("[WasUI] Failed to load icon library, using fallback")
        IconLibrary = nil
        return false
    end
end

-- 获取图标数据（返回 { imageId, { ImageRectSize, ImageRectPosition } }）
function WasUI.Icon(iconName)
    if IconLibrary and IconLibrary.Icon2 then
        local iconData = IconLibrary.Icon2(iconName, nil, true)
        if iconData then
            return {
                iconData[1],
                {
                    ImageRectSize = iconData[2].ImageRectSize,
                    ImageRectPosition = iconData[2].ImageRectPosition,
                }
            }
        end
    end
    -- 回退图标（可以自行扩充映射）
    local fallback = {
        home = "rbxassetid://0",
        zap = "rbxassetid://0",
        sword = "rbxassetid://0",
        eye = "rbxassetid://0",
        settings = "rbxassetid://0",
        x = "rbxassetid://0",
        check = "rbxassetid://0",
        "chevron-down" = "rbxassetid://0",
        copy = "rbxassetid://0",
        key = "rbxassetid://0",
    }
    local id = fallback[iconName] or "rbxassetid://0"
    return { id, { ImageRectSize = Vector2.new(0,0), ImageRectPosition = Vector2.new(0,0) } }
end

-- ============================================================
-- 主题配置
-- ============================================================
local DefaultTheme = {
    Colors = {
        Primary = Color3.fromRGB(0, 120, 215),
        Secondary = Color3.fromRGB(100, 100, 100),
        Success = Color3.fromRGB(0, 200, 0),
        Danger = Color3.fromRGB(200, 0, 0),
        Warning = Color3.fromRGB(255, 200, 0),
        Info = Color3.fromRGB(0, 200, 255),
        Light = Color3.fromRGB(240, 240, 240),
        Dark = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(0, 0, 0),
        Background = Color3.fromRGB(45, 45, 45),
        InputBackground = Color3.fromRGB(60, 60, 60),
        WindowBackground = Color3.fromRGB(35, 35, 35),
        TitleBar = Color3.fromRGB(45, 45, 45),
    },
    Font = Enum.Font.GothamMedium,
    CornerRadius = UDim.new(0, 8),
    StrokeThickness = 1,
    WindowPadding = UDim.new(0, 12),
    TitleBarHeight = 32,
    TabHeight = 40,
}

-- ============================================================
-- 全局状态管理器（右上角显示开启的开关）
-- ============================================================
local StatusPanel = nil
local ActiveToggles = {}
local ToggleNameMap = {}

local function updateStatusPanel()
    if not StatusPanel then return end
    local activeNames = {}
    for name, active in pairs(ActiveToggles) do
        if active then
            table.insert(activeNames, name)
        end
    end
    local text = table.concat(activeNames, "  •  ")
    if text == "" then text = "无" end
    StatusPanel.Text = text
    StatusPanel.TextColor3 = (text == "无") and DefaultTheme.Colors.Text or DefaultTheme.Colors.Success
end

local function registerToggle(toggleObj, displayName)
    ToggleNameMap[toggleObj] = displayName
    ActiveToggles[displayName] = toggleObj:isOn()
    updateStatusPanel()
    toggleObj:on("Changed", function(isOn)
        ActiveToggles[displayName] = isOn
        updateStatusPanel()
    end)
end

local function createStatusPanel()
    if StatusPanel then return end
    local player = Players.LocalPlayer
    if not player then return end
    local panel = Instance.new("TextLabel")
    panel.Name = "WasUI_StatusPanel"
    panel.Size = UDim2.new(0, 300, 0, 32)
    panel.Position = UDim2.new(1, -310, 0, 10)
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0, 0.7)
    panel.BackgroundTransparency = 0.3
    panel.Text = ""
    panel.TextColor3 = DefaultTheme.Colors.Text
    panel.TextSize = 14
    panel.Font = DefaultTheme.Font
    panel.TextXAlignment = Enum.TextXAlignment.Right
    panel.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = panel
    panel.Parent = player.PlayerGui
    StatusPanel = panel
end

-- ============================================================
-- 控件基类
-- ============================================================
local BaseControl = {}
BaseControl.__index = BaseControl

function BaseControl.new(parent, typeName)
    local self = setmetatable({}, BaseControl)
    self.type = typeName
    self.instance = nil
    self.options = {}
    self.events = {}
    self.enabled = true
    self.parent = parent
    self.theme = nil
    return self
end

function BaseControl:applyEffects(instance, options)
    if options.CornerRadius ~= false then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = options.CornerRadius or self.theme.CornerRadius
        corner.Parent = instance
    end
    if options.BorderColor3 and options.BorderSizePixel then
        local stroke = Instance.new("UIStroke")
        stroke.Color = options.BorderColor3
        stroke.Thickness = options.BorderSizePixel
        stroke.Parent = instance
    end
end

function BaseControl:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = Instance.new("BindableEvent")
    end
    return self.events[eventName].Event:Connect(callback)
end

function BaseControl:fire(eventName, ...)
    if self.events[eventName] then
        self.events[eventName]:Fire(...)
    end
end

function BaseControl:setEnabled(enabled)
    self.enabled = enabled
    if self.instance then
        self.instance.Active = enabled
        self.instance.Selectable = enabled
        self.instance.BackgroundTransparency = enabled and (self.options.BackgroundTransparency or 0) or 0.5
        if self.instance:IsA("TextButton") or self.instance:IsA("TextBox") then
            self.instance.TextTransparency = enabled and 0 or 0.5
        end
    end
end

function BaseControl:getInstance()
    return self.instance
end

function BaseControl:setParent(parent)
    self.parent = parent
    if self.instance then
        self.instance.Parent = parent
    end
end

function BaseControl:destroy()
    if self.instance then
        self.instance:Destroy()
    end
    for _, ev in pairs(self.events) do
        ev:Destroy()
    end
    self.events = {}
end

-- ============================================================
-- 按钮控件
-- ============================================================
local Button = setmetatable({}, BaseControl)
Button.__index = Button

function Button.new(parent, text, preset, customOptions, theme)
    local self = BaseControl.new(parent, "Button")
    setmetatable(self, Button)
    self.theme = theme
    self.preset = preset or {}
    self.options = {}
    self.text = text or ""

    for k, v in pairs(self.preset) do
        self.options[k] = v
    end
    for k, v in pairs(customOptions or {}) do
        self.options[k] = v
    end

    local button = Instance.new("TextButton")
    button.Text = self.text
    button.AutoButtonColor = false
    button.BackgroundTransparency = self.options.BackgroundTransparency or 0
    button.BackgroundColor3 = self:resolveColor(self.options.BackgroundColor3) or self.theme.Colors.Primary
    button.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
    button.TextSize = self.options.TextSize or 18
    button.Font = self.options.Font or self.theme.Font
    button.BorderSizePixel = self.options.BorderSizePixel or 0
    if self.options.BorderColor3 then
        button.BorderColor3 = self:resolveColor(self.options.BorderColor3)
    end

    if self.options.Padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = self.options.Padding
        padding.PaddingRight = self.options.Padding
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = button
    end

    self:applyEffects(button, self.options)

    local scale = Instance.new("UIScale")
    scale.Parent = button
    scale.Scale = 1

    button.MouseEnter:Connect(function()
        if not self.enabled then return end
        local tween = TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1.05})
        tween:Play()
    end)
    button.MouseLeave:Connect(function()
        if not self.enabled then return end
        local tween = TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1})
        tween:Play()
    end)
    button.MouseButton1Click:Connect(function()
        if not self.enabled then return end
        self:fire("Click")
    end)

    self.instance = button
    self:setParent(parent)
    return self
end

function Button:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function Button:setText(text)
    self.text = text
    if self.instance then
        self.instance.Text = text
    end
end

-- ============================================================
-- 标签控件
-- ============================================================
local Label = setmetatable({}, BaseControl)
Label.__index = Label

function Label.new(parent, text, customOptions, theme)
    local self = BaseControl.new(parent, "Label")
    setmetatable(self, Label)
    self.theme = theme
    self.options = customOptions or {}
    self.text = text or ""

    local label = Instance.new("TextLabel")
    label.Text = self.text
    label.BackgroundTransparency = self.options.BackgroundTransparency or 1
    label.BackgroundColor3 = self:resolveColor(self.options.BackgroundColor3) or self.theme.Colors.Background
    label.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
    label.TextSize = self.options.TextSize or 16
    label.Font = self.options.Font or self.theme.Font
    label.TextXAlignment = self.options.TextXAlignment or Enum.TextXAlignment.Center
    label.TextYAlignment = self.options.TextYAlignment or Enum.TextYAlignment.Center
    label.BorderSizePixel = 0

    self:applyEffects(label, self.options)

    self.instance = label
    self:setParent(parent)
    return self
end

function Label:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function Label:setText(text)
    self.text = text
    if self.instance then
        self.instance.Text = text
    end
end

-- ============================================================
-- 输入框控件
-- ============================================================
local TextBox = setmetatable({}, BaseControl)
TextBox.__index = TextBox

function TextBox.new(parent, placeholder, customOptions, theme)
    local self = BaseControl.new(parent, "TextBox")
    setmetatable(self, TextBox)
    self.theme = theme
    self.options = customOptions or {}
    self.placeholder = placeholder or ""

    local box = Instance.new("TextBox")
    box.Text = ""
    box.PlaceholderText = self.placeholder
    box.BackgroundTransparency = self.options.BackgroundTransparency or 0
    box.BackgroundColor3 = self:resolveColor(self.options.BackgroundColor3) or self.theme.Colors.InputBackground
    box.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
    box.PlaceholderColor3 = self:resolveColor(self.options.PlaceholderColor3) or Color3.fromRGB(150, 150, 150)
    box.TextSize = self.options.TextSize or 16
    box.Font = self.options.Font or self.theme.Font
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = self.options.ClearTextOnFocus or false

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = box

    self:applyEffects(box, self.options)

    box.FocusLost:Connect(function(enterPressed)
        self:fire("FocusLost", enterPressed, box.Text)
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        self:fire("TextChanged", box.Text)
    end)

    self.instance = box
    self:setParent(parent)
    return self
end

function TextBox:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function TextBox:getText()
    return self.instance and self.instance.Text or ""
end

function TextBox:setText(text)
    if self.instance then
        self.instance.Text = text
    end
end

-- ============================================================
-- iOS 风格开关 (Toggle)
-- ============================================================
local Toggle = setmetatable({}, BaseControl)
Toggle.__index = Toggle

function Toggle.new(parent, text, initialState, customOptions, theme)
    local self = BaseControl.new(parent, "Toggle")
    setmetatable(self, Toggle)
    self.theme = theme
    self.options = customOptions or {}
    self.text = text or ""
    self.isOn = initialState or false

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 200, 0, 32)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = self.text
    label.BackgroundTransparency = 1
    label.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
    label.TextSize = self.options.TextSize or 16
    label.Font = self.options.Font or self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 51, 0, 31)
    switchBg.Position = UDim2.new(1, -51, 0.5, -15.5)
    switchBg.BackgroundColor3 = self.isOn and self.theme.Colors.Success or Color3.fromRGB(120, 120, 120)
    switchBg.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15.5)
    corner.Parent = switchBg
    switchBg.Parent = container

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0, 27, 0, 27)
    slider.Position = self.isOn and UDim2.new(1, -29, 0.5, -13.5) or UDim2.new(0, 2, 0.5, -13.5)
    slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    slider.BorderSizePixel = 0
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 13.5)
    sliderCorner.Parent = slider
    slider.Parent = switchBg

    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Image = "rbxassetid://0"
    button.Parent = switchBg

    button.MouseButton1Click:Connect(function()
        if not self.enabled then return end
        self.isOn = not self.isOn
        switchBg.BackgroundColor3 = self.isOn and self.theme.Colors.Success or Color3.fromRGB(120, 120, 120)
        local targetPos = self.isOn and UDim2.new(1, -29, 0.5, -13.5) or UDim2.new(0, 2, 0.5, -13.5)
        local tween = TweenService:Create(slider, TweenInfo.new(0.2), {Position = targetPos})
        tween:Play()
        self:fire("Changed", self.isOn)
    end)

    self.instance = container
    self.switchBg = switchBg
    self.slider = slider
    self.label = label
    self:setParent(parent)
    return self
end

function Toggle:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function Toggle:isOn()
    return self.isOn
end

function Toggle:setOn(isOn)
    if self.isOn == isOn then return end
    self.isOn = isOn
    self.switchBg.BackgroundColor3 = self.isOn and self.theme.Colors.Success or Color3.fromRGB(120, 120, 120)
    local targetPos = self.isOn and UDim2.new(1, -29, 0.5, -13.5) or UDim2.new(0, 2, 0.5, -13.5)
    local tween = TweenService:Create(self.slider, TweenInfo.new(0.2), {Position = targetPos})
    tween:Play()
    self:fire("Changed", self.isOn)
end

function Toggle:setText(text)
    self.text = text
    if self.label then
        self.label.Text = text
    end
end

-- ============================================================
-- 滑块控件
-- ============================================================
local Slider = setmetatable({}, BaseControl)
Slider.__index = Slider

function Slider.new(parent, min, max, defaultValue, customOptions, theme)
    local self = BaseControl.new(parent, "Slider")
    setmetatable(self, Slider)
    self.theme = theme
    self.options = customOptions or {}
    self.min = min or 0
    self.max = max or 100
    self.value = math.clamp(defaultValue or self.min, self.min, self.max)

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 200, 0, 30)

    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1, 0, 0, 4)
    trackBg.Position = UDim2.new(0, 0, 0.5, -2)
    trackBg.BackgroundColor3 = self:resolveColor(self.options.TrackColor) or Color3.fromRGB(80, 80, 80)
    trackBg.BorderSizePixel = 0
    trackBg.Parent = container
    self:applyEffects(trackBg, self.options)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((self.value - self.min) / (self.max - self.min), 0, 1, 0)
    fill.BackgroundColor3 = self:resolveColor(self.options.FillColor) or self.theme.Colors.Primary
    fill.BorderSizePixel = 0
    fill.Parent = trackBg

    local knob = Instance.new("ImageButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((self.value - self.min) / (self.max - self.min), -8, 0.5, -8)
    knob.BackgroundColor3 = self:resolveColor(self.options.KnobColor) or self.theme.Colors.Light
    knob.BackgroundTransparency = 0
    knob.BorderSizePixel = 0
    knob.Image = "rbxassetid://0"
    knob.AutoButtonColor = false
    self:applyEffects(knob, self.options)
    knob.Parent = container

    local valueLabel = nil
    if self.options.ShowValue then
        valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 40, 1, 0)
        valueLabel.Position = UDim2.new(1, 5, 0, 0)
        valueLabel.Text = tostring(math.floor(self.value))
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
        valueLabel.TextSize = 14
        valueLabel.Font = self.theme.Font
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = container
    end

    local dragging = false
    local connection

    local function updateFromMouseX(input)
        local relativeX = input.Position.X - trackBg.AbsolutePosition.X
        local percent = math.clamp(relativeX / trackBg.AbsoluteSize.X, 0, 1)
        local newValue = self.min + (self.max - self.min) * percent
        self:setValue(newValue)
    end

    knob.MouseButton1Down:Connect(function()
        dragging = true
        connection = RunService.RenderStepped:Connect(function()
            local mouse = Players.LocalPlayer:GetMouse()
            updateFromMouseX(mouse)
        end)
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)

    self.instance = container
    self.trackBg = trackBg
    self.fill = fill
    self.knob = knob
    self.valueLabel = valueLabel
    self:setParent(parent)
    return self
end

function Slider:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function Slider:setValue(value)
    self.value = math.clamp(value, self.min, self.max)
    local percent = (self.value - self.min) / (self.max - self.min)
    self.fill.Size = UDim2.new(percent, 0, 1, 0)
    self.knob.Position = UDim2.new(percent, -8, 0.5, -8)
    if self.valueLabel then
        self.valueLabel.Text = tostring(math.floor(self.value))
    end
    self:fire("Changed", self.value)
end

function Slider:getValue()
    return self.value
end

-- ============================================================
-- 选项卡管理器（独立滚动）
-- ============================================================
local TabManager = {}
TabManager.__index = TabManager

function TabManager.new(parent, theme)
    local self = setmetatable({}, TabManager)
    self.parent = parent
    self.theme = theme
    self.tabs = {}
    self.activeTab = nil

    self.tabBar = Instance.new("ScrollingFrame")
    self.tabBar.Size = UDim2.new(1, 0, 0, self.theme.TabHeight)
    self.tabBar.BackgroundColor3 = self.theme.Colors.TitleBar
    self.tabBar.BorderSizePixel = 0
    self.tabBar.ScrollBarThickness = 4
    self.tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    self.tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    self.tabBar.Parent = parent

    self.contentArea = Instance.new("ScrollingFrame")
    self.contentArea.Size = UDim2.new(1, 0, 1, -self.theme.TabHeight)
    self.contentArea.Position = UDim2.new(0, 0, 0, self.theme.TabHeight)
    self.contentArea.BackgroundColor3 = self.theme.Colors.WindowBackground
    self.contentArea.BorderSizePixel = 0
    self.contentArea.ScrollBarThickness = 8
    self.contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.contentArea.Parent = parent

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, self.theme.TabHeight)
    divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    divider.BorderSizePixel = 0
    divider.Parent = parent

    return self
end

function TabManager:addTab(name, contentBuilder)
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = self.theme.Colors.Text
    btn.TextSize = 16
    btn.Font = self.theme.Font
    btn.AutoButtonColor = false
    btn.Parent = self.tabBar

    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(1, 0, 0, 2)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = self.theme.Colors.Primary
    underline.BorderSizePixel = 0
    underline.Visible = false
    underline.Parent = btn

    btn.MouseButton1Click:Connect(function()
        self:setActiveTab(name)
    end)

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = self.contentArea

    if contentBuilder then
        contentBuilder(contentFrame)
    end

    table.insert(self.tabs, {name = name, button = btn, content = contentFrame, underline = underline})
    self.tabBar.CanvasSize = UDim2.new(0, #self.tabs * 100, 0, 0)

    if not self.activeTab then
        self:setActiveTab(name)
    end

    return contentFrame
end

function TabManager:setActiveTab(name)
    for _, tab in ipairs(self.tabs) do
        local isActive = (tab.name == name)
        tab.content.Visible = isActive
        tab.underline.Visible = isActive
        tab.button.TextColor3 = isActive and self.theme.Colors.Primary or self.theme.Colors.Text
    end
    self.activeTab = name
end

function TabManager:getContentFrame(name)
    for _, tab in ipairs(self.tabs) do
        if tab.name == name then
            return tab.content
        end
    end
    return nil
end

-- ============================================================
-- 窗口类
-- ============================================================
local Window = {}
Window.__index = Window

function Window.new(title, options)
    local self = setmetatable({}, Window)
    self.theme = options.theme or DefaultTheme
    self.size = options.size or UDim2.new(0, 800, 0, 600)
    self.position = options.position or UDim2.new(0.5, -400, 0.5, -300)
    self.title = title or "WasUI"

    local player = Players.LocalPlayer
    if not player then error("No LocalPlayer") end
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "WasUI_Window_" .. tostring(os.time())
    self.gui.Parent = player.PlayerGui

    self.frame = Instance.new("Frame")
    self.frame.Size = self.size
    self.frame.Position = self.position
    self.frame.BackgroundColor3 = self.theme.Colors.WindowBackground
    self.frame.BorderSizePixel = 0
    self.frame.ClipsDescendants = true
    self.frame.Parent = self.gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.theme.CornerRadius
    corner.Parent = self.frame

    self.titleBar = Instance.new("Frame")
    self.titleBar.Size = UDim2.new(1, 0, 0, self.theme.TitleBarHeight)
    self.titleBar.BackgroundColor3 = self.theme.Colors.TitleBar
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 60, 0, 0)
    titleLabel.Text = self.title
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = self.theme.Colors.Text
    titleLabel.TextSize = 14
    titleLabel.Font = self.theme.Font
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.titleBar

    -- macOS 风格三个点按钮（使用图标库）
    local buttons = {"close", "minimize", "maximize"}
    local buttonPositions = {10, 34, 58}
    for i, btnType in ipairs(buttons) do
        local icon = WasUI.Icon(btnType)
        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(0, 16, 0, 16)
        btn.Position = UDim2.new(0, buttonPositions[i], 0.5, -8)
        btn.BackgroundTransparency = 1
        btn.Image = icon[1]
        btn.ImageRectSize = icon[2].ImageRectSize
        btn.ImageRectOffset = icon[2].ImageRectPosition
        btn.AutoButtonColor = false
        btn.Parent = self.titleBar

        if btnType == "close" then
            btn.MouseButton1Click:Connect(function()
                self:close()
            end)
        elseif btnType == "minimize" then
            btn.MouseButton1Click:Connect(function()
                self:minimize()
            end)
        elseif btnType == "maximize" then
            btn.MouseButton1Click:Connect(function()
                self:maximize()
            end)
        end
    end

    -- 拖动功能
    local dragging = false
    local dragStart = nil
    local frameStart = nil

    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = self.frame.Position
        end
    end)

    self.titleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self.contentContainer = Instance.new("Frame")
    self.contentContainer.Size = UDim2.new(1, 0, 1, -self.theme.TitleBarHeight)
    self.contentContainer.Position = UDim2.new(0, 0, 0, self.theme.TitleBarHeight)
    self.contentContainer.BackgroundTransparency = 1
    self.contentContainer.Parent = self.frame

    self.tabManager = TabManager.new(self.contentContainer, self.theme)

    return self
end

function Window:addTab(name, contentBuilder)
    return self.tabManager:addTab(name, contentBuilder)
end

function Window:close()
    self.gui:Destroy()
    self:fire("Close")
end

function Window:minimize()
    self.frame.Size = UDim2.new(0, 300, 0, self.theme.TitleBarHeight)
    self.contentContainer.Visible = false
    self:fire("Minimize")
end

function Window:maximize()
    self.frame.Size = UDim2.new(1, 0, 1, 0)
    self.frame.Position = UDim2.new(0, 0, 0, 0)
    self.contentContainer.Visible = true
    self:fire("Maximize")
end

function Window:restore()
    self.frame.Size = self.originalSize
    self.frame.Position = self.originalPosition
    self.contentContainer.Visible = true
    self:fire("Restore")
end

function Window:on(event, callback)
    if not self.events then self.events = {} end
    if not self.events[event] then
        self.events[event] = Instance.new("BindableEvent")
    end
    return self.events[event].Event:Connect(callback)
end

function Window:fire(event, ...)
    if self.events and self.events[event] then
        self.events[event]:Fire(...)
    end
end

-- ============================================================
-- 主库导出
-- ============================================================
local WasUI = {}

-- 图标库加载
WasUI.loadIconLibrary = loadIconLibrary
WasUI.Icon = WasUI.Icon  -- 已经在前面定义

function WasUI.init(windowFolder)
    WasUI.configManager = ConfigManager.new(windowFolder)
    WasUI.loadIconLibrary()
    createStatusPanel()
    return WasUI
end

function WasUI.createWindow(title, options)
    return Window.new(title, options or {theme = DefaultTheme})
end

-- 预设按钮样式
local ButtonPresets = {
    Primary = {
        BackgroundColor3 = "Primary",
        TextColor3 = "Text",
        TextSize = 18,
        Padding = UDim.new(0, 20),
    },
    Secondary = {
        BackgroundTransparency = 1,
        TextColor3 = "Primary",
        BorderColor3 = "Primary",
        BorderSizePixel = 2,
        TextSize = 16,
        Padding = UDim.new(0, 16),
    },
    Danger = {
        BackgroundColor3 = "Danger",
        TextColor3 = "Text",
        TextSize = 18,
        Padding = UDim.new(0, 20),
    },
    Text = {
        BackgroundTransparency = 1,
        TextColor3 = "Primary",
        BorderSizePixel = 0,
        TextSize = 16,
        Padding = UDim.new(0, 12),
    },
}

function WasUI.createButton(parent, text, presetName, customOptions)
    local preset = ButtonPresets[presetName] or ButtonPresets.Primary
    return Button.new(parent, text, preset, customOptions, DefaultTheme)
end

function WasUI.createLabel(parent, text, customOptions)
    return Label.new(parent, text, customOptions, DefaultTheme)
end

function WasUI.createTextBox(parent, placeholder, customOptions)
    return TextBox.new(parent, placeholder, customOptions, DefaultTheme)
end

function WasUI.createToggle(parent, text, initialState, customOptions)
    local toggle = Toggle.new(parent, text, initialState, customOptions, DefaultTheme)
    registerToggle(toggle, text)
    return toggle
end

function WasUI.createSlider(parent, min, max, defaultValue, customOptions)
    return Slider.new(parent, min, max, defaultValue, customOptions, DefaultTheme)
end

-- 自动挂载
function WasUI.autoMount(screenGuiName)
    local player = Players.LocalPlayer
    if not player then
        warn("[WasUI] No LocalPlayer found.")
        return nil
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = screenGuiName or "WasUI"
    gui.Parent = player.PlayerGui
    return gui
end

-- 配置管理器（简化版）
local ConfigManager = {}
ConfigManager.__index = ConfigManager

local hasFileSystem = pcall(function()
    return isfolder and makefolder and writefile and readfile
end)

function ConfigManager.new(windowFolder)
    local self = setmetatable({}, ConfigManager)
    self.Folder = windowFolder
    self.Path = hasFileSystem and "WindUI/" .. tostring(windowFolder) .. "/config/" or nil
    self.Configs = {}

    if hasFileSystem then
        local root = "WindUI/" .. windowFolder
        if not isfolder(root) then
            makefolder(root)
        end
        if not isfolder(self.Path) then
            makefolder(self.Path)
        end
    else
        warn("[WasUI] File system not available, configs will be stored in memory only.")
    end

    return self
end

function ConfigManager:CreateConfig(configName, autoLoad)
    local config = {
        Name = configName,
        Path = self.Path and (self.Path .. configName .. ".json") or nil,
        Elements = {},
        CustomData = {},
        AutoLoad = autoLoad or false,
        Version = 1.0,
    }

    function config:Register(element, key, defaultValue)
        self.Elements[element] = {
            key = key,
            defaultValue = defaultValue,
        }
    end

    function config:Save()
        if not hasFileSystem or not self.Path then return false end
        local data = {}
        for element, info in pairs(self.Elements) do
            local value = element:getValue()
            data[info.key] = value
        end
        for k, v in pairs(self.CustomData) do
            data[k] = v
        end
        data.__autoload = self.AutoLoad
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if success then
            pcall(writefile, self.Path, encoded)
            return true
        end
        return false
    end

    function config:Load()
        if not hasFileSystem or not self.Path then return false end
        if not isfile(self.Path) then return false end
        local success, content = pcall(readfile, self.Path)
        if not success then return false end
        local success2, data = pcall(HttpService.JSONDecode, HttpService, content)
        if not success2 then return false end
        for element, info in pairs(self.Elements) do
            local value = data[info.key]
            if value ~= nil then
                element:setValue(value)
            elseif info.defaultValue ~= nil then
                element:setValue(info.defaultValue)
            end
        end
        for k, v in pairs(data) do
            if k ~= "__autoload" then
                self.CustomData[k] = v
            end
        end
        return true
    end

    function config:SetCustomData(key, value)
        self.CustomData[key] = value
    end

    function config:GetCustomData(key, defaultValue)
        return self.CustomData[key] or defaultValue
    end

    if autoLoad then
        task.spawn(function()
            task.wait(0.5)
            config:Load()
        end)
    end

    self.Configs[configName] = config
    return config
end

function ConfigManager:AllConfigs()
    if not hasFileSystem or not self.Path then return {} end
    local files = {}
    local success, list = pcall(function()
        return listfiles(self.Path)
    end)
    if success then
        for _, file in ipairs(list) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(files, name)
            end
        end
    end
    return files
end

WasUI.ConfigManager = ConfigManager
WasUI.getConfigManager = function() return WasUI.configManager end
WasUI.createConfig = function(configName, autoLoad)
    if not WasUI.configManager then
        warn("[WasUI] ConfigManager not initialized. Call WasUI.init(windowFolder) first.")
        return nil
    end
    return WasUI.configManager:CreateConfig(configName, autoLoad)
end

-- 工具函数
function WasUI.setTheme(newTheme)
    for k, v in pairs(newTheme) do
        DefaultTheme[k] = v
    end
end

function WasUI.getTheme()
    return DefaultTheme
end

function WasUI.resolveColor(color)
    if type(color) == "string" then
        return DefaultTheme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

-- 预设注册
function WasUI.registerPreset(name, preset)
    ButtonPresets[name] = preset
end

-- 设置图标（手动覆盖）
function WasUI.setIcon(name, imageId)
    -- 可选：手动覆盖图标库映射
    -- 此处简单实现，实际可扩展
end

return WasUI