#!/usr/bin/env ruby

require "csv"


csvlist = ['csvs/DOCUMENTS.csv','csvs/LETTERS.csv','csvs/MISCELANEOUS.csv','csvs/PHOTOGRAPHS.csv']
# csvlist = ['csvs/DOCUMENTS.csv','csvs/LETTERS.csv','csvs/MISCELANEOUS.csv','csvs/PHOTOGRAPHS.csv']
@errors = []

onefile = csvlist[1]

def getbaseid(id)
  id[/\d{3}/]
  #id.gsub("\n", '')
end

def getrange(array)
  start = array.first
  stop = array.last
  if start && stop 
    (start..stop).to_a
  end
end

def idlister(filename)

  CSV.foreach(filename, headers: true) do |row|
    next if !row['SCAN ID']
    ids = row['SCAN ID'].split("to")

    basename = ids.first[/(shan_\w\.)\d{3}/,1]

    nums = ids.map do |id|
      getbaseid(id)
    end

    # puts nums.to_s

   

    if nums.length > 2
      @errors << nums.to_s 
    else
      newrange = getrange(nums)
      if newrange
        puts newrange.map {|num| "#{basename}#{num}"}
      end
    end
    
  end
end

csvlist.each do |filename|
  idlister(filename)
end

# puts "end"

puts @errors
