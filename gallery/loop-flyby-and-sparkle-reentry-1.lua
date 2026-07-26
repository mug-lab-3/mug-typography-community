-- @MugTypography
-- @duration 9.0
-- @required 3d
-- @title Loop Flyby and Sparkle Reentry
-- @author Mug
-- @version 1.0
-- @api_level 3
--[[ @description
Characters loop in from the right, exit left, then re-enter from the distance with
a sparkle before fading out to the left.
]]

-- =========================================================
-- Timing
-- =========================================================

local LOOP_START = 0.00
local LOOP_STAGGER = 0.095
local LOOP_DURATION = 2.75

local BETWEEN_GAP = 0.32

local REENTRY_STAGGER = 0.085
local REENTRY_DURATION = 1.05

local SPARKLE_AT = 0.80
local SPARKLE_DURATION = 0.34

local OUTRO_STAGGER = 0.035
local OUTRO_DURATION = 0.72
local FALLBACK_DURATION = 9.0

-- =========================================================
-- One unified clockwise motion path
-- =========================================================

-- This is intentionally one continuous path:
-- right entrance -> clockwise loop -> left exit.
--
-- There are no timing boundaries for entrance, loop, or exit.
-- The points describe only the spatial shape of a single movement.
local FLYBY_PATH = {
    -- Approach from the right, already curving toward the loop.
    { x = 1.28, y = 0.65 },
    { x = 1.13, y = 0.63 },
    { x = 0.96, y = 0.60 },
    { x = 0.81, y = 0.56 },
    { x = 0.72, y = 0.51 },

    -- Clockwise loop: right -> bottom -> left -> top -> right.
    { x = 0.68, y = 0.42 },
    { x = 0.61, y = 0.34 },
    { x = 0.50, y = 0.30 },
    { x = 0.38, y = 0.33 },
    { x = 0.30, y = 0.41 },
    { x = 0.27, y = 0.51 },
    { x = 0.31, y = 0.61 },
    { x = 0.40, y = 0.68 },
    { x = 0.52, y = 0.70 },
    { x = 0.63, y = 0.65 },
    { x = 0.69, y = 0.56 },

    -- Peel away from the loop without returning to the same point.
    -- The curve keeps its momentum, bends downward, then opens left.
    { x = 0.67, y = 0.47 },
    { x = 0.60, y = 0.40 },
    { x = 0.48, y = 0.37 },
    { x = 0.33, y = 0.39 },
    { x = 0.17, y = 0.43 },
    { x = 0.00, y = 0.47 },
    { x = -0.18, y = 0.49 },
    { x = -0.34, y = 0.50 },
}

-- Number of samples used to approximate arc length.
-- Higher values improve speed uniformity at a small calculation cost.
local ARC_LENGTH_SAMPLES = 96

local MAX_BANK_ANGLE = 10.0

-- =========================================================
-- Re-entry
-- =========================================================

local REENTRY_FROM_X = 0.05
local REENTRY_FROM_Y = 0.58
local REENTRY_FROM_Z = 1.50
local REENTRY_START_SCALE = 0.50

local REENTRY_START_YAW = -72.0
local REENTRY_START_PITCH = 15.0
local LANDING_OVERSHOOT_Z = -0.022

-- =========================================================
-- Outro
-- =========================================================

local OUTRO_SHIFT_X = -0.32
local OUTRO_SHIFT_Y = 0.018
local OUTRO_YAW = -12.0

local CAMERA_PERSPECTIVE = 1.20

-- =========================================================
-- Helpers
-- =========================================================

local function saturate(value)
    return mt.saturate(value)
end

local function lerp(a, b, progress)
    return mt.lerp(a, b, progress)
end

local function gaussian(value, center, width)
    local distance = (value - center) / width
    return math.exp(-(distance * distance))
end

local function bank_from_tangent(dx, dy)
    -- Keep the glyph upright and use only a small visual bank.
    local angle =
        math.deg(
            math.atan(
                dy,
                math.abs(dx) + 0.0001
            )
        )

    return mt.clamp(
        angle,
        -MAX_BANK_ANGLE,
        MAX_BANK_ANGLE
    )
