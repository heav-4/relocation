local M = {}
local sources = {}

love.audio.setVolume(0.5)
M.mute = false

function M.load_sources()
    local files = love.filesystem.getDirectoryItems("sound files")
    for i, filename in ipairs(files) do
        if #filename >= 4 then
            local ending = filename:sub(#filename-3, #filename)
            if ending == ".wav" or ending == ".ogg" or ending == ".mp3" then
                local filestart = filename:sub(1, #filename-4)
                sources[filestart] = {love.audio.newSource("sound files/"..filename, "static")}
            end
        end
    end
end

function M.play(sourcename, volume)
    if M.mute then return end
    volume = volume or 1
    if not sources[sourcename] then error("missing a sound file: "..sourcename) end
    for i, v in ipairs(sources[sourcename]) do
        if not v:isPlaying() then
            v:setVolume(volume)
            v:play()
            return
        end
    end
    local new_source = sources[sourcename][1]:clone()
    new_source:seek(0)
    new_source:setVolume(volume)
    new_source:play()
    table.insert(sources[sourcename], new_source)
end

return M