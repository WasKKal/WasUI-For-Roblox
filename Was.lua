-- ============================================================
-- 1. 加载服务
-- ============================================================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- ============================================================
-- 2. 主题配置 (默认主题)
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
    },
    Font = Enum.Font.GothamMedium,
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 1,
    Shadow = false,
    InputHeight = 36,
    SliderHeight = 4,
}

-- ============================================================
-- 3. 按钮预设
-- ============================================================
local ButtonPresets = {
    Primary = {
        BackgroundColor3 = "Primary",
        TextColor3 = "Text",
        BorderColor3 = nil,
        CornerRadius = nil,
        Font = nil,
        TextSize = 18,
        Padding = UDim.new(0, 20),
    },
    Secondary = {
        BackgroundTransparency = 1,
        TextColor3 = "Primary",
        BorderColor3 = "Primary",
        BorderSizePixel = 2,
        CornerRadius = nil,
        Font = nil,
        TextSize = 16,
        Padding = UDim.new(0, 16),
    },
    Danger = {
        BackgroundColor3 = "Danger",
        TextColor3 = "Text",
        BorderColor3 = nil,
        CornerRadius = nil,
        Font = nil,
        TextSize = 18,
        Padding = UDim.new(0, 20),
    },
    Text = {
        BackgroundTransparency = 1,
        TextColor3 = "Primary",
        BorderSizePixel = 0,
        CornerRadius = nil,
        Font = nil,
        TextSize = 16,
        Padding = UDim.new(0, 12),
    },
}

-- ============================================================
-- 4. 控件基类
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
    self.theme = nil -- 会在子类中设置
    return self
end

function BaseControl:applyEffects(instance, options)
    -- 圆角
    if options.CornerRadius ~= false then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = options.CornerRadius or self.theme.CornerRadius
        corner.Parent = instance
    end
    -- 描边
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
-- 5. 按钮控件
-- ============================================================
local Button = setmetatable({}, BaseControl)
Button.__index = Button

function Button.new(parent, text, preset, customOptions, theme)
    local self = BaseControl.new(parent, "Button")
    self.theme = theme
    self.preset = preset or {}
    self.options = {}
    self.text = text or ""

    -- 合并预设和自定义选项
    for k, v in pairs(self.preset) do
        self.options[k] = v
    end
    for k, v in pairs(customOptions or {}) do
        self.options[k] = v
    end

    -- 创建 TextButton
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

    -- 内边距
    if self.options.Padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = self.options.Padding
        padding.PaddingRight = self.options.Padding
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = button
    end

    -- 应用效果
    self:applyEffects(button, self.options)

    -- 动画
    local scale = Instance.new("UIScale")
    scale.Parent = button
    scale.Scale = 1

    button.MouseEnter:Connect(function()
        if not self.enabled then return end
        local tween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.05})
        tween:Play()
    end)
    button.MouseLeave:Connect(function()
        if not self.enabled then return end
        local tween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
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
-- 6. 标签控件
-- ============================================================
local Label = setmetatable({}, BaseControl)
Label.__index = Label

function Label.new(parent, text, customOptions, theme)
    local self = BaseControl.new(parent, "Label")
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
-- 7. 输入框控件
-- ============================================================
local TextBox = setmetatable({}, BaseControl)
TextBox.__index = TextBox

function TextBox.new(parent, placeholder, customOptions, theme)
    local self = BaseControl.new(parent, "TextBox")
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

    -- 内边距
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
-- 8. 复选框控件
-- ============================================================
local Checkbox = setmetatable({}, BaseControl)
Checkbox.__index = Checkbox

function Checkbox.new(parent, text, initialState, customOptions, theme)
    local self = BaseControl.new(parent, "Checkbox")
    self.theme = theme
    self.options = customOptions or {}
    self.text = text or ""
    self.checked = initialState or false

    -- 主容器 Frame
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 200, 0, 30)

    -- 复选框按钮
    local box = Instance.new("ImageButton")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(0, 0, 0.5, -10)
    box.BackgroundColor3 = self:resolveColor(self.options.BackgroundColor3) or self.theme.Colors.InputBackground
    box.BackgroundTransparency = 0
    box.BorderSizePixel = 0
    box.Image = "rbxassetid://0"
    box.AutoButtonColor = false
    self:applyEffects(box, self.options)

    -- 勾选图标（勾时显示）
    local checkIcon = Instance.new("ImageLabel")
    checkIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
    checkIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
    checkIcon.BackgroundTransparency = 1
    checkIcon.Image = "rbxassetid://13736108106" -- 勾选图标
    checkIcon.Visible = self.checked
    checkIcon.Parent = box

    -- 文本标签
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Text = self.text
    label.BackgroundTransparency = 1
    label.TextColor3 = self:resolveColor(self.options.TextColor3) or self.theme.Colors.Text
    label.TextSize = self.options.TextSize or 16
    label.Font = self.options.Font or self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    -- 点击切换状态
    box.MouseButton1Click:Connect(function()
        if not self.enabled then return end
        self.checked = not self.checked
        checkIcon.Visible = self.checked
        self:fire("Changed", self.checked)
    end)

    box.Parent = container
    self.instance = container
    self.box = box
    self.checkIcon = checkIcon
    self.label = label
    self:setParent(parent)
    return self
