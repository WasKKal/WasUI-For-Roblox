local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

if _G.WasUILoaded then return _G.WasUIModule end
_G.WasUILoaded = true

WasUI.DefaultDisplayOrder = 10
WasUI.DialogTitle = "确定关闭吗？"
WasUI.DefaultNotificationTitle = "通知"

WasUI.NotificationWidth = 260
WasUI.NotificationHeight = 32
WasUI.NotificationSpacing = 6
WasUI.NotificationTop = 16
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}

WasUI.Themes = {
    Dark = {
        Background = Color3.fromRGB(22,22,26),
        Primary = Color3.fromRGB(32,32,38),
        Secondary = Color3.fromRGB(42,42,48),
        Text = Color3.fromRGB(230,230,230),
        Accent = Color3.fromRGB(30,80,180),
        Success = Color3.fromRGB(50,180,100),
        Warning = Color3.fromRGB(230,170,50),
        Error = Color3.fromRGB(210,70,70),
    }
}
WasUI.CurrentTheme = WasUI.Themes.Dark

WasUI.Objects = {}
WasUI.ActiveRainbowTexts = {}
WasUI.RainbowOrder = {}

local CoreGui = game:GetService("CoreGui")

local DropdownGui = Instance.new("ScreenGui")
DropdownGui.Name = "WasUI_Dropdowns"
DropdownGui.ResetOnSpawn = false
DropdownGui.DisplayOrder = 1000
DropdownGui.Parent = CoreGui

local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "WasUI_Notifications"
NotificationGui.ResetOnSpawn = false
NotificationGui.DisplayOrder = 999
NotificationGui.Parent = CoreGui

local function Create(obj, props)
    local i = Instance.new(obj)
    for k,v in pairs(props) do i[k] = v end
    return i
end

local function Tween(obj, goals, t)
    return TweenService:Create(obj, TweenInfo.new(t or 0.2), goals):Play()
end

local function RefreshRainbowLayout()
    local y = 12
    for _, name in ipairs(WasUI.RainbowOrder) do
        local d = WasUI.ActiveRainbowTexts[name]
        if d and d.Label then
            d.Label.Position = UDim2.new(1,-190,0,y)
            y += d.Label.AbsoluteSize.Y + 4
        end
    end
end

local function CreateRainbowTextForFeature(name)
    if type(name) ~= "string" then return end
    if WasUI.ActiveRainbowTexts[name] then return end

    local sg = Create("ScreenGui",{
        Name="Rb_"..name, ResetOnSpawn=false, DisplayOrder=100, Parent=CoreGui
    })
    local lbl = Create("TextLabel",{
        Size=UDim2.new(0,180,0,0), BackgroundTransparency=1,
        Text=name, Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Right,
        TextStrokeTransparency=0.6, TextStrokeColor3=Color3.new(0,0,0),
        Parent=sg
    })
    task.wait()
    lbl.Size = UDim2.new(0,180,0,lbl.TextBounds.Y+2)

    WasUI.ActiveRainbowTexts[name] = {
        ScreenGui = sg, Label = lbl
    }
    table.insert(WasUI.RainbowOrder, name)
    RefreshRainbowLayout()
end

local function DestroyRainbowTextForFeature(name)
    if type(name)~="string" then return end
    local d = WasUI.ActiveRainbowTexts[name]
    if d then
        d.ScreenGui:Destroy()
        WasUI.ActiveRainbowTexts[name] = nil
        for i=#WasUI.RainbowOrder,1,-1 do
            if WasUI.RainbowOrder[i]==name then
                table.remove(WasUI.RainbowOrder,i)
                break
            end
        end
        RefreshRainbowLayout()
    end
end

local rbTime = 0
RunService.Heartbeat:Connect(function(dt)
    rbTime += dt*3.5
    local r = (math.sin(rbTime)+1)/2
    local g = (math.sin(rbTime+2)+1)/2
    local b = (math.sin(rbTime+4)+1)/2
    local c = Color3.new(r,g,b)
    for _,d in pairs(WasUI.ActiveRainbowTexts) do
        if d.Label then d.Label.TextColor3 = c end
    end
end)

local function CloseAllDropdowns()
    for i=#WasUI.OpenDropdowns,1,-1 do
        WasUI.OpenDropdowns[i]:Close()
    end
end

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        CloseAllDropdowns()
    end
end)

