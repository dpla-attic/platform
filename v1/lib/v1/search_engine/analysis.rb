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
                'filter' => ['pattern_replace', 'lowercase']
              },
            },
            'filter' => {
              'pattern_replace' => {
                'type' => 'pattern_replace',
                'pattern' => '^[\\W&&[^\\s]]+',
                'replacement' => '',
              }
            }
          }
        }
      end

    end

  end

end
