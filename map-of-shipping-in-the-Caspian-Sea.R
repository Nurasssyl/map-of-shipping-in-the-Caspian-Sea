pacman::p_load(
  tidyverse, terra,
  sf, giscoR, ggnewscale
)

rastfile <- "C:/Users/User/Desktop/Диссертация/shipdensity_global.tif"

global_traffic <- terra::rast(rastfile)

xmin <- 46.516
ymin <- 36.483
xmax <- 54.266
ymax <- 47.133


bounding_box <- sf::st_sfc(
  sf::st_polygon(
    list(
      cbind(
        c(xmin, xmax, xmax, xmin, xmin),
        c(ymin, ymin, ymax, ymax, ymin)
      )
    )
  ),
  crs = 4326
)

shipping_traffic <- terra::crop(
  x = global_traffic,
  y = bounding_box,
  snap = "in"
)

terra::plot(shipping_traffic)

shipping_traffic_clean <- terra::ifel(
  shipping_traffic == 0,
  NA,
  shipping_traffic
)

u <- "https://eogdata.mines.edu/nighttime_light/annual/v22/2022/VNL_v22_npp-j01_2022_global_vcmslcfg_c202303062300.average_masked.dat.tif.gz"
filename <- basename(u)

download.file(
  url = u,
  destfile = filename,
  mode = "wb"
)

path_to_nightlight <- list.files(
  path = getwd(),
  pattern = filename,
  full.names = TRUE
)

nightlight <- terra::rast(
  paste0(
    "/vsigzip/",
    path_to_nightlight
  )
)

nightlight_region <- terra::crop(
  x = nightlight,
  y = bounding_box,
  snap = "in"
)

nightlight_resampled <- terra::resample(
  x = nightlight_region,
  y = shipping_traffic_clean,
  method = "bilinear"
)

terra::plot(nightlight_resampled)

nightlight_cols <- c("#061c2c", "#1f4762", "#FFD966", "white")

nightlight_pal <- colorRampPalette(
  nightlight_cols,
  bias = 12
)(256)

shipping_traffic_cols <- hcl.colors(
  n = 5,
  palette = "Blues"
)

scales::show_col(
  shipping_traffic_cols,
  ncol = 5,
  labels = TRUE
)

shipping_traffic_pal <- colorRampPalette(
  shipping_traffic_cols[1:4]
)(256)

nightlight_df <- as.data.frame(
  nightlight_resampled,
  xy = TRUE,
  na.rm = TRUE
)

names(nightlight_df)[3] <- "nightlight_value"

shipping_traffic_df <- as.data.frame(
  shipping_traffic_clean,
  xy = TRUE,
  na.rm = TRUE
)

head(nightlight_df)
head(shipping_traffic_df)

map <- ggplot() +
  geom_raster(
    data = nightlight_df,
    aes(
      x = x,
      y = y,
      fill = nightlight_value
    )
  ) +
  scale_fill_gradientn(
    colors = nightlight_pal
  ) +
  ggnewscale::new_scale_fill() +
  geom_raster(
    data = shipping_traffic_df,
    aes(
      x = x,
      y = y,
      fill = shipdensity_global
    )
  ) +
  scale_fill_gradientn(
    colors = shipping_traffic_pal
  ) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.margin = unit(
      c(
        t = -1, r = -1,
        b = -1, l = -1
      ), "cm"
    )
  )

ggsave(
  filename = "kaz_shipping_traffic.png",
  plot = map,
  width = 7,
  height = 7
)
