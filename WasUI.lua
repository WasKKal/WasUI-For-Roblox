local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if _G.WasUILoaded then
    warn("WasUI 已加载，跳过重复加载")
    return _G.WasUIModule
end
_G.WasUILoaded = true

WasUI.DefaultDisplayOrder = 10

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

WasUI.Themes = {
    Dark = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(25, 25, 30),
        Background = Color3.fromRGB(28, 28, 34),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123),
        Section = Color3.fromRGB(45, 45, 50),
        Input = Color3.fromRGB(45, 45, 50),
        TabBorder = Color3.fromRGB(60, 60, 65),
        TabButton = Color3.fromRGB(0, 0, 0)
    }
}
WasUI.CurrentTheme = WasUI.Themes.Dark
WasUI.Objects = {}
WasUI.ActiveRainbowTexts = {}

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
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function UpdateAllRainbowTextPositions()
    local sorted = {}
    for name, data in pairs(WasUI.ActiveRainbowTexts) do
        table.insert(sorted, {Name = name, Data = data})
    end
    table.sort(sorted, function(a, b)
        return a.Data.CreatedTime < b.Data.CreatedTime
    end)
    
    for i, v in ipairs(sorted) do
        local targetY = 10 + (i - 1) * 26
        Tween(v.Data.ScreenGui, {Position = UDim2.new(1, -190, 0, targetY)}, 0.2)
    end
end

local function CreateRainbowTextForFeature(featureName)
    if WasUI.ActiveRainbowTexts[featureName] then return end
    
    local screenGui = CreateInstance("ScreenGui", {
        Name = "FeatureRainbowText_" .. featureName,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = game:GetService("CoreGui")
    })
    local textLabel = CreateInstance("TextLabel", {
        Name = "RainbowText",
        Size = UDim2.new(0, 180, 0, 24),
        Position = UDim2.new(1, -190, 0, 10),
        BackgroundTransparency = 1,
        Text = featureName,
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        Parent = screenGui
    })
    
    local rainbowSpeed = 4
    local time = 0
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * rainbowSpeed
        local r = (math.sin(time) + 1) / 2
        local g = (math.sin(time + math.pi/3) + 1) / 2
        local b = (math.sin(time + 2*math.pi/3) + 1) / 2
        textLabel.TextColor3 = Color3.new(r, g, b)
    end)
    
    WasUI.ActiveRainbowTexts[featureName] = {
        ScreenGui = screenGui,
        Connection = connection,
        CreatedTime = tick()
    }
    UpdateAllRainbowTextPositions()
end

local function DestroyRainbowTextForFeature(featureName)
    local data = WasUI.ActiveRainbowTexts[featureName]
    if data then
        data.ScreenGui:Destroy()
        data.Connection:Disconnect()
        WasUI.ActiveRainbowTexts[featureName] = nil
        UpdateAllRainbowTextPositions()
    end
end

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

local Button = setmetatable({}, {__index = Control})
Button.__index = Button
function Button:New(name, parent, text, onClick)
    local self = Control.New(self, name, parent)
    self.Instance = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "Button",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent
    })
    self.Instance.MouseEnter:Connect(function() 
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
    end)
    self.Instance.MouseLeave:Connect(function() 
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
    end)
    self.Instance.MouseButton1Click:Connect(function()
        if onClick then onClick() end
    end)
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, initialState, onToggle, featureName)
    local self = Control.New(self, name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = featureName or name

    self.Background = CreateInstance("ImageButton", {
        Name = "BG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -40, 0.5, -9),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Background})
    
    self.Knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Toggled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Background
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Knob})

    if self.Toggled then
        CreateRainbowTextForFeature(self.FeatureName)
    end

    self.Background.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.2)
            CreateRainbowTextForFeature(self.FeatureName)
        else
            Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
            DestroyRainbowTextForFeature(self.FeatureName)
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
    end)
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label
function Label:New(name, parent, text)
    local self = Control.New(self, name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = parent
    })
    return self
end