end

-- Approximate constant-speed travel along the Catmull-Rom path.
--
-- Catmull-Rom's raw t distributes equal time to spline segments, not equal
-- distance. Uneven waypoint spacing can therefore look like separate sections.
-- This function samples the complete path and maps normalized distance back
-- to the corresponding spline t.
local function arc_length_parameter(points, distance_progress)
    local target = saturate(distance_progress)

    if target <= 0.0 then
        return 0.0
    end

    if target >= 1.0 then
        return 1.0
    end

    local previous_x, previous_y =
        mt.path.catmull_rom(points, 0.0)

    local total_length = 0.0

    -- First pass: measure the full path length.
    for sample = 1, ARC_LENGTH_SAMPLES do
        local t = sample / ARC_LENGTH_SAMPLES
        local x, y = mt.path.catmull_rom(points, t)

        local dx = x - previous_x
        local dy = y - previous_y

        total_length =
            total_length
            + math.sqrt(dx * dx + dy * dy)

        previous_x = x
        previous_y = y
    end

    if total_length <= 0.000001 then
        return target
    end

    local target_length =
        total_length * target

    previous_x, previous_y =
        mt.path.catmull_rom(points, 0.0)

    local accumulated = 0.0

    -- Second pass: locate the segment containing the target distance.
    for sample = 1, ARC_LENGTH_SAMPLES do
        local current_t =
            sample / ARC_LENGTH_SAMPLES

        local x, y =
            mt.path.catmull_rom(
                points,
                current_t
            )

        local dx = x - previous_x
        local dy = y - previous_y
        local segment_length =
            math.sqrt(dx * dx + dy * dy)

        local next_accumulated =
            accumulated + segment_length

        if next_accumulated >= target_length then
            local previous_t =
                (sample - 1)
                / ARC_LENGTH_SAMPLES

            local inside_segment = 0.0

            if segment_length > 0.000001 then
                inside_segment =
                    (
                        target_length
                        - accumulated
                    )
                    / segment_length
            end

            return lerp(
                previous_t,
                current_t,
                inside_segment
            )
        end

        accumulated = next_accumulated
        previous_x = x
        previous_y = y
    end

    return 1.0
end

-- =========================================================
-- Camera
-- =========================================================

function OnPreLayout(ctx)
    if ctx.meta.capabilities.has_3d then
        ctx.camera.perspective =
            CAMERA_PERSPECTIVE
    end
end

-- =========================================================
-- Character animation
-- =========================================================

