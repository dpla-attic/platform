module V1

  module SearchEngine

    module Analysis

      def self.for_new_index
        {
          'analysis' => {
            'analyzer' => {
              'canonical_sort' => {
              'type' => 'custom',
                'tokenizer' => 'keyword',
                'filter' => ['lowercase', 'pattern_replace'],
              },
            },
            'filter' => {
              'pattern_replace' => {
                'type' => 'pattern_replace',
                # any combination of layered leading non-alphanumerics and/or leading stopwords: a, an, the
                'pattern' => '^([^a-z0-9]+|a\b|an\b|the\b)*',
                'replacement' => '',
              }
            }
          }
        }
      end

    end

  end

end
