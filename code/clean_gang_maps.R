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

#load packages
pckgs <- c("tidyverse", "sf")
lapply(pckgs, library, character.only=TRUE)

#Set Options
options(scipen=100)

#Clean Workspace
rm(pckgs)

#Session Info for Reproducibility
sessionInfo()

# NOTES -------------------------------------------------------------------

#Chicago PD informed me there was no change between 2012 and 2013, hence
#the did not provide me with a 2013 map. I reflect this in the data
#by replicating the 2012 map in 2013


# CREATE USEFUL FUNCTIONS -------------------------------------------------

#function to load gang maps
gangReader <- function(file, yr, dt=NULL){
  
  dat <- read_sf(file)
  
  dat <- dat %>%
    mutate(year = yr) %>%
    select(year, 
           contains("gang"), 
           contains("area"),
           contains("len")
    )
  
  names(dat)[1:4] <- c("year", "gang", "area", "length")
  
  if(yr!=2017){
    dat <- rbind(dat, dt)
  }
  
  return(dat)
}

# LOAD DEPENDENCIES -------------------------------------------------------

#load gang maps
gang.maps <- gangReader("data/raw/gang_maps/gangs2017.shp", 2017) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2016.shp", 2016, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2015.shp", 2015, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2014.shp", 2014, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2012.shp", 2012, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2011.shp", 2011, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2010.shp", 2010, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gangs2009.shp", 2009, gang.maps) 
gang.maps <- gangReader("data/raw/gang_maps/gang2008.shp", 2008, gang.maps)
gang.maps <- gangReader("data/raw/gang_maps/gangs2007.shp", 2007, gang.maps)
gang.maps <- gangReader("data/raw/gang_maps/gangs2006.shp", 2006, gang.maps)
gang.maps <- gangReader("data/raw/gang_maps/gangs2005.shp", 2005, gang.maps)
gang.maps <- gangReader("data/raw/gang_maps/gangs2004.shp", 2004, gang.maps)

#Load blocks map
load("data/clean/blocksMap.rda")

# CLEAN DATA --------------------------------------------------------------

#fix projection
gang.maps <- st_transform(gang.maps, crs=st_crs(blocks.shp)) 

#Make gang names look nice
stringFixer <- function(x){
  return(tolower(trimws(x)))
}

gang.maps <- gang.maps %>%
  mutate(gang = stringFixer(gang))

#Fix name inconsistencies. 
#NOTE: I assume all gangs that appear in the same year are distinct organizations.  
#      Otherwise, I use my judgement to adjucate year-by-year inconsistencies in 
#      name spellings of gangs
gang.maps <- gang.maps %>% 
  mutate(gang = if_else(gang=="ylo cobras", "young latin organization cobras", gang), 
         gang = if_else(gang=="ylo disciples", "young latin organization disciples", gang),
         gang = if_else(gang=="young latin organization disciple", "young latin organization disciples", gang),
         gang = if_else(gang=="two six", "two-six", gang), 
         gang = if_else(gang=="krazy get down boys", "krazy getdown boys", gang),
         gang = if_else(gang=="black p stone", "black p stones", gang),
         gang = if_else(gang=="12th st players", "12th street players", gang))

#drop area and length variables
#NOTE: I think they are wrong, so I'm going to calculate them manually later
#      if it turns out I need them. 
gang.maps <- gang.maps %>%
  select(-area, -length)

#Take gangs with territory name "NA" missing out of the dataset.  
# NOTE: At some point I need to see if I can infer which gangs this 
#       missing territory belongs to based on prior year boundaries. 
#       However, this only occurs twice in the data so I am not too 
#       concerned about it. 
missing.name.territory <- gang.maps %>% filter(is.na(gang))
gang.maps <- gang.maps %>% filter(!is.na(gang))

#NOTE: There are a number of observations listed as things like "mix unknown 
#      and traveling vice lords. I take this to mean both gangs occupy the area 
#      and add the territory to both gangs polygons.

#Create function to fix territorial boundary problems
boundaryFixer <- function(dt, problem.name, seperate.names){
  problem.years <- dt %>%
    filter(gang==problem.name) %>%
    .$year
  
  for (p.year in problem.years){
    print(p.year)
    for (s.name in seperate.names){
      print(s.name)
      joint.territory <- dt %>%
        filter(year==p.year & gang==problem.name) 
      
      individual.territory <- dt %>%
        filter(year==p.year & gang==s.name) 
      
      total.territory <- st_union(st_buffer(rbind(joint.territory, individual.territory)$geometry, 0)) %>%
        st_sf() %>%
        mutate(year = p.year, 
               gang = s.name) %>%
        select(year, gang, geometry)
      
      dt <- dt %>%
        filter(!(gang==s.name & year==p.year)) %>%
        rbind(total.territory)
    }
  }
  return(dt %>% filter(gang != problem.name)) 
}


#fix "black p stone & mickey cobras"
problem.name <- "black p stone & mickey cobras"
seperate.names <- c("black p stones", "mickey cobras")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "mickey cobras & cvl & black p stone"
problem.name <- "mickey cobras & cvl & black p stone"
seperate.names <- c("black p stones", "mickey cobras", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "black p stones mickey cobras cvl"
problem.name <- "black p stones mickey cobras cvl"
seperate.names <- c("black p stones", "mickey cobras", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "mix unknown & traveling vice lords"
problem.name <- "mix unknown & traveling vice lords"
seperate.names <- c("unknown vice lords", "traveling vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "4ch bps cvl"
problem.name <- "4ch bps cvl"
seperate.names <- c("four corner hustlers", "black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "four corner hustlers & black p stones"
problem.name <- "four corner hustlers & black p stones"
seperate.names <- c("four corner hustlers", "black p stones")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "gangster disciples & black disciples"
problem.name <- "gangster disciples & black disciples"
seperate.names <- c("gangster disciples", "black disciples")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bd gd imperial vice lords"
#NOTE: Not sure the fix here is correct.  There is no "Imperial Vicelords" gang in my data, but 
#      there is an "Imperial Insane Vicelords".  Chicagogangs.org has both gangs listed, but the 
#      "Imperial Vicelords" are listed as "coming soon".  I attribute this territory to imperial
#       insane vicelords, but I may need to revise this in the future.
problem.name <- "bd gd imperial vice lords"
seperate.names <- c("gangster disciples", "black disciples", "imperial insane vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bd bps cvl"
problem.name <- "bd bps cvl"
seperate.names <- c("black disciples", "black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bps cvl"
problem.name <- "bps cvl"
seperate.names <- c("black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#Add in 2013 gang map
#NOTE: Chicago PD informed me there was no change between 2012 and 2013, hence
#       the did not provide me with a 2013 map. I reflect this information here
#       by replicating the 2012 map in 2013
gang.maps <- gang.maps %>%
  filter(year==2012) %>%
  mutate(year=2013) %>%
  rbind(gang.maps) %>%
  arrange(gang, year) %>%
  as_tibble() %>%
  st_sf()

# OUTPUT TARGETS ----------------------------------------------------------

#save gang maps
save(gang.maps, file="data/clean/gangMaps.rda")

