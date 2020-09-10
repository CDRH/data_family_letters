class Photograph

  def initialize(item)
    @item = item
  end

  def draw_point
    if @item["spatial"]
      s = @item["spatial"].first
      {
        "type" => "Point",
        "coordinates" => [
          s["coordinates"]["lon"],
          s["coordinates"]["lat"]
        ]
      }
    end
  end

  def location
    if @item["spatial"]
      s = @item["spatial"].first
      s["title"]
    end
  end

  def properties
    {
      "identifier" => @item["identifier"]
    }
  end

end