end

function Checkbox:resolveColor(color)
    if type(color) == "string" then
        return self.theme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

function Checkbox:isChecked()
    return self.checked
end

function Checkbox:setChecked(checked)
    self.checked = checked
    if self.checkIcon then
        self.checkIcon.Visible = checked
    end
    self:fire("Changed", checked)
end

function Checkbox:setText(text)
    self.text = text
    if self.label then
        self.label.Text = text
    end
end

-- ============================================================
-- 9. 滑块控件
-- ============================================================
local Slider = setmetatable({}, BaseControl)
Slider.__index = Slider

function Slider.new(parent, min, max, defaultValue, customOptions, theme)
    local self = BaseControl.new(parent, "Slider")
    self.theme = theme
    self.options = customOptions or {}
    self.min = min or 0
    self.max = max or 100
    self.value = math.clamp(defaultValue or self.min, self.min, self.max)

    -- 容器
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 200, 0, 30)

    -- 轨道背景
    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1, 0, 0, 4)
    trackBg.Position = UDim2.new(0, 0, 0.5, -2)
    trackBg.BackgroundColor3 = self:resolveColor(self.options.TrackColor) or Color3.fromRGB(80, 80, 80)
    trackBg.BorderSizePixel = 0
    trackBg.Parent = container
    self:applyEffects(trackBg, self.options)

    -- 填充条
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((self.value - self.min) / (self.max - self.min), 0, 1, 0)
    fill.BackgroundColor3 = self:resolveColor(self.options.FillColor) or self.theme.Colors.Primary
    fill.BorderSizePixel = 0
    fill.Parent = trackBg

    -- 滑块按钮
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

    -- 数值显示（可选）
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

    -- 鼠标拖动更新
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
            local mouse = game.Players.LocalPlayer:GetMouse()
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
-- 10. 配置管理器
-- ============================================================
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

    function config:SetAsCurrent()
        self.Parent = self
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

-- ============================================================
-- 11. 主库模块
-- ============================================================
local WasUI = {}

-- 当前主题
local currentTheme = DefaultTheme

-- 配置管理器实例（全局）
WasUI.configManager = nil

-- 初始化（必须调用，传入窗口名称）
function WasUI.init(windowFolder)
    WasUI.configManager = ConfigManager.new(windowFolder)
    return WasUI
end

-- 设置主题
function WasUI.setTheme(newTheme)
    for k, v in pairs(newTheme) do
        currentTheme[k] = v
    end
end

-- 获取当前主题
function WasUI.getTheme()
    return currentTheme
end

-- 注册自定义预设
function WasUI.registerPreset(name, preset)
    ButtonPresets[name] = preset
end

-- ========== 控件创建 ==========
function WasUI.createButton(parent, text, presetName, customOptions)
    local preset = ButtonPresets[presetName] or ButtonPresets.Primary
    return Button.new(parent, text, preset, customOptions, currentTheme)
end

function WasUI.createLabel(parent, text, customOptions)
    return Label.new(parent, text, customOptions, currentTheme)
end

function WasUI.createTextBox(parent, placeholder, customOptions)
    return TextBox.new(parent, placeholder, customOptions, currentTheme)
end

function WasUI.createCheckbox(parent, text, initialState, customOptions)
    return Checkbox.new(parent, text, initialState, customOptions, currentTheme)
end

function WasUI.createSlider(parent, min, max, defaultValue, customOptions)
    return Slider.new(parent, min, max, defaultValue, customOptions, currentTheme)
end

-- ========== 自动挂载UI位置 ==========
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

-- ========== 配置管理辅助 ==========
function WasUI.getConfigManager()
    return WasUI.configManager
end

function WasUI.createConfig(configName, autoLoad)
    if not WasUI.configManager then
        warn("[WasUI] ConfigManager not initialized. Call WasUI.init(windowFolder) first.")
        return nil
    end
    return WasUI.configManager:CreateConfig(configName, autoLoad)
end

-- ========== 工具函数 ==========
function WasUI.resolveColor(color)
    if type(color) == "string" then
        return currentTheme.Colors[color]
    elseif type(color) == "Color3" then
        return color
    end
    return nil
end

-- ============================================================
-- 12. 返回主库
-- ============================================================
return WasUI