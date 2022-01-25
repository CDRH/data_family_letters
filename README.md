# Cartas a la Familia: De la migración de Jesusita a Jane / Family Letters: On the Migration from Jesusita to Jane

## About This Data Repository

**How to Use This Repository:** This repository is intended for use with the [CDRH API](https://github.com/CDRH/api) and the [Family Letters Ruby on Rails application](https://github.com/CDRH/family_letters).

**Data Repo:** [https://github.com/CDRH/data_family_letters](https://github.com/CDRH/data_family_letters)

**Source Files:** TEI XML, PDF, CSV, HTML, JSON

**Script Languages:** Ruby, XSLT

**Encoding Schema:** [Text Encoding Initiative (TEI) Guidelines](https://tei-c.org/release/doc/tei-p5-doc/en/html/index.html)

## About Cartas a la Familia / The Family Letters

The Family Letters project preserves, digitizes, analyzes and makes public a collection of the correspondence and other personal documents of a Mexican American family that migrated from the state of Zacatecas, Mexico, to the states of Colorado and Nebraska during the first half of the twentieth century. Family Letters: On the Migration from Jesusita to Jane is a project directed by Isabel Velázquez, and published jointly by the Center for Digital Research in the Humanities and the Department of Modern Languages and Literatures at the University of Nebraska, Lincoln, under a [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](https://creativecommons.org/licenses/by-nc-sa/3.0/).

**Project Site:** [https://familyletters.unl.edu/](https://familyletters.unl.edu/)

**Rails Repo:** [https://github.com/CDRH/family_letters](https://github.com/CDRH/family_letters)

**Credits:** [https://familyletters.unl.edu/en/about](https://familyletters.unl.edu/en/about)

**Work to Be Done:** [https://github.com/CDRH/family_letters/issues](https://github.com/CDRH/family_letters/issues)

This repository was designed before the Datura gem begin to include individual fields in CsvToEs. At some point, this may be rewritten to use the Datura methods for ease of maintenance and clarity of code.

## Technical Information

See the [Datura documentation](https://github.com/CDRH/datura) for general updating and posting instructions. 

**NOTE: Do not edit the CSV files. They are generated from a spreadsheet (documents.csv) and a [mediacommons](https://mediacommons.unl.edu/luna/servlet/UNL~111~111) export (photographs.csv)**

This repository also queries the API in order to get information across
documents / items for locations, then creates geoJSON from that result.
This step is done in the `data_manager.rb` file. Configure whether or
not the API is queried and the endpoint in `config/public.yml`

**Update ES:**

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

## About the Center for Digital Research in the Humanities

The Center for Digital Research in the Humanities (CDRH) is a joint initiative of the University of Nebraska-Lincoln Libraries and the College of Arts & Sciences. The Center for Digital Research in the Humanities is a community of researchers collaborating to build digital content and systems in order to generate and express knowledge of the humanities. We mentor emerging voices and advance digital futures for all.

**Center for Digital Research in the Humanities GitHub:** [https://github.com/CDRH](https://github.com/CDRH)

**Center for Digital Research in the Humanities Website:** [https://cdrh.unl.edu/](https://cdrh.unl.edu/)
