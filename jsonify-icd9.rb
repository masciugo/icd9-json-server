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
      cc.from = cc.from
      cc.to = (cc.to || cc.from)
      data['chapters'] << cc
      # puts cc
      next
    when CHAPTER_VE_RE
      csc = nil
      csc_counter = 0
      cc = OpenStruct.new(row.match(CHAPTER_VE_RE).named_captures)
      cc.name.strip!
      cc.id = data['chapters'].size + 1
      cc.from = cc.from
      cc.to = (cc.to || cc.from)
      data['chapters'] << cc
       # puts cc
      # puts row
      next
    when SUBCHAPTER_RE
      next unless cc
      csc_counter += 1
      csc = OpenStruct.new(row.match(SUBCHAPTER_RE).named_captures)
      csc.name.strip!
      csc.id = "#{cc.id}-#{csc_counter}"
      csc.to ||= csc.from
      csc.chapterId = cc.id
      data['subchapters'] << csc
       # puts csc
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
    cd = OpenStruct.new(row.match(DESEASE_RE).named_captures)
    area_id = cd.id[0..(cd.id.start_with?('E') ? 3 : 2)]
    c = data['chapters'].find{|c| area_id.between?(c.from,c.to)}
    cd.chapterId = c.id
    sc = data['subchapters'].find{|sc| area_id.between?(sc.from,sc.to)}
    cd.subchapterId = sc.id if sc
    cd.longName = [c, sc, cd].compact.map(&:name).join(' | ')
    data['diseases'] << cd
  end
rescue RuntimeError => e
  fail(e)
end

data['chapters'].map!(&:to_h)
data['subchapters'].map!(&:to_h)
data['diseases'].map!(&:to_h)

File.open("data.json", "w") {|f| f.write(data.to_json) }

