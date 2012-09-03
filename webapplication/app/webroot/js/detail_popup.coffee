tabIdCounter = 1
DETAIL_PAGE_SIZE = 5

class DetailPopup

    constructor: (@feature, @onClose) ->
        @detailsPageIdx = null
        @hasClosed = false

        self = this
        @popup = new OpenLayers.Popup.Anchored(
            'featurePopup',
            @feature.geometry.getBounds().getCenterLonLat(),
            new OpenLayers.Size(400,247), # golden ratio
            Edgar.templates.mapPopup(@feature.attributes),
            null,
            false,
            ()-> self.endPopup())

        @feature.layer.map.addPopup(@popup)

        @initPopupContent()

        @feature.layer.events.register('featureunselected', this, @endPopup)
        @feature.layer.map.events.register('zoomend', this, @endPopup)


    endPopup: () ->
        return if @hasClosed

        @hasClosed = true
        @feature.layer.map.events.unregister('zoomend', this, @endPopup)
        @feature.layer.events.unregister('featureunselected', this, @endPopup)

        @feature.layer.map.removePopup(@popup)
        @popup.destroy()
        @onClose()


    initPopupContent: () ->
        $tabsElem = $(@popup.contentDiv).find('.map-popup-tabs')
        self = this

        # openlayers close box was causing layout issues, so just did one myself
        $tabsElem.find('.close-button').click( () -> self.endPopup() )

        # jquery ui tabs require ids, but ids have to be unique, so we generate
        # all the ids with tabPrefix out the front to ensure they are unique
        tabPrefix = "popup#{tabIdCounter++}"
        $tabsElem.find('ul.tab-strip > li > a').each( (idx, elem) ->
            $(elem).attr('href', "\##{tabPrefix}-tab#{idx+1}")
        )
        $tabsElem.children('.tab-panel').each( (idx, elem) ->
            $(elem).attr('id', "#{tabPrefix}-tab#{idx+1}")
        )
        $tabsElem.tabs({
            select: (event, ui) -> self.onTabSelected(ui)
        })


    onTabSelected: (ui) ->
        if $(ui.panel).hasClass('details-panel') and not @detailsPageIdx?
            @loadDetails(0)


    loadDetails: (pageIdx) ->
        if @hasClosed
            return

        if pageIdx < 0
            return

        #TODO: detect pageIdx >= numPages

        @detailsPageIdx = pageIdx

        $detailsPanel = $(@popup.contentDiv).find('.details-panel')
        $detailsPanel.html(Edgar.templates.mapPopupLoading({baseUrl:Edgar.baseUrl}))

        bbox = @feature.data.gridBounds
        self = this
        $.ajax({
            url: "#{Edgar.baseUrl}species/geo_json_occurrences/#{Edgar.mapdata.species.id}.json",
            dataType: 'json',
            data: {
                bound: true,
                clustered: 'none',
                limit: DETAIL_PAGE_SIZE,
                offset: DETAIL_PAGE_SIZE*self.detailsPageIdx,
                bbox: "#{bbox.minlon},#{bbox.minlat},#{bbox.maxlon},#{bbox.maxlat}"
            }
            success: ((data, status, xhr) -> self.showDetails(data)),
            error: (data, status, xhr) ->
                console.log('Failed to fetch occurrence details (data/status/xhr):')
                console.log(data)
                console.log(status)
                console.log(xhr)
                # just retry after waiting a bit
                setTimeout((() -> self.loadDetails(self.detailsPageIdx)), 2000)
        })


    showDetails: (details) ->
        if @hasClosed
            return

        details.pageIdx = @detailsPageIdx
        details.pageSize = DETAIL_PAGE_SIZE
        details.totalOccurrences = @totalOccurrencesInFeature()
        console.log(details)
        html = Edgar.templates.mapPopupDetailsPanel(details)

        $detailsPanel = $(@popup.contentDiv).find('.details-panel')
        $detailsPanel.html(html)
        @initDetailPanel($detailsPanel)


    initDetailPanel: ($detailsPanel) ->
        self = this
        $detailsPanel.find('.next-page').click(() ->
            self.loadDetails(self.detailsPageIdx + 1)
        )
        $detailsPanel.find('.prev-page').click(() ->
            self.loadDetails(self.detailsPageIdx - 1)
        )

    totalOccurrencesInFeature: () ->
        total = 0
        for row in @feature.data.classificationTotals
            if not row.isGrandTotal
                total += row.total

        return total



window.Edgar = window.Edgar || {}
window.Edgar.DetailPopup = DetailPopup
