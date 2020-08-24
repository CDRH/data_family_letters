# Cartas a la Familia: De la migración de Jesusita a Jane

Family Letters: On the Migration from Jesusita to Jane

This repository is intended for use with the [CDRH API](https://github.com/CDRH/api) and the [Family Letters Ruby on Rails application](https://github.com/CDRH/family_letters).

## Updating

See the [Datura documentation](https://github.com/CDRH/datura) for general updating and posting instructions. **NOTE: do not edit the CSV files -- they are generated from a spreadsheet (documents.csv) and a [mediacommons](https://mediacommons.unl.edu/luna/servlet/UNL~111~111) export (photographs.csv)**

This repository also queries the API in order to get information across
documents / items for locations, then creates geoJSON from that result.
This step is done in the `data_manager.rb` file. Configure whether or
not the API is queried and the endpoint in `config/public.yml`

Update ES:

```
post
```
Update HTML and GeoJSON:

```
post -x html
```

Update only GeoJSON:

```
post -x html -f api_location
```

## Work to be Done

This repository was designed before the Datura gem begin
to include individual fields in CsvToEs. At some point, this may
be rewritten to use the Datura methods for ease of maintenance and clarity of code.
