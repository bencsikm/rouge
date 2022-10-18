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
      <<-DOC
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
      DOC

      keywords = %w(
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
      )



      keywords_type =  %w(
        array pointer int sint dint lint usint uint udint ulint real lreal
        time date time_of_day date_and_time dt tod 
        wstring string bool byte word dword lword ref_to any_num any_int any_string
        char wchar bsint bint bdint hsint hint hdint
      )



      name_function = %w(
        abs acos asin atan cos exp ln log sin sqrt tan sizeof
        shl shr sar rol ror mod
      )

      state :root do
        mixin :whitespace
        
      end

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
        rule %r/(?<!_)(?:(#{keywords.join('|')}))(?=\s|;)/i, Keyword
        rule %r/(\/\/.+)/, Comment::Single
        rule %r/.+/i, Other
      end



      <<-DOC
      =begin
      # old code for examples

      start { push :bol }

      state :expr_bol do
        mixin :inline_whitespace

        rule %r/#if\s0/, Comment, :if_0
        rule %r/#/, Comment::Preproc, :macro

        rule(//) { pop! }
      end

      # :expr_bol is the same as :bol but without labels, since
      # labels can only appear at the beginning of a statement.
      state :bol do
        #remove \ in front of # below
        rule %r/\#{id}:(?!:)/, Name::Label
        mixin :expr_bol
      end

      state :inline_whitespace do
        rule %r/[ \t\r]+/, Text
        rule %r/\\\n/, Text # line continuation
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :whitespace do
        rule %r/\n+/m, Text, :bol
        rule %r(//(\\.|.)*?$), Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :expr_whitespace do
        rule %r/\n+/m, Text, :expr_bol
        mixin :whitespace
      end

      state :statements do
        mixin :whitespace
        rule %r/(u8|u|U|L)?"/, Str, :string
        rule %r((u8|u|U|L)?'(\\.|\\[0-7]{1,3}|\\x[a-f0-9]{1,2}|[^\\'\n])')i, Str::Char
        rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
        rule %r(\d+e[+-]?\d+[lu]*)i, Num::Float
        rule %r/0x[0-9a-f]+[lu]*/i, Num::Hex
        rule %r/0[0-7]+[lu]*/i, Num::Oct
        rule %r/\d+[lu]*/i, Num::Integer
        rule %r(\*/), Error
        rule %r([~!%^&*+=\|?:<>/-]), Operator
        rule %r/[()\[\],.;]/, Punctuation
        rule %r/\bcase\b/, Keyword, :case
        rule %r/(?:true|false|NULL)\b/, Name::Builtin
        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          elsif self.class.builtins.include? name
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :case do
        rule %r/:/, Punctuation, :pop!
        mixin :statements
      end

      state :root do
        mixin :expr_whitespace
        rule %r(
          ([\w*\s]+?[\s*]) # return arguments
          ( # {id})          # function name
          (\s*\([^;]*?\))  # signature
          (# {ws}?)({|;)    # open brace or semicolon
        )mx do |m|
          # TODO: do this better.
          recurse m[1]
          token Name::Function, m[2]
          recurse m[3]
          recurse m[4]
          token Punctuation, m[5]
          if m[5] == ?{
            push :function
          end
        end
        rule %r/\{/, Punctuation, :function
        mixin :statements
      end

      state :function do
        mixin :whitespace
        mixin :statements
        rule %r/;/, Punctuation
        rule %r/{/, Punctuation, :function
        rule %r/}/, Punctuation, :pop!
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\\n/, Str
        rule %r/\\/, Str # stray backslash
      end

      state :macro do
        mixin :include
        rule %r([^/\n\\]+), Comment::Preproc
        rule %r/\\./m, Comment::Preproc
        mixin :inline_whitespace
        rule %r(/), Comment::Preproc
        # NB: pop! goes back to :bol
        rule %r/\n/, Comment::Preproc, :pop!
      end

      state :include do
        rule %r/(include)(\s*)(<[^>]+>)([^\n]*)/ do
          groups Comment::Preproc, Text, Comment::PreprocFile, Comment::Single
        end
        rule %r/(include)(\s*)("[^"]+")([^\n]*)/ do
          groups Comment::Preproc, Text, Comment::PreprocFile, Comment::Single
        end
      end

      state :if_0 do
        # NB: no \b here, to cover #ifdef and #ifndef
        rule %r/^\s*#if/, Comment, :if_0
        rule %r/^\s*#\s*el(?:se|if)/, Comment, :pop!
        rule %r/^\s*#\s*endif\b.*?(?<!\\)\n/m, Comment, :pop!
        rule %r/.*?\n/, Comment
      end

      =end 
      DOC
    end
  end
end
