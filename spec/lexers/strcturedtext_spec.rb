# -*- coding: utf-8 -*- #
# frozen_string_literal: true

describe Rouge::Lexers::StructuredText do
  let(:subject) { Rouge::Lexers::StructuredText.new }

  describe 'guessing' do
    include Support::Guessing

    it 'guesses by filename' do
      # *.st needs source hints bcause it's also used by smallTalk
      assert_guess :filename => 'foo.st', :source => 'END_PROGRAM'
    end

    it 'guesses by mimetype' do
      assert_guess :mimetype => 'text/x-structuretext'
    end
  end
end
