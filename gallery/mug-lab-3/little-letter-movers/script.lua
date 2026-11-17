-- @MugTypography
-- @title Little Letter Movers
-- @duration 8
-- @version 4.0
-- @api_level 15
-- @input number 1 "Stagger seconds" default=0.35
-- @input number 2 "Travel seconds" default=1.6
-- @input number 3 "Worker size" default=4.0
-- @input number 4 "Return speed" default=0.35
-- @input boolean 1 "Intro" default=true
-- @input boolean 2 "Outro" default=true
-- @input number 5 "Intro Duration (s)" default=4.0
-- @input number 6 "Outro Duration (s)" default=4.0
-- @input number 7 "Worker Texture (0-13)" default=0
-- @input number 8 "Worker Texture P1" default=0.6
-- @input number 9 "Worker Texture P2" default=0.5
-- @input number 10 "Worker Texture P3" default=0.7
-- @input number 11 "Worker Texture P4" default=45
-- @input number 12 "Worker Texture P5" default=0
-- @input color 1 "Worker color" default={1,0.55,0.3,1}
-- @input color 2 "Worker Texture Color" default={1,1,1,1}
--[[ @description
Little workers push letters into place one by one, then return to clear them away.
]]
--[[ @description.ja
小さな職人たちが文字を一つずつ押して並べ、再び戻ってきて片付けます。
]]

-- Worker Texture: 0 None, 1 Water, 2 Air Cushion, 3 Glitter, 4 Iridescent, 5 Faceted, 6 Stained Glass,
-- 7 Metallic, 8 Metallic 2, 9 Stripe, 10 Colored Pencil, 11 Halftone, 12 Halftone Diamond, 13 Prism Foil.
-- P5 is read only by Iridescent, Metallic, Colored Pencil, Halftone, Halftone Diamond and Prism Foil.
local MATERIALS = {
    "none", "water_droplet", "air_cushion", "glitter", "iridescent", "faceted", "stained_glass",
    "metallic", "metallic_2", "stripe", "colored_pencil", "halftone", "halftone_diamond", "prism_foil",
}

-- Worker drawing, in path units around the hips (1000 = 1 em, Y down).
local BODY = mt.svg_path("M -43 -100 C -43 -135 43 -135 43 -100 L 43 30 C 43 50 -43 50 -43 30 Z")
local HEAD = mt.svg_path("M -55 -180 C -55 -250 55 -250 55 -180 C 55 -110 -55 -110 -55 -180 Z")
local ARM_LENGTH, ARM_WIDTH, HAND_RADIUS = 112, 21, 14
local LEG_WIDTH, FOOT_WIDTH = 24, 16

-- Side view, back to front. The far limbs go in the back layer, behind the text, so a carried
-- letter sits between the two hands.
local PARTS = {
    { key = "farLeg", layer = "back" },
    { key = "farArm", layer = "back" },
    { key = "body", layer = "front", path = BODY },
    { key = "head", layer = "front", path = HEAD },
    { key = "nearLeg", layer = "front" },
    { key = "nearArm", layer = "front" },
}
local CAMERA_FIELDS = { "target_x", "target_y", "yaw", "pitch", "perspective", "zoom", "lens_shift_x", "lens_shift_y" }
local SETTLE_SECONDS = 0.35 -- pause between placing a letter and walking back

local workers = {}
local planeCamera, planeRoot

-- A straight limb of even width from (x1, y1) to (x2, y2).
local function limb(path, x1, y1, x2, y2, width)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
    local nx, ny = -dy / len * width * 0.5, dx / len * width * 0.5
    path:move_to(x1 - nx, y1 - ny)
    path:line_to(x2 - nx, y2 - ny)
    path:line_to(x2 + nx, y2 + ny)
    path:line_to(x1 + nx, y1 + ny)
    path:close()
end

-- An arm from the shoulder at an angle (0 = straight ahead, 90 = straight down), with a round hand.
-- Every pose uses the same length, so the arm never grows or shrinks.
local function arm(path, shoulderX, shoulderY, degrees)
    local radians = math.rad(degrees)
    local hx = shoulderX + ARM_LENGTH * math.cos(radians)
    local hy = shoulderY + ARM_LENGTH * math.sin(radians)
    limb(path, shoulderX, shoulderY, hx, hy, ARM_WIDTH)
    local r = HAND_RADIUS
    path:move_to(hx + r, hy)
    path:quad_to(hx + r, hy + r, hx, hy + r)
    path:quad_to(hx - r, hy + r, hx - r, hy)
    path:quad_to(hx - r, hy - r, hx, hy - r)
    path:quad_to(hx + r, hy - r, hx + r, hy)
    path:close()
