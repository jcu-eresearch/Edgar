module Classification
  # XXX
  # NOTE: Ensure that these are always SQL safe. Don't make these dynamic.

  ALL_CLASSIFICATIONS = [:unknown, :invalid, :historic, :vagrant, :irruptive, :core, :introduced]
  STANDARD_CLASSIFICATIONS = [:unknown, :historic, :vagrant, :irruptive, :core, :introduced]

  def self.serializable_hash(classification)
    colour = case(classification.to_sym)
    when :unknown               then "#000000"
    when :invalid, :doubtful    then "#cc0000"
    when :historic              then "#997722"
    when :vagrant               then "#ff7700"
    when :irruptive             then "#ff66aa"
    when :core                  then "#0022ff"
    when :introduced            then "#7700ff"
    when :other                 then "#ff7700"
    else                             "#ffffff"
    end

    {
      fill_color:     colour,
      stroke_color:   colour,
      font_color:     colour,
      classification: classification,
    }
  end
end