function WasUI:Notify(opt)
    local title = opt.Title or WasUI.DefaultNotificationTitle
    local content = opt.Content or ""
    local duration = opt.Duration or 3
    local id = HttpService:GenerateGUID()

    local fr = Create("Frame",{
        Size=UDim2.new(0,WasUI.NotificationWidth,0,WasUI.NotificationHeight),
        Position=UDim2.new(1,WasUI.NotificationWidth+20,0,WasUI.NotificationTop),
        BackgroundColor3=Color3.fromRGB(30,30,34),
        BackgroundTransparency=0.3,
        Parent=NotificationGui
    })
    local str = Create("UIStroke",{
        Color=Color3.fromRGB(10,10,12), Thickness=1, Parent=fr
    })
    Create("UICorner",{CornerRadius=UDim.new(0,4), Parent=fr})

    local tl = Create("TextLabel",{
        Size=UDim2.new(0,60,1,0), Position=UDim2.new(0,4,0,0),
        BackgroundTransparency=1, Text=title,
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamSemibold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=fr
    })

    local ct = Create("TextLabel",{
        Size=UDim2.new(1,-72,1,0), Position=UDim2.new(0,68,0,0),
        BackgroundTransparency=1, Text=content,
        TextColor3=Color3.fromRGB(210,210,210), Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=fr
    })

    WasUI.ActiveNotifications[id] = fr
    local total = 0
    for _,c in pairs(WasUI.ActiveNotifications) do
        if c ~= fr then
            total += c.Size.Y.Offset + WasUI.NotificationSpacing
        end
    end
    Tween(fr,{Position=UDim2.new(1,-WasUI.NotificationWidth-12,0,WasUI.NotificationTop+total)},0.3)

    task.delay(duration, function()
        if not WasUI.ActiveNotifications[id] then return end
        Tween(fr,{Position=UDim2.new(1,WasUI.NotificationWidth+20,0,fr.Position.Y.Offset)},0.3)
        task.wait(0.3)
        fr:Destroy()
        WasUI.ActiveNotifications[id] = nil
    end)
end

local Button = {}
Button.__index = Button
function Button.New(parent, text, cb)
    local self = setmetatable({}, Button)
    self.Instance = Create("TextButton",{
        Size=UDim2.new(1,0,0,28), Parent=parent,
        BackgroundColor3=WasUI.CurrentTheme.Primary, BackgroundTransparency=0.2,
        Text=text, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamSemibold, TextSize=12,
        AutoButtonColor=false
    })
    Create("UICorner",{CornerRadius=UDim.new(0,4), Parent=self.Instance})
    self.Instance.MouseButton1Click:Connect(function()
        if cb then cb() end
    end)
    return self
end

local Toggle = {}
Toggle.__index = Toggle
function Toggle.New(parent, text, default, cb, fname)
    local self = setmetatable({}, Toggle)
    self.Toggled = not not default
    self.Callback = cb
    self.FeatureName = type(fname)=="string" and fname or text

    local fr = Create("Frame",{
        Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Parent=parent
    })

    local lbl = Create("TextLabel",{
        Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundTransparency=1, Text=text, TextColor3=WasUI.CurrentTheme.Text,
        Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=fr
    })

    local bg = Create("Frame",{
        Size=UDim2.new(0,34,0,16), Position=UDim2.new(1,-38,0.5,-8),
        BackgroundColor3=self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(60,60,66),
        Parent=fr
    })
    Create("UICorner",{CornerRadius=UDim.new(1,0), Parent=bg})

    local knob = Create("Frame",{
        Size=UDim2.new(0,12,0,12), Position=self.Toggled and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),
        BackgroundColor3=Color3.new(1,1,1), Parent=bg
    })
    Create("UICorner",{CornerRadius=UDim.new(1,0), Parent=knob})

    if self.Toggled then CreateRainbowTextForFeature(self.FeatureName) end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Toggled = not self.Toggled
            if self.Toggled then
                Tween(bg,{BackgroundColor3=WasUI.CurrentTheme.Success},0.15)
                Tween(knob,{Position=UDim2.new(1,-14,0.5,-6)},0.15)
                CreateRainbowTextForFeature(self.FeatureName)
            else
                Tween(bg,{BackgroundColor3=Color3.fromRGB(60,60,66)},0.15)
                Tween(knob,{Position=UDim2.new(0,2,0.5,-6)},0.15)
                DestroyRainbowTextForFeature(self.FeatureName)
            end
            if self.Callback then self.Callback(self.Toggled) end
        end
    end)

    return self
end

local Label = {}
Label.__index = Label
function Label.New(parent, text)
    local self = setmetatable({}, Label)
    self.Instance = Create("TextLabel",{
        Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Parent=parent,
        Text=text, TextColor3=WasUI.CurrentTheme.Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left
    })
    return self
end

local Category = {}
Category.__index = Category
function Category.New(parent, title)
    local self = setmetatable({}, Category)
    self.Instance = Create("Frame",{
        Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=parent
    })
    local lbl = Create("TextLabel",{
        Size=UDim2.new(1,0,1,0), Parent=self.Instance,
        BackgroundTransparency=1, Text=title,
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left
    })
    return self
end

