require 'qpid_proton'

class Farkle

  attr_accessor :parent

  def initialize(value, parent)
    # puts "Creating a farkle with a value of #{value}..."
    @value = value
    @parent = parent
    # ObjectSpace.define_finalizer(self, self.class.finalize!(value))
  end

  def self.finalize!(value)
    proc {
      puts "I'm deleting my #{value}!"
    }
  end

  def to_s
    "value=#{@value}"
  end

end

$rubyrefs = []
$rubyref_class = nil

MAXIMUM = 100000

puts "Creating #{MAXIMUM} objects."

(1...MAXIMUM).each do |which|
  rubyref = Cproton::RubyRef.new
  $rubyref_class = rubyref.class if $rubyref_class.nil?
  farkle = Farkle.new(which, rubyref)
  rubyref.object = farkle
  $rubyrefs << rubyref
  rubyref = nil

  # add an extra, empty rubyref
  $rubyrefs << Cproton::RubyRef.new

  # release objects if we're past the threshold
  while $rubyrefs.size >= (MAXIMUM / 10).to_i
    # puts "Deleting a reference."
    discarded = $rubyrefs.delete_at(0)
    discarded.object.parent = nil unless discarded.object.nil?
    # Cproton.pn_rubyref_free(discarded)
  end
end

puts "Running garbage collection."
GC.start

puts "Some sample references:"
$rubyrefs.each { |rubyref| puts rubyref.object unless rubyref.object.nil? }

def object_status
  puts "Counting..."
  count = 0
  $rubyrefs.each {|rubyref| count += 1 unless rubyref.object.nil? }

  puts "There are #{$rubyrefs.size} references, of which #{count} have Farkles."
  puts "There are #{ObjectSpace.each_object(Farkle).count} Farkles."
  puts "There are #{ObjectSpace.each_object($rubyref_class).count} rubyrefs."
end

object_status

puts "Sleeping for a bit..."

sleep 10

puts "Emptying out our array..."
$rubyrefs.clear
puts "Running garbage collection."
GC.start

object_status
