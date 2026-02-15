#!/usr/bin/env ruby

require 'erb'

class Extraction
  attr_reader :image_path, :txt_path

  def initialize(image_path)
    @image_path = image_path
    extract!
  end

  private

  def now
    Time.now.strftime('%F %T')
  end

  def extract!
    # prepare result file
    base_path = File.join(File.dirname(image_path), File.basename(image_path, '.*'))
    @txt_path = "#{base_path}.txt"
    return if File.exist?(txt_path)

    # run ocr
    start_at = now
    print "#{start_at}: #{image_path}"
    tmp_path = "/tmp/#{File.basename(image_path)}"
    `sips --resampleWidth 512 #{image_path} --out #{tmp_path}`
    result = `ollama run glm-ocr:bf16 'Text Recognition: #{tmp_path}' 2>/dev/null`

    # write result
    File.write(txt_path, result)
    print "\r#{start_at} => #{now}: #{image_path}\n"
  end
end

class ImgLoc
  def initialize(img_loc)
    @img_loc = img_loc
  end

  def dir?
    File.directory?(@img_loc)
  end

  def image_files
    if dir?
      image_extensions = %w[jpg jpeg png]
      wildcast = File.join(@img_loc, "/**/*.{#{image_extensions.join(',')}}")
      return Dir.glob(wildcast, File::FNM_CASEFOLD)
    end

    if File.exist?(images_location)
      [@img_loc]
    end

    []
  end

  def result_loc
    dir? ? @img_loc : File.dirname(@img_loc)
  end
end

src = ImgLoc.new(ARGV[0].to_s)

at_exit do
  html = ERB.new(File.read('extractions.html.erb')).result(binding)
  output_path = File.join(src.result_loc, 'extractions.html')
  File.write(output_path, html)
end

extractions = []
src.image_files.map do |image_path|
  extractions << Extraction.new(image_path)
end

puts "Done!"
