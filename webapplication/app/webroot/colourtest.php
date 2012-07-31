<html>
<head>

<style>

body { 
    background-image: url(googlephystile.png);
    background-repeat: repeat-y;
    background-attachment: fixed;
}

* { font-size: 1em; font-weight: bold; color: #000; text-align: center; text-shadow: white 0 0 1px; }

table {
    border-collapse: collapse;
    margin: 5em 5em 5em auto;;
    opacity: 0.75;
}

td {
    width: 1em;
    padding: 0.5em;
    height: 5em;
}

td.new:after {
    display: inline-block;
    content: 'new!';
    color: red;
    padding: 0.5em;
    background: yellow;
    border: 4px dotted red;
    -webkit-border-radius: 50%;
    -moz-border-radius: 50%;
    border-radius: 50%;
    -webkit-transform: rotate(-30deg);
    -moz-transform: rotate(-30deg);
    -ms-transform: rotate(-30deg);
}

tr:nth-child(2) td:nth-child(1):before { content: 'least suitable'; }
tr:nth-child(2) td:nth-child(2) { border: 1px solid #ccc; border-right: none; }

td:nth-child(8):before { content: 'most suitable'; }

</style>

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js" type="text/javascript"></script>

<script>

newsets = ['tanyellowdarkgreen', 'yellowpurple'];

sets = { 
	'bluegreen': ['03c',
	              '06a',
	              '088',
	              '0a6',
	              '0c3'],

	'bluedarkgreen': ['01c',
	                  '03a',
	                  '056',
	                  '073',
	                  '090'],

	'bluered': ['00c',
	            '309',
	            '606',
	            '903',
	            'c00'],

	'yellowpurple': ['fc0',
	                 'd94',
	                 'c68',
	                 'b3c',
	                 'a0f'],

	'yellowgreen': ['fc0',
	                'bc0',
	                '8c0',
	                '4c0',
	                '0c0'],

	'tangreen': ['970',
	             '690',
	             '4b0',
	             '2d0',
	             '0f0'],

	'yellowdarkgreen': ['ff0',
	                    '9d0',
	                    '6b0',
	                    '390',
	                    '070'],

	'tanyellowdarkgreen': ['970',
	                       'ba0',
	                       'cc0',
	                       '690',
	                       '070'],

	'tanredderyellowdarkgreen': ['970',
	                             'ba0',
	                             'fc0',
	                             '690',
	                             '070'],

	'redgreen': ['f00',
	             'c30',
	             '960',
	             '690',
	             '3c0'],

	'orangegreen': ['c30',
	                '940',
	                '660',
	                '390',
	                '0c0'],

	'orangedarkgreen': ['c30',
	                    '940',
	                    '650',
	                    '360',
	                    '070']
};

$(function() {
    $.each(sets, function(setname, setcolors) {
        var table = "<table class='" + setname;
	table = table + "'><tr><td colspan='8'";

        if ($.inArray(setname, newsets) > -1) {
            table = table + " class='new'";
        }
        table = table + ">" + setname +
            "</td></tr><tr><td></td><td></td>";
        var css = "";
        
        $.each(setcolors, function(index, color) {
            css = css + "." + setname + " td:nth-child(" 
                + (3 + index) + ") { background-color: #"
                + color + " }\n";
            table = table + "<td></td>";
        });

        $('body').append("<style>" + css + "</style>");
        $('body').append(table + "<td></td></tr></table>\n");
    });
});

</script>
</head>
<body>
<!--
<pre>
<?php

include('/home/daniel/projects/ap03/Edgar/mapping/lib/map_utility_functions.php');

mu_addStyleClasses(null, "0.12");

?>
</pre>
-->
<hr>
colour test

</body>
</html>

