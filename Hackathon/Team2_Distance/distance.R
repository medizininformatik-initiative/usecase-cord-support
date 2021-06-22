require("readr")
require("tidyr")
require("dplyr")
require("geosphere")

# mapping plz to geocoordinates
plz_coord <- read_csv("/Users/martinboeker/Downloads/Uniklinika/PLZ_manual_correction(1).csv")
# input from step 1: individual plz and kh plz
dat_orig <- read_csv("/Users/martinboeker/OneDrive/data/projekte/geokoordinaten/dat.csv")
dat <- dat_orig

plz_coord <- mutate(plz_coord, kh_plz, kh_plz2 = as.numeric(kh_plz))
# left_join for checking input data
dat <- inner_join(dat, plz_coord, by=c("clinic_zip" = "kh_plz2"))
dat <- inner_join(dat, plz_coord, by=c("pat_zip" = "kh_plz2"))

birdflight_distance <- function(v) {
  # unpacking lists (from tibble) to vectors
  source_long <- v[[1]]
  source_lat  <- v[[2]]
  dest_long   <- v[[3]]
  dest_lat    <- v[[4]]
  dist_km     <- distHaversine(p1 = c(source_long, source_lat)
                               ,p2 = c(dest_long, dest_lat))/1000
  return(dist_km)
}

dat2 <- select(dat, kh_plz_lon.x, kh_plz_lat.x, kh_plz_lon.y, kh_plz_lat.y, kh_plz.x, kh_plz.y)
dist <- apply(dat2[1:4],1, birdflight_distance)
dat2 <- cbind(dat2, dist)

# cbind won't work ⇒ join on plz

dat2$kh_plz.x <- as.numeric(dat2$kh_plz.x)
dat2$kh_plz.y <- as.numeric(dat2$kh_plz.y)
dat_orig <- full_join(dat_orig, dat2, by=c("clinic_zip" = "kh_plz.x", "pat_zip" = "kh_plz.y"))
dat_orig

# to do: write file to disk