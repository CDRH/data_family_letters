require "json"
require "open-uri"
require "uri"

class Datura::DataManager

  def build_html(urls)
    combined = ""
    # retrieve and then combine into a single file which can be parsed
    urls.each do |url|
      lang = url.include?("/en/") ? "en" : "es"
      raw = open(url) { |f| f.read }

      # wrap the web scraping results in a div that describes the language
      combined << "<div lang=\"#{lang}\">"
      html = Nokogiri::HTML(raw)
      combined << html.at_xpath("//div[@id='content-wrapper']").inner_html
      combined << "</div>"
    end
    combined
  rescue => exception
    print_error(exception, urls)
  end

  def pre_file_preparation
    if @options["scrape_website"]
      url = File.join(@options["site_url"], @options["scrape_endpoint"])
      puts "getting list of urls to scrape from #{url}"
      list_of_pages = open(url) { |f| f.read }
      # family letters has urls such as research and en/research
      # representing spanish and english views of the same content
      # so the urls are returned in pairs
      JSON.parse(list_of_pages).each do |pair|
        # share an id for the two files
        site_url_for_regex = @options["site_url"]
          .gsub("/", "\/")
          .gsub(".", "\.")
        id = pair
          .first[/^#{site_url_for_regex}\/(.*)/, 1]
          .gsub("/", "_")
        output_file = "#{@options["collection_dir"]}/source/webs/#{id}.html"

        html = build_html(pair)
        File.open(output_file, 'w') { |file| file.write(html) }
      end
    else
      puts %{Files in source/webs are not being refreshed from the website
        contents. If you wish to scrape the family letters website, please
        add or update config/public.yml to use "scrape_website: true"}
    end
  rescue => exception
    print_error(exception, url)
  end

  def print_error(e, url)
    puts %{Something went wrong while scraping the family letters website:
  URL(S): #{url}
  ERROR: #{e}
To post content, please check the endpoint in config/public.yml, or
temporarily disable the scrape_website setting in that file}.red
  end

end
