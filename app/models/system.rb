class System < ActiveRecord::Base
  has_many :locales
  
  def to_hash
    locales.each_with_object({}) do |locale, system|
      system[locale.name] = locale.to_hash
    end
  end
  
  def dump
    File.open(location + "/locales.yml", "w+") { |f| YAML.dump(to_hash, f) }
  end
end
