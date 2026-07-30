-- @MugTypography
-- @duration 9
-- @recommend bg #18322b
-- @title Flower Bloom
-- @author Mug
-- @version 1.0
-- @api_level 5
--[[ @description
Flowers bloom in a random order, gently sway, and transform into the
original text. In the outro, the letters return to flowers before
disappearing together.
]]

local kFlowerViewBox = { 0, 0, 1000, 1000 }
local kFlowerEmScale = 0.78
local kFontEmCanvasHeight = 0.10

-- Tight source bounds, expressed as fractions of the shared view box.
local flowerBounds = {
    { width = 0.7132, height = 0.6954 },
    { width = 0.7800, height = 0.7800 },
    { width = 0.6616, height = 0.6670 },
    { width = 0.8060, height = 0.8060 },
    { width = 0.7154, height = 0.7610 },
}

local flowerTemplates = {
    mt.svg_path([[
M 538.4 455 C 620 336.2 574.4 158 500 125 C 425.6 158 380 336.2 461.6 455 C 485.6 473 514.4 473 538.4 455 Z
M 554.7 522.6 C 692.9 563.5 848.3 465.1 856.6 384.1 C 802.3 323.6 618.7 335.3 530.9 449.6 C 521.2 478 530.1 505.4 554.7 522.6 Z
M 495.4 559 C 499.2 703.1 640.8 820.4 720.4 803.4 C 761.2 733 693.4 562 557.5 513.8 C 527.5 513.4 504.2 530.3 495.4 559 Z
M 442.5 513.8 C 306.6 562 238.8 733 279.6 803.4 C 359.2 820.4 500.8 703.1 504.6 559 C 495.8 530.3 472.5 513.4 442.5 513.8 Z
M 469.1 449.6 C 381.3 335.3 197.7 323.6 143.4 384.1 C 151.7 465.1 307.1 563.5 445.3 522.6 C 469.9 505.4 478.8 478 469.1 449.6 Z
M 610 500 C 610 439.2 560.8 390 500 390 C 439.2 390 390 439.2 390 500 C 390 560.8 439.2 610 500 610 C 560.8 610 610 560.8 610 500 Z
]], {
        view_box = kFlowerViewBox,
        em_scale = kFlowerEmScale,
    }),
    mt.svg_path([[
M 515 428 C 547 313.5 529.1 141.8 500 110 C 470.9 141.8 453 313.5 485 428 C 494.4 446 505.6 446 515 428 Z
M 549 445.2 C 633.9 362 704.3 204.4 695 162.3 C 653.9 175.2 552.5 315 523 430.1 C 522.1 450.4 531.9 456.1 549 445.2 Z
M 569.9 477 C 685 447.5 824.8 346.1 837.7 305 C 795.6 295.7 638 366.1 554.8 451 C 543.9 468.1 549.6 477.9 569.9 477 Z
M 572 515 C 686.5 547 858.2 529.1 890 500 C 858.2 470.9 686.5 453 572 485 C 554 494.4 554 505.6 572 515 Z
M 554.8 549 C 638 633.9 795.6 704.3 837.7 695 C 824.8 653.9 685 552.5 569.9 523 C 549.6 522.1 543.9 531.9 554.8 549 Z
M 523 569.9 C 552.5 685 653.9 824.8 695 837.7 C 704.3 795.6 633.9 638 549 554.8 C 531.9 543.9 522.1 549.6 523 569.9 Z
M 485 572 C 453 686.5 470.9 858.2 500 890 C 529.1 858.2 547 686.5 515 572 C 505.6 554 494.4 554 485 572 Z
M 451 554.8 C 366.1 638 295.7 795.6 305 837.7 C 346.1 824.8 447.5 685 477 569.9 C 477.9 549.6 468.1 543.9 451 554.8 Z
M 430.1 523 C 315 552.5 175.2 653.9 162.3 695 C 204.4 704.3 362 633.9 445.2 549 C 456.1 531.9 450.4 522.1 430.1 523 Z
M 428 485 C 313.5 453 141.8 470.9 110 500 C 141.8 529.1 313.5 547 428 515 C 446 505.6 446 494.4 428 485 Z
M 445.2 451 C 362 366.1 204.4 295.7 162.3 305 C 175.2 346.1 315 447.5 430.1 477 C 450.4 477.9 456.1 468.1 445.2 451 Z
M 477 430.1 C 447.5 315 346.1 175.2 305 162.3 C 295.7 204.4 366.1 362 451 445.2 C 468.1 456.1 477.9 450.4 477 430.1 Z
M 600 500 C 600 444.8 555.2 400 500 400 C 444.8 400 400 444.8 400 500 C 400 555.2 444.8 600 500 600 C 555.2 600 600 555.2 600 500 Z
]], {
        view_box = kFlowerViewBox,
        em_scale = kFlowerEmScale,
    }),
    mt.svg_path([[
M 543.5 458 C 645 339 572.5 179.2 500 118 C 427.5 179.2 355 339 456.5 458 Q 500 500 543.5 458 Z
M 514.6 558.7 C 566.9 706.1 741.6 723.2 830.8 691 C 814.1 597.6 711.9 454.9 558.1 483.3 Q 500 500 514.6 558.7 Z
M 441.9 483.3 C 288.1 454.9 185.9 597.6 169.2 691 C 258.4 723.2 433.1 706.1 485.4 558.7 Q 500 500 441.9 483.3 Z
M 546.5 510.6 C 660.1 532.3 741.3 438 746.8 357.5 C 674.4 322 552.1 345.2 514.1 454.4 Q 500 500 546.5 510.6 Z
M 467.6 535 C 392 622.5 433 740 500 785 C 567 740 608 622.5 532.4 535 Q 500 500 467.6 535 Z
M 485.9 454.4 C 447.9 345.2 325.6 322 253.2 357.5 C 258.7 438 339.9 532.3 453.5 510.6 Q 500 500 485.9 454.4 Z
M 555 500 C 555 469.6 530.4 445 500 445 C 469.6 445 445 469.6 445 500 C 445 530.4 469.6 555 500 555 C 530.4 555 555 530.4 555 500 Z
]], {
        view_box = kFlowerViewBox,
        em_scale = kFlowerEmScale,
    }),
    mt.svg_path([[
M 509.8 382 C 539 262.3 517.5 165.4 500 97 C 482.4 165.4 461 262.3 490.3 382 Q 500 500 509.8 382 Z
M 554.2 394.7 C 620.6 310.8 632.6 225.7 638.9 164.6 C 600.2 212.2 548.5 281 536.1 387.3 Q 500 500 554.2 394.7 Z
M 590.3 423.5 C 695.7 359.5 749 275.8 785 215 C 724.2 251 640.5 304.3 576.5 409.7 Q 500 500 590.3 423.5 Z
M 612.7 463.9 C 719 451.5 787.8 399.8 835.4 361.1 C 774.3 367.4 689.2 379.4 605.3 445.8 Q 500 500 612.7 463.9 Z
M 618 509.8 C 737.7 539 834.6 517.5 903 500 C 834.6 482.4 737.7 461 618 490.3 Q 500 500 618 509.8 Z
M 605.3 554.2 C 689.2 620.6 774.3 632.6 835.4 638.9 C 787.8 600.2 719 548.5 612.7 536.1 Q 500 500 605.3 554.2 Z
M 576.5 590.3 C 640.5 695.7 724.2 749 785 785 C 749 724.2 695.7 640.5 590.3 576.5 Q 500 500 576.5 590.3 Z
M 536.1 612.7 C 548.5 719 600.2 787.8 638.9 835.4 C 632.6 774.3 620.6 689.2 554.2 605.3 Q 500 500 536.1 612.7 Z
M 490.3 618 C 461 737.7 482.4 834.6 500 903 C 517.5 834.6 539 737.7 509.8 618 Q 500 500 490.3 618 Z
M 445.8 605.3 C 379.4 689.2 367.4 774.3 361.1 835.4 C 399.8 787.8 451.5 719 463.9 612.7 Q 500 500 445.8 605.3 Z
M 409.7 576.5 C 304.3 640.5 251 724.2 215 785 C 275.8 749 359.5 695.7 423.5 590.3 Q 500 500 409.7 576.5 Z
M 387.3 536.1 C 281 548.5 212.2 600.2 164.6 638.9 C 225.7 632.6 310.8 620.6 394.7 554.2 Q 500 500 387.3 536.1 Z
M 382 490.3 C 262.3 461 165.4 482.5 97 500 C 165.4 517.6 262.3 539 382 509.8 Q 500 500 382 490.3 Z
M 394.7 445.8 C 310.8 379.4 225.7 367.4 164.6 361.1 C 212.2 399.8 281 451.5 387.3 463.9 Q 500 500 394.7 445.8 Z
M 423.5 409.7 C 359.5 304.3 275.8 251 215 215 C 251 275.8 304.3 359.5 409.7 423.5 Q 500 500 423.5 409.7 Z
M 463.9 387.3 C 451.5 281 399.8 212.2 361.1 164.6 C 367.4 225.7 379.4 310.8 445.8 394.7 Q 500 500 463.9 387.3 Z
M 650 500 C 650 417.2 582.8 350 500 350 C 417.2 350 350 417.2 350 500 C 350 582.8 417.2 650 500 650 C 582.8 650 650 582.8 650 500 Z
]], {
        view_box = kFlowerViewBox,
        em_scale = kFlowerEmScale,
    }),
    mt.svg_path([[
M 529 452 C 616 298.7 552.2 174.6 500 87 C 447.8 174.6 384 298.7 471 452 Q 500 500 529 452 Z
M 553.1 495.9 C 696.7 492.7 759.7 397.9 801.4 326 C 718.3 326.1 604.7 333.3 530.1 456.1 Q 500 500 553.1 495.9 Z
M 527.1 549.1 C 616.3 701.1 755.7 707.9 857.7 706.5 C 807.9 617.5 732.3 500.2 556.1 498.9 Q 500 500 527.1 549.1 Z
M 477 548 C 408 674 458.6 776 500 848 C 541.4 776 592 674 523 548 Q 500 500 477 548 Z
M 443.9 498.9 C 267.7 500.2 192.1 617.5 142.3 706.5 C 244.3 707.9 383.7 701.1 472.9 549.1 Q 500 500 443.9 498.9 Z
M 469.9 456.1 C 395.3 333.3 281.7 326.1 198.6 326 C 240.3 397.9 303.3 492.7 446.9 495.9 Q 500 500 469.9 456.1 Z
M 570 500 C 570 461.3 538.7 430 500 430 C 461.3 430 430 461.3 430 500 C 430 538.7 461.3 570 500 570 C 538.7 570 570 538.7 570 500 Z
]], {
        view_box = kFlowerViewBox,
        em_scale = kFlowerEmScale,
    }),
}