function OnLayout(ctx)
    if ctx.char_count <= 0 then
        return
    end

    local last_loop_end =
        LOOP_START
        + LOOP_DURATION
        + math.max(
            ctx.char_count - 1,
            0
        )
        * LOOP_STAGGER

    local reentry_start =
        last_loop_end
        + BETWEEN_GAP

    local remaining =
        mt.timeline.remaining(
            ctx,
            FALLBACK_DURATION
        )

    for index = 1, ctx.char_count do
        local character =
            ctx.chars[index]

        local natural_x =
            character.geometry.bounds_center_x

        local natural_y =
            character.geometry.bounds_center_y

        -- =================================================
        -- 1) Unified right-to-loop-to-left flyby
        -- =================================================

        local flyby_time =
            ctx.time
            - LOOP_START
            - (index - 1)
            * LOOP_STAGGER

        local flyby_progress =
            saturate(
                flyby_time
                / LOOP_DURATION
            )

        if flyby_time < 0.0 then
            local start_x, start_y =
                mt.path.catmull_rom(
                    FLYBY_PATH,
                    0.0
                )

            mt.layout.place_2d(
                ctx,
                character,
                start_x,
                start_y
            )

            character.opacity = 0.0

        elseif flyby_progress < 1.0 then
            -- One timing curve for the complete movement.
            -- There are no separate intro/loop/exit eases.
            local distance_progress =
                mt.ease.cubic_bezier(
                    0.32,
                    0.00,
                    0.68,
                    1.00,
                    flyby_progress
                )

            local path_t =
                arc_length_parameter(
                    FLYBY_PATH,
                    distance_progress
                )

            local x, y, tangent_x, tangent_y =
                mt.path.catmull_rom(
                    FLYBY_PATH,
                    path_t
                )

            mt.layout.place_2d(
                ctx,
                character,
                x,
                y
            )

            character.rotation =
                character.rotation
                + bank_from_tangent(
                    tangent_x,
                    tangent_y
                )

            local enter_alpha =
                mt.smoothstep(
                    0.0,
                    0.055,
                    flyby_progress
                )

            local exit_alpha =
                1.0
                - mt.smoothstep(
                    0.965,
                    1.0,
                    flyby_progress
                )

            character.opacity =
                character.opacity
                * enter_alpha
                * exit_alpha

            if ctx.meta.capabilities.has_3d then
                -- Depth is also continuous over the full flyby.
                local depth_wave =
                    math.sin(
                        distance_progress
                        * math.pi
                        * 2.0
                    )

                local depth_gate =
                    mt.smoothstep(
                        0.08,
                        0.20,
                        distance_progress
                    )
                    * (
                        1.0
                        - mt.smoothstep(
                            0.78,
                            0.94,
                            distance_progress
                        )
                    )

                -- Intro moves from the foreground toward the background.
                -- Negative Z is closer to the camera; positive Z is farther away.
                local intro_progress =
                    mt.smoothstep(
                        0.00,
                        0.34,
                        distance_progress
                    )

                local intro_z =
                    mt.lerp(
                        -0.10,
                        0.18,
                        intro_progress
                    )

                -- Return from the background to the normal text plane
                -- before the character reaches the left-side exit.
                local exit_depth_return =
                    mt.smoothstep(
                        0.58,
                        0.88,
                        distance_progress
                    )

                local base_z =
                    mt.lerp(
                        intro_z,
                        0.0,
                        exit_depth_return
                    )

                -- Keep only a subtle depth motion during the middle of the loop.
                local loop_depth_gate =
                    mt.smoothstep(
                        0.28,
                        0.42,
                        distance_progress
                    )
                    * (
                        1.0
                        - mt.smoothstep(
                            0.68,
                            0.82,
                            distance_progress
                        )
                    )

                character.z =
                    character.z
                    + base_z
                    + depth_wave
                    * 0.025
                    * loop_depth_gate

                character.yaw =
                    character.yaw
                    + math.cos(
                        distance_progress
                        * math.pi
                        * 2.0
                    )
                    * 11.0
                    * depth_gate
            end

        else
            character.opacity = 0.0
        end

        -- =================================================
        -- 2) Staggered re-entry from distant left
        -- =================================================

        local reentry_time =
            ctx.time
            - reentry_start
            - (index - 1)
            * REENTRY_STAGGER

        local reentry_progress =
            saturate(
                reentry_time
                / REENTRY_DURATION
            )

        if reentry_time >= 0.0 then
            -- Start gently in the distance, accelerate toward the viewer,
            -- then decelerate smoothly into the final position.
            local move =
                mt.ease.cubic_bezier(
                    0.38,
                    0.00,
                    0.18,
                    1.00,
                    reentry_progress
                )

            -- One shared landing phase controls position, scale and depth.
            -- This keeps the small forward bounce synchronized with arrival.
            local landing_phase =
                mt.smoothstep(
                    0.72,
                    1.00,
                    reentry_progress
                )

            local landing_bounce =
                math.sin(
                    landing_phase
                    * math.pi
                )
                * (
                    1.0
                    - landing_phase
                    * 0.35
                )

            local target_x =
                lerp(
                    REENTRY_FROM_X,
                    natural_x,
                    move
                )

            local target_y =
                lerp(
                    REENTRY_FROM_Y,
                    natural_y,
                    move
                )
                + landing_bounce
                * 0.006

            mt.layout.place_2d(
                ctx,
                character,
                target_x,
                target_y
            )

            character.opacity =
                character.opacity
                + mt.smoothstep(
                    0.03,
                    0.26,
                    reentry_progress
                )

            character.scale =
                character.scale
                * (
                    lerp(
                        REENTRY_START_SCALE,
                        1.0,
                        move
                    )
                    + landing_bounce
                    * 0.035
                )

            character.rotation =
                character.rotation
                + lerp(
                    -8.0,
                    0.0,
                    move
                )
                - landing_bounce
                * 1.2

            if ctx.meta.capabilities.has_3d then
                character.z =
                    character.z
                    + lerp(
                        REENTRY_FROM_Z,
                        0.0,
                        move
                    )
                    + landing_bounce
                    * LANDING_OVERSHOOT_Z

                character.yaw =
                    character.yaw
                    + lerp(
                        REENTRY_START_YAW,
                        0.0,
                        move
                    )
                    + landing_bounce
                    * 2.5

                character.pitch =
                    character.pitch
                    + lerp(
                        REENTRY_START_PITCH,
                        0.0,
                        move
                    )
                    - landing_bounce
                    * 1.2
            end

            -- =============================================
            -- 3) Individual sparkle
            -- =============================================

            local sparkle_time =
                reentry_time
                - REENTRY_DURATION
                * SPARKLE_AT

            local sparkle_progress =
                sparkle_time
                / SPARKLE_DURATION

            local sparkle =
                gaussian(
                    sparkle_progress,
                    0.46,
                    0.20
                )
                * mt.smoothstep(
                    0.0,
                    0.12,
                    sparkle_progress
                )
                * (
                    1.0
                    - mt.smoothstep(
                        0.82,
                        1.0,
                        sparkle_progress
                    )
                )

            if sparkle > 0.001 then
                character.fill.use = true

                character.fill.color.r =
                    lerp(
                        character.fill.color.r,
                        1.0,
                        sparkle
                    )

                character.fill.color.g =
                    lerp(
                        character.fill.color.g,
                        1.0,
                        sparkle
                    )

                character.fill.color.b =
                    lerp(
                        character.fill.color.b,
                        1.0,
                        sparkle
                    )

                character.scale =
                    character.scale
                    * (
                        1.0
                        + 0.07
                        * sparkle
                    )

                if ctx.meta.capabilities.has_3d then
                    character.z =
                        character.z
                        - 0.055
                        * sparkle

                    character.yaw =
                        character.yaw
                        + 9.0
                        * sparkle
                end
            end
        end

        -- =================================================
        -- 4) Smooth staggered outro
        -- =================================================

        -- Include the full stagger span in the outro window so even
        -- the final character reaches progress 1.0 at the clip end.
        local outro_total =
            OUTRO_DURATION
            + math.max(
                ctx.char_count - 1,
                0
            )
            * OUTRO_STAGGER

        local outro_time =
            outro_total
            - remaining
            - (index - 1)
            * OUTRO_STAGGER

        local outro_progress =
            saturate(
                outro_time
                / OUTRO_DURATION
            )

        if outro_progress > 0.0 then
            local move =
                mt.ease.in_out_cubic(
                    outro_progress
                )

            character.offset_x =
                character.offset_x
                + OUTRO_SHIFT_X
                * move

            character.offset_y =
                character.offset_y
                + math.sin(
                    outro_progress
                    * math.pi
                )
                * OUTRO_SHIFT_Y

            character.opacity =
                character.opacity
                * (
                    1.0
                    - mt.smoothstep(
                        0.0,
                        1.0,
                        outro_progress
                    )
                )

            character.rotation =
                character.rotation
                - 8.0
                * move

            if ctx.meta.capabilities.has_3d then
                character.z =
                    character.z
                    + 0.10
                    * move

                character.yaw =
                    character.yaw
                    + OUTRO_YAW
                    * move
            end
        end
    end
end