gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
util.no_globals()

local matrix = require "matrix2d"
local rpc = require "rpc"
local json = require "json"
local font = resource.load_font "silkscreen.ttf"

local py = rpc.create()

local function log(fmt, ...)
    print(string.format("[player] "..fmt, ...))
end

local function Display()
    local rotation = 0
    local offset = 0
    local spread = 1
    local is_portrait = false
    local transform

    local w, h = NATIVE_WIDTH, NATIVE_HEIGHT

    local function round(v)
        return math.floor(v+.5)
    end

    local function update_placement(new_rotation, new_offset, new_spread)
        rotation = new_rotation
        offset = new_offset
        spread = new_spread

        is_portrait = rotation == 90 or rotation == 270

        gl.setup(w, h)

        if rotation == 0 then
            transform = matrix.ident()
        elseif rotation == 90 then
            transform = matrix.trans(w, 0) *
                        matrix.rotate_deg(rotation)
        elseif rotation == 180 then
            transform = matrix.trans(w, h) *
                        matrix.rotate_deg(rotation)
        elseif rotation == 270 then
            transform = matrix.trans(0, h) *
                        matrix.rotate_deg(rotation)
        else
            return error(string.format("cannot rotate by %d degree", rotation))
        end

        if is_portrait then
            transform = transform * matrix.trans(-h * offset, 0)
        else
            transform = transform * matrix.trans(-w * offset, 0)
        end
    end

    local function draw_video(vid, x1, y1, x2, y2)
        local tx1, ty1 = transform(x1, y1)
        local tx2, ty2 = transform(x2, y2)
        local x1, y1, x2, y2 = round(math.min(tx1, tx2)),
                               round(math.min(ty1, ty2)),
                               round(math.max(tx1, tx2)),
                               round(math.max(ty1, ty2))
        return vid:place(x1, y1, x2, y2, rotation)
    end

    local function draw_image(img, x1, y1, x2, y2)
        return img:draw(x1, y1, x2, y2)
    end

    local function frame_setup()
        return matrix.apply_gl(transform)
    end

    local function size()
        if is_portrait then
            return h, w
        else
            return w, h
        end
    end

    local function place(offset, spread)
        local w, h = size()
        return w * offset, 0, w * (offset+spread), h
    end

    local function covers(left, right)
        -- return left < 2 and right >= 1j
        return left < offset + spread and right > offset
    end

    update_placement(0, 0, 1)

    return {
        update_placement = update_placement;
        frame_setup = frame_setup;
        draw_image = draw_image;
        draw_video = draw_video;
        is_portrait = function() return is_portrait end;
        size = size;
        place = place;
        covers = covers;
    }
end
local Display = Display()

local function Text(text)
    local w, h = Display.size()
    local x = math.random(0, w-100)
    local y = math.random(0, h-20)
    return {
        draw = function()
            font:write(x, y, text, 16, 1,1,1,.8)
        end;
        hide = function()
        end;
        dispose = function()
        end;
    }
end

local function Image(file, asset_id)
    local res = resource.load_image{
        file = file,
    }
    local started
    return {
        draw = function(...)
            if not started then
                started = sys.now()
            end
            return Display.draw_image(res, ...)
        end;
        hide = function()
        end;
        dispose = function()
            if started then
                py.record_playback(asset_id, sys.now() - started)
            end
            res:dispose()
        end;
    }
end

local function Video(file, asset_id)
    local res = resource.load_video{
        file = file,
        raw = true,
        paused = true,
        audio = true,
    }
    local started = false
    return {
        draw = function(...)
            if not started then
                res:start()
                started = sys.now()
            end
            Display.draw_video(res, ...):layer(-1)
        end;
        hide = function()
            res:layer(-2)
        end;
        dispose = function()
            if started then
                py.record_playback(asset_id, sys.now() - started)
            end
            res:dispose()
        end;
    }
end

-----------

local old, cur, nxt
local playlist = {}
local overwrite_x1, overwrite_y1, overwrite_x2, overwrite_y2

py.register("preload", function(item)
    if nxt then
        nxt.dispose()
    end

    if item == 'no-item' then
        nxt = Text('nothing scheduled')
    elseif item == 'idle' then
        nxt = Text('idle')
    else
        local item = playlist[item]

        if not item then
            nxt = Text('scheduled item not found')
        elseif item.type == "image" then
            nxt = Image(item.file:copy(), item.asset_id)
        else
            nxt = Video(item.file:copy(), item.asset_id)
        end
    end
end)

py.register("switch", function()
    if not nxt then
        return
    end
    if old then
        old.dispose()
    end
    old = cur
    cur = nxt
    nxt = nil
end)

local function draw()
    if not cur then
        return
    end

    if old then
        old.hide()
    end

    local x1, y1, x2, y2 = Display.place(0, 1)

    if overwrite_x1 ~= 0 or overwrite_y1 ~= 0 or
       overwrite_x2 ~= 0 or overwrite_y2 ~= 0
    then
        x1 = overwrite_x1
        y1 = overwrite_y1
        x2 = overwrite_x2
        y2 = overwrite_y2
    end

    cur.draw(x1, y1, x2, y2)

    if old then
        old.dispose()
        old = nil
    end
end

util.json_watch("config.json", function(config)
    Display.update_placement(config.rotation, 0, 1)

    overwrite_x1 = config.x1
    overwrite_y1 = config.y1
    overwrite_x2 = config.x2
    overwrite_y2 = config.y2

    local new_playlist = {}
    for _, item in ipairs(config.content) do
        new_playlist[#new_playlist+1] = {
            file = resource.open_file(item.file.asset_name),
            type = item.file.type,
            asset_id = item.file.asset_id,
        }
    end
    playlist = new_playlist
    pp(playlist)
end)

function node.render()
    Display.frame_setup()
    gl.clear(0,0,0,0)
    draw()
end