local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback)
    local self = Control.New(self, name, parent)
    self.Options = options or {}
    self.SelectedValue = defaultValue
    self.Callback = callback
    self.IsOpen = false

    self.Container = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = parent
    })

    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = self.Container
    })

    self.DropButton = CreateInstance("TextButton", {
        Name = "DropButton",
        Size = UDim2.new(0.3, 0, 0, 24),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        Text = defaultValue,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 11,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.DropButton})

    self.OptionsContainer = CreateInstance("Frame", {
        Name = "OptionsContainer",
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        Visible = false,
        ClipsDescendants = false,
        ZIndex = 9999,
        Parent = parent.Parent.Parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.OptionsContainer})

    local layout = CreateInstance("UIListLayout", {Parent = self.OptionsContainer})
    for i, opt in ipairs(options) do
        local btn = CreateInstance("TextButton", {
            Name = "Opt_" .. opt,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            Text = opt,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = self.OptionsContainer
        })
        btn.MouseButton1Click:Connect(function()
            self.SelectedValue = opt
            self.DropButton.Text = opt
            self.IsOpen = false
            Tween(self.OptionsContainer, {Size = UDim2.new(0, self.DropButton.AbsoluteSize.X, 0, 0)}, 0.2)
            task.wait(0.2)
            self.OptionsContainer.Visible = false
            if callback then callback(opt) end
        end)
    end

    self.DropButton.MouseButton1Click:Connect(function()
        self.IsOpen = not self.IsOpen
        if self.IsOpen then
            self.OptionsContainer.Position = UDim2.new(0, self.DropButton.AbsolutePosition.X, 0, self.DropButton.AbsolutePosition.Y + 24)
            self.OptionsContainer.Size = UDim2.new(0, self.DropButton.AbsoluteSize.X, 0, 0)
            self.OptionsContainer.Visible = true
            local h = #options * 24
            Tween(self.OptionsContainer, {Size = UDim2.new(0, self.DropButton.AbsoluteSize.X, 0, h)}, 0.3)
        else
            Tween(self.OptionsContainer, {Size = UDim2.new(0, self.DropButton.AbsoluteSize.X, 0, 0)}, 0.2)
            task.wait(0.2)
            self.OptionsContainer.Visible = false
        end
    end)
    return self
end

local Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider
function Slider:New(name, parent, title, min, max, default, callback)
    local self = Control.New(self, name, parent)
    self.Min = min
    self.Max = max
    self.Value = default or min
    self.Callback = callback

    self.Container = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = parent
    })

    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = self.Container
    })

    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.3, 0, 0, 20),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Container
    })

    self.Track = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(0.94, 0, 0, 8),
        Position = UDim2.new(0.03, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(60, 60, 65),
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Track})

    self.Fill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - min)/(max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = self.Track
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Fill})

    local dragging = false
    self.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = self.Track.AbsolutePosition
            local size = self.Track.AbsoluteSize
            local x = math.clamp(input.Position.X - pos.X, 0, size.X)
            local percent = x / size.X
            self.Value = math.round(min + (max - min) * percent)
            self.ValueLabel.Text = tostring(self.Value)
            Tween(self.Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
            if callback then callback(self.Value) end
        end
    end)
    return self
end

WasUI.Notifications = {}
function WasUI:Notify(opt)
    local root = game:GetService("CoreGui")
    local sg = CreateInstance("ScreenGui", {Parent = root, ResetOnSpawn = false, DisplayOrder = 999})
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(0, 240, 0, 30),
        Position = UDim2.new(1, -260, 0, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.2,
        Parent = sg
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    local text = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = opt.Content,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        Parent = frame
    })
    task.wait(opt.Duration or 2)
    sg:Destroy()
end

local Panel = {}
Panel.__index = Panel
function Panel:New(title, parent, size)
    local self = setmetatable({}, Panel)
    self.Tabs = {}
    self.TabContents = {}
    self.ActiveTab = nil

    self.Main = CreateInstance("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -190, 0.5, -175),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 0.25,
        Parent = parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Main})

    self.Border = CreateInstance("Frame", {
        Name = "Border",
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        BackgroundTransparency = 1,
        Parent = self.Main
    })
    local stroke = CreateInstance("UIStroke", {
        Thickness = 2,
        Color = Color3.fromRGB(255,0,0),
        Parent = self.Border
    })
    local t = 0
    RunService.Heartbeat:Connect(function(dt)
        t += dt * 4
        stroke.Color = Color3.new(
            (math.sin(t)+1)/2,
            (math.sin(t+math.pi/3)+1)/2,
            (math.sin(t+2*math.pi/3)+1)/2
        )
    end)

    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        Parent = self.Main
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.TitleBar})

    self.DotGroup = CreateInstance("Frame", {
        Name = "Dots",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })

    self.Close = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 0, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(255,95,87),
        Parent = self.DotGroup
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1,0), Parent = self.Close})

    self.Min = CreateInstance("Frame", {
        Name = "Min",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 16, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(255,189,46),
        Parent = self.DotGroup
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1,0), Parent = self.Min})

    self.Max = CreateInstance("Frame", {
        Name = "Max",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 32, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(39,201,63),
        Parent = self.DotGroup
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1,0), Parent = self.Max})

    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })

    local drag = false
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            local start = self.Main.Position
            local p = input.Position
            UserInputService.InputChanged:Connect(function(move)
                if drag and move.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = move.Position - p
                    self.Main.Position = UDim2.new(start.X.Scale, start.X.Offset + delta.X, start.Y.Scale, start.Y.Offset + delta.Y)
                end
            end)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)

    self.Close.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Main.Visible = false
            for k, v in pairs(WasUI.ActiveRainbowTexts) do
                v.ScreenGui:Destroy()
                v.Connection:Disconnect()
            end
            WasUI.ActiveRainbowTexts = {}
        end
    end)

    self.Announce = CreateInstance("Frame", {
        Name = "Announce",
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.4,
        Parent = self.Main
    })

    self.Avatar = CreateInstance("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(40,40,45),
        Parent = self.Announce
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0,8), Parent = self.Avatar})

    self.UserText = CreateInstance("TextLabel", {
        Name = "UserText",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 62.4, 0.12, 0),
        BackgroundTransparency = 1,
        Text = "Player: "..Players.LocalPlayer.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Parent = self.Announce
    })
    self.Welcome = CreateInstance("TextLabel", {
        Name = "Welcome",
        Size = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 62.4, 0.55, 0),
        BackgroundTransparency = 1,
        Text = "Welcome",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = self.Announce
    })

    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 106),
        BackgroundColor3 = Color3.fromRGB(50,50,55),
        BackgroundTransparency = 0.3,
        Parent = self.Main
    })
    CreateInstance("Frame", {Size = UDim2.new(1,0,0,1), BackgroundColor3 = WasUI.CurrentTheme.TabBorder, Parent = self.TabBar})
    CreateInstance("Frame", {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = WasUI.CurrentTheme.TabBorder, Parent = self.TabBar})

    self.TabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0,0),
        Parent = self.TabBar
    })

    self.Content = CreateInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -10, 1, -130),
        Position = UDim2.new(0, 5, 0, 130),
        BackgroundTransparency = 1,
        Parent = self.Main
    })

    self.IsMinimized = false
    self.OriginSize = self.Main.Size
    self.MinSize = UDim2.new(0, 60, 0, 26)

    self.Min.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self.IsMinimized then
                Tween(self.Main, {Size = self.MinSize}, 0.4)
                self.Announce.Visible = false
                self.TabBar.Visible = false
                self.Content.Visible = false
                self.Title.Visible = false
                self.IsMinimized = true
            else
                Tween(self.Main, {Size = self.OriginSize}, 0.4)
                self.Announce.Visible = true
                self.TabBar.Visible = true
                self.Content.Visible = true
                self.Title.Visible = true
                self.IsMinimized = false
            end
        end
    end)
    return self