local flowerColors = {
    { r = 0.93, g = 0.36, b = 0.47, a = 1.0 },
    { r = 1.00, g = 0.97, b = 0.91, a = 1.0 },
    { r = 0.94, g = 0.48, b = 0.20, a = 1.0 },
    { r = 0.96, g = 0.79, b = 0.27, a = 1.0 },
    { r = 0.58, g = 0.40, b = 0.80, a = 1.0 },
}

local kTextColor = { r = 0.96, g = 0.94, b = 0.84, a = 1.0 }

-- Primary timing controls, in seconds.
local kBloomStaggerDuration = 1.15 -- Total spread between first and last bloom
local kBloomDuration = 0.42 -- Time for one flower to snap open
local kAllFlowersHoldDuration = 0.65 -- Hold before flowers begin becoming letters
local kTextRevealStaggerDuration = 1.0 -- Total spread between first and last letter
local kFlowerToLetterFoldDuration = 0.18 -- Time for one flower to fold to the swap point
local kLetterPopDuration = 0.52 -- Time for one letter to pop open
local kOutroTextToFlowerDuration = 1.85 -- Time for all letters to become flowers
local kOutroFlowerHoldDuration = 0.50 -- Hold after every outro flower is visible
local kOutroDisappearDuration = 0.40 -- Simultaneous flower disappearance time

