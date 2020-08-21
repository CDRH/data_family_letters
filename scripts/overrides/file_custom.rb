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
    create_from_city_densities
    # just send something blank back to datura
    # to make it happy
    {}
  end

  def transform_solr
  end

  private

  def create_photographs
    items = @file.select { |item| item["subcategory"] == "Photograph" }
    geojson = items_to_geojson(items)
    write_geojson("photographs.json", geojson)
  end

  def create_from_city_densities
    # collect all letters
    # aggregate cities sending letters and amounts
    # create point layers with overall density
    # create line layers with number info
    # TODO break down by decade?
    items = @file.select { |item| item["subcategory"] == "Letter" }
    cities_total = {}
    cities_from_to = {}

    # create a feature for each city and increase a count prop
    items.each do |item|
      letter = Letter.new(item)
      next if !letter.origin

      place = letter.origin["title"]
      if !cities_total.key?(place)
        cities_total[place] = {
          "type" => "Feature",
          "properties" => {
            "count" => 1,
            "location" => place,
            "letters" => [ letter.properties ]
          },
          "geometry" => letter.origin_geometry
        }
      else
        cities_total[place]["properties"]["count"] += 1
        cities_total[place]["properties"]["letters"] << letter.properties
      end
    end

    # iterate through cities_total and calculate
    # percentage of primarily spanish letters

    json = {
      "type" => "FeatureCollection",
      "features" => cities_total.values
    }
    write_geojson("city_from.json", json)
    # items.each do |item|

    #   next if !from || !to

    #   place = from["title"]
    #   if !cities_total.key?(place)
    #     cities_total[place] = 0
    #     # assuming this also hasn't been created
    #     cities_from_to[place] = {}
    #   end
    #   cities_total[place] += 1
    #   if !cities_from_to[place].key?(to["title"])
    #     cities_from_to[place][to["title"]] = 0
    #   end
    #   cities_from_to[place][to["title"]] += 1
    # end
    # puts cities_total
    # puts "--"
    # puts cities_from_to
  end

  def items_to_geojson(items)
    features = items.map do |item|
      photo = Photograph.new(item)
      photo.feature
    end
    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  def write_geojson(filename, contents)
    loc = File.join(@output_dir, filename)
    File.open(loc, "w") { |f| f.write(JSON.pretty_generate(contents))}
  end

end
