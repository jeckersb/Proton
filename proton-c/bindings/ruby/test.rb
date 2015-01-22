require 'qpid_proton'

class Farkle

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

rubyrefs = []
rubyref_class = nil

MAXIMUM = 100000

puts "Creating #{MAXIMUM} objects."

(1..MAXIMUM).each do |which|
  rubyref = Cproton.pn_rubyref
  rubyref_class = rubyref.class if rubyref_class.nil?
  farkle = Farkle.new(which, rubyref)
  Cproton.pn_rubyref_set_ruby_object(rubyref, Cproton.pn_rb2void(farkle))
  rubyrefs << rubyref

  # add an extra, empty rubyref
  rubyrefs << Cproton.pn_rubyref

  # release objects if we're past the threshold
  while rubyrefs.size > (MAXIMUM / 10).to_i
    # puts "Deleting a reference."
    discarded = rubyrefs.delete_at(0)
    Cproton.pn_rubyref_free(discarded)
  end
end

puts "Running garbage collection."
GC.start

puts "Counting..."
count = 0
rubyrefs.each {|rubyref| count += 1 unless Cproton.pn_void2rb(Cproton.pn_rubyref_get_ruby_object(rubyref)).nil? }

puts "There are #{rubyrefs.size} references, of which #{count} have Farkles."
puts "There are #{ObjectSpace.each_object(Farkle).count} Farkles."
puts "There are #{ObjectSpace.each_object(rubyref_class).count} rubyrefs."

# puts "Let's look at them:"
# rubyrefs.each do |rubyref|
#   puts "     #{Cproton.pn_void2rb(Cproton.pn_rubyref_get_ruby_object(rubyref))}"
# end

rubyrefs.each do |rubyref|
  Cproton.pn_rubyref_free(rubyref)
end

puts "Sleeping for a bit..."

sleep 10

puts "There are #{rubyrefs.size} objects in the rubyrefs array."
puts "There are #{ObjectSpace.each_object(Farkle).count} Farkles."
puts "There are #{ObjectSpace.each_object(rubyref_class).count} rubyrefs."