local Dropdown = {}
Dropdown.__index = Dropdown
function Dropdown.New(parent, title, opts, def, cb)
    local self = setmetatable({}, Dropdown)
    self.Options = opts or {}
    self.Selected = def or opts[1]
    self.Callback = cb
    self.Open = false

    self.Frame = Create("Frame",{
        Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=parent
    })

    self.Title = Create("TextLabel",{
        Size=UDim2.new(0,70,1,0), BackgroundTransparency=1, Parent=self.Frame,
        Text=title, TextColor3=WasUI.CurrentTheme.Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left
    })

    self.Btn = Create("TextButton",{
        Size=UDim2.new(1,-76,0,22), Position=UDim2.new(0,74,0.5,-11),
        BackgroundColor3=WasUI.CurrentTheme.Primary, BackgroundTransparency=0.2,
        Text=self.Selected, TextColor3=WasUI.CurrentTheme.Text, Font=Enum.Font.Gotham, TextSize=12,
        Parent=self.Frame
    })
    Create("UICorner",{CornerRadius=UDim.new(0,4), Parent=self.Btn})

    self.Drop = Create("Frame",{
        Size=UDim2.new(1,-76,0,0), Position=UDim2.new(0,74,0,22),
        BackgroundColor3=WasUI.CurrentTheme.Background, BackgroundTransparency=0.3,
        Visible=false, Parent=DropdownGui, ClipsDescendants=true
    })
    Create("UICorner",{CornerRadius=UDim.new(0,4), Parent=self.Drop})
    Create("UIStroke",{Color=Color3.fromRGB(10,10,12), Thickness=1, Parent=self.Drop})

    local list = Create("UIListLayout",{Parent=self.Drop, SortOrder=Enum.SortOrder.LayoutOrder})
    local pad = Create("UIPadding",{Parent=self.Drop, PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)})

    self.Btn.MouseButton1Click:Connect(function()
        self.Open = not self.Open
        self.Drop.Visible = self.Open
        if self.Open then
            table.insert(WasUI.OpenDropdowns, self)
            local h = 4
            for _,v in ipairs(self.Options) do h+=20 end
            Tween(self.Drop,{Size=UDim2.new(1,-76,0,h)},0.15)
        else
            Tween(self.Drop,{Size=UDim2.new(1,-76,0,0)},0.15)
        end
    end)

    for _,v in ipairs(self.Options) do
        local b = Create("TextButton",{
            Size=UDim2.new(1,0,0,20), Parent=self.Drop,
            BackgroundTransparency=1, Text=v, TextColor3=WasUI.CurrentTheme.Text,
            Font=Enum.Font.Gotham, TextSize=12
        })
        b.MouseButton1Click:Connect(function()
            self.Selected = v
            self.Btn.Text = v
            if self.Callback then self.Callback(v) end
            self.Open = false
            self.Drop.Visible = false
            Tween(self.Drop,{Size=UDim2.new(1,-76,0,0)},0.15)
        end)
    end

    return self
end

local Slider = {}
Slider.__index = Slider
function Slider.New(parent, title, min, max, def, cb)
    local self = setmetatable({}, Slider)
    self.Min = min
    self.Max = max
    self.Value = math.clamp(def, min, max)
    self.Callback = cb

    self.Frame = Create("Frame",{
        Size=UDim2.new(1,0,0,32), BackgroundTransparency=1, Parent=parent
    })

    self.Title = Create("TextLabel",{
        Size=UDim2.new(0,70,0,20), BackgroundTransparency=1, Parent=self.Frame,
        Text=title, TextColor3=WasUI.CurrentTheme.Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left
    })

    self.ValueLbl = Create("TextLabel",{
        Size=UDim2.new(1,-76,0,20), Position=UDim2.new(0,74,0,0),
        BackgroundTransparency=1, Text=tostring(self.Value), TextColor3=WasUI.CurrentTheme.Text,
        Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right, Parent=self.Frame
    })

    self.Track = Create("Frame",{
        Size=UDim2.new(1,-4,0,6), Position=UDim2.new(0,2,0,24),
        BackgroundColor3=WasUI.CurrentTheme.Primary, BackgroundTransparency=0.4, Parent=self.Frame
    })
    Create("UICorner",{CornerRadius=UDim.new(1,0), Parent=self.Track})

    self.Fill = Create("Frame",{
        Size=UDim2.new((self.Value-min)/(max-min),0,1,0),
        BackgroundColor3=WasUI.CurrentTheme.Accent, Parent=self.Track
    })
    Create("UICorner",{CornerRadius=UDim.new(1,0), Parent=self.Fill})

    local drag = false
    local function update(x)
        local t = math.clamp((x - self.Track.AbsolutePosition.X)/self.Track.AbsoluteSize.X, 0,1)
        self.Value = math.round(self.Min + t*(self.Max-self.Min))
        self.ValueLbl.Text = tostring(self.Value)
        Tween(self.Fill,{Size=UDim2.new(t,0,1,0)},0.05)
        if self.Callback then self.Callback(self.Value) end
    end

    self.Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)

    return self
