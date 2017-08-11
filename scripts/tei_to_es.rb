class TeiToEs

  ################
  #    XPATHS    #
  ################

  # in the below example, the xpath for "person" is altered
  def override_xpaths
    xpaths = {}
    xpaths["person"] = "/TEI/teiHeader/profileDesc/particDesc/person"
    return xpaths
  end

  #################
  #    GENERAL    #
  #################

  def read_file path
    Common.create_xml_object("#{@options["coll_dir"]}/#{path}")
  end

  # do something before pulling fields
  def preprocessing
    # read additional files, alter the @xml, add data structures, etc
    @personography = read_file "authority_files/shanahan_listperson.xml"
  end

  # do something after pulling the fields
  def postprocessing
    # change the resulting @json object here
  end

  # Add more fields
  #  make sure they follow the custom field naming conventions
  #  *_d, *_i, *_k, *_t
  def assemble_collection_specific
  #   @json["fieldname_k"] = some_value_or_method
  end

  ################
  #    FIELDS    #
  ################

  # Please see docs/tei_to_es.rb for complete instructions and examples

  # Note: basic override
  # def self.fieldname
  #   your custom code
  # end

  def person
    list = []
    people = @xml.xpath(@xpaths["person"])
    people.each do |p|
      xmlid = p["id"]
      role = p["type"]

      # collect the parts of the person's name
      person = @personography.xpath("//person[@id='#{xmlid}']")
      nameFull = person.xpath("persName[@type='display']").text
      nameSqueezed = Common.squeeze(nameFull)
      # birth = person.xpath("ab/persName/surname[@type='birth']").text
      # they may have zero or many additional names, so iterate through
      # add = person.xpath("ab/persName/addName").map { |n| n.text }.join(", ")

      # put together the name itself
      label = nameSqueezed

      pers_obj = { "name" => label, "id" => xmlid }
      pers_obj["role"] = role if role
      list << pers_obj

      # some of the personography entries are also tied to annotations, keep track of them
      #@person_annos << person.xpath("ab/ref[@type='annotation']/@target").text
    end
    return list.uniq
  end

  # In the below example, the normal "person" behavior is customized
  def self.person
    # TODO will need some examples of how this will work
    # and put in the xpaths above, also for attributes, etc
    # should contain name, id, and role
    eles = @xml.xpath(@xpaths["person"])
    return eles.map { |p| { "role" => p["role"], "name" => p.text, "id" => nil } }
  end

end
