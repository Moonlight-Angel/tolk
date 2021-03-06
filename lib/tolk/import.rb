module Tolk
  module Import
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def import_secondary_locales
        locales = Dir.entries(self.locales_config_path)

        locale_block_filter = Proc.new {
          |l| ['.', '..'].include?(l) ||
            !l.ends_with?('.yml') ||
            (Tolk.config.block_xxx_en_yml_locale_files && l.match(/(.*\.){2,}/)) # reject files of type xxx.en.yml
        }
        locales = locales.reject(&locale_block_filter)

        primary_locale = Tolk::Locale.primary_locale.name
        locales.each { |l|
          locale_name = File.basename(l, File.extname(l)).split('.').last
          next if locale_name == primary_locale
          import_locale(locale_name, l)
        }
      end

      def import_locale(locale_name, locale_path)
        locale = Tolk::Locale.where(name: locale_name).first_or_create
        data = locale.read_locale_file(locale_path)
        return unless data

        phrases = Tolk::Phrase.all
        count = 0

        data.each do |key, value|
          phrase = phrases.detect {|p| p.key == key}

          if phrase
            translation = locale.translations.new(:text => value, :phrase => phrase)
            if translation.save
              count = count + 1
            elsif translation.errors[:variables].present?
              puts "[WARN] Key '#{key}' from '#{locale_path}.yml' could not be saved: #{translation.errors[:variables].first}"
            end
          else
            puts "[ERROR] Key '#{key}' was found in '#{locale_path}.yml' but #{Tolk::Locale.primary_language_name} translation is missing"
          end
        end

        puts "[INFO] Imported #{count} keys from #{locale_path}"
      end

    end

    def read_locale_file(filename)
      locale_file = "#{self.locales_config_path}/#{filename}"
      raise "Locale file #{locale_file} does not exists" unless File.exists?(locale_file)

      puts "[INFO] Reading #{locale_file} for locale #{self.name}"
      begin
        self.class.flat_hash(Tolk::YAML.load_file(locale_file)[self.name])
      rescue
        puts "[ERROR] File #{locale_file} expected to declare #{self.name} locale, but it does not. Skipping this file."
        nil
      end

    end

  end
end
