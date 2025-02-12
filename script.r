##Libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               janitor,
               here, 
               stars,
               sf,
               rvest)

pacman::p_load_gh("giocomai/latlon2map")


##Download the geometries of NUTS3 regions. Filer non-EU countries

#Array with EU countries 2 letters codes
eu_countries <- c("AT", "BE", "BG", "CY", "CZ", "DE", 
                  "DK", "EE", "EL", "ES", "FI", "FR",
                  "HR", "HU", "IE", "IT", "LT", "LU", 
                  "LV", "MT", "NL", "PL", "PT", "RO",
                  "SE", "SI", "SK")


#Download NUTS-3 geometries and filter the unwanted ones
nuts_3 <- latlon2map::ll_get_nuts_eu(level = 3, resolution = 1) %>% 
  sf::st_transform(3035) %>% 
  janitor::clean_names() %>% 
  dplyr::select(cntr_code, nuts_id, name_latn) %>% 
  dplyr::filter(cntr_code %in% eu_countries) %>% 
  dplyr::filter(!nuts_id %in% c("FRY10","FRY20","FRY30","FRY40","FRY50"))#Exclude overseas territories as there is no data for them


#Create 500m buffer for the NUTS-3 geometries and write a new file with the buffered ones
buffered_nuts_3 <- sf::st_sf(nuts_id = character(),
                             geometry = sf::st_sfc(crs = 3035))

nuts_ids <- nuts_3$nuts_id

for (i in nuts_ids) {
  
  nuts_i <- nuts_3 %>% 
    dplyr::filter(nuts_id == i) 
  
  nuts_i_diff <- nuts_3 %>% 
    dplyr::filter(nuts_id != i) %>% 
    sf::st_union()
  
  #Create a buffer of 500 meters around the NUTS boundaries
  nuts_i_buffered <- sf::st_buffer(nuts_i, dist = 500)
  
  #Subtract other regions from the buffered region
  nuts_i_buffered_clean <- sf::st_difference(nuts_i_buffered, nuts_i_diff)
  
  #Bind
  buffered_nuts_3 <- buffered_nuts_3 %>% 
    rbind(nuts_i_buffered_clean) 
  
}


##Extract the names of the files to download and analyse
url <- "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/EIGL-Data/RASTER/"


files <- rvest::read_html(url) %>%
  rvest::html_nodes('table') %>% 
  rvest::html_nodes("a") %>%
  rvest::html_attr("href") %>%
  grep("\\.tif$", ., value = TRUE) 


##Create folder for writing outputs
dir.create(here::here("outputs"))


