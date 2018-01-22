require 'json'
require 'ostruct'
require "byebug"

file_icd9 = (ARGV[0] || exit(1))
file_icd9_cm = (ARGV[1] || exit(1))

ITEM_ID_RE = /((\d{3})|(V\d{2})|(E\d{3}))/
CHAPTER_RE = /^(?<id>\d{1,2})\.\s\s(?<name>[A-Z0-9 ,-]+)\s?\((?<from>\d{3})\-(?<to>\d{3})\)$/
CHAPTER_VE_RE = /^(?<name>(SUPPLEMENTARY CLASSIFICATION).+)\s?\((?<from>((V\d{2})|(E\d{3})))(\-(?<to>((V\d{2})|(E\d{3}))))?\)$/
SUBCHAPTER_RE = /^(?<name>[A-Z0-9 ,-]+)\s?\((?<from>#{ITEM_ID_RE})(\-(?<to>#{ITEM_ID_RE}))?\)$/
DESEASE_RE = /^(?<id>[VE]?\d+)\s+(?<name>.+)$/

data = {
  'chapters' => [],
  'subchapters' => [],
  'diseases' => []
}
csc = cc = nil
csc_counter = 0
chapter_index = []
subchapter_index = []
row_n = 0

begin
  File.readlines(file_icd9).each do |row|
    row_n += 1
    row.strip!
    case row
    when CHAPTER_RE
      csc = nil
      csc_counter = 0
      cc = OpenStruct.new(row.match(CHAPTER_RE).named_captures)
      cc.name.strip!
      cc.from = cc.from.to_i
      cc.to = (cc.to || cc.from).to_i
      data['chapters'] << cc.to_h
      (cc.from..cc.to).step(1).each{|i| chapter_index[i] = cc.id}
      # puts cc.to_h
      next
    when CHAPTER_VE_RE
      csc = nil
      csc_counter = 0
      cc = OpenStruct.new(row.match(CHAPTER_VE_RE).named_captures)
      cc.name.strip!
      cc.id = data['chapters'].size + 1
      cc.from = cc.from.to_i
      cc.to = (cc.to || cc.from).to_i
      data['chapters'] << cc.to_h
      (cc.from..cc.to).step(1).each{|i| chapter_index[i] = cc.id}
       # puts cc.to_h
      # puts row
      next
    when SUBCHAPTER_RE
      next unless cc
      csc_counter += 1
      csc = OpenStruct.new(row.match(SUBCHAPTER_RE).named_captures)
      csc.name.strip!
      csc.id = "#{cc.id}-#{csc_counter}"
      csc.from = csc.from.to_i
      csc.to = (csc.to || csc.from).to_i
      csc.chapterId = cc.id
      data['subchapters'] << csc.to_h
      (csc.from..csc.to).step(1).each{|i| subchapter_index[i] = csc.id}
       # puts csc.to_h
      # puts row
      next
    else
      # puts "UNEXPECTED row [#{row_n}]: #{row}"
    end
  end
rescue RuntimeError => e
  fail(e)
end

begin
  File.readlines(file_icd9_cm, :encoding => 'iso-8859-1').each do |row|
    row.strip!
    current_disease = OpenStruct.new(row.match(DESEASE_RE).named_captures)
    current_disease.id.insert(3,'.')
    area_id = current_disease.id.split('.').first.to_i
    current_disease.chapterId = chapter_index[area_id]
    current_disease.subchapterId = subchapter_index[area_id]
    data['diseases'] << current_disease.to_h
  end
rescue RuntimeError => e
  fail(e)
end

File.open("data.json", "w") {|f| f.write(data.to_json) }

