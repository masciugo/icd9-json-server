require 'json'
require 'ostruct'
require "byebug"

file = (ARGV[0] || exit(1))

ITEM_ID_RE = /((\d{3})|(V\d{2})|(E\d{3}))/
CHAPTER_RE = /^(?<id>\d{1,2})\.\s\s(?<name>[A-Z0-9 ,-]+)\s?\((?<from>\d{3})\-(?<to>\d{3})\)$/
CHAPTER_VE_RE = /^(?<name>(SUPPLEMENTARY CLASSIFICATION).+)\s?\((?<from>((V\d{2})|(E\d{3})))(\-(?<to>((V\d{2})|(E\d{3}))))?\)$/
SUBCHAPTER_RE = /^(?<name>[A-Z0-9 ,-]+)\s?\((?<from>#{ITEM_ID_RE})(\-(?<to>#{ITEM_ID_RE}))?\)$/
DESEASE_RE = /^(?<id>#{ITEM_ID_RE}(\.\d+)?)\t(?<name>.+)$/

data = {
  'chapters' => [],
  'subchapters' => [],
  'diseases' => []
}
current_chapter = nil
current_subchapter = nil
row_n = 0

begin
  File.readlines(file).each do |row|
    row_n += 1
    row.strip!
    case row
    when CHAPTER_RE
      current_subchapter = nil
      current_chapter = OpenStruct.new(row.match(CHAPTER_RE).named_captures)
      current_chapter.name.strip!
      current_chapter.id = current_chapter.id.to_i
      data['chapters'] << current_chapter.to_h
      # puts current_chapter.to_h
      next
    when CHAPTER_VE_RE
      current_subchapter = nil
      current_chapter = OpenStruct.new(row.match(CHAPTER_VE_RE).named_captures)
      current_chapter.name.strip!
      current_chapter.id = data['chapters'].size + 1
      data['chapters'] << current_chapter.to_h
      # puts current_chapter.to_h
      next
    when SUBCHAPTER_RE
      next unless current_chapter
      current_subchapter = OpenStruct.new(row.match(SUBCHAPTER_RE).named_captures)
      current_subchapter.name.strip!
      current_subchapter.id = data['subchapters'].size + 1
      current_subchapter.chapterId = current_chapter.id
      data['subchapters'] << current_subchapter.to_h
      # puts current_subchapter.to_h
      next
    when DESEASE_RE
      current_disease = OpenStruct.new(row.match(DESEASE_RE).named_captures)
      current_disease.subchapterId = current_subchapter.id if current_subchapter
      current_disease.chapterId = current_chapter.id
      current_disease.name.strip!
      current_disease.longName = [current_chapter, current_subchapter, current_disease].compact.map(&:name).join(' | ')
      # puts "DUPLICATE #{row}" if data['diseases'].any?{|d| d['id'] == current_disease.id}
      data['diseases'] << current_disease.to_h
      # puts current_disease
    else
      puts "UNEXPECTED row [#{row_n}]: #{row}"
    end
  end
rescue RuntimeError => e
  fail(e)
end
basename = File.basename(ARGV[0], ".*" )
File.open("#{basename}.json", "w") {|f| f.write(data.to_json) }
# puts data.to_json

