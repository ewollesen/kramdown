# -*- coding: utf-8 -*-
#
#--
# Copyright (C) 2009-2010 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown.
#
# kramdown is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
#

require 'kramdown/parser/kramdown'

module Kramdown

  module Parser

    # Used for parsing a document in Markdown format.
    #
    # This parser is based on the kramdown parser and removes the parser methods for the additional
    # non-Markdown features. However, since some things are handled differently by the kramdown
    # parser methods (like deciding when a list item contains just text), this parser differs from
    # real Markdown parsers in some respects.
    #
    # Note, though, that the parser basically fails just one of the Markdown test cases (some others
    # also fail but those failures are negligible).
    class Markdown < Kramdown

      # Array with all the parsing methods that should be removed from the standard kramdown parser.
      EXTENDED = [:codeblock_fenced, :table, :definition_list, :footnote_definition, :abbrev_definition, :block_math,
                  :block_extensions,
                  :footnote_marker, :smart_quotes, :inline_math, :span_extensions, :typographic_syms]

      def initialize(source, options) # :nodoc:
        super
        @block_parsers.delete_if {|i| EXTENDED.include?(i)}
        @span_parsers.delete_if {|i| EXTENDED.include?(i)}
      end

      # :stopdoc:

      BLOCK_BOUNDARY = /#{BLANK_LINE}|#{EOB_MARKER}|\Z/
      BLOCKQUOTE_MATCH = /(^.*\n)+?(?=#{BLANK_LINE}|#{EOB_MARKER}|^#{OPT_SPACE}#{LAZY_END_HTML_STOP}|^#{OPT_SPACE}#{LAZY_END_HTML_START}|\Z)/
      CODEBLOCK_MATCH = /(?:#{BLANK_LINE}?(?:#{INDENT}[ \t]*\S.*\n)+)*/
      PARAGRAPH_MATCH = BLOCKQUOTE_MATCH

      IAL_RAND_CHARS = (('a'..'z').to_a + ('0'..'9').to_a)
      IAL_RAND_STRING = (1..20).collect {|a| IAL_RAND_CHARS[rand(IAL_RAND_CHARS.size)]}.join
      LIST_ITEM_IAL = /^\s*(#{IAL_RAND_STRING})?\s*\n/
      IAL_SPAN_START = LIST_ITEM_IAL

      # :startdoc:

    end

  end

end
