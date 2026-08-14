-- @MugTypography
-- @duration 8
-- @title Bounce Stream
-- @author Mug
-- @version 1.0
-- @api_level 9
-- @recommend bg solid #0b0d14
-- @recommend text "BOUNCE"
-- @input number 1 "Balls" default=256
-- @input number 2 "Flow Speed" default=1.0
-- @input number 3 "Gravity" default=1.0
-- @input number 4 "Bounciness" default=0.86
-- @input number 5 "Ball Size" default=1.0
-- @input number 6 "Ground Line" default=0.22
-- @input number 7 "Squash" default=1.0
-- @input number 8 "Panda Share" default=0.5
-- @input color 1 "Panda Color" default={0.94, 0.95, 0.97, 1.0}
-- @input color 2 "Pig Color" default={1.0, 0.72, 0.78, 1.0}
--[[ @description
Countless pandas and pigs bounce their way across the frame from left to
right, each entering at its own moment with its own height, speed and size.
]]

local kFallbackClipLength = 8.0

local kMinimumBalls = 4
local kMinimumRate = 0.05
local kMaximumRate = 6.0
local kMinimumSize = 0.1
local kMaximumSize = 4.0
local kMinimumGround = 0.0
local kMaximumGround = 1.0
local kMinimumSquash = 0.0
local kMaximumSquash = 3.0

-- Seconds for one ball to cross the frame at Flow Speed 1.
local kBaseCrossingSeconds = 3.4
-- Balls enter and leave beyond the edges, so none of them pops into existence
-- in view. The travel spans this much more than the visible width.
local kEdgeMargin = 0.14

local kBaseGravity = 2.4
-- Restitution is capped below 1 so a ball always loses some energy on impact;
-- at 1 it would rebound to its release height forever and stop reading as a
-- ball. The reset at the right edge, not the decay, is what ends its life.
local kMaximumRestitution = 0.96
-- Per-ball spread around the Bounciness setting, so a crowd never lands in
-- lockstep: some balls are lively, some are dead, most sit in between.
local kRestitutionJitter = 0.16
local kGravityJitter = 0.28
local kDropHeightMin = 0.18
local kDropHeightMax = 0.62
local kLaunchVelocityMax = 0.35

local kSizeJitterMin = 0.55
local kSizeJitterMax = 1.45
-- Bigger balls read as nearer, so they also travel faster and paint brighter.
-- Tying all three to one value is what sells the depth without any projection.
local kNearSpeedBoost = 0.55

local kMinimumPandaShare = 0.0
local kMaximumPandaShare = 1.0

local kIntroDuration = 0.6
local kOutroDuration = 0.8

-- Panda, drawn for this script. Circles are cubic approximations with control
-- points at radius * 0.5523 from each quadrant point.
-- Winding is what makes the face read: the head and ears run counter-clockwise
-- and every feature on top of them runs clockwise, so the non-zero fill rule
-- cuts the eyes, pupils and nose out instead of painting them over.
local pandaPath = mt.svg_path([[
M 148 106
C 176.7 106 200 129.3 200 158
C 200 186.7 176.7 210 148 210
C 119.3 210 96 186.7 96 158
C 96 129.3 119.3 106 148 106
Z
M 148 134
C 134.7 134 124 144.7 124 158
C 124 171.3 134.7 182 148 182
C 161.3 182 172 171.3 172 158
C 172 144.7 161.3 134 148 134
Z
M 364 106
C 392.7 106 416 129.3 416 158
C 416 186.7 392.7 210 364 210
C 335.3 210 312 186.7 312 158
C 312 129.3 335.3 106 364 106
Z
M 364 134
C 350.7 134 340 144.7 340 158
C 340 171.3 350.7 182 364 182
C 377.3 182 388 171.3 388 158
C 388 144.7 377.3 134 364 134
Z
M 256 132
C 322 132 386 168 414 224
C 438 272 440 336 416 388
C 390 444 328 476 256 476
C 184 476 122 444 96 388
C 72 336 74 272 98 224
C 126 168 190 132 256 132
Z
M 214 256
C 206 252 195 253 186 256
C 162 264 140 288 136 314
C 132 340 148 362 172 366
C 198 370 222 350 230 322
C 238 296 232 268 214 256
Z
M 298 256
C 280 268 274 296 282 322
C 290 350 314 370 340 366
C 364 362 380 340 376 314
C 372 288 350 264 326 256
C 317 253 306 252 298 256
Z
M 180 288
C 191 288 200 297 200 308
C 200 319 191 328 180 328
C 169 328 160 319 160 308
C 160 297 169 288 180 288
Z
M 332 288
C 343 288 352 297 352 308
C 352 319 343 328 332 328
C 321 328 312 319 312 308
C 312 297 321 288 332 288
Z
M 256 372
C 237 372 222 382 222 394
C 222 406 237 416 256 416
C 275 416 290 406 290 394
C 290 382 275 372 256 372
Z
]], {
    view_box = { 0, 0, 512, 512 },
    em_scale = 0.34,
})

