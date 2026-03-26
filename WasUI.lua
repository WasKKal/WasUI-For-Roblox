-- WasUI Library
-- 一个轻量级、可扩展的Roblox UI框架

local WasUI = {}
WasUI.__index = WasUI

-- 服务引用
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 创建主配置文件夹
local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

-- 主题系统
WasUI.Themes = {
    Default = {
        Primary = Color3.fromRGB(41, 128, 185),
        Secondary = Color3.fromRGB(52, 152, 219),
        Background = Color3.fromRGB(236, 240, 241),
        Text = Color3.fromRGB(44, 62, 80),
        Accent = Color3.fromRGB(231, 76, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
    },
    Dark = {
        Primary = Color3.fromRGB(30, 30, 36),
        Secondary = Color3.fromRGB(40, 40, 46),
        Background = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123)
    }
}

-- 当前主题
WasUI.CurrentTheme = WasUI.Themes.Default

-- 工具函数
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        easingStyle,
        easingDirection
    )
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- 控件基类
local Control = {}
Control.__index = Control

function Control:New(name, parent)
    local self = setmetatable({}, Control)
    self.Name = name
    self.Parent = parent
    self.Instance = nil
    self.Visible = true
    return self
end

function Control:SetPosition(position)
    if self.Instance then
        self.Instance.Position = position
    end
end

function Control:SetSize(size)
    if self.Instance then
        self.Instance.Size = size
    end
end

function Control:SetVisible(visible)
    self.Visible = visible
    if self.Instance then
        self.Instance.Visible = visible
    end
end

-- 按钮控件
local Button = setmetatable({}, {__index = Control})
Button.__index = Button

function Button:New(name, parent, text, onClick)
    local self = Control.New(self, name, parent)
    
    -- 创建按钮实例
    self.Instance = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(0, 200, 0, 50),
        Position = UDim2.new(0.5, -100, 0.5, -25),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "Button",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = parent
    })
    
    -- 圆角
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Instance
    })
    
    -- 悬停效果
    self.Instance.MouseEnter:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
    end)
    
    self.Instance.MouseLeave:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
    end)
    
    -- 点击效果
    self.Instance.MouseButton1Down:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
    end)
    
    self.Instance.MouseButton1Up:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
        if onClick then onClick() end
    end)
    
    return self
end

-- 图标按钮
function Button:WithIcon(iconId)
    if not self.Icon then
        self.Icon = CreateInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 10, 0.5, -12),
            BackgroundTransparency = 1,
            Image = iconId,
            Parent = self.Instance
        })
        
        self.Instance.TextXAlignment = Enum.TextXAlignment.Right
        self.Instance.Text = "  " .. (self.Instance.Text or "")
    end
    return self
end

-- 开关按钮
function Button:AsToggle(initialState, onToggle)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    
    if self.Toggled then
        self.Instance.BackgroundColor3 = WasUI.CurrentTheme.Success
    end
    
    self.Instance.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        if self.Toggled then
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
        else
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
    end)
    
    return self
end

-- 标签控件
local Label = setmetatable({}, {__index = Control})
Label.__index = Label

function Label:New(name, parent, text)
    local self = Control.New(self, name, parent)
    
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0.5, -100, 0.5, -15),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    
    return self
end

-- 输入框控件
local TextBox = setmetatable({}, {__index = Control})
TextBox.__index = TextBox

function TextBox:New(name, parent, placeholder, onTextChanged)
    local self = Control.New(self, name, parent)
    
    -- 背景框
    self.Frame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(0, 250, 0, 40),
        Position = UDim2.new(0.5, -125, 0.5, -20),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Frame
    })
    
    -- 输入框
    self.Instance = CreateInstance("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -20, 1, -10),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder or "Enter text...",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        ClearTextOnFocus = false,
        Parent = self.Frame
    })
    
    -- 事件
    if onTextChanged then
        self.Instance:GetPropertyChangedSignal("Text"):Connect(function()
            onTextChanged(self.Instance.Text)
        end)
    end
    
    return self
end

-- 面板容器
local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = Control.New(self, name, parent)
    
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = size or UDim2.new(0, 300, 0, 200),
        Position = position or UDim2.new(0.5, -150, 0.5, -100),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Instance
    })
    
    -- 标题栏
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    local titleCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.TitleBar
    })
    
    -- 修复圆角
    local bottomFix = CreateInstance("Frame", {
        Name = "BottomFix",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.TitleBar
    })
    
    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- 关闭按钮
    self.CloseButton = CreateInstance("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        Parent = self.TitleBar
    })
    
    self.CloseButton.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)
    
    -- 内容区域
    self.Content = CreateInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })
    
    return self
end

-- 向面板添加控件
function Panel:AddToContent(control)
    control.Parent = self.Content
    return control
end

-- 库主函数
function WasUI:CreateWindow(title, size, position)
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Window",
        ResetOnSpawn = false,
        Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    })
    
    local window = Panel:New(title, screenGui, size, position)
    return window
end

-- 配置管理
function WasUI:SaveConfig(key, data)
    local configValue = WasUI_Folder:FindFirstChild(key)
    if not configValue then
        configValue = CreateInstance("StringValue", {
            Name = key,
            Parent = WasUI_Folder
        })
    end
    -- 实际项目中应使用HttpService:JSONEncode(data)
    configValue.Value = tostring(data)
end

function WasUI:LoadConfig(key, default)
    local configValue = WasUI_Folder:FindFirstChild(key)
    if configValue and configValue.Value ~= "" then
        -- 实际项目中应使用HttpService:JSONDecode(configValue.Value)
        return configValue.Value
    end
    return default
end

-- 返回公共接口
return {
    CreateWindow = function(title, size, position)
        return WasUI:CreateWindow(title, size, position)
    end,
    CreateButton = function(parent, text, onClick)
        return Button:New("Button", parent, text, onClick)
    end,
    CreateLabel = function(parent, text)
        return Label:New("Label", parent, text)
    end,
    CreateTextBox = function(parent, placeholder, onTextChanged)
        return TextBox:New("TextBox", parent, placeholder, onTextChanged)
    end,
    CreatePanel = function(parent, size, position)
        return Panel:New("Panel", parent, size, position)
    end,
    SaveConfig = function(key, data)
        WasUI:SaveConfig(key, data)
    end,
    LoadConfig = function(key, default)
        return WasUI:LoadConfig(key, default)
    end,
    SetTheme = function(themeName)
        if WasUI.Themes[themeName] then
            WasUI.CurrentTheme = WasUI.Themes[themeName]
        end
    end
}
