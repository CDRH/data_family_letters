class Letter

  def initialize(item)
    # takes an api document response
    # and gets it ready for use creating geojson

    @item = item
  end

  def decade
    dec = 0
    if @item["date"]
      year = @item["date"][/^\d{4}/]
      if year
        y = year.to_i
        dec = y - (y % 10)
      end
    end
    dec
  end

  def destination
    find_spatial("destination")
  end

  def destination_geometry
    s = destination
    draw_point(s)
  end

  def route_geometry
    coords = @item["spatial"].map do |s|
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

  def origin
    find_spatial("origin")
  end

  def origin_geometry
    s = origin
    draw_point(s)
  end

  def properties
    {
      "title" => @item["title"],
      "title_es" => @item["title_es_k"],
      "identifier" => @item["identifier"],
      "date" => @item["date"],
      "decade" => decade,
      "language" => @item["language"]
    }
  end

  private

  def draw_point(spatial)
    if spatial
      {
        "type" => "Point",
        "coordinates" => [
          spatial["coordinates"]["lon"],
          spatial["coordinates"]["lat"]
        ]
      }
    end
  end

  def find_spatial(type)
    if @item["spatial"]
      idx = @item["spatial"].find_index do |s|
        s["type"] == type if s
      end
      @item["spatial"][idx] if idx
    end
  end

end
