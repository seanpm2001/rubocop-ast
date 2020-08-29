# frozen_string_literal: true

require_relative 'parser.racc'

module RuboCop
  module AST
    class NodePattern
      # Parser for NodePattern
      # Note: class reopened in `parser.racc`
      class Parser < Racc::Parser
        extend Forwardable

        Builder = NodePattern::Builder
        Lexer = NodePattern::Lexer

        def initialize(builder = self.class::Builder.new)
          super()
          @builder = builder
        end

        ##
        # (Similar API to `parser` gem)
        # Parses a source and returns the AST.
        #
        # @param [Parser::Source::Buffer, String] source_buffer The source buffer to parse.
        # @return [NodePattern::Node]
        #
        def parse(source)
          @lexer = self.class::Lexer.new(source)
          ast = do_parse
          return ast unless block_given?

          yield ast, @lexer
        rescue Lexer::Error => e
          raise NodePattern::Invalid, e.message
        ensure
          @lexer = nil # Don't keep references
        end

        def inspect
          "<##{self.class}>"
        end

        private

        def_delegators :@builder, :emit_list, :emit_unary_op, :emit_atom, :emit_capture, :emit_call
        def_delegators :@lexer, :next_token

        # Overrides Racc::Parser's method:
        def on_error(token, val, _vstack)
          detail = token_to_str(token) || '?'
          raise NodePattern::Invalid, "parse error on value #{val.inspect} (#{detail})"
        end
      end
    end
  end
end
