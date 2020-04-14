#list of everything this file makes
all: directories \
	clean_data \
	relational_database \
	analysis \
	working_paper \
	slide_deck

#Major sub-components involved in making all
directories: data/tmp \
	data/clean \
	data/relational_database \
	output \
	output/tables \
	output/figures \
	output/numbers \
	log_files

clean_data: data/clean/blocksMap.rda \
	data/clean/communityMap.rda \
	data/clean/gangMaps.rda \
	data/clean/crime.rda

relational_database:
	
analysis:

working_paper:

slide_deck:

#################
# PRELIMINARIES #
#################
data/tmp: 
	mkdir data/tmp

data/clean: 
	mkdir data/clean

data/relational_database: 
	mkdir data/relational_database

output:
	mkdir output

output/tables:
	mkdir output/tables

output/figures:
	mkdir output/figures

output/numbers: 
	mkdir output/numbers

log_files:
	mkdir log_files


#####################
# CLEANING RAW DATA #
#####################

#Chicago GIS data
data/clean/blocksMap.rda data/clean/communityMap.rda: code/clean_gis.R \
	data/raw/Boundaries_Census_Blocks_2000/geo_export_5bde9092-2ed2-4ae9-b06c-e07612db27bf.shp \
	data/raw/Boundaries_Community_Areas_current/geo_export_5e83a6c7-1676-4d4f-920c-4476fe3a058f.shp
	R CMD BATCH code/clean_gis.R
	mv clean_gis.Rout log_files/clean_gis.txt

#Clean Gang Map data
data/clean/gangMaps.rda: code/clean_gang_maps.R \
	data/raw/gang_maps \
	data/clean/blocksMap.rda
	R CMD BATCH code/clean_gang_maps.R
	mv clean_gang_maps.Rout log_files/clean_gang_maps.txt

#Clean crime data
data/clean/crime.rda: code/clean_crime_data.R \
	data/raw/Crimes_2001_to_april_14_2020.csv \
	data/clean/blocksMap.rda
	R CMD BATCH code/clean_crime_data.R
	mv clean_crime_data.Rout log_files/clean_crime_data.txt


##############################
# MAKE A RELATIONAL DATABASE #
##############################

############
# ANALYSIS #
############

#################
# WORKING PAPER #
#################

##############
# SLIDE DECK #
##############