-- Motion styling controls.
local kInitialRotation = -18.0
local kLetterInitialRotationRange = 24.0
local kFlowerBoundsFit = 0.90
local kSwapScale = 0.08
local kFlowerSeedScale = 0.04
local kFlowerSwayDegrees = 3.5
local kFlowerSwayFrequency = 0.7
local kFlowerSwayFadeInDuration = 0.18
local kLetterStartStretchX = 0.72
local kLetterStartStretchY = 1.28
local kFallbackClipLength = 10.0
local kBloomRandomSequenceOffset = 1000
local kConversionRandomSequenceOffset = 2000
local kLetterRotationRandomSequenceOffset = 3000
local kAllFlowersCompleteTime =
    kBloomStaggerDuration + kBloomDuration
local kConversionStartTime =
    kAllFlowersCompleteTime + kAllFlowersHoldDuration
local kIntroDuration =
    kConversionStartTime
    + kTextRevealStaggerDuration
    + kFlowerToLetterFoldDuration
    + kLetterPopDuration
local kOutroDuration =
    kOutroTextToFlowerDuration
    + kOutroFlowerHoldDuration
    + kOutroDisappearDuration

local function getEffectState(ctx)
    local introProgress, outroProgress =
        mt.timeline.intro_outro_seconds(
            ctx,
            kIntroDuration,
            kOutroDuration,
            kFallbackClipLength
        )

    local effectTime = introProgress * kIntroDuration
    local disappearProgress = 0.0
    if outroProgress > 0.0 then
        local outroTime = outroProgress * kOutroDuration
        local transformProgress =
            mt.saturate(outroTime / kOutroTextToFlowerDuration)
        effectTime =
            mt.lerp(
                kIntroDuration,
                kConversionStartTime,
                mt.ease.in_out_cubic(transformProgress)
            )

        local disappearStartTime =
            kOutroTextToFlowerDuration + kOutroFlowerHoldDuration
        disappearProgress =
            mt.saturate(
                (outroTime - disappearStartTime)
                / kOutroDisappearDuration
            )
    end
    return effectTime, disappearProgress
