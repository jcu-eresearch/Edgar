class DetailPopup

    constructor: (@feature, @onClose) ->
        self = this

        console.log(@feature.attributes)

        @popup = new OpenLayers.Popup.FramedCloud(
            "featurePopup",
            @feature.geometry.getBounds().getCenterLonLat(),
            new OpenLayers.Size(100,100),
            Edgar.templates.detailPopupContent(@feature.attributes),
            null,
            true,
            ()-> self.endPopup())

        @feature.layer.map.addPopup(@popup)
        @feature.layer.events.register('featureunselected', this, @endPopup)
        @feature.layer.map.events.register('zoomend', this, @endPopup)


    endPopup: () ->
        @feature.layer.map.events.unregister('zoomend', this, @endPopup)
        @feature.layer.events.unregister('featureunselected', this, @endPopup)

        @feature.layer.map.removePopup(@popup)
        @popup.destroy()
        @onClose()


window.Edgar = window.Edgar || {}
window.Edgar.DetailPopup = DetailPopup
