module LocationHelper

  def prepare_places
    places = CSV.read(
      File.join(@options["collection_dir"], "source/authority/places.csv"),
      encoding: "utf-8",
      headers: true,
      return_headers: true
    )
    locs = {}
    places.each { |p| locs[p["Title"]] = p }
    locs
  end

end
