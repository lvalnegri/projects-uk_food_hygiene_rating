##############################################
# UK FOOD HYGIENE RATING - Download Shops
##############################################
# source data main page: http://ratings.food.gov.uk/open-data
# example URL for LAD XXX: http://ratings.food.gov.uk/OpenDataFiles/FHRSXXXen-GB.xml

# load packages
invisible(lapply(c('data.table', 'RMySQL', 'rvest', 'XML'), require, character.only = TRUE))

# download metadata about Local Authorities, delete Welsh duplicates
lads <- cbind(
        read_html('http://ratings.food.gov.uk/open-data') %>%
            html_nodes('td:nth-child(1) , td:nth-child(2) , td:nth-child(3)') %>% 
            html_text() %>% 
            matrix(byrow = TRUE, ncol = 3),
        read_html('http://ratings.food.gov.uk/open-data') %>%
            html_nodes('#openDataStatic a') %>%
            html_attr('href') %>% 
            matrix()
    ) %>% 
    as.data.table() %>% 
    setnames(c('name', 'updated_at', 'tot_shops', 'url')) %>% 
    subset(!grepl('cy', url)) %>% 
    setorder(url)

# clean and transform
lads[, `:=`(
    name = trimws(name),
    updated_at = as.Date(substr(trimws(updated_at), 1, 10), '%d/%m/%Y'),
    tot_shops = as.numeric(gsub('[^0-9]', '', tot_shops)),
    lad_id = gsub('[^0-9]', '', url)
)]

# create empty structure to contain data about shops
shops <- data.table(
            lad_id = character(0),
            shop_id = character(0), 
            shop_ladid = character(0), 
            name = character(0), 
            sector = character(0), 
            sector_id = character(0), 
            postcode = character(0), 
            rating = character(0), 
            updated_at = character(0), 
            score_H = character(0), 
            score_S = character(0), 
            score_C = character(0), 
            x_lon = numeric(0), 
            y_lat = numeric(0)
)

# download shops data, keeping only the required fields
print(paste('Processing local authorities...'))
for(idx in 1:nrow(lads)){
    print(paste('Processing file n.', idx, 'out of', nrow(lads)) )
    print('Downloading...')
    xmlfile <- xmlToList(xmlTreeParse(lads[idx, url]))[[2]]
    if(!is.null(dim(xmlfile))){
        print(paste('uh-oh... XML file for lad', lads[idx, lad_id], 'has an error... :`-('))
        next
    }
    print(paste('Adding', length(xmlfile), 'records...'))
    shops <- rbindlist(list(
                        shops,
                        as.data.table(cbind(
                            lapply(xmlfile, '[[', 'LocalAuthorityCode'), 
                            lapply(xmlfile, '[[', 'FHRSID'), 
                            lapply(xmlfile, '[[', 'LocalAuthorityBusinessID'), 
                            lapply(xmlfile, '[[', 'BusinessName'),
                            lapply(xmlfile, '[[', 'BusinessType'), 
                            lapply(xmlfile, '[[', 'BusinessTypeID'),
                            lapply(xmlfile, '[[', 'PostCode'),
                            lapply(xmlfile, '[[', 'RatingValue'),
                            lapply(xmlfile, '[[', 'RatingDate'),
                            lapply(lapply(xmlfile, '[[', 'Scores'), '[[', 'Hygiene'),
                            lapply(lapply(xmlfile, '[[', 'Scores'), '[[', 'Structural'),
                            lapply(lapply(xmlfile, '[[', 'Scores'), '[[', 'ConfidenceInManagement'),
                            lapply(lapply(xmlfile, '[[', 'Geocode'), '[[', 'Longitude'),
                            lapply(lapply(xmlfile, '[[', 'Geocode'), '[[', 'Latitude')
                        ), row.names = FALSE)
    ))
    print(paste('DONE! Total count of records so far:', dim(shops)[1]))
}

# transform previous result as a data.table
shops <- data.table(cbind.data.frame(
            lapply(shops, 
                   function(x) 
                        unlist(lapply(x, 
                                      function(y) 
                                          ifelse(is.null(unlist(y)), NA, y) 
                        )) 
            ), 
            stringsAsFactors = FALSE 
         ))

# clean and recode postcodes to 7-chars form
shops[nchar(postcode) == 8, postcode := gsub(' ', '', postcode)]
shops[!grepl("[[:digit:]][[:alpha:]][[:alpha:]]$", postcode), postcode := NA]
shops[nchar(postcode) == 6, postcode := paste(substr(postcode, 1, 3), substring(postcode, 4))]
shops[nchar(postcode) < 7, postcode := NA]

# recode character ratings to numeric
shops[, rating := tolower(gsub(' ', '', rating))]
shops[rating == 'awaitinginspection', rating := '7']
shops[rating == 'awaitingpublication', rating := '8']
shops[rating == 'exempt', rating := '9']
shops[rating == 'passandeatsafe', rating := '13']
shops[rating == 'pass', rating := '12']
shops[rating == 'improvementrequired', rating := '11']

# delete invalid date, then convert to numeric yyyymmdd
shops[updated_at == 'true', updated_at := NA]
shops[, updated_at := gsub('-', '', updated_at)]

shops[, rating := as.numeric(rating)]


# open connection to database
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

# prepare table for sectors
setkey(shops, sector_id)
dts <- shops[, .N, .(sector_id, name = sector, rating = rating)][order(sector_id, rating)]
dts <- dcast.data.table(dts, sector_id + name ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
dts <- dts[shops[, .(tot_shops = .N), sector_id]]

# save sectors to database and csv file for github
dbSendQuery(dbc, "TRUNCATE TABLE sectors")
dbWriteTable(dbc, 'sectors', dts, row.names = FALSE, append = TRUE)
write.csv(dts, 'csv/sectors.csv', row.names = FALSE)

# prepare ratings for lads
lads[, url := NULL]
setkey(shops, lad_id)
dts <- shops[, .N, .(lad_id, rating)][order(lad_id, rating)]
dts <- dcast.data.table(dts, lad_id ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
lads <- dts[lads, on = 'lad_id']

# save lads to database and csv file for github
dbSendQuery(dbc, "TRUNCATE TABLE lads")
dbWriteTable(dbc, 'lads', lads, row.names = FALSE, append = TRUE)
write.csv(lads, 'csv/LADs.csv', row.names = FALSE)

# add OA id to shops
dbcp = dbConnect(MySQL(), group = 'dataOps', dbname = 'geography_uk')
pc <- data.table(dbGetQuery(dbcp, "SELECT postcode, OA FROM postcodes"))
dbDisconnect(dbcp)
shops <- pc[shops, on = 'postcode']

# save shops to database
shops[, sector := NULL]
dbSendQuery(dbc, "TRUNCATE TABLE shops")
dbWriteTable(dbc, 'shops', shops, row.names = FALSE, append = TRUE)

# close connection to database
dbDisconnect(dbc)

# Cut shops dataset, recode resulting subset, and save it as 'fst' for quick reading in Shiny apps


# convert to numeric
cols <- names(shops)
cols <- cols[!( cols %in% c('shop_ladid', 'name', 'sector', 'postcode'))]
shops[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]




# Clean & Exit
rm(list = ls())
gc()
    
