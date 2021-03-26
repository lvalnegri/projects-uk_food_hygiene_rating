###########################################
# SHINY - FOOD HYGIENE RATINGS * global.R #
###########################################

# load packages
pkgs <- c('popiFun',
    'data.table', 'DT', 'fst', 'ggplot2', 'leaflet', 'leaflet.extras', 'kableExtra',
    'shiny', 'shinycssloaders', 'shinyjs', 'shinythemes', 'shinyWidgets'
)
lapply(pkgs, require, char = TRUE)

# load data
data_path <- file.path(datauk_path, 'geodemographics', 'poi', 'food_shops')
app_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'uk_food_shops')
shops <- read_fst(file.path(data_path, 'shops'), as.data.table = TRUE)
lads <- read_fst(file.path(data_path, 'lads'), as.data.table = TRUE)
lcns <- read_fst(file.path(app_path, 'locations'), as.data.table = TRUE)
lcnt <- read_fst(file.path(app_path, 'location_types'), as.data.table = TRUE)
lcnh <- read_fst(file.path(geouk_path, 'hierarchies'), as.data.table = TRUE)
lcnk <- read_fst(file.path(geouk_path, 'lookups'), as.data.table = TRUE)
bnd <- readRDS(file.path(app_path, 'boundaries'))
cols_geo <- names(bnd)
sct <- dbm_do('uk_geodemo_poi', 'r', 'food_shops_sectors')
rtg <- dbm_do('uk_geodemo_poi', 'r', 'food_shops_scores')

# set constants
last_updated <- max(lads$updated_at)

# build lists for users controls

lst.geo <- structure(
        lapply( 
            unique(lcnt$theme), 
            function(x) structure(lcnt[theme == x, location_type], names = lcnt[theme == x, name])
        ), 
        names = toupper(unique(lcnt$theme))
)

y <- lcns[type == 'RGN'][order(name)]
lst.rgn <- as.list(y$location_id)
names(lst.rgn) <- y$name

lst.shw <- c(
    'Ratings' = 'rating', 
    'Score Hygiene' = 'score_H', 
    'Score Structural' = 'score_S', 
    'Score Confidence' = 'score_C', 
    'Group' = 'group'
)

y <- 
lst.rtg <- as.list(y$location_id)
names(lst.rtg) <- y$name

y <- 
lst.sct <- as.list(y$location_id)
names(lst.sct) <- y$name



build_geo_list <- function(child, parent, id){
    yt <- lcns[ location_id %in% 
                    lcnk[ hierarchy_id ==  
                              lcnh[child_type == child & parent_type == parent, hierarchy_id] 
                        & parent_id == id, 
                            child_id 
                    ],
               .(location_id, name)
        ][order(name)]
    y <- as.list(yt$location_id)
    names(y) <- yt$name
    y
}

# functions
navbarPageWithText <- function(..., text) {
    navbar <- navbarPage(...)
    textEl <- tags$p(class = 'navbar-text', text)
    navbar[[3]][[1]]$children[[1]] <- tagAppendChild( navbar[[3]][[1]]$children[[1]], textEl)
    navbar
}

# themes