end

local function assignRandomRanks(entries, key)
    table.sort(entries, function(left, right)
        local leftValue = left[key]
        local rightValue = right[key]
        if leftValue == rightValue then
            return left.index < right.index
        end
        return leftValue < rightValue
    end)

    local ranks = {}
    for rank, entry in ipairs(entries) do
        ranks[entry.index] = rank
    end
    return ranks
end

local function getAnimatedCharacterData(ctx)
    local orders = {}
    local entries = {}
    for index = 1, ctx.char_count do
        if mt.text.classify(ctx.chars[index].text) ~= "space" then
            orders[index] = #entries + 1
            entries[#entries + 1] = {
                index = index,
                bloom_key =
                    mt.random(
                        ctx.meta.instance_seed,
                        index + kBloomRandomSequenceOffset
                    ),
                conversion_key =
                    mt.random(
                        ctx.meta.instance_seed,
                        index + kConversionRandomSequenceOffset
                    ),
            }
        end
    end

    local bloomRanks = assignRandomRanks(entries, "bloom_key")
    local conversionRanks = assignRandomRanks(entries, "conversion_key")
    return orders, bloomRanks, conversionRanks, #entries
end

local function getCharacterTiming(
    bloomRank,
    conversionRank,
    characterCount,
    effectTime
)
    local bloomDelay =
        mt.distribute(bloomRank, math.max(characterCount, 1))
        * kBloomStaggerDuration
    local bloomStartTime = bloomDelay
    local bloomLocalTime = effectTime - bloomStartTime
    local randomDelay =
        mt.distribute(conversionRank, math.max(characterCount, 1))
        * kTextRevealStaggerDuration
    local foldStartTime = kConversionStartTime + randomDelay
    local glyphStartTime = foldStartTime + kFlowerToLetterFoldDuration
    return bloomLocalTime, foldStartTime, glyphStartTime
end

