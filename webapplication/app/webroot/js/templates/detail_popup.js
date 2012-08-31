// This file was automatically generated from detail_popup.soy.
// Please don't edit this file by hand.

if (typeof Edgar == 'undefined') { var Edgar = {}; }
if (typeof Edgar.templates == 'undefined') { Edgar.templates = {}; }


Edgar.templates.detailPopupContent = function(opt_data, opt_sb) {
  var output = opt_sb || new soy.StringBuilder();
  output.append('<dl>', (opt_data.gridBounds) ? '<dt>Latitude Range</dt><dd>' + soy.$$escapeHtml(opt_data.gridBounds.minlat) + '&deg; to ' + soy.$$escapeHtml(opt_data.gridBounds.maxlat) + '&deg;</dd><dt>Longitude Range</dt><dd>' + soy.$$escapeHtml(opt_data.gridBounds.minlon) + '&deg; to ' + soy.$$escapeHtml(opt_data.gridBounds.maxlon) + '&deg;</dd>' : (opt_data.occurrenceCoord) ? '<dt>Latitude</dt><dd>' + soy.$$escapeHtml(opt_data.occurrenceCoord.lat) + '</dd><dt>Longitude</dt><dd>' + soy.$$escapeHtml(opt_data.occurrenceCoord.lon) + '</dd>' : '', '</dl>');
  if (opt_data.classificationTotals) {
    output.append('<div class="table_wrapper"><table class="classifications"><thead><tr><th>Classification</th><th>Observations</th></tr></thead><tbody>');
    var rowList25 = opt_data.classificationTotals;
    var rowListLen25 = rowList25.length;
    for (var rowIndex25 = 0; rowIndex25 < rowListLen25; rowIndex25++) {
      var rowData25 = rowList25[rowIndex25];
      output.append((rowData25.isGrandTotal) ? '<tr class="total">' : '<tr class="count ' + soy.$$escapeHtml(rowData25.total == 0 ? 'none' : 'some') + '">', '<td>', soy.$$escapeHtml(rowData25.label), '</td><td>', soy.$$escapeHtml(rowData25.total == 0 ? '-' : rowData25.total), '</td></tr>', (rowData25.contentious > 0) ? '<tr class="contentious"><td colspan="2">(' + soy.$$escapeHtml(rowData25.contentious) + ' in contention)</td></tr>' : '');
    }
    output.append('</tbody></table></div>');
  }
  return opt_sb ? '' : output.toString();
};
