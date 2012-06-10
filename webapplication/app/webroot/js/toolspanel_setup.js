$(function() {
    var tools = $('#toolspanel .tool');
    tools.each( function(index, tool) {
        tool = $(tool);
        var header = $(tool).children('h1').first();
        var body = tool.children('.toolcontent').first();
        header.disableSelection();
        header.click( function() {
            header.toggleClass('closed');
            body.toggle('blind', 'fast');
            return false;
        });
    });

    $('#emission_scenarios').change(function() {
        Edgar.map.emissionScenario = $(this).val();
        reloadDistributionLayers();
    });

    $('#year_selector').change(function() {
        Edgar.map.year = $(this).val();
        reloadDistributionLayers();
    });

    $('#use_emission_and_year').change(reloadDistributionLayers);

    // year/scenario defaults
    Edgar.map.emissionScenario = $('#emission_scenarios').val();
    Edgar.map.year = parseInt($('#year_selector').val());
    reloadDistributionLayers();
});