end

function Panel:SetWelcomeText(text)
    self.Welcome.Text = text
end

function Panel:AddTab(name)
    local btn = CreateInstance("TextButton", {
        Name = name.."Tab",
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.TabButton,
        BackgroundTransparency = 0.7,
        Text = name,
        TextColor3 = Color3.fromRGB(100,100,105),
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.TabBar
    })
    local line = CreateInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(0,0,0,2),
        Position = UDim2.new(0.5,0,1,-2),
        AnchorPoint = Vector2.new(0.5,1),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        Parent = btn
    })

    local content = CreateInstance("ScrollingFrame", {
        Name = name.."Content",
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 0,
        Parent = self.Content
    })
    CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,4),
        Parent = content
    })

    btn.MouseButton1Click:Connect(function()
        for _, tab in pairs(self.Tabs) do
            Tween(tab.Button, {BackgroundTransparency = 0.7, TextColor3 = Color3.fromRGB(100,100,105)}, 0.2)
            Tween(tab.Line, {Size = UDim2.new(0,0,0,2), BackgroundTransparency = 1}, 0.2)
            tab.Content.Visible = false
        end
        Tween(btn, {BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
        Tween(line, {Size = UDim2.new(0.8,0,0,2), BackgroundTransparency = 0}, 0.2)
        content.Visible = true
        self.ActiveTab = name
    end)

    local tab = {
        Button = btn,
        Line = line,
        Content = content
    }
    table.insert(self.Tabs, tab)
    self.TabContents[name] = content

    if #self.Tabs == 1 then
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        line.Size = UDim2.new(0.8,0,0,2)
        line.BackgroundTransparency = 0
        content.Visible = true
    end
    return content
end

function Panel:AddTitle(text, tab)
    local target = self.TabContents[tab]
    local lbl = CreateInstance("TextLabel", {
        Size = UDim2.new(1,0,0,28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = target
    })
    return lbl
end

function Panel:AddLabel(text, tab)
    local target = self.TabContents[tab]
    return Label:New("Label", target, text)
end

function Panel:AddButton(text, cb, tab)
    local target = self.TabContents[tab]
    return Button:New("Btn", target, text, cb)
end

function Panel:AddToggle(text, default, cb, tab)
    local target = self.TabContents[tab]
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(1,0,0,28),
        BackgroundTransparency = 1,
        Parent = target
    })
    CreateInstance("TextLabel", {
        Size = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = frame
    })
    return ToggleSwitch:New("Toggle", frame, default, cb, text)
end

function Panel:AddDropdown(title, opts, default, cb, tab)
    local target = self.TabContents[tab]
    return Dropdown:New("Drop", target, title, opts, default, cb)
end

function Panel:AddSlider(title, min, max, def, cb, tab)
    local target = self.TabContents[tab]
    return Slider:New("Slider", target, title, min, max, def, cb)
end

function WasUI:CreateWindow(title, size)
    local sg = CreateInstance("ScreenGui", {
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false,
        DisplayOrder = self.DefaultDisplayOrder
    })
    return Panel:New(title, sg, size)
end

_G.WasUIModule = WasUI
return WasUI
