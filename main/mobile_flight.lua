-- MobileFlightSystem v3.0
-- GitHub: https://raw.githubusercontent.com/[YOUR_USERNAME]/roblox-scripts/main/mobile_flight.lua

local Players = game:GetService( "Players") 
local UIS = game:GetService( "UserInputService") 
local RunService = game:GetService( "RunService") 
local TweenService = game:GetService( "TweenService") 

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait( ) 
local humanoid = character:WaitForChild( "Humanoid") 

-- 飞行控制参数
local FLIGHT_CONFIG = {
    ThrustSpeed = 22,
    GlideDecay = 0.96,
    MaxAltitude = 1000,
    JoystickSensitivity = 0.3
}

-- 飞行状态
local flightState = {
    IsFlying = false,
    IsGliding = false,
    VerticalThrust = 0,
    BodyPosition = nil,
    BodyGyro = nil
}

-- 创建触控UI
local function CreateFlightUI( ) 
    local gui = Instance.new( "ScreenGui") 
    gui.Name = "FlightUIContainer"
    gui.ResetOnSpawn = false

    -- 虚拟摇杆
    local joystick = Instance.new( "Frame") 
    joystick.Size = UDim2.new( 0.2, 0, 0.2, 0) 
    joystick.Position = UDim2.new( 0.1, 0, 0.7, 0) 
    joystick.BackgroundTransparency = 0.8
    joystick.Name = "VirtualJoystick"

    local thumb = Instance.new( "ImageButton") 
    thumb.Size = UDim2.new( 0.4, 0, 0.4, 0) 
    thumb.Position = UDim2.new( 0.3, 0, 0.3, 0) 
    thumb.Image = "rbxassetid://3570697347"
    thumb.Parent = joystick

    -- 控制按钮
    local buttonTemplate = {
        Size = UDim2.new( 0.15, 0, 0.15, 0) ,
        BackgroundTransparency = 0.7,
        ImageColor3 = Color3.new( 1, 1, 1) 
    }

    local takeoffBtn = Instance.new( "ImageButton") 
    takeoffBtn.Position = UDim2.new( 0.8, 0, 0.6, 0) 
    takeoffBtn.Image = "rbxassetid://3572495782"
    takeoffBtn.Name = "Takeoff"
    table.foreach( buttonTemplate, function( k,v) takeoffBtn[k] = v end) 

    local landBtn = takeoffBtn:Clone( ) 
    landBtn.Position = UDim2.new( 0.8, 0, 0.8, 0) 
    landBtn.Image = "rbxassetid://3572496010"
    landBtn.Name = "Land"

    local glideBtn = takeoffBtn:Clone( ) 
    glideBtn.Position = UDim2.new( 0.6, 0, 0.8, 0) 
    glideBtn.Image = "rbxassetid://3572495926"
    glideBtn.Name = "Glide"

    -- 组合UI元素
    joystick.Parent = gui
    takeoffBtn.Parent = gui
    landBtn.Parent = gui
    glideBtn.Parent = gui
    gui.Parent = player:WaitForChild( "PlayerGui") 

    return {
        Joystick = joystick,
        Thumb = thumb,
        Takeoff = takeoffBtn,
        Land = landBtn,
        Glide = glideBtn
    }
end

-- 初始化飞行物理组件
local function InitializeFlightPhysics( ) 
    local root = character:WaitForChild( "HumanoidRootPart") 
    
    flightState.BodyPosition = Instance.new( "BodyPosition") 
    flightState.BodyPosition.MaxForce = Vector3.new( 4e4, 4e4, 4e4) 
    flightState.BodyPosition.P = 1500
    
    flightState.BodyGyro = Instance.new( "BodyGyro") 
    flightState.BodyGyro.MaxTorque = Vector3.new( 4e4, 4e4, 4e4) 
    flightState.BodyGyro.P = 2500
    
    flightState.BodyPosition.Parent = root
    flightState.BodyGyro.Parent = root
    humanoid.PlatformStand = true
end

-- 虚拟摇杆控制
local function HandleJoystickInput( ui) 
    local isDragging = false
    local joystickPos = ui.Joystick.AbsolutePosition
    local joystickSize = ui.Joystick.AbsoluteSize.X

    ui.Thumb.InputBegan:Connect( function( input) 
        if input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end) 

    ui.Thumb.InputChanged:Connect( function( input) 
        if isDragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = ( input.Position - joystickPos) / joystickSize
            delta = Vector2.new( 
                math.clamp( delta.X, -1, 1) ,
                math.clamp( delta.Y, -1, 1) 
            ) * FLIGHT_CONFIG.JoystickSensitivity
            
            flightState.VerticalThrust = -delta.Y
            ui.Thumb.Position = UDim2.new( 
                0.3 + delta.X * 0.7, 
                0,
                0.3 + delta.Y * 0.7, 
                0
            ) 
        end
    end) 

    ui.Thumb.InputEnded:Connect( function( ) 
        isDragging = false
        flightState.VerticalThrust = 0
        ui.Thumb.Position = UDim2.new( 0.3, 0, 0.3, 0) 
    end) 
end

-- 按钮控制系统
local function HandleButtonInput( ui) 
    ui.Takeoff.MouseButton1Down:Connect( function( ) 
        if not flightState.IsFlying then
            flightState.IsFlying = true
            InitializeFlightPhysics( ) 
        end
    end) 

    ui.Land.MouseButton1Down:Connect( function( ) 
        if flightState.IsFlying then
            flightState.IsFlying = false
            flightState.BodyPosition:Destroy( ) 
            flightState.BodyGyro:Destroy( ) 
            humanoid.PlatformStand = false
        end
    end) 

    ui.Glide.MouseButton1Click:Connect( function( ) 
        flightState.IsGliding = not flightState.IsGliding
        ui.Glide.ImageColor3 = flightState.IsGliding 
            and Color3.new( 0.5, 1, 0.5) 
            or Color3.new( 1,