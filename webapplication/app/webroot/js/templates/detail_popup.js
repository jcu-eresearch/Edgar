// This file was automatically generated from detail_popup.soy.
// Please don't edit this file by hand.

if (typeof Edgar == 'undefined') { var Edgar = {}; }
if (typeof Edgar.templates == 'undefined') { Edgar.templates = {}; }


Edgar.templates.mapPopup = function(opt_data, opt_sb) {
  var output = opt_sb || new soy.StringBuilder();
  output.append('<div class="map-popup-tabs"><div class="close-button"></div><ul class="tab-strip"><li><a>summary</a></li><li><a>detail</a></li></ul><div class="tab-panel summary-panel"><dl>', (opt_data.gridBounds) ? '<dt>Latitude Range</dt><dd>' + soy.$$escapeHtml(opt_data.gridBounds.minlat) + '&deg; to ' + soy.$$escapeHtml(opt_data.gridBounds.maxlat) + '&deg;</dd><dt>Longitude Range</dt><dd>' + soy.$$escapeHtml(opt_data.gridBounds.minlon) + '&deg; to ' + soy.$$escapeHtml(opt_data.gridBounds.maxlon) + '&deg;</dd>' : (opt_data.occurrenceCoord) ? '<dt>Latitude</dt><dd>' + soy.$$escapeHtml(opt_data.occurrenceCoord.lat) + '</dd><dt>Longitude</dt><dd>' + soy.$$escapeHtml(opt_data.occurrenceCoord.lon) + '</dd>' : '', '</dl>');
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
  output.append('</div><div class="tab-panel details-panel"></div></div>');
  return opt_sb ? '' : output.toString();
};


Edgar.templates.mapPopupDetailsPanel = function(opt_data, opt_sb) {
  var output = opt_sb || new soy.StringBuilder();
  output.append('<h3 class="curr-page">showing ', soy.$$escapeHtml(opt_data.pageIdx * opt_data.pageSize + 1), ' - ', soy.$$escapeHtml(opt_data.pageIdx * opt_data.pageSize + opt_data.features.length), ' of ', soy.$$escapeHtml(opt_data.totalOccurrences), '</h3><div class="page-nav">', (opt_data.pageIdx > 0) ? '<a class="prev-page">&laquo; previous ' + soy.$$escapeHtml(opt_data.pageSize) + '</a>' : '', (opt_data.pageIdx < Math.ceil(opt_data.totalOccurrences / opt_data.pageSize) - 1) ? '<a class="next-page">next ' + soy.$$escapeHtml(opt_data.pageSize) + ' &raquo;</a>' : '', '</div><div class="occurrence-list">');
  var fList65 = opt_data.features;
  var fListLen65 = fList65.length;
  if (fListLen65 > 0) {
    for (var fIndex65 = 0; fIndex65 < fListLen65; fIndex65++) {
      var fData65 = fList65[fIndex65];
      output.append('<div class="occurrence-detail">(', soy.$$escapeHtml(fData65.geometry.coordinates[0]), ', ', soy.$$escapeHtml(fData65.geometry.coordinates[1]), ') with ', soy.$$escapeHtml(fData65.properties.uncertainty), 'm accuracy<br />Basis: ', soy.$$escapeHtml(fData65.properties.basis ? fData65.properties.basis : 'unknown'), '<br />Date: ', soy.$$escapeHtml(fData65.properties.date ? fData65.properties.date : 'unknown'), '<br />Source: <a href="', soy.$$escapeHtml(fData65.properties.source_url), '">', soy.$$escapeHtml(fData65.properties.source_name), '</a></div>');
    }
  } else {
    output.append('<p class="none-found">No occurrences found.</p>');
  }
  output.append('</div>');
  return opt_sb ? '' : output.toString();
};


Edgar.templates.mapPopupLoading = function(opt_data, opt_sb) {
  var output = opt_sb || new soy.StringBuilder();
  output.append('<div class="loading"><img src="', soy.$$escapeHtml(opt_data.baseUrl), 'img/loading-bar.gif" /></div>');
  return opt_sb ? '' : output.toString();
};
