module Twine
  module Formatters
    class Rails < Abstract
      FORMAT_NAME = 'rails'
      EXTENSION = '.yml'
      DEFAULT_FILE_NAME = 'localize.yml'

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^.+\.yml$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /^((.+)-)?([^-]+)\.yml$/.match(segment)
          if match
            return match[3]
          end
        end

        return
      end

      def read_file(path, lang)
        begin
          require "yaml"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install yaml' in order to read or write Rails YAML files."
        end

        yaml = YAML.load_file(path)
        yaml[lang].each do |key, value|
          new_key = key.gsub("\n","\\n")
          value.gsub!("\n","\\n")
          value.gsub!(/%(?!([0-9]+\$)?(@|d|l|i))/, '%%')   # handle literal percentage signs for iOS/Android
          set_translation_for_key(new_key, lang, value)
        end
      end

      def write_file(path, lang)
        begin
          require "json"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install yaml' in order to read or write Rails YAML files."
        end

        printed_string = false
        default_lang = @strings.language_codes[0]
        encoding = @options[:output_encoding] || 'UTF-8'
        File.open(path, "w:#{encoding}") do |f|
          f.print "\"#{lang}\":\n"

          @strings.sections.each_with_index do |section, si|
            section.rows.each_with_index do |row, ri|
              if row.matches_tags?(@options[:tags], @options[:untagged])
                if printed_string
                  f.print "\n"
                end

                key = row.key
                key = key.gsub('"', '\\\\"')

                value = row.translated_string_for_lang(lang, default_lang)
                value = value.gsub('"', '\\\\"')
                value = value.gsub('%%', '%')   # handle literal percentage signs from iOS/Android

                f.print "  \"#{key}\": \"#{value}\""
                printed_string = true
              end
            end
          end
          f.puts "\n"

        end
      end
    end
  end
end
