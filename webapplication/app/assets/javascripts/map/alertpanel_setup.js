$(function() {

    // all we need to do it make the close button hide the alert panel

    var $alertpanel = $('#alertpanel');
    var $hidebutton = $alertpanel.find('.closebutton');

    $hidebutton.click( function() {
        $alertpanel.hide();
    });
});
