-- @MugTypography
-- @title Little Letter Movers
-- @duration 8
-- @version 3.12
-- @api_level 13
-- @input number 1 "Stagger seconds" default=0.35
-- @input number 2 "Travel seconds" default=1.6
-- @input number 3 "Worker size" default=1.0
-- @input number 4 "Return speed" default=0.35
-- @input boolean 1 "Intro" default=true
-- @input boolean 2 "Outro" default=true
-- @input number 5 "Intro Duration (s)" default=4.0
-- @input number 6 "Outro Duration (s)" default=4.0
-- @input number 7 "Worker Texture (0-8)" default=0
-- @input number 8 "Worker Texture P1" default=0.6
-- @input number 9 "Worker Texture P2" default=0.5
-- @input number 10 "Worker Texture P3" default=0.7
-- @input number 11 "Worker Texture P4" default=45
-- @input color 1 "Worker color" default={1,0.55,0.3,1}
-- @input color 2 "Worker Texture Color" default={1,1,1,1}
--[[ @description
Little workers push letters into place one by one, then return to clear them away.
]]
--[[ @description.ja
小さな職人たちが文字を一つずつ押して並べ、再び戻ってきて片付けます。
]]

-- 0 None, 1 Water, 2 Air Cushion, 3 Glitter, 4 Iridescent,
-- 5 Faceted, 6 Stained Glass, 7 Metallic, 8 Metallic 2.
local materials = {"none", "water_droplet", "air_cushion", "glitter", "iridescent", "faceted", "stained_glass", "metallic", "metallic_2"}
local ids = {}
local planeCamera, planeRoot
local body = mt.svg_path("M -43 -100 C -43 -135 43 -135 43 -100 L 43 30 C 43 50 -43 50 -43 30 Z")
local head = mt.svg_path("M -55 -180 C -55 -250 55 -250 55 -180 C 55 -110 -55 -110 -55 -180 Z")
-- Draw a tapered limb from joint to endpoint in path coordinates.
local function limb(path, x1, y1, x2, y2, width)
    local dx, dy = x2-x1, y2-y1
    local len = math.max(0.001, math.sqrt(dx*dx + dy*dy))
    local nx, ny = -dy / len * width * 0.5, dx / len * width * 0.5
    path:move_to(x1-nx, y1-ny)
    path:line_to(x2-nx, y2-ny)
    path:line_to(x2+nx, y2+ny)
    path:line_to(x1+nx, y1+ny)
    path:close()
end

function OnPreLayout(ctx)
    -- Character count is available only after layout.  Before layout, reserve
    -- enough slots for the input's Unicode code points, within host limits.
    ids = {}
    planeCamera = ctx.shape_cameras:declare()
    planeRoot = ctx.shapes:declare({camera=planeCamera})
    local count = utf8.len(ctx.global.text) or #ctx.global.text
    local capacity = math.floor(math.max(0, ctx.meta.limits.max_shapes - 1) / 4)
    local reserve = math.min(count, ctx.meta.limits.max_characters, capacity)
    for i = 1, reserve do
        ids[i] = {body=ctx.shapes:declare({path=body,layer="front",parent=planeRoot}), legs=ctx.shapes:declare({layer="front",parent=planeRoot}), arm=ctx.shapes:declare({layer="front",parent=planeRoot}), head=ctx.shapes:declare({path=head,layer="front",parent=planeRoot})}
    end