-- Pig, built the same way: head and ears counter-clockwise, every feature on
-- top of them clockwise so it is cut out of the head.
local pigPath = mt.svg_path([[
M 132 92
L 216 148
L 118 206
Z
M 380 92
L 394 206
L 296 148
Z
M 256 128
C 353.2 128 432 202.4 432 294
C 432 385.6 353.2 460 256 460
C 158.8 460 80 385.6 80 294
C 80 202.4 158.8 128 256 128
Z
M 196 234
C 182.7 234 172 248.3 172 266
C 172 283.7 182.7 298 196 298
C 209.3 298 220 283.7 220 266
C 220 248.3 209.3 234 196 234
Z
M 316 234
C 302.7 234 292 248.3 292 266
C 292 283.7 302.7 298 316 298
C 329.3 298 340 283.7 340 266
C 340 248.3 329.3 234 316 234
Z
M 256 318
C 209.6 318 172 341.4 172 370
C 172 398.6 209.6 422 256 422
C 302.4 422 340 398.6 340 370
C 340 341.4 302.4 318 256 318
Z
M 228 348
C 238.5 348 247 357.8 247 370
C 247 382.2 238.5 392 228 392
C 217.5 392 209 382.2 209 370
C 209 357.8 217.5 348 228 348
Z
M 284 348
C 294.5 348 303 357.8 303 370
C 303 382.2 294.5 392 284 392
C 273.5 392 265 382.2 265 370
C 265 357.8 273.5 348 284 348
Z
]], {
    view_box = { 0, 0, 512, 512 },
    em_scale = 0.34,
})

local ballCount = 0
-- Carried from OnPreLayout to OnLayout within the same frame, and overwritten
-- from the inputs every frame rather than accumulated, so OnLayout can repeat
-- the species draw and paint each animal its own color.
local pandaShare = 0.0

function OnPreLayout(ctx)
    ballCount = math.floor(mt.clamp(ctx.inputs.numbers[1],
        kMinimumBalls, ctx.meta.limits.max_characters))

    local panda = ctx.glyphs:declare({
        path = pandaPath,
        advance_x = 0,
        advance_y = 0,
        bounds = { 0, 0, 0, 0 },
    })
    local pig = ctx.glyphs:declare({
        path = pigPath,
        advance_x = 0,
        advance_y = 0,
        bounds = { 0, 0, 0, 0 },
    })

    -- Which animal each slot holds is decided once here, from a seed that is
    -- stable for the instance, so the mix never reshuffles between frames.
    -- Drawing per slot rather than alternating leaves the run lengths uneven,
    -- which is what makes the crowd look mixed instead of striped.
    pandaShare = mt.clamp(ctx.inputs.numbers[8],
        kMinimumPandaShare, kMaximumPandaShare)
    local pieces = {}
    for index = 1, ballCount do
        pieces[index] = mt.random(ctx.meta.instance_seed, index, "species") < pandaShare
            and panda or pig
    end

    ctx.global.text = table.concat(pieces)
end