end

-- A leg from the hip, swinging forward by `swing` (-1..1) and lifted by `lift`, with a flat foot.
local function leg(path, hipX, swing, lift)
    local footX, footY = hipX + swing * 68, 105 - lift
    limb(path, hipX, 20, footX, footY, LEG_WIDTH)
    limb(path, footX - 9, footY, footX + 22, footY, FOOT_WIDTH)
end

function OnPreLayout(ctx)
    -- Character count is known only after layout, so reserve one worker per code point,
    -- within the shape budget.
    planeCamera = ctx.shape_cameras:declare()
    planeRoot = ctx.shapes:declare({ camera = planeCamera })
    local limits = ctx.meta.limits
    local count = utf8.len(ctx.global.text) or #ctx.global.text
    local capacity = math.floor(math.max(0, limits.max_shapes - 1) / #PARTS)
    workers = {}
    for i = 1, math.min(count, limits.max_characters, capacity) do
        local worker = {}
        for _, part in ipairs(PARTS) do
            worker[part.key] = ctx.shapes:declare({ path = part.path, layer = part.layer, parent = planeRoot })
        end
        workers[i] = worker
    end
end

-- Workers live on a plane that follows the text's camera and Global pose.
local function follow_text(ctx)
    local view = ctx.shape_cameras[planeCamera]
    for _, field in ipairs(CAMERA_FIELDS) do
        view[field] = ctx.camera[field]
    end
    local root, g = ctx.shapes[planeRoot], ctx.global
    root.offset_x, root.offset_y = g.position_x, g.position_y
    root.pivot_x, root.pivot_y = g.pivot_x, g.pivot_y
    root.yaw, root.pitch, root.rotation = g.yaw, g.pitch, g.rotation
end

local function read_settings(ctx)
    local n, colors, flags = ctx.inputs.numbers, ctx.inputs.colors, ctx.inputs.booleans
    local material = MATERIALS[math.floor(mt.clamp(n[7], 0, #MATERIALS - 1) + 0.5) + 1]
    local s = {
        stagger = mt.clamp(n[1], 0.05, 2.0),
        travel = mt.clamp(n[2], 0.4, 5.0),
        returnSpeed = mt.clamp(n[4], 0.05, 2.0),
        scale = mt.clamp(n[3], 0.3, 3.0) * ctx.global.scale * 1.2,
        introDuration = flags[1] and mt.clamp(n[5], 0, 60) or 0,
        outroDuration = flags[2] and mt.clamp(n[6], 0, 60) or 0,
        color = colors[1],
        texture = {
            use = true,
            type = material,
            p1 = mt.saturate(n[8]),
            p2 = mt.saturate(n[9]),
            p3 = mt.saturate(n[10]),
            p4 = material == "stained_glass" and mt.saturate(n[11]) or n[11],
            p5 = n[12],
            color = colors[2],
        },
    }
    s.farColor = mt.color.lerp_oklab(s.color, { r = 0, g = 0, b = 0, a = s.color.a }, 0.28)
    return s
end

-- Plain worker look: the worker never inherits the text's stroke, shadow or blur.
local function style(shape, s, fillColor, opacity)
    shape.opacity = opacity
    shape.scale = s.scale
    shape.fill = { use = true, color = fillColor }
    shape.stroke = { use = true, width = 0, outer_width = 0, gap = 0 }
    shape.shadow = { use = true, color = { r = 0, g = 0, b = 0, a = 0 }, blur_x = 0, blur_y = 0, glow = 0 }
    shape.blur = { use = true, amount_x = 0, amount_y = 0, glow = 0 }
    shape.texture = s.texture
end

-- Moves one letter in (or back out) and returns the worker's timing for this letter.
local function move_letter(c, t, s, reversing)
    local p = mt.saturate(t / s.travel)
    local easing = reversing and (1 - (1 - p) ^ 1.2) or (1 - (1 - p) ^ 3)
    local settle = math.max(0, t - s.travel)
    -- The exit plays the same entrance motion backwards.
    c.offset_x = c.offset_x - 0.28 * (1 - easing)
    c.rotation = c.rotation - 10 * (1 - easing)
    if t < 0 then c.opacity = 0 end
    if t >= s.travel then
        c.rotation = c.rotation + 5 * math.exp(-5 * settle) * math.sin(settle * 18)
    end
    return p, settle, math.max(0, settle - SETTLE_SECONDS)
end

local function draw_worker(ctx, i, c, t, s, reversing)
    local w = {}
    for _, part in ipairs(PARTS) do
        w[part.key] = ctx.shapes[workers[i][part.key]]
    end

    local p, settle, returning = move_letter(c, t, s, reversing)
    local b = mt.layout.measure_bounds_2d(ctx, { i }, "character", "before_global_rotation")
    if not b then return end

    local h = math.max(b.height, 0.03)
    local walk = math.sin(math.max(0, t) * 15)
    local walking = p < 1 or returning > 0

    -- Behind the letter, facing it; turn around and walk off once it is in place.
    -- On the exit the worker starts on the far side and pushes the other way.
    local gap = h * 0.16 / ctx.canvas.aspect_ratio
    local toLetter = reversing and -1 or 1
    local x = (reversing and b.right + gap or b.left - gap) - returning * s.returnSpeed
    local flip = (returning > 0 and -1 or 1) * toLetter
    -- While carrying, step up to the letter so both hands reach around it.
    local pathUnit = s.scale * ctx.font.em_size / 1000 / ctx.canvas.aspect_ratio
    x = x + toLetter * 55 * pathUnit * (1 - mt.saturate(returning / 0.25))
    local y = b.bottom + h * 0.13 + (walking and math.abs(walk) * h * 0.03 or 0)

    local visible = mt.saturate(t / 0.12)
    for order, part in ipairs(PARTS) do
        local shape = w[part.key]
        local isFar = part.layer == "back"
        style(shape, s, isFar and s.farColor or s.color, visible)
        shape.z_index = i * 10 + order -- keeps the 3D depth sort from swapping the parts
        shape.offset_x = 0.5 + x - ctx.global.position_x
        shape.offset_y = 0.5 + y - ctx.global.position_y
        shape.stretch_x = flip
    end

    -- Lean into the push, wobble when the letter lands, lean back while walking off.
    local lean = p < 1 and 10 or (returning > 0 and -5 or -8 * math.exp(-settle * 5) * math.sin(settle * 14))
    lean = lean * toLetter
    w.body.rotation, w.head.rotation, w.farArm.rotation, w.nearArm.rotation = lean, lean, lean, lean

    -- Alternating steps: each foot lifts on its forward swing. Both hips sit under the body.
    local cycle = walking and walk or 0
    for _, side in ipairs({ { w.farLeg, -1, -5 }, { w.nearLeg, 1, 5 } }) do
        local swing = cycle * side[2]
        leg(side[1].path, side[3], swing, walking and math.max(0, swing) * 32 or 0)
    end

    if returning <= 0 then
        -- Hands reach around the letter (far hand behind it, near hand in front),
        -- then drop to the sides once it is in place.
        local lower = mt.saturate((settle - 0.03) / 0.25)
        local reach = mt.lerp(8, 80, lower)
        arm(w.farArm.path, -3, -96, reach - 10)
        arm(w.nearArm.path, 3, -92, reach)
    else
        -- Arms swing opposite to the leg on the same side.
        arm(w.farArm.path, -3, -96, 90 - 45 * walk)
        arm(w.nearArm.path, 3, -96, 90 + 45 * walk)
    end
end

function OnLayout(ctx)
    follow_text(ctx)
    local s = read_settings(ctx)

    local intro, outro = mt.timeline.intro_outro_seconds(ctx, s.introDuration, s.outroDuration, 8)
    local fullTime = s.travel + math.max(0, ctx.char_count - 1) * s.stagger + SETTLE_SECONDS + 1.2 / s.returnSpeed
    local reversing = s.outroDuration > 0 and outro > 0
    local active = (s.introDuration > 0 and intro < 1) or reversing
    local sceneTime = (reversing and 1 - outro or intro) * fullTime

    for i = 1, #workers do
        for _, id in pairs(workers[i]) do
            ctx.shapes[id].opacity = 0
        end
        local c = i <= ctx.char_count and ctx.chars[i]
        if active and c and c.part_count > 0 and mt.text.classify(c.text) ~= "space" then
            draw_worker(ctx, i, c, sceneTime - (i - 1) * s.stagger, s, reversing)
        end
    end
end