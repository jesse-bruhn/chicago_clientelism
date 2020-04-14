# DOCUMENTATION -----------------------------------------------------------
#
#   Author:     Jesse Bruhn
#   Contact:    jbruhn@princeton.edu
#
# PREAMBLE ----------------------------------------------------------------

#print date
Sys.Date()

#Clear workspace
rm(list=ls())

#Load Packages
pckgs <- c("tidyverse", "sf", "data.table", "lubridate")
lapply(pckgs, library, character.only=TRUE)

#Set Options
options(scipen=100)

#Clean Workspace
rm(pckgs)

#Session Info for Reproducibility
sessionInfo()

# NOTES -------------------------------------------------------------------

#This code takes the incident level crime data which I downloaded from the 
#Chicago open data portal and creates a data set at the block-month-crime
#level.

# LOAD DEPENDENCIES -------------------------------------------------------

#Load Crime Data
#NOTE: I need to use data table because the file is lare. 
df <- fread("data/raw/Crimes_2001_to_present.csv")

#load chicago block geometry
load("data/clean/blocksMap.rda")

# CLEAN DATA --------------------------------------------------------------

#Clean Column Names
colnames(df) <- c("id", "case_num", "date_time", "block", "iucr", "type", "description", "location", 
                  "arrest", "domestic", "beat", "district", "ward", "community_area", "fbi_code", 
                  "x_coord", "y_coord", "year", "date_updated", "latitude", "longitude", "coordinates")

#drop observations with missing lat and lon.  
#NOTE: There are 83309 observations missing latitude and longitude.  
#      There are no observations missing only one or the other.  
#      The total number of obs are 6426392 so this represents ~ 1.3 percent 
#      of the sample.
df <- df[!is.na(df$latitude) | !is.na(df$longitude), ] 

#Convert crimes into geospatial dataframe
df <- as_tibble(df)
df <- st_as_sf(df, coords = c("longitude", "latitude"), 
               crs = st_crs(blocks.shp) , agr = "constant")

#determine block of each crime 
#NOTE: This takes a while. 
block.assignments <- st_intersects(df, blocks.shp)

#There are 14324 crimes which do not intersect with the shapefile.  
#I set them to missing here. 
intZero <- function(x){
  ifelse(is.integer(x) && length(x) == 0, NA, x)
}
block.assignments <- unlist(lapply(block.assignments, intZero))

#Replace match positions with block.id
block.assignments <- ifelse(!is.na(block.assignments), blocks.shp$block.id[block.assignments], NA)

#merge blocks back into the data frame
df <- df %>%
  mutate(block.id = block.assignments)

#Drop crimes which do not intersect with blocks.shp 
#NOTE: There are about 14324 of these 
#      which is very small relative to the sample
df <- df %>%
  filter(!is.na(block.id))

#clean date and time data 
#NOTE: Ultimately I want to aggregate by year-month.  Setting the date of each crime
#      to be the first of each month in which the crime occurred is an easy way to 
#      accomplish this while still keeping date as a "date" class variable which 
#      will make plotting easy.  
df <- df %>%
  mutate(date_time = mdy_hms(date_time), 
         date = date(date_time))
day(df$date) <- 01

#Remove geographic information from data frame
st_geometry(df) <- NULL

#find blocks that never report a crime so i can include them in final data set
crimeless.blocks <- setdiff(unique(blocks.shp$block.id), unique(df$block.id))
crimeless.blocks <- tibble(block.id = crimeless.blocks, 
                           type = rep(df$type[1], length.out=length(crimeless.blocks)),
                           date = rep(ydm(20010101), length.out=length(crimeless.blocks)), 
                           n = rep(0, length.out=length(crimeless.blocks)))

#Aggregate data by block-date-type.
df <- df %>% 
  group_by(block.id, date, type) %>%
  count() %>%
  ungroup() 

#Add in crimeless blocks and add in implicit zeros
df <- df %>%
  rbind(crimeless.blocks) %>%
  complete(block.id, date, type, fill = list(n=0))

# OUTPUT TARGETS ----------------------------------------------------------

#rename file
crime <- df

#Save Cleaned  Crime Data  
save(crime, file="data/clean/crime.rda")


