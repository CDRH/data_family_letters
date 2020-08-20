require "fileutils"
require "json"

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
  end

  def transform_solr
  end

  private

  def create_photographs
    puts @file.length
    items = @file.select { |item| item["subcategory"] == "Photograph" }
    puts JSON.pretty_generate(items_to_geojson(items))
  end

  def geojson_geometry(spatial)
    if spatial.length == 1
      {
        "type" => "Point",
        "coordinates" => [
          spatial.first["coordinates"]["lon"],
          spatial.first["coordinates"]["lat"]
        ]
      }
    else
      coords = spatial.map do |s|
        [
          s["coordinates"]["lon"],
          s["coordinates"]["lat"]
        ]
      end
      {
        "type" => "LineString",
        "coordinates" => coords
      }
    end
  end

  def items_to_geojson(items)
    features = items.map do |item|
      {
        "type" => "Feature",
        "properties" => item,
        "geometry" => geojson_geometry(item["spatial"])
      }
    end
    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end

end
