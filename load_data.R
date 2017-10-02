# source data main page: http://ratings.food.gov.uk/open-data
# example URL for LAD XXX: http://ratings.food.gov.uk/OpenDataFiles/FHRSXXXen-GB.xml

# load packages
invisible(lapply(c('data.table', 'RMySQL', 'rvest', 'XML'), require, character.only = TRUE))

print('Downloading index file...')
lads <- read_html('http://ratings.food.gov.uk/open-data') %>%
            html_nodes('#openDataStatic a') %>%
            html_attr('href') %>%
            as.data.table() %>%
            setnames('url') %>% 
            subset(!grepl('cy', url)) %>% 
            setorder(url)
lads[, lad_id := gsub('[^0-9]', '', url)]
n_lads <- nrow(lads)

# create dataframe to contain data about shops
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

print(paste('Processing local authorities...'))
for(idx in 1:n_lads){
#    if( lads[idx, lad_id] %in% c('074', '766', '771', '790') ) next
    print(paste('Processing file n.', idx, 'out of', n_lads) )
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

# transform previous result as a dataframe
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

# clean and recode postcodes to 7-chars form (delete all < 6 and > 8)
convert_postcode <- Vectorize(function(pc){
    if(is.na(pc)) return(NA)
    if(nchar(pc) < 6 | nchar(pc) > 8) return(NA)
    pc <- sub(' ', '', pc)
    pc_in <- substr(pc, nchar(pc) - 2, nchar(pc))
    pc_out <- substr(pc, 1, nchar(pc) - 3)
    pc_out <- paste0(pc_out, '  ')
    pc_out <- substr(pc_out, 1, 4)
    paste0(pc_out, pc_in)
})
shops[, postcode := convert_postcode(postcode)]

# recode character ratings to numeric
shops[, rating := tolower(gsub(' ', '', rating))]
shops[rating == 'awaitinginspection', rating := '7']
shops[rating == 'awaitingpublication', rating := '8']
shops[rating == 'exempt', rating := '9']
shops[rating == 'passandeatsafe', rating := '13']
shops[rating == 'pass', rating := '12']
shops[rating == 'improvementrequired', rating := '11']

# delete invalid date
shops[updated_at == 'true', updated_at := NA]
# delete dash in date to render it numeric yyyymmdd
shops[, updated_at := gsub('-', '', updated_at)]

# convert to numeric
cols <- names(shops)
cols <- cols[!( cols %in% c('shop_ladid', 'name', 'sector', 'postcode'))]
shops[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]

# prepare table for sectors
setkey(shops, sector_id)
t <- shops[, .N, .(sector_id, name = sector, rating)][order(sector_id, rating)]
st <- dcast.data.table(t, sector_id + name ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
st <- st[shops[, .(tot_shops = .N), sector_id]]

# prepare table for lads
setkey(shops, lad_id)
t <- shops[, .N, .(lad_id, rating)][order(lad_id, rating)]
ld <- dcast.data.table(t, lad_id ~ paste0('R', ifelse(rating < 10, '0', ''), rating), fill = 0)
lads <- 

# open connection to database
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'uk_food_hygiene_ratings')

# save sectors to database
dbSendQuery(dbc, "TRUNCATE TABLE sectors")
dbWriteTable(dbc, 'sectors', st, row.names = FALSE, append = TRUE)
# save sectors to csv file
write.csv(st, 'sectors.csv', row.names = FALSE)

# save lads to database
dbSendQuery(dbc, "TRUNCATE TABLE lads")
dbWriteTable(dbc, 'lads', ld, row.names = FALSE, append = TRUE)
# save lads to csv file
write.csv(ld, 'lads.csv', row.names = FALSE)

# save shops to database
shops[, sector := NULL]
dbSendQuery(dbc, "TRUNCATE TABLE shops")
dbWriteTable(dbc, 'shops', shops, row.names = FALSE, append = TRUE)

# close connection
dbDisconnect(dbc)

# Clean & Exit
rm(list = ls())
gc()

