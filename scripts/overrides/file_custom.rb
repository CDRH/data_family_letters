require "fileutils"
require "json"

require_relative "letter.rb"
require_relative "photograph.rb"

class FileCustom < FileType

  def read_file
    json = File.read(@file_location)
    JSON.parse(json)
  end

  def transform_es
  end

  def transform_html
    puts "transforming API results into geoJSON"

    @output_dir = File.join(
      @options["collection_dir"],
      "output",
      @options["environment"],
      "geojson"
    )
    # make geojson directory
    FileUtils.mkdir_p(@output_dir)

    create_photographs

    create_city_densities_destination
    create_city_densities_origin
    create_letter_route

    create_letters_by_decade
    # just send something blank back to datura
    # to make it happy
    {}
  end

  def transform_solr
  end

  private

  # creates points with count information for number of incoming or outgoing
  # letters, whichever is selected by "letter_method" [ aka letter.origin or
  # letter.destination ]
  # letter_method
  #   "origin" or "destination"
  def aggregate_city_densities(letter_method)
    items = @file.select { |item| item["subcategory"] == "Letter" }
    cities_total = {}

    # create a feature for each city and increase a count prop
    items.each do |item|
      letter = Letter.new(item)
      type = letter.send(letter_method)
      next if !type

      place = type["title"]
      es = (item["language"]) == "es" ? 1 : 0
      en = item["language"] == "en" ? 1 : 0
      if !cities_total.key?(place)
        cities_total[place] = {
          "type" => "Feature",
          "properties" => {
            "count" => 1,
            "es" => es,
            "en" => en,
            "location" => place,
            "letters" => [ letter.properties ]
          },
          "geometry" => letter.send("#{letter_method}_geometry")
        }
      else
        props = cities_total[place]["properties"]
        props["count"] += 1
        props["es"] += es
        props["en"] += en
        props["letters"] << letter.properties
      end
    end
    cities_total
  end


  def aggregate_letter_routes_by_route
    items = @file.select { |item| item["subcategory"] == "Letter" }
    # holds city_from|city_to with pipe delineator
    routes_total = {}

    # create a feature for each city and increase a count prop
    items.each do |item|
      letter = Letter.new(item)
      origin = letter.origin
      dest = letter.destination
      next if !origin || !dest

      place_from = origin["title"]
      place_to = dest["title"]
      key = "#{place_from}|#{place_to}"

      es = (item["language"]) == "es" ? 1 : 0
      en = item["language"] == "en" ? 1 : 0
      if routes_total.key?(key)
        props = routes_total[key]["properties"]
        props["count"] += 1
        props["es"] += 1
        props["en"] += 1
        props["letters"] << letter.properties
      else
        routes_total[key] = {
          "type" => "Feature",
          "properties" => {
            "count" => 1,
            "es" => es,
            "en" => en,
            "location" => "#{place_from} to #{place_to}",
            "letters" => [ letter.properties ]
          },
          "geometry" => letter.route_geometry
        }
      end
    end
    routes_total
  end

  def create_city_densities_destination
    features = aggregate_city_densities("destination")
    json = {
      "type" => "FeatureCollection",
      "features" => features.values
    }
    write_geojson("city_to.json", json)
  end

  def create_city_densities_origin
    features = aggregate_city_densities("origin")
    json = {
      "type" => "FeatureCollection",
      "features" => features.values
    }
    write_geojson("city_from.json", json)
  end

  def create_letter_route
    routes_total = aggregate_letter_routes_by_route
    json = {
      "type" => "FeatureCollection",
      "features" => routes_total.values
    }
    write_geojson("routes_all.json", json)
  end

  def create_letters_by_decade
  end

  def create_photographs
    items = @file.select { |item| item["subcategory"] == "Photograph" }
    features = items.map do |item|
      photo = Photograph.new(item)
      photo.feature
    end
    geojson = {
      "type" => "FeatureCollection",
      "features" => features
    }
    write_geojson("photographs.json", geojson)
  end

  def write_geojson(filename, contents)
    loc = File.join(@output_dir, filename)
    File.open(loc, "w") { |f| f.write(JSON.pretty_generate(contents))}
  end

end
