# data-raw/create-logo.R
#
# Recreate the ucdpR package logo.
#
# Development-only dependencies:
# install.packages(c("ggplot2", "hexSticker"))
#
# Optional SVG output:
# install.packages("svglite")

library(ggplot2)
library(hexSticker)

dir.create(
  file.path("man", "figures"),
  recursive = TRUE,
  showWarnings = FALSE
)

# -------------------------------------------------------------------------
# Original palette: deliberately distinct from institutional UCDP branding
# -------------------------------------------------------------------------

cream      <- "#F6F0E4"
paper      <- "#FFFDF7"
navy       <- "#17324D"
teal       <- "#2E7774"
gold       <- "#D2A84A"
brick      <- "#A3483C"
slate      <- "#587083"
grid       <- "#C7D1D4"
charcoal   <- "#172027"

# -------------------------------------------------------------------------
# Geometry helpers
# -------------------------------------------------------------------------

sheet_polygon <- function(xmin, xmax, ymin, ymax, offset_x = 0, offset_y = 0) {
  data.frame(
    x = c(xmin, xmax, xmax, xmin) + offset_x,
    y = c(ymin, ymin, ymax, ymax) + offset_y
  )
}

# An intentionally abstract landform. It is original geometric artwork,
# not a tracing of a UCDP map or another organization's logo.
landform <- data.frame(
  x = c(
    0.25, 0.31, 0.38, 0.45, 0.52, 0.59, 0.67, 0.75,
    0.78, 0.72, 0.66, 0.58, 0.54, 0.47, 0.39, 0.32,
    0.27, 0.22
  ),
  y = c(
    0.47, 0.55, 0.57, 0.54, 0.59, 0.56, 0.60, 0.54,
    0.45, 0.39, 0.40, 0.35, 0.29, 0.32, 0.28, 0.34,
    0.39, 0.43
  )
)

event_points <- data.frame(
  x = c(0.34, 0.48, 0.62, 0.70),
  y = c(0.46, 0.48, 0.44, 0.51),
  size = c(3.2, 4.1, 3.5, 3.0),
  colour = c(gold, brick, teal, brick)
)

# -------------------------------------------------------------------------
# Central illustration: stacked releases + map + event observations
# -------------------------------------------------------------------------

atlas_art <- ggplot() +
  # Historical release layers
  geom_polygon(
    data = sheet_polygon(0.18, 0.86, 0.13, 0.71, 0.055, 0.055),
    aes(x = x, y = y),
    fill = gold,
    colour = charcoal,
    linewidth = 1.1
  ) +
  geom_polygon(
    data = sheet_polygon(0.18, 0.86, 0.13, 0.71, -0.035, 0.025),
    aes(x = x, y = y),
    fill = teal,
    colour = charcoal,
    linewidth = 1.1
  ) +

  # Current release sheet
  geom_polygon(
    data = sheet_polygon(0.18, 0.86, 0.13, 0.71),
    aes(x = x, y = y),
    fill = paper,
    colour = charcoal,
    linewidth = 1.35
  ) +

  # Coordinate grid on the current sheet
  annotate(
    "segment",
    x = c(0.32, 0.46, 0.60, 0.74),
    xend = c(0.32, 0.46, 0.60, 0.74),
    y = 0.20,
    yend = 0.63,
    colour = grid,
    linewidth = 0.55
  ) +
  annotate(
    "segment",
    x = 0.23,
    xend = 0.81,
    y = c(0.27, 0.38, 0.49, 0.60),
    yend = c(0.27, 0.38, 0.49, 0.60),
    colour = grid,
    linewidth = 0.55
  ) +

  # Abstract geographic coverage
  geom_polygon(
    data = landform,
    aes(x = x, y = y),
    fill = navy,
    colour = charcoal,
    linewidth = 0.65
  ) +

  # Event observations
  geom_point(
    data = event_points,
    aes(x = x, y = y, size = size, fill = colour),
    shape = 21,
    colour = paper,
    stroke = 1.15,
    show.legend = FALSE
  ) +
  scale_size_identity() +
  scale_fill_identity() +

  # Download arrow: website/catalogue into the versioned research object
  annotate(
    "segment",
    x = 0.52,
    xend = 0.52,
    y = 0.91,
    yend = 0.79,
    colour = navy,
    linewidth = 2.15,
    lineend = "round"
  ) +
  annotate(
    "segment",
    x = 0.42,
    xend = 0.52,
    y = 0.84,
    yend = 0.77,
    colour = navy,
    linewidth = 2.15,
    lineend = "round"
  ) +
  annotate(
    "segment",
    x = 0.62,
    xend = 0.52,
    y = 0.84,
    yend = 0.77,
    colour = navy,
    linewidth = 2.15,
    lineend = "round"
  ) +

  coord_fixed(
    xlim = c(0, 1),
    ylim = c(0, 1),
    expand = FALSE,
    clip = "off"
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "transparent", colour = NA),
    panel.background = element_rect(fill = "transparent", colour = NA),
    plot.margin = margin(0, 0, 0, 0)
  )

# -------------------------------------------------------------------------
# Sticker-rendering function
# -------------------------------------------------------------------------

make_ucdpR_sticker <- function(filename, dpi = 600) {
  hexSticker::sticker(
    subplot = atlas_art,
    package = "ucdpR",

    # Central illustration
    s_x = 1.00,
    s_y = 0.785,
    s_width = 1.14,
    s_height = 0.98,

    # Package name
    p_x = 1.00,
    p_y = 1.50,
    p_color = charcoal,
    p_family = "sans",
    p_fontface = "bold",
    p_size = 5.45,

    # Hexagon
    h_fill = cream,
    h_color = navy,
    h_size = 2.3,

    # Website
    url = "christianoswald.github.io/ucdpR",
    u_color = charcoal,
    u_family = "sans",
    u_size = 0.73,
    u_angle = 30,

    white_around_sticker = FALSE,
    filename = filename,
    dpi = dpi
  )
}

# -------------------------------------------------------------------------
# Render package logo
# -------------------------------------------------------------------------

make_ucdpR_sticker(
  filename = file.path("man", "figures", "logo.png")
)

if (requireNamespace("svglite", quietly = TRUE)) {
  make_ucdpR_sticker(
    filename = file.path("man", "figures", "logo.svg")
  )
}