end
function OnLayout(ctx)
    local view = ctx.shape_cameras[planeCamera]
    view.target_x, view.target_y = ctx.camera.target_x, ctx.camera.target_y
    view.yaw, view.pitch = ctx.camera.yaw, ctx.camera.pitch
    view.perspective, view.zoom = ctx.camera.perspective, ctx.camera.zoom
    view.lens_shift_x, view.lens_shift_y = ctx.camera.lens_shift_x, ctx.camera.lens_shift_y
    local root = ctx.shapes[planeRoot]
    root.offset_x, root.offset_y = ctx.global.position_x, ctx.global.position_y
    root.pivot_x, root.pivot_y = ctx.global.pivot_x, ctx.global.pivot_y
    root.yaw, root.pitch, root.rotation = ctx.global.yaw, ctx.global.pitch, ctx.global.rotation
    local stagger = mt.clamp(ctx.inputs.numbers[1], 0.05, 2.0)
    local travel = mt.clamp(ctx.inputs.numbers[2], 0.4, 5.0)
    local size = mt.clamp(ctx.inputs.numbers[3], 0.3, 3.0)
    local returnSpeed = mt.clamp(ctx.inputs.numbers[4], 0.05, 2.0)
    local color = ctx.inputs.colors[1]
    local materialIndex = math.floor(mt.clamp(ctx.inputs.numbers[7], 0, 8) + 0.5) + 1
    local material = materials[materialIndex]
    local tex1 = mt.clamp(ctx.inputs.numbers[8], 0, 1)
    local tex2 = mt.clamp(ctx.inputs.numbers[9], 0, 1)
    local tex3 = mt.clamp(ctx.inputs.numbers[10], 0, 1)
    local tex4 = ctx.inputs.numbers[11]
    if material == "stained_glass" then tex4 = mt.clamp(tex4, 0, 1) end
    local texColor = ctx.inputs.colors[2]
    local scale = size * ctx.global.scale * 1.2
    local introDuration = ctx.inputs.booleans[1] and mt.clamp(ctx.inputs.numbers[5], 0, 60) or 0
    local outroDuration = ctx.inputs.booleans[2] and mt.clamp(ctx.inputs.numbers[6], 0, 60) or 0
    local intro, outro = mt.timeline.intro_outro_seconds(ctx, introDuration, outroDuration, 8)
    local fullTime = travel + math.max(0, ctx.char_count - 1) * stagger + 0.35 + 1.2 / returnSpeed
    local reversing = outroDuration > 0 and outro > 0
    local activeIntro = introDuration > 0 and intro < 1
    local active = activeIntro or reversing
    local sceneTime = reversing and (1-outro) * fullTime or intro * fullTime
    for i = 1, #ids do
        local worker, legs, arm, face = ctx.shapes[ids[i].body], ctx.shapes[ids[i].legs], ctx.shapes[ids[i].arm], ctx.shapes[ids[i].head]
        local all = {worker, legs, arm, face}
        for _, shape in ipairs(all) do shape.opacity = 0 end
        local c = i <= ctx.char_count and ctx.chars[i]
        if active and c and c.part_count > 0 and mt.text.classify(c.text) ~= "space" then
            local t = sceneTime - (i - 1) * stagger
            local p = mt.saturate(t / travel)
            local easing = reversing and (1 - (1 - p)^1.2) or (1 - (1 - p)^3)
            -- Evaluate the same entrance motion backwards for the exit.
            c.offset_x = c.offset_x - 0.28 * (1 - easing)
            c.rotation = c.rotation - 10 * (1 - easing)
            if t < 0 then c.opacity = 0 end
            local settleRotation = math.max(0, t - travel)
            if t >= travel then
                c.rotation = c.rotation + 5 * math.exp(-5 * settleRotation) * math.sin(settleRotation * 18)
            end
            local settle = math.max(0, t - travel)
            local b = mt.layout.measure_bounds_2d(ctx, {i}, "character", "before_global_rotation")
            if b then
                local returning = math.max(0, t - travel - 0.35)
                local visible = mt.saturate(t / 0.12)
                local h = math.max(b.height, 0.03)
                local walk = math.sin(math.max(0,t) * 15)
                local walking = p < 1 or returning > 0
                local gap = h * 0.16 / ctx.canvas.aspect_ratio
                local x = b.left - gap - returning * returnSpeed
                local flip = returning > 0 and -1 or 1
                if reversing then
                    -- Approach from the left, pass to the far side, then push left.
                    x = b.right + gap - returning * returnSpeed
                    flip = returning > 0 and 1 or -1
                end
                local bob = walking and math.abs(walk) * h * 0.03 or 0
                local y = b.bottom + h * 0.13 + bob
                for _, shape in ipairs(all) do
                    shape.offset_x, shape.offset_y = 0.5 + x - ctx.global.position_x, 0.5 + y - ctx.global.position_y
                    shape.scale = scale
                    shape.stretch_x = flip
                    shape.fill.use = true
                    shape.fill.color = color
                    -- Do not inherit visual treatments from the text.
                    shape.stroke.use = true
                    shape.stroke.width, shape.stroke.outer_width, shape.stroke.gap = 0, 0, 0
                    shape.shadow.use = true
                    shape.shadow.color = {r=0, g=0, b=0, a=0}
                    shape.shadow.blur_x, shape.shadow.blur_y, shape.shadow.glow = 0, 0, 0
                    shape.blur.use = true
                    shape.blur.amount_x, shape.blur.amount_y, shape.blur.glow = 0, 0, 0
                    shape.texture.use = true
                    shape.texture.type = material
                    shape.texture.p1, shape.texture.p2, shape.texture.p3, shape.texture.p4 = tex1, tex2, tex3, tex4
                    shape.texture.color = texColor
                    shape.opacity = visible
                end
                worker.rotation = p < 1 and 10 or (returning > 0 and -5 or -8 * math.exp(-settle * 5) * math.sin(settle * 14))
                if reversing then worker.rotation = -worker.rotation end
                arm.rotation, face.rotation = worker.rotation, worker.rotation
                -- Continuous alternating steps: each foot lifts on its forward swing.
                local cycle = walking and walk or 0
                for leg = -1, 1, 2 do
                    local swing = cycle * leg
                    local lift = walking and math.max(0, swing) * 32 or 0
                    local hipX = leg * 23
                    local footX = hipX + swing * 68
                    limb(legs.path, hipX, 20, footX, 105-lift, 24)
                    limb(legs.path, footX-9, 105-lift, footX+22, 105-lift, 16)
                end
                -- Two arms originate near the middle of the upper torso.
                local lower = mt.saturate((settle - 0.03) / 0.25)
                if returning <= 0 then
                    local handX = 145 * (1-lower) + 52 * lower
                    local handY = -105 * (1-lower) + 42 * lower
                    limb(arm.path, 42, -75, handX, handY, 22)
                else
                    for side = -1, 1, 2 do
                        local swing = -walk * side
                        local handX = side * 15 + 105 * swing
                        local handY = -108 + 120 * math.sqrt(1 - 0.35 * swing * swing)
                        limb(arm.path, side * 8, -108, handX, handY, 21)
                    end
                end
            end
        end
    end
end