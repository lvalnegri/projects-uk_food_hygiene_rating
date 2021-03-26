#################################################################
# SHINY - FOOD HYGIENE RATINGS * DOTSMAP - server.R (srv_dmp.R) #
#################################################################

onclick('tgl_dmp_geo', toggle(id = 'hdn_dmp_geo', anim = TRUE) )
onclick('tgl_dmp_vls', toggle(id = 'hdn_dmp_vls', anim = TRUE) )
onclick('tgl_dmp_flt', toggle(id = 'hdn_dmp_flt', anim = TRUE) )
onclick('tgl_dmp_opt', toggle(id = 'hdn_dmp_opt', anim = TRUE) )
onclick('tgl_dmp_dwn', toggle(id = 'hdn_dmp_dwn', anim = TRUE) )

output$ui_dmp_geo_lad <- renderUI({
    pickerInput('cbo_dmp_geo_lad', 'LOCAL AUTHORITY:', choices = build_geo_list('LAD', 'RGN', input$cbo_dmp_geo_rgn))
})

output$ui_dmp_vls_rtg <- renderUI({
    pickerInput('cbo_dmp_geo_lad', 'LOCAL AUTHORITY:', choices = build_geo_list('LAD', 'RGN', input$cbo_dmp_geo_rgn))
})

output$out_dmp <- renderLeaflet({
    if(is.null(input$cbo_dmp_geo_lad)) return(NULL)
    yc <- shops[!is.na(x_lon) & LAD == input$cbo_dmp_geo_lad]
    leaflet(options = leafletOptions(minZoom = 8)) %>% 
        addProviderTiles(providers$Wikimedia) %>% 
        addResetMapButton() %>% 
        addCircleMarkers(
            data = yc,
            lng = ~x_lon, lat = ~y_lat,
            radius = 5,
            fill = TRUE,
            fillColor = 'red',
            fillOpacity = 0.7,
            stroke = TRUE,
            weight  =1,
            color = 'black',
            opacity = 1,
            label = ~name
        )

})