local function getFlowerIndex(index)
    return ((index - 1) % #flowerTemplates) + 1
end

local function getFlowerFitScale(ctx, character, flowerIndex)
    local glyphWidth =
        character.geometry.bounds_width * ctx.canvas.aspect_ratio
    local glyphHeight = character.geometry.bounds_height
    local flowerBoundsForIndex = flowerBounds[flowerIndex]
    local flowerWidth =
        flowerBoundsForIndex.width
        * kFlowerEmScale
        * kFontEmCanvasHeight
    local flowerHeight =
        flowerBoundsForIndex.height
        * kFlowerEmScale
        * kFontEmCanvasHeight
    local widthScale = glyphWidth / flowerWidth
    local heightScale = glyphHeight / flowerHeight
    return math.min(widthScale, heightScale) * kFlowerBoundsFit
end

function OnLayout(ctx)
    local effectTime, outroDisappearProgress = getEffectState(ctx)
    local animatedCharacterOrders, bloomRanks, conversionRanks, animatedCharacterCount =
        getAnimatedCharacterData(ctx)

    for index = 1, ctx.char_count do
        local character = ctx.chars[index]
        local animatedOrder = animatedCharacterOrders[index]

        if animatedOrder ~= nil then
            local bloomLocalTime, foldStartTime, glyphStartTime =
                getCharacterTiming(
                    bloomRanks[index],
                    conversionRanks[index],
                    animatedCharacterCount,
                    effectTime
                )
            local flowerIndex = getFlowerIndex(animatedOrder)
            local inspectorScale = character.scale
            local flowerFitScale =
                getFlowerFitScale(ctx, character, flowerIndex)
            local letterInitialRotation =
                mt.random_range(
                    ctx.meta.instance_seed,
                    index + kLetterRotationRandomSequenceOffset,
                    -kLetterInitialRotationRange,
                    kLetterInitialRotationRange
                )

            character.fill.use = true
            mt.layout.pivot_at_2d(ctx, character, "center")

            if effectTime < glyphStartTime then
                local bloomProgress = mt.saturate(bloomLocalTime / kBloomDuration)
                local bloom = mt.lerp(
                    kFlowerSeedScale,
                    1.0,
                    mt.ease.out_back(bloomProgress)
                )
                local foldProgress =
                    mt.saturate(
                        (effectTime - foldStartTime)
                        / kFlowerToLetterFoldDuration
                    )
                local fold = mt.ease.in_cubic(foldProgress)
                local swayAmount = mt.ease.out_sine(
                    mt.saturate(
                        (bloomLocalTime - kBloomDuration)
                        / kFlowerSwayFadeInDuration
                    )
                )
                local sway =
                    mt.wave(ctx.time, kFlowerSwayFrequency, index * 0.31)
                    * kFlowerSwayDegrees
                    * swayAmount
                    * (1.0 - fold)

                character.scale =
                    inspectorScale
                    * bloom
                    * mt.lerp(flowerFitScale, kSwapScale, fold)
                character.stretch_x = 1.0
                character.stretch_y = 1.0
                character.rotation =
                    mt.lerp(kInitialRotation, 0.0, bloomProgress)
                    + sway
                    + fold * letterInitialRotation
                character.opacity = mt.saturate(bloomLocalTime / 0.12)
                character.fill.color = flowerColors[flowerIndex]

                if character.part_count > 0 then
                    local firstPart = ctx.parts[character.part_start]
                    firstPart.pivot_x = 0.5
                    firstPart.pivot_y = 0.5
                    firstPart.scale = 1.0
                    firstPart.stretch_x = 1.0
                    firstPart.stretch_y = 1.0
                    firstPart.rotation = 0.0
                    firstPart.offset_x = 0.5
                    firstPart.offset_y = 0.5
                end
            else
                local letterProgress =
                    mt.saturate(
                        (effectTime - glyphStartTime)
                        / kLetterPopDuration
                    )
                local letterOpen = mt.ease.out_back(letterProgress)

                character.scale =
                    inspectorScale * mt.lerp(kSwapScale, 1.0, letterOpen)
                character.stretch_x =
                    mt.lerp(kLetterStartStretchX, 1.0, letterProgress)
                character.stretch_y =
                    mt.lerp(kLetterStartStretchY, 1.0, letterProgress)
                character.rotation =
                    mt.lerp(letterInitialRotation, 0.0, letterProgress)
                character.opacity = 1.0
                character.fill.color =
                    mt.color.lerp(
                        flowerColors[flowerIndex],
                        kTextColor,
                        letterProgress
                    )
            end

            local outroDisappear =
                mt.ease.in_cubic(outroDisappearProgress)
            character.scale = character.scale * (1.0 - outroDisappear)
            character.opacity = character.opacity * (1.0 - outroDisappear)
        end
    end
end

function OnPath(ctx)
    local effectTime = getEffectState(ctx)
    local animatedCharacterOrders, bloomRanks, conversionRanks, animatedCharacterCount =
        getAnimatedCharacterData(ctx)

    for index = 1, ctx.char_count do
        local animatedOrder = animatedCharacterOrders[index]
        if animatedOrder ~= nil then
            local _, _, glyphStartTime =
                getCharacterTiming(
                    bloomRanks[index],
                    conversionRanks[index],
                    animatedCharacterCount,
                    effectTime
                )

            if effectTime < glyphStartTime then
                local parts = ctx.paths:character(index)
                for partIndex, part in ipairs(parts) do
                    if partIndex == 1 then
                        part.path:assign(
                            flowerTemplates[getFlowerIndex(animatedOrder)]
                        )
                    else
                        part.path:clear()
                    end
                end
            end
        end
    end
end
