require 'json'
require 'ostruct'
require "byebug"

file = (ARGV[0] || exit(1))

CHAPTER_REGXP = /^(?<id>\d{1,2})\.\s\s(?<name>[A-Z0-9 ,-]+)\s?\((?<from>\d{3})\-(?<to>\d{3})\)$/
SUBCHAPTER_REGXP = /^(?<name>[A-Z0-9 ,]+)\s?\((?<from>\d{3})\-(?<to>\d{3})\)$/
DESEASE_REGXP = /^(?<id>\d{3}(\.\d+)?)\t(?<name>.+)$/
DISEASES_RANGE = /\((\d{3})\-\d{3}\)$/

data = {
  'chapters' => [],
  'subchapters' => [],
  'diseases' => []
}
current_chapter = nil
current_subchapter = nil

begin
  File.readlines(file).each do |line|
    line.strip!
    case line
    when CHAPTER_REGXP
      current_subchapter = nil
      current_chapter = OpenStruct.new(line.match(CHAPTER_REGXP).named_captures)
      current_chapter.name.strip!
      current_chapter.id = current_chapter.id.to_i
      data['chapters'] << current_chapter.to_h
      next
    when SUBCHAPTER_REGXP
      # debugger
      next unless current_chapter
      current_subchapter = OpenStruct.new(line.match(SUBCHAPTER_REGXP).named_captures)
      current_subchapter.name.strip!
      current_subchapter.id = data['subchapters'].size + 1
      current_subchapter.chapterId = current_chapter.id
      data['subchapters'] << current_subchapter.to_h
      next
    when DESEASE_REGXP
      current_disease = OpenStruct.new(line.match(DESEASE_REGXP).named_captures)
      current_disease.subchapterId = current_subchapter.id if current_subchapter
      current_disease.chapterId = current_chapter.id
      current_disease.name.strip!
      current_disease.longName = [current_chapter, current_subchapter, current_disease].compact.map(&:name).join(' | ')
      # puts "DUPLICATE #{line}" if data['diseases'].any?{|d| d['id'] == current_disease.id}
      data['diseases'] << current_disease.to_h
    else
      puts "UNEXPECTED line: #{line}"
    end
  end
rescue RuntimeError => e
  fail(e)
end
basename = File.basename(ARGV[0], ".*" )
File.open("#{basename}.json", "w") {|f| f.write(data.to_json) }
# puts data.to_json

