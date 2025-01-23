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

  # little bit of a cheat in order to make a custom output format
  # using the HTML transformation step
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

    # get a set of all the letters
    @items = @file.select { |item| item["category2"] == "Letter" }

    create_all_letters
    create_letters_by_decade
    create_letters_by_location
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
  def aggregate_city_densities(letter_method, items)
    cities_total = {}

    # create a feature for each city and increase a count prop
    items.each do |item|
      letter = Letter.new(item)
      type = letter.send(letter_method)
      next if !type
      place = type["title"]
      push_letter_to_hash(
        cities_total,
        letter,
        "#{letter_method}_geometry",
        place,
        item,
        locations: [place]
      )
    end
    cities_total
  end

  def aggregate_letter_routes(items)
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
      key = [place_from, place_to].join("|")

      push_letter_to_hash(
        routes_total,
        letter,
        "route_geometry",
        key,
        item,
        locations: [place_from, place_to]
      )
    end
    routes_total
  end

  def aggregate_letter_routes_by_location(letter_method, country: nil, state: nil)
    # first we need to filter out any letters that are not relevant
    # aka: if letter_method is "destination" and state is "Colorado" we only
    # want letters being sent to Colorado
    placename = country || state
    items = @items.select do |i|
      i["spatial"].any? do |s|
        next if !s
        if country
          s["country"] == country && s["type"] == letter_method
        elsif state
          s["state"] == state && s["type"] == letter_method
        end
      end
    end
    aggregate_letter_routes(items)
  end

  def create_all_letters
    # routes
    routes_total = aggregate_letter_routes(@items)
    wrap_collection(routes_total.values, "routes.json")
    # destination
    features = aggregate_city_densities("destination", @items)
    wrap_collection(features.values, "destination.json")
    # origin
    features = aggregate_city_densities("origin", @items)
    wrap_collection(features.values, "origin.json")
  end

  def create_letters_by_decade
    decades = @items.group_by { |item| Letter.new(item).decade }
    decades.each do |year, items|
      # now group each decade by routes
      routes_total = aggregate_letter_routes(items)
      wrap_collection(routes_total.values, "#{year}_routes.json")
      # destination
      dest = aggregate_city_densities("destination", items)
      wrap_collection(dest.values, "#{year}_destination.json")
      # origin
      origin = aggregate_city_densities("origin", items)
      wrap_collection(origin.values, "#{year}_origin.json")
    end
  end

  def create_letters_by_location
    # from Michoacán
    mic_from = aggregate_letter_routes_by_location("origin", state: "Michoacán")
    wrap_collection(mic_from.values, "Michoacan_origin_routes.json")

    # to Michoacán
    mic_to = aggregate_letter_routes_by_location("destination", state: "Michoacán")
    wrap_collection(mic_to.values, "Michoacan_destination_routes.json")

    # from zacatecas
    zac_from = aggregate_letter_routes_by_location("origin", state: "Zacatecas")
    wrap_collection(zac_from.values, "Zacatecas_origin_routes.json")

    # to zacatecas (no letters currently)
    # zac_to = aggregate_letter_routes_by_location("destination", state: "Zacatecas")
    # wrap_collection(zac_to.values, "Zacatecas_destination_routes.json")

    # from colorado
    co_from = aggregate_letter_routes_by_location("origin", state: "Colorado")
    wrap_collection(co_from.values, "Colorado_origin_routes.json")

    # to colorado
    co_to = aggregate_letter_routes_by_location("destination", state: "Colorado")
    wrap_collection(co_to.values, "Colorado_destination_routes.json")

    # from nebraska
    ne_from = aggregate_letter_routes_by_location("origin", state: "Nebraska")
    wrap_collection(ne_from.values, "Nebraska_origin_routes.json")

    # to nebraska
    ne_to = aggregate_letter_routes_by_location("destination", state: "Nebraska")
    wrap_collection(ne_to.values, "Nebraska_destination_routes.json")
  end

  # nearly the exact same as push_letter_to_hash functionality
  # except that we don't need languages for photos
  # but can consider combining if desired
  def create_photographs
    items = @file.select { |item| item["category2"] == "Photograph" }
    cities = {}
    items.map do |item|
      photo = Photograph.new(item)
      key = photo.location
      if !cities.key?(key)
        cities[key] = {
          "type" => "Feature",
          "properties" => {
            "count" => 1,
            "locations" => [ key ],
            "photos" => [ photo.properties ]
          },
          "geometry" => photo.draw_point
        }
      else
        props = cities[key]["properties"]
        props["count"] += 1
        props["photos"] << photo.properties
      end
    end
    wrap_collection(cities.values, "photographs.json")
  end

  # either create a new Feature or alter the properties
  # of an existing one to push onto a hash aggregating them
  def push_letter_to_hash(agg, letter, geometry, key, item, locations: [])
    es = (item["language"]) == "es" ? 1 : 0
    en = item["language"] == "en" ? 1 : 0
    if !agg.key?(key)
      agg[key] = {
        "type" => "Feature",
        "properties" => {
          "count" => 1,
          "es" => es,
          "en" => en,
          "locations" => locations,
          "letters" => [ letter.properties ]
        },
        "geometry" => letter.send(geometry)
      }
    else
      props = agg[key]["properties"]
      props["count"] += 1
      props["es"] += es
      props["en"] += en
      props["letters"] << letter.properties
    end
  end

  def wrap_collection(features, filename)
    geojson = {
      "type" => "FeatureCollection",
      "features" => features
    }
    write_geojson(filename, geojson)
  end

  def write_geojson(filename, contents)
    loc = File.join(@output_dir, filename)
    File.open(loc, "w") { |f| f.write(JSON.pretty_generate(contents))}
  end

end
