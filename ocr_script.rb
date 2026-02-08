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

at_exit do
  html = ERB.new(File.read('extractions.html.erb')).result(binding)
  File.write('/tmp/abc.html', html)
end

images_location = ARGV[0].to_s

image_files =
  if File.directory?(images_location)
    image_extensions = %w[jpg jpeg png]
    wildcast = File.join(images_location, "/**/*.{#{image_extensions.join(',')}}")
    Dir.glob(wildcast, File::FNM_CASEFOLD)
  elsif File.exist?(images_location)
    [images_location]
  else
    []
  end

extractions = []
image_files.map do |image_path|
  extractions << Extraction.new(image_path)
end

puts "Done!"