function OnLayout(ctx)
    -- 2D-only: every ball is positioned with place_2d and depth is painted with
    -- size, speed and color, so the projection could only cost subdivision.
    ctx.output.force_disable_3d_projection = true

    local introAmount, outroAmount =
        mt.timeline.intro_outro_seconds(ctx, kIntroDuration, kOutroDuration, kFallbackClipLength)
    local presence = mt.ease.out_cubic(introAmount) * (1.0 - mt.ease.in_cubic(outroAmount))

    local flowRate = mt.clamp(ctx.inputs.numbers[2], kMinimumRate, kMaximumRate)
    local gravityScale = mt.clamp(ctx.inputs.numbers[3], kMinimumRate, kMaximumRate)
    local bounciness = mt.clamp(ctx.inputs.numbers[4], 0.0, kMaximumRestitution)
    local ballSize = mt.clamp(ctx.inputs.numbers[5], kMinimumSize, kMaximumSize)
    local groundY = mt.clamp(ctx.inputs.numbers[6], kMinimumGround, kMaximumGround)
    local squashScale = mt.clamp(ctx.inputs.numbers[7], kMinimumSquash, kMaximumSquash)
    local pandaColor = ctx.inputs.colors[1]
    local pigColor = ctx.inputs.colors[2]

    local seed = ctx.meta.instance_seed
    local gravity = kBaseGravity * gravityScale
    local travelSpan = 1.0 + kEdgeMargin * 2.0

    for index, ball in mt.each_char(ctx) do
        -- Depth comes first: it decides size, speed and color together, so a
        -- ball that looks near also behaves near.
        local nearness = mt.random(seed, index, "depth")
        local sizeJitter = mt.lerp(kSizeJitterMin, kSizeJitterMax, nearness)
        local crossingSeconds = kBaseCrossingSeconds
            / (flowRate * (1.0 + nearness * kNearSpeedBoost))

        -- Each ball owns a slot in the crossing cycle, so the stream is evenly
        -- fed instead of arriving in clumps. The wrap is what makes the flow
        -- endless: a ball leaving the right edge is the one entering at left.
        local slot = (index - 1) / ballCount
        local jitter = mt.random(seed, index, "slot") / ballCount
        local cycle = (ctx.time / crossingSeconds + slot + jitter) % 1.0

        -- Whole crossings completed so far. Folding this into the seed redraws
        -- every ball's arc each time it re-enters, so the stream never repeats
        -- a visible pattern.
        local pass = math.floor(ctx.time / crossingSeconds + slot + jitter)
        local passSeed = seed + pass * 7919

        local dropHeight = mt.random_range(passSeed, index, kDropHeightMin, kDropHeightMax, "drop")
        local launchVelocity = mt.random(passSeed, index, "launch") * kLaunchVelocityMax

        -- Physical properties vary per ball and are redrawn on every pass, so
        -- the stream reads as a crowd of different objects rather than one ball
        -- cloned many times. Both are centred on the Inspector value.
        local ballRestitution = mt.clamp(
            bounciness + (mt.random(passSeed, index, "restitution") - 0.5) * kRestitutionJitter,
            0.0, kMaximumRestitution)
        local ballGravity = gravity
            * (1.0 + (mt.random(passSeed, index, "gravity") - 0.5) * kGravityJitter)

        -- The ball's own clock: time since it entered at the left edge. Driving
        -- bounce_y with this rather than ctx.time is what lets every ball be at
        -- a different point in its arc.
        local ballTime = cycle * crossingSeconds
        local bounce = mt.bounce_y({
            t = ballTime,
            ground_y = groundY,
            start_y = groundY + dropHeight,
            gravity = ballGravity,
            restitution = ballRestitution,
            start_velocity = launchVelocity,
            squash = 0.15 * squashScale,
            stretch = 0.06 * squashScale,
        })

        mt.layout.place_2d(ctx, ball, -kEdgeMargin + cycle * travelSpan, bounce.y)

        ball.scale = ball.scale * ballSize * sizeJitter
        -- Squash and stretch are defined against the canvas axes: a ball flattens
        -- along Y as it meets the ground. Scale and stretch are applied inside
        -- the rotation, so spinning the ball would tilt that flattening with it
        -- and the impact would read as a diagonal smear. The ball is left
        -- unrotated so the deformation stays square to the floor.
        ball.stretch_x = ball.stretch_x * bounce.stretch_x
        ball.stretch_y = ball.stretch_y * bounce.stretch_y
        ball.opacity = ball.opacity * presence
        ball.fill.use = true
        -- Repeat the draw OnPreLayout used to pick this slot's glyph. Same seed,
        -- same index, same channel, so the color always lands on the animal
        -- that is actually being drawn there.
        local isPanda = mt.random(seed, index, "species") < pandaShare
        ball.fill.color = isPanda and pandaColor or pigColor
    end
end
