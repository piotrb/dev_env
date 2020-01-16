# frozen_string_literal: true

class StatefulParser
  def initialize(normalizer: nil)
    @state = :none
    @states = []
    @normalizer = normalizer
  end

  def state(name, match, applies_to = [:none])
    @states << [name, match, applies_to]
  end

  def parse(line)
    normalized_line = @normalizer ? @normalizer.call(line) : line
    matchers = @states.select { |s| s.last.include?(@state) || s.last.include?(:any) }
    new_state = nil
    matchers.each do |(name, match, _applies_to)|
      next unless normalized_line =~ match
      if new_state
        raise "multiple state transitions match: #{[new_state, name].inspect}"
      end

      new_state = name
    end
    @state = new_state if new_state
    yield @state, line
  end

  def parse_string(string, &block)
    string.each_line do |line|
      parse(line, &block)
    end
  end
end