##Loop to download, read, analyse, and write analysis outputs of all the datasets
for (j in files) {
  
  #Download the file and read it
  download.file(url = paste0(url, j),
                destfile = paste0("/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/stars/tif/", j))
  
  df_path <- system.file(paste0("tif/", j), package = "stars")
  
  df <- stars::read_stars(df_path) 
  
  #create an empty dataframe to bind the results of the analysis to
  data_nuts3 <- data.frame(nuts_id = character(),
                           sum = double(),
                           top_1_pc_tot = double(),
                           top_1_pc_share = double())
  
  
  #For every nuts3 region crop the raw data file and: (i) sum the values; (ii) calculate how much energy is demanded by the top 1% of the cells
  for (k in nuts_ids) {
    
    #Filter the boundaries of the region
    geo <- buffered_nuts_3 %>% 
      dplyr::filter(nuts_id == k) 
    
    #Crop the raster
    region_cropped <- sf::st_crop(df, geo)
    
    #Sum values of cells
    region_sum <- sum(sapply(region_cropped, sum, na.rm = TRUE)) 
  
    #Create df with the nuts_id of the region and the sum of the cells values
    data_k_tot <- data.frame(nuts_id = k,
                             sum = region_sum) 

    #Transform the cropped raster in a sf 
    reg_sf <- sf::st_as_sf(region_cropped, 
                           as_points = FALSE,
                           merge = FALSE,
                           na.rm = TRUE,
                           use_integer = is.logical(x[[1]]) || is.integer(x[[1]]),
                           long = FALSE,
                           connect8 = FALSE) %>%
      sf::st_set_geometry(NULL)  
    
    #Sort and select the top 1% of values
    n <- round(nrow(reg_sf) * 0.01, 0)
  
    top_1_percent <- reg_sf[order(reg_sf[[j]], decreasing = TRUE)[1:n],] %>% sum()
    
    #Calculate the share demanded by the top 1% of cells
    data_k_1_pc <- data.frame(nuts_id = k,
                              top_1_pc_tot = top_1_percent,
                              top_1_pc_share = top_1_percent*100/region_sum)
    
    data_k <- data_k_tot %>% dplyr::left_join(data_k_1_pc, by = "nuts_id")
    
    data_nuts3 <- data_nuts3 %>% rbind(data_k)
    
  }
  
  
  #Rename the columns with values with the name of the actual variables
  names(data_nuts3)[2] <- j %>% stringr::str_remove("_2019.tif")
  names(data_nuts3)[3] <- j %>% stringr::str_replace("_2019.tif", "_top_1_pc_tot")
  names(data_nuts3)[4] <- j %>% stringr::str_replace("_2019.tif", "_top_1_pc_share")
  
  
  #Write the output as csv
  readr::write_csv(data_nuts3, 
                   here::here("outputs", j %>% stringr::str_replace("_2019.tif", ".csv")))
  
  
}

##Create a dataset for all the 8 energy types
energy_types <- c("electricity", "gas", "heat", "nuclear", "oil", "others", "renewables", "solid")


for (l in energy_types) {
  
  ##Read all csv and create a single dataset by joining them
  csvs <- list.files(here::here("outputs"), full.names = T) %>% 
    grep(l, ., value = TRUE) %>% 
    purrr::map(., function(f) readr::read_csv(f)) %>% 
    purrr::reduce(., function(x, y) dplyr::left_join(x, y, by = "nuts_id"))
  
  
  ##join with additional information of the geographic entity and write the output
  data <- nuts_3 %>% 
    sf::st_set_geometry(NULL) %>% 
    dplyr::left_join(csvs) %>% 
    dplyr::arrange(.$nuts_id) %>% 
    readr::write_csv(here::here("outputs", paste0(l, "_data.csv")), na = "")
  
}


#Read csv of renewable energy potential
untapped <- UntappedPotentialRenewableEnergy_20240625 %>% 
  janitor::clean_names() %>% glimpse()

#sum the demand across all the energy types and sectors of activities besides the non energy use ones
energy_demand_twh <- data %>% 
  mutate(tot_toe =electricity_tot_demand+gas_tot_demand+oil_tot_demand+solid_tot_demand+nuclear_tot_demand+others_tot_demand+heat_tot_demand -gas_neu_demand-oil_neu_demand- solid_neu_demand - others_neu_demand - heat_neu_demand) %>% 
  mutate(tot_wh = tot_toe * 11630000) %>% 
  mutate(tot_twh = tot_wh / 10^12) %>% 
  select(nuts_id, tot_twh) 

#sum the current renewable prodiuction and the untapped potential
untapped_tj <- untapped %>% 
  select(nuts3_id, total_untapped_potential_terawatt_hours, total_current_production_terawatt_hours)  %>% 
  mutate(current_plus_unt = total_untapped_potential_terawatt_hours + total_current_production_terawatt_hours) 



possible_renew_share <- energy_demand_twh %>% 
  left_join(untapped_tj, by = c("nuts_id" = "nuts3_id")) %>% 
  mutate(pc_tot_renewable = current_plus_unt*100/tot_twh) %>%  
  left_join(nuts_3) %>% 
  st_set_geometry(.$geometry) 