# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class StructuredText < RegexLexer
      title "Structured Text"
      desc "IEC 61131-3 Structured Text programming language"

      tag 'structuredtext'
      aliases 'iecst', 'scl', 'stl', 'structured-text'
      filenames '*.st'
      
      mimetypes 'text/x-structuretext'

      

      # optional comment or whitespace
      #ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
      #id = /[a-zA-Z_][a-zA-Z0-9_]*/
      
      def self.keywords    
        @keywords ||= Set.new %w(
          if then end_if elsif else case of end_case
          to do by while repeat until end_while end_repeat for end_for from
          public private protected retain non_retain internal constant
          or and not xor le ge eq ne ge lt
          return exit at task with using extend
          nil true false
          action end_action
          program end_program function end_function function_block end_function_block configuration
          end_configuration  transition end_transition type end_type struct end_struct step
          end_step initial_step namespace end_namespace channel end_channel library end_library folder end_folder resource end_resource
          var var_global end_var var_input var_external var_out var_output var_in_out var_temp var_interval var_access var_config
          method end_method property end_property interface end_interface
          virtual global
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          array pointer int sint dint lint usint uint udint ulint real lreal
          time date time_of_day date_and_time dt tod 
          wstring string bool byte word dword lword ref_to any_num any_int any_string
          char wchar bsint bint bdint hsint hint hdint
        )
      end

      def self.name_function
        @name_function ||= Set.new %w(
          abs acos asin atan cos exp ln log sin sqrt tan sizeof
          shl shr sar rol ror mod
        )
      end

      # to_real, to_dint, etc. are these apart of actual language?

      state :root do
        rule %r/(\/\/.+)/, Comment::Single
        rule %r/(\(\*)/, Comment::Multiline, :comment_multi
        mixin :blocks
        rule %r/"/, Literal::String, :string
        rule %r/'/, Literal::String::Char, :char
        # Address of
        # constants
        # precompiler statements
        mixin :whitespace
        
      end

      state :comment_multi do
        rule %r/(\*\))/, Comment::Multiline, :pop!
        rule %r/./, Comment::Multiline
      end

      state :blocks do
        rule %r/(\w)*/i do |m|
          name = m[0].downcase
          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.name_function.include? name
            token Name::Function
          else
            token Name
          end
        end
      end

      state :string do
        rule %r/"/, Literal::String, :pop!
        rule %r/./, Literal::String
      end

      state :char do
        rule %r/'/, Literal::String::Char, :pop!
        rule %r/./, Literal::String::Char
      end


      

      state :whitespace do
        rule %r/\s/, Text::Whitespace
        rule %r/./i, Other
      end

    end
  end
end
