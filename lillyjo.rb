require 'net/http'
require 'oga'
require 'pry-byebug'

class LillyJo

  def initialize
    @visited_links = {}
    @keyword_count = {}
  end

  def retrieve_menu
    click('http://swisscom-fiftyone.sv-restaurant.ch/de.html')
    evaluate_content
    find_highest_count
  end

  def click(url)
    puts "Clicking #{url}"
    home_uri = URI(url)
    html_string = Net::HTTP.get(home_uri)
    oga_document = Oga.parse_html(html_string.force_encoding('UTF-8'))
    @visited_links[url] = oga_document
    all_hrefs = oga_document.css('a').map { |a| a.attribute('href') }.compact.map { |attribute| attribute.value }
    filtered_hrefs = all_hrefs.keep_if do |href|
      href.start_with?('http://swisscom-fiftyone.sv-restaurant.ch/') ||
        !href.match(/^\w+:/)
    end

    filtered_hrefs.each do |href|
      if !@visited_links.include?(href) && !href.include?('pdf') && !href.include?('disclaimer') && !href.include?('impressum')
        click(href)
      end
    end
  end

  def evaluate_content
    @visited_links.each do |url, content|
      content.css('body').each do |element|
        text = element.text
        unless text.valid_encoding?
          text = text.encode('UTF-8', invalid: :replace, replace: '?')
        end
        match_data = text.scan(/(Angebot|Lunch|Menü)/i)
        @keyword_count[url] = match_data.length
      end
    end
  end

  def find_highest_count
    highest_value = 0
    key_url = ''
    @keyword_count.each do |url, count|
      if count >= highest_value
        highest_value = count
        key_url = url
      end
    end
    puts key_url
  end
end

lillyjo = LillyJo.new
lillyjo.retrieve_menu