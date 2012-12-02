
module Guide

import Gadfly
import Gadfly.render

load("Compose.jl")
using Compose


# Where the guide should be placed in relation to the plot.
abstract GuidePosition
type TopGuidePosition    <: GuidePosition end
type RightGuidePosition  <: GuidePosition end
type BottomGuidePosition <: GuidePosition end
type LeftGuidePosition   <: GuidePosition end
type UnderGuidePosition  <: GuidePosition end

const top_guide_position    = TopGuidePosition()
const right_guide_position  = RightGuidePosition()
const bottom_guide_position = BottomGuidePosition()
const left_guide_position   = LeftGuidePosition()
const under_guide_position  = UnderGuidePosition()


type PanelBackground <: Gadfly.GuideElement
end

const background = PanelBackground()


function render(guide::PanelBackground, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    p = stroke(nothing) | fill(theme.panel_background)
    c = canvas() << (rectangle() << p)
    {(c, under_guide_position)}
end


type XTicks <: Gadfly.GuideElement
end

const x_ticks = XTicks()


function render(guide::XTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    ticks = Dict{Float64, String}()
    for aes in aess
        if Gadfly.issomething(aes.xtick) && Gadfly.issomething(aes.xtick_labels)
            for (val, label) in zip(aes.xtick, aes.xtick_labels)
                ticks[val] = label
            end
        end
    end

    form = compose([lines((tick, 0h), (tick, 1h)) for (tick, label) in ticks]...)
    grid_lines = canvas() << (form << stroke(theme.grid_color))

    (_, height) = text_extents(theme.tick_label_font,
                               theme.tick_label_font_size,
                               values(ticks)...)
    padding = 1mm

    tick_labels = compose([text(tick, 1h - padding, label, hcenter, vbottom)
                           for (tick, label) in ticks]...)
    tick_labels <<= stroke(nothing) |
                    fill(theme.tick_label_color) |
                    font(theme.tick_label_font) |
                    fontsize(theme.tick_label_font_size)
    tick_labels = canvas(0, 0, 1w, height + 2padding) << tick_labels

    {(grid_lines, under_guide_position),
     (tick_labels, bottom_guide_position)}
end


type YTicks <: Gadfly.GuideElement
end

const y_ticks = YTicks()

function render(guide::YTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    ticks = Dict{Float64, String}()
    for aes in aess
        if Gadfly.issomething(aes.ytick) && Gadfly.issomething(aes.ytick_labels)
            for (val, label) in zip(aes.ytick, aes.ytick_labels)
                ticks[val] = label
            end
        end
    end

    form = compose([lines((0w, tick), (1w, tick)) for (tick, label) in ticks]...)
    grid_lines = canvas() << (form << stroke(theme.grid_color))

    (width, _) = text_extents(theme.tick_label_font,
                              theme.tick_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding

    tick_labels = compose([text(width - padding, tick, label, hright, vcenter)
                           for (tick, label) in ticks]...)
    tick_labels <<= stroke(nothing) |
                    fill(theme.tick_label_color) |
                    font(theme.tick_label_font) |
                    fontsize(theme.tick_label_font_size)
    tick_labels = canvas(0, 0, width, 1cy) << tick_labels

    {(grid_lines, under_guide_position),
     (tick_labels, left_guide_position)}
end


# X-axis label Guide
type XLabel <: Gadfly.GuideElement
    label::String
end


function render(guide::XLabel, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    (_, text_height) = text_extents(theme.axis_label_font,
                                    theme.axis_label_font_size,
                                    guide.label)

    padding = 2mm
    t = text(0.5w, 1h - padding, guide.label, hcenter, vbottom)
    t <<= stroke(nothing) |
          fill(theme.axis_label_color) |
          font(theme.axis_label_font) |
          fontsize(theme.axis_label_font_size)
    c = canvas(0, 0, 1w, text_height + padding)

    {(c << t, bottom_guide_position)}
end


# Y-axis label Guide
type YLabel <: Gadfly.GuideElement
    label::String
end


function render(guide::YLabel, theme::Gadfly.Theme, aess::Vector{Gadfly.Aesthetics})
    (text_width, text_height) = text_extents(theme.axis_label_font,
                                             theme.axis_label_font_size,
                                             guide.label)
    padding = 2mm
    t = text(0.5w, 0.5h, guide.label, hcenter, vcenter)
    t <<= stroke(nothing) |
          fill(theme.axis_label_color) |
          font(theme.axis_label_font) |
          fontsize(theme.axis_label_font_size)
    c = canvas(0, 0, text_height + 2padding, 1cy,
               Rotation(-0.5pi, 0.5w, 0.5h))

    {(c << t, left_guide_position)}
end


# Arrange a plot with its guides
#
# Args:
#   plot_canvas: A canvas containing the plot graphics.
#   guides: Tuples of guide canvases each with a GuidePosition giving
#           where the guide should be placed relative to the plot.
#
# Returns:
#   A new canvas containing the plot with guides layed out in the specified
#   manner.
function layout_guides(plot_canvas::Canvas,
                       guides::(Canvas, GuidePosition)...)

    # Every guide is updated to use the plot's unit box.
    guides = [(set_unit_box(guide, plot_canvas.unit_box), pos)
              for (guide, pos) in guides]

    # Group by position
    top_guides    = Canvas[]
    right_guides  = Canvas[]
    bottom_guides = Canvas[]
    left_guides   = Canvas[]
    under_guides  = Canvas[]
    for (guide, pos) in guides
        if pos === top_guide_position
            push(top_guides, guide)
        elseif pos === right_guide_position
            push(right_guides, guide)
        elseif pos === bottom_guide_position
            push(bottom_guides, guide)
        elseif pos === left_guide_position
            push(left_guides, guide)
        elseif pos === under_guide_position
            push(under_guides, guide)
        end
    end

    # Stack the guides on edge edge of the plot
    top_guides    = vstack(0, 0, 1, [(g, hcenter) for g in top_guides]...)
    right_guides  = hstack(0, 0, 1, [(g, vcenter) for g in right_guides]...)
    bottom_guides = vstack(0, 0, 1, [(g, hcenter) for g in bottom_guides]...)
    left_guides   = hstack(0, 0, 1, [(g, vcenter) for g in left_guides]...)

    # Reposition each guide stack, now that we know the extents
    t = top_guides.box.height
    r = right_guides.box.width
    b = bottom_guides.box.height
    l = left_guides.box.width
    pw = 1cx - l - r # plot width
    ph = 1cy - t - b # plot height

    top_guides    = set_box(top_guides,    BoundingBox(l, 0, pw, t))
    right_guides  = set_box(right_guides,  BoundingBox(l + pw, t, r, ph))
    bottom_guides = set_box(bottom_guides, BoundingBox(l, t + ph, pw, b))
    left_guides   = set_box(left_guides,   BoundingBox(0, t, l, ph))

    plot_canvas = canvas(l, t, pw, ph) | compose(under_guides...) | plot_canvas
    canvas() | plot_canvas | top_guides | right_guides | bottom_guides | left_guides
end

end # module Guide