end

local Window = {}
Window.__index = Window
function WasUI:CreateWindow(title, size)
    local self = setmetatable({}, Window)
    self.Size = size or UDim2.new(0,380,0,360)

    local sg = Create("ScreenGui",{ResetOnSpawn=false, DisplayOrder=WasUI.DefaultDisplayOrder, Parent=CoreGui})
    self.Main = Create("Frame",{Size=self.Size, Position=UDim2.new(0.5,-self.Size.X.Offset/2,0.5,-self.Size.Y.Offset/2),
        BackgroundColor3=WasUI.CurrentTheme.Background, BackgroundTransparency=0.2, Parent=sg})
    Create("UICorner",{CornerRadius=UDim.new(0,6), Parent=self.Main})
    Create("UIStroke",{Color=Color3.fromRGB(10,10,12), Thickness=1, Parent=self.Main})

    self.TitleBar = Create("Frame",{Size=UDim2.new(1,0,0,28), Parent=self.Main,
        BackgroundColor3=WasUI.CurrentTheme.Primary, BackgroundTransparency=0.2})
    Create("UICorner",{CornerRadius=UDim.new(0,6), Parent=self.TitleBar})

    self.Title = Create("TextLabel",{Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=title, TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamSemibold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, Parent=self.TitleBar})

    local drag = false
    local sx, sy
    self.TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            sx = i.Position.X - self.Main.Position.X.Offset
            sy = i.Position.Y - self.Main.Position.Y.Offset
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag then
            self.Main.Position = UDim2.new(0,i.Position.X-sx, 0,i.Position.Y-sy)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)

    self.Close = Create("TextButton",{Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-26,0,3),
        BackgroundTransparency=1, Text="×", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=18, Parent=self.TitleBar})
    self.Close.MouseButton1Click:Connect(function() sg:Destroy() end)

    self.Tabs = Create("Frame",{Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,28),
        BackgroundColor3=WasUI.CurrentTheme.Secondary, BackgroundTransparency=0.3, Parent=self.Main})
    local tabList = Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=self.Tabs})

    self.Container = Create("Frame",{Size=UDim2.new(1,0,1,-54), Position=UDim2.new(0,0,0,54),
        BackgroundTransparency=1, Parent=self.Main})
    self.Pages = {}
    self.Active = nil

    function self:AddTab(name)
        local btn = Create("TextButton",{Size=UDim2.new(0,90,1,0), Parent=self.Tabs,
            BackgroundTransparency=1, Text=name, TextColor3=WasUI.CurrentTheme.Text,
            Font=Enum.Font.GothamSemibold, TextSize=12})
        local line = Create("Frame",{Size=UDim2.new(0,0,0,2), Position=UDim2.new(0.5,0,1,-2),
            AnchorPoint=Vector2.new(0.5,0), BackgroundColor3=Color3.fromRGB(25,60,140),
            Visible=false, Parent=btn})
        local page = Create("Frame",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Visible=false, Parent=self.Container})
        local list = Create("UIListLayout",{Parent=page, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
        local pad = Create("UIPadding",{Parent=page, PaddingTop=UDim.new(0,6), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)})
        table.insert(self.Pages, {Button=btn, Line=line, Page=page})
        btn.MouseButton1Click:Connect(function()
            for _,p in ipairs(self.Pages) do
                p.Line.Visible = false
                Tween(p.Line,{Size=UDim2.new(0,0,0,2)},0.1)
                p.Page.Visible = false
            end
            line.Visible = true
            Tween(line,{Size=UDim2.new(1,0,0,2)},0.2)
            page.Visible = true
            self.Active = page
        end)
        if not self.Active then
            line.Visible = true
            Tween(line,{Size=UDim2.new(1,0,0,2)},0)
            page.Visible = true
            self.Active = page
        end
        return page
    end

    function self:SetWelcome(txt) end
    return self
end

function WasUI:CreateButton(p,t,c) return Button.New(p,t,c) end
function WasUI:CreateToggle(p,t,d,c,f) return Toggle.New(p,t,d,c,f) end
function WasUI:CreateLabel(p,t) return Label.New(p,t) end
function WasUI:CreateCategory(p,t) return Category.New(p,t) end
function WasUI:CreateDropdown(p,t,o,d,c) return Dropdown.New(p,t,o,d,c) end
function WasUI:CreateSlider(p,tmi,ma,de,c) return Slider.New(p,t,mi,ma,de,c) end

_G.WasUIModule = WasUI
return WasUI