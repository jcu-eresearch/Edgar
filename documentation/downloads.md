
# Edgar downloadable archives

There are two zip archives downloadable from Edgar for each modelled species.

## Observations

The `latest-occurrences.zip` archive includes a single file in CSV format that includes the occurrences used to model current and projected suitability for the selected species.  The columns in the CSV are:

- LATDEC: the latitude of the occurrence in signed decimal degrees
- LONGDEC: the longitude of the occurrence in signed decimal degrees
- DATE: the date of the occurrence
- BASIS: a category for the occurrence
- CLASSIFICATION: the category of the occurrence, selected from the classification categories available in Edgar. Only classifications considered useful to suitability modelling are included (e.g. "doubtful" and "vagrant" occurrences are excluded from the CSV)
- SOURCE: the source of the occurrence records


## Projections

The `latest-projected-distributions.zip` archive includes several sets of files:


### Maxent process files

A model of species climate suitability is produced using the maxent tool, with seven bioclim variables and the filtered set of occurrences for the selected species.  The archive includes several files related to this model generation.

- `{species-id}.html` contains a summary of the maxent process and results
- `/plots` includes various graphs used in the maxent summary
- `maxent.log` output of the maxent model creation process
- `{species-id}.lambdas`
- `{species-id}_omission.csv`
- `{species-id}_sampleAverages.csv`
- `{species-id}_samplePredictions.csv`
- `maxentResults.csv`


### Current suitability distribution

`1990.asc` is the climate suitability for the species, projected across Australia given the current climate.  This is the current suitability distribution displayed by the Edgar web interface.


### Individual model outputs

`{scenario}_{modeler}_{year}.asc` is the result of a single modelling run, in ASCIIgrid format.  Each pixel encodes a suitability estimate for that geographic area for the selected species, projected across Australia given the climate described.  For each filename:

- `{scenario}` identifies the Representative Concentration Pathway used for this modelling run from the IPCC's AR5.  Possible values are:
  - `RCP3PD` is the RCP2.6 scenario
  - `RCP45` is the RCP4.5 scenario
  - `RCP6` is the RCP6.0 scenario
  - `RCP85` is the RCP8.5 scenario
- `{year}` is the middle year of the 30 year climate period being modelled (e.g., 2025 is the middle of the climate period 2011-2040)
- `{modeler}` is the climate projection model used to project the climate


### Medians of model outputs

`{scenario}_median_{year}.{asc|tif}` files are a summary across the various climate projection models.  Each pixel represents the median value across corresponding pixels in the individual model outputs.  The same data is available in ASCIIgrid and GeoTIFF formats.  These are the projected suitability distributions displayed by the Edgar web interface.

Each median file has an auxiliary file `{scenario}_median_{year}.asc.aux.xml` in an ESRI format containing additional spatial information about the media maps.


### Other outputs

`JOB_ENV_VARS.txt` contains the environmental variables existing in the server environment used to generate all output for this species.
