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
pckgs <- c("tidyverse", "sf")
lapply(pckgs, library, character.only=TRUE)

#Set Options
options(scipen=100)

#Clean Workspace
rm(pckgs)

#Session Info for Reproducibility
sessionInfo()

# NOTES -------------------------------------------------------------------

# The shape files come from the city of chicago data portal.  The 
# block shape file is from the year 2000, while the Community area
# shape file is from the year 2010; however, community area boundaries
# have been static sice their creation, so this is not a problem.

# LOAD DEPENDENCIES -------------------------------------------------------

#load shapefiles. NOTE:  
blocks.shp <- read_sf("data/raw/Boundaries_Census_Blocks_2000/geo_export_5bde9092-2ed2-4ae9-b06c-e07612db27bf.shp")
community.shp <- read_sf("data/raw/Boundaries_Community_Areas_current/geo_export_5e83a6c7-1676-4d4f-920c-4476fe3a058f.shp")

# CLEAN DATA --------------------------------------------------------------

#NOTE: One census block is repeated twice in the blocks shapefile. 
#      The group_by / summarise commands here effectively merge 
#      these two geometries. 

#Clean names of block variables
blocks.shp <- blocks.shp %>% 
  rename(block.id = census_b_1, 
         tract = census_tra,
         community.area = block_comm) %>%
  select(block.id, 
         tract, 
         community.area) %>% 
  group_by(block.id, 
           tract, 
           community.area) %>% 
  summarise() %>%
  ungroup()

#Clean names of community area variables
community.shp <- community.shp %>%
  rename(community.area = area_numbe, 
         community.name = community) %>%
  select(community.area, 
         community.name) %>%
  ungroup()


# OUTPUT TARGETS ----------------------------------------------------------

#save shapefiles
save(blocks.shp, file="data/clean/blocksMap.rda")
save(community.shp, file="data/clean/communityMap.rda")










