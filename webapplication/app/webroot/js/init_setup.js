//
// initialise some global variables and whatnot
//

//global Edgar object
window.Edgar = window.Edgar || {};
//vars related to the species map
Edgar.map = Edgar.map || {};
//(object) current species displayed on the map
Edgar.map.species = null;
//(string) identifier of the emission scenario for the distribution map (e.g. "giss_aom")
Edgar.map.emissionScenario = null;
//(integer) the year that the distribution map represents (e.g. 2010, or 2020, or 1980)
Edgar.map.year = null;

// logged in user?  This is set in fullscreencontent.ctp if there's a logged in user
Edgar.user = null;

