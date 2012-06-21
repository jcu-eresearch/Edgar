//
// initialise some global variables and whatnot
//

// the global Edgar object
window.Edgar = window.Edgar || {};

// the species map itself
Edgar.map = null;

// vars related to the species map
Edgar.mapdata = Edgar.mapdata || {};

Edgar.mapdata.species = null; // (object) current species displayed on the map
Edgar.mapdata.emissionScenario = null; //(string) identifier for current emission scenario
Edgar.mapdata.year = null; //(integer) the year that the suitability map represents (e.g. 2010)

// logged in user?  This is set in fullscreencontent.ctp if there's a logged in user
Edgar.user = null;

