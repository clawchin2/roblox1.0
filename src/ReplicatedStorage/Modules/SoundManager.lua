-- Sound Manager
-- Centralized audio management

local SoundManager = {}

-- Sound IDs
local SOUNDS = {
    Jump = {id = "rbxassetid://376021808", volume = 0.5},
    Coin = {id = "rbxassetid://1997914399", volume = 0.7},
    Death = {id = "rbxassetid://5801257795", volume = 0.8},
    Checkpoint = {id = "rbxassetid://175659077", volume = 0.6},
    Milestone = {id = "rbxassetid://1537979440", volume = 1.0},
    Music = {id = "rbxassetid://1838618353", volume = 0.3},
}

-- Cache for sound instances
local soundCache = {}

-- Get or create sound
function SoundManager:getSound(soundName)
    if soundCache[soundName] then
        return soundCache[soundName]
    end
    
    local config = SOUNDS[soundName]
    if not config then
        warn("[SoundManager] Unknown sound: " .. soundName)
        return nil
    end
    
    local sound = Instance.new("Sound")
    sound.Name = soundName
    sound.SoundId = config.id
    sound.Volume = config.volume
    
    if soundName == "Music" then
        sound.Looped = true
    end
    
    -- Parent to workspace for now
    sound.Parent = workspace
    soundCache[soundName] = sound
    
    return sound
end

-- Play a sound
function SoundManager:Play(soundName)
    local sound = self:getSound(soundName)
    if sound then
        if soundName == "Music" then
            if not sound.IsPlaying then
                sound:Play()
            end
        else
            sound:Play()
        end
    end
end

-- Stop music
function SoundManager:StopMusic()
    local music = soundCache["Music"]
    if music then
        music:Stop()
    end
end

-- Set volume
function SoundManager:SetVolume(soundName, volume)
    local sound = soundCache[soundName]
    if sound then
        sound.Volume = volume
    end
end

-- Mute all
function SoundManager:Mute()
    for name, sound in pairs(soundCache) do
        sound.Volume = 0
    end
end

-- Unmute
function SoundManager:Unmute()
    for name, sound in pairs(soundCache) do
        local config = SOUNDS[name]
        if config then
            sound.Volume = config.volume
        end
    end
end

print("[SoundManager] Loaded!")

return SoundManager