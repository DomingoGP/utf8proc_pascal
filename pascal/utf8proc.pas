unit utf8proc;

{*
 * Pascal translation of the utf8proc library plus some additions: 2025 Domingo Galmés
 * See https://github.com/JuliaStrings/utf8proc
 *     http://juliastrings.github.io/utf8proc/
 *
 * Original license of the C version.
}

{
 * Copyright (c) 2014-2021 Steven G. Johnson, Jiahao Chen, Peter Colberg, Tony Kelman, Scott P. Jones, and other contributors.
 * Copyright (c) 2009 Public Software Group e. V., Berlin, Germany
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
}

{*
 *  This library contains derived data from the
 *  Unicode data files.
 *
 *  The original data files are available at
 *  http://www.unicode.org/Public/UNIDATA/
 *
 *  Please notice the copyright statement in the file "utf8proc_data.inc".
 *
}

{*
 * @mainpage
 *
 * utf8proc is a free/open-source (MIT/expat licensed) C library
 * providing Unicode normalization, case-folding, and other operations
 * for strings in the UTF-8 encoding, supporting up-to-date Unicode versions.
 * See the utf8proc home page (http://julialang.org/utf8proc/)
 * for downloads and other information, or the source code on github
 * (https://github.com/JuliaLang/utf8proc).
 *
 * For the utf8proc API documentation, see: @ref utf8proc.h
 *
 * The features of utf8proc include:
 *
 * - Transformation of strings (utf8proc_map()) to:
 *    - decompose (@ref UTF8PROC_DECOMPOSE) or compose (@ref UTF8PROC_COMPOSE) Unicode combining characters (http://en.wikipedia.org/wiki/Combining_character)
 *    - canonicalize Unicode compatibility characters (@ref UTF8PROC_COMPAT)
 *    - strip "ignorable" (@ref UTF8PROC_IGNORE) characters, control characters (@ref UTF8PROC_STRIPCC), or combining characters such as accents (@ref UTF8PROC_STRIPMARK)
 *    - case-folding (@ref UTF8PROC_CASEFOLD)
 * - Unicode normalization: utf8proc_NFD(), utf8proc_NFC(), utf8proc_NFKD(), utf8proc_NFKC()
 * - Detecting grapheme boundaries (utf8proc_grapheme_break() and @ref UTF8PROC_CHARBOUND)
 * - Character-width computation: utf8proc_charwidth()
 * - Classification of characters by Unicode category: utf8proc_category() and utf8proc_category_string()
 * - Encode (utf8proc_encode_char()) and decode (utf8proc_iterate()) Unicode codepoints to/from UTF-8.
 }


{$ifdef FPC}
{$mode delphi}
{$MACRO ON}
{$POINTERMATH ON}
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}
{$endif}

interface

uses
  Classes, SysUtils;


{* @name API version
 *
 * The utf8proc API version MAJOR.MINOR.PATCH, following
 * semantic-versioning rules (http://semver.org) based on API
 * compatibility.
 *
 * This is also exited at runtime by utf8proc_version(); however, the
 * runtime version may append a string like "-dev" to the version number
 * for prerelease versions.
 *
 * @note The shared-library version number in the Makefile
 *       (and CMakeLists.txt, and MANIFEST) may be different,
 *       being based on ABI compatibility rather than API compatibility.
}

  {* The MAJOR version number (increased when backwards API compatibility is broken).}
const
  UTF8PROC_VERSION_MAJOR = 2;
  { The MINOR version number (increased when new functionality is added in a backwards-compatible manner).}
  UTF8PROC_VERSION_MINOR = 11;
  { The PATCH version (increased for fixes that do not change the API).}
  UTF8PROC_VERSION_PATCH = 0;
  UTF8PROC_VERSION_STR = '2.11.0';
  UTF8PROC_UNICODE_VERSION_STR = '17.0.0';

type

  utf8proc_int8_t = int8;
  //utf8proc_uint8_t=byte;

  //Putf8proc_uint8_t=PByte;
  //PPutf8proc_uint8_t=^Putf8proc_uint8_t;

  utf8proc_int16_t = int16;
  utf8proc_uint16_t = uint16;
  Putf8proc_uint16_t = ^utf8proc_uint16_t;
  PPutf8proc_uint16_t = ^Putf8proc_uint16_t;

  utf8proc_int32_t = int32;
  Putf8proc_int32_t = ^utf8proc_int32_t;
  PPutf8proc_int32_t = ^Putf8proc_int32_t;
  utf8proc_uint32_t = uint32;

  utf8proc_size_t = size_t;
  utf8proc_ssize_t = PtrInt;
  //utf8proc_boolean=boolean;

{
 * Option flags used by several functions in the library.
}
  utf8proc_option_t = DWORD;

const
  { The given UTF-8 input is nil terminated.}
  UTF8PROC_NULLTERM = (1 shl 0);
  { Unicode Versioning Stability has to be respected.}
  UTF8PROC_STABLE = (1 shl 1);
  { Compatibility decomposition (i.e. formatting information is lost).}
  UTF8PROC_COMPAT = (1 shl 2);
  { exit a result with composed characters. }
  UTF8PROC_COMPOSE = (1 shl 3);
  { exit a result with decomposed characters.}
  UTF8PROC_DECOMPOSE = (1 shl 4);
  { Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE.}
  UTF8PROC_IGNORE = (1 shl 5);
  { exit an error, if the input contains unassigned codepoints. }
  UTF8PROC_REJECTNA = (1 shl 6);
  {
   * Indicating that NLF-sequences (LF, CRLF, CR, NEL) are representing a
   * line break, and should be converted to the codepoint for line
   * separation (LS).
  }
  UTF8PROC_NLF2LS = (1 shl 7);
  {
   * Indicating that NLF-sequences are representing a paragraph break, and
   * should be converted to the codepoint for paragraph separation
   * (PS).
   }
  UTF8PROC_NLF2PS = (1 shl 8);
  { Indicating that the meaning of NLF-sequences is unknown.}
  UTF8PROC_NLF2LF = UTF8PROC_NLF2LS or UTF8PROC_NLF2PS;
  { Strips and/or convers control characters.
   *
   * NLF-sequences are transformed into space, except if one of the
   * NLF2LS/PS/LF options is given. HorizontalTab (HT) and FormFeed (FF)
   * are treated as a NLF-sequence in this case.  All other control
   * characters are simply removed.
   }
  UTF8PROC_STRIPCC = (1 shl 9);
  {
   * Performs unicode case folding, to be able to do a case-insensitive
   * string comparison.
  }
  UTF8PROC_CASEFOLD = (1 shl 10);
  {
   * Inserts $FF bytes at the beginning of each sequence which is
   * representing a single grapheme cluster (see UAX#29).
  }
  UTF8PROC_CHARBOUND = (1 shl 11);
  { Lumps certain characters together.
   *
   * E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-". See lump.md for details.
   *
   * If NLF2LF is set, this includes a transformation of paragraph and
   * line separators to ASCII line-feed (LF).
  }
  UTF8PROC_LUMP = (1 shl 12);
  { Strips all character markings.
   *
   * This includes non-spacing, spacing and enclosing (i.e. accents).
   * @note This option works only with @ref UTF8PROC_COMPOSE or
   *       @ref UTF8PROC_DECOMPOSE
  }
  UTF8PROC_STRIPMARK = (1 shl 13);
  {
   * Strip unassigned codepoints.
  }
  UTF8PROC_STRIPNA = (1 shl 14);

{ @name Error codes
 * Error codes being exited by almost all functions.
}

  { Memory could not be allocated.}
const
  UTF8PROC_ERROR_NOMEM = -1;
  { The given string is too long to be processed.}
const
  UTF8PROC_ERROR_OVERFLOW = -2;
  { The given string is not a legal UTF-8 string. }
const
  UTF8PROC_ERROR_INVALIDUTF8 = -3;
  { The @ref UTF8PROC_REJECTNA flag was set and an unassigned codepoint was found. }
const
  UTF8PROC_ERROR_NOTASSIGNED = -4;
  { Invalid options have been used. }
const
  UTF8PROC_ERROR_INVALIDOPTS = -5;

  { @name Types }

  { Holds the value of a property. }
type
  utf8proc_propval_t = utf8proc_int16_t;

  { Boundclass property. (TR29) }
  utf8proc_boundclass_type_t = DWORD;

const
  UTF8PROC_BOUNDCLASS_START = 0; {< Start }
  UTF8PROC_BOUNDCLASS_OTHER = 1; {< Other }
  UTF8PROC_BOUNDCLASS_CR = 2; {< Cr }
  UTF8PROC_BOUNDCLASS_LF = 3; {< Lf }
  UTF8PROC_BOUNDCLASS_CONTROL = 4; {< Control }
  UTF8PROC_BOUNDCLASS_EXTEND = 5; {< Extend }
  UTF8PROC_BOUNDCLASS_L = 6; {< L }
  UTF8PROC_BOUNDCLASS_V = 7; {< V }
  UTF8PROC_BOUNDCLASS_T = 8; {< T }
  UTF8PROC_BOUNDCLASS_LV = 9; {< Lv }
  UTF8PROC_BOUNDCLASS_LVT = 10; {< Lvt }
  UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR = 11; {< Regional indicator }
  UTF8PROC_BOUNDCLASS_SPACINGMARK = 12; {< Spacingmark }
  UTF8PROC_BOUNDCLASS_PREPEND = 13; {< Prepend }
  UTF8PROC_BOUNDCLASS_ZWJ = 14; {< Zero Width Joiner }

    { the following are no longer used in Unicode 11, but we keep
       the constants here for backward compatibility }
  UTF8PROC_BOUNDCLASS_E_BASE = 15; {< Emoji Base }
  UTF8PROC_BOUNDCLASS_E_MODIFIER = 16; {< Emoji Modifier }
  UTF8PROC_BOUNDCLASS_GLUE_AFTER_ZWJ = 17; {< Glue_After_ZWJ }
  UTF8PROC_BOUNDCLASS_E_BASE_GAZ = 18; {< E_BASE + GLUE_AFTER_ZJW }

    { the Extended_Pictographic property is used in the Unicode 11
       grapheme-boundary rules, so we store it in the boundclass field }
  UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC = 19;
  UTF8PROC_BOUNDCLASS_E_ZWG = 20; { UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC + ZWJ }
  //);
type
  { Indic_Conjunct_Break property. (TR44) }
  utf8proc_indic_conjunct_break_t = word;

const
  UTF8PROC_INDIC_CONJUNCT_BREAK_NONE = 0;
  UTF8PROC_INDIC_CONJUNCT_BREAK_LINKER = 1;
  UTF8PROC_INDIC_CONJUNCT_BREAK_CONSONANT = 2;
  UTF8PROC_INDIC_CONJUNCT_BREAK_EXTEND = 3;

type
  { Unicode categories. }
  utf8proc_category_t = (
    UTF8PROC_CATEGORY_CN = 0, {< Other, not assigned }
    UTF8PROC_CATEGORY_LU = 1, {< Letter, uppercase }
    UTF8PROC_CATEGORY_LL = 2, {< Letter, lowercase }
    UTF8PROC_CATEGORY_LT = 3, {< Letter, titlecase }
    UTF8PROC_CATEGORY_LM = 4, {< Letter, modifier }
    UTF8PROC_CATEGORY_LO = 5, {< Letter, other }
    UTF8PROC_CATEGORY_MN = 6, {< Mark, nonspacing }
    UTF8PROC_CATEGORY_MC = 7, {< Mark, spacing combining }
    UTF8PROC_CATEGORY_ME = 8, {< Mark, enclosing }
    UTF8PROC_CATEGORY_ND = 9, {< Number, decimal digit }
    UTF8PROC_CATEGORY_NL = 10, {< Number, letter }
    UTF8PROC_CATEGORY_NO = 11, {< Number, other }
    UTF8PROC_CATEGORY_PC = 12, {< Punctuation, connector }
    UTF8PROC_CATEGORY_PD = 13, {< Punctuation, dash }
    UTF8PROC_CATEGORY_PS = 14, {< Punctuation, open }
    UTF8PROC_CATEGORY_PE = 15, {< Punctuation, close }
    UTF8PROC_CATEGORY_PI = 16, {< Punctuation, initial quote }
    UTF8PROC_CATEGORY_PF = 17, {< Punctuation, final quote }
    UTF8PROC_CATEGORY_PO = 18, {< Punctuation, other }
    UTF8PROC_CATEGORY_SM = 19, {< Symbol, math }
    UTF8PROC_CATEGORY_SC = 20, {< Symbol, currency }
    UTF8PROC_CATEGORY_SK = 21, {< Symbol, modifier }
    UTF8PROC_CATEGORY_SO = 22, {< Symbol, other }
    UTF8PROC_CATEGORY_ZS = 23, {< Separator, space }
    UTF8PROC_CATEGORY_ZL = 24, {< Separator, line }
    UTF8PROC_CATEGORY_ZP = 25, {< Separator, paragraph }
    UTF8PROC_CATEGORY_CC = 26, {< Other, control }
    UTF8PROC_CATEGORY_CF = 27, {< Other, format }
    UTF8PROC_CATEGORY_CS = 28, {< Other, surrogate }
    UTF8PROC_CATEGORY_CO = 29 {< Other, private use });


  { Bidirectional character classes. }
  utf8proc_bidi_class_t = (
    UTF8PROC_BIDI_CLASS_NULL = 0, {only for pascal conversion}
    UTF8PROC_BIDI_CLASS_L = 1, {< Left-to-Right }
    UTF8PROC_BIDI_CLASS_LRE = 2, {< Left-to-Right Embedding }
    UTF8PROC_BIDI_CLASS_LRO = 3, {< Left-to-Right Override }
    UTF8PROC_BIDI_CLASS_R = 4, {< Right-to-Left }
    UTF8PROC_BIDI_CLASS_AL = 5, {< Right-to-Left Arabic }
    UTF8PROC_BIDI_CLASS_RLE = 6, {< Right-to-Left Embedding }
    UTF8PROC_BIDI_CLASS_RLO = 7, {< Right-to-Left Override }
    UTF8PROC_BIDI_CLASS_PDF = 8, {< Pop Directional Format }
    UTF8PROC_BIDI_CLASS_EN = 9, {< European Number }
    UTF8PROC_BIDI_CLASS_ES = 10, {< European Separator }
    UTF8PROC_BIDI_CLASS_ET = 11, {< European Number Terminator }
    UTF8PROC_BIDI_CLASS_AN = 12, {< Arabic Number }
    UTF8PROC_BIDI_CLASS_CS = 13, {< Common Number Separator }
    UTF8PROC_BIDI_CLASS_NSM = 14, {< Nonspacing Mark }
    UTF8PROC_BIDI_CLASS_BN = 15, {< Boundary Neutral }
    UTF8PROC_BIDI_CLASS_B = 16, {< Paragraph Separator }
    UTF8PROC_BIDI_CLASS_S = 17, {< Segment Separator }
    UTF8PROC_BIDI_CLASS_WS = 18, {< Whitespace }
    UTF8PROC_BIDI_CLASS_ON = 19, {< Other Neutrals }
    UTF8PROC_BIDI_CLASS_LRI = 20, {< Left-to-Right Isolate }
    UTF8PROC_BIDI_CLASS_RLI = 21, {< Right-to-Left Isolate }
    UTF8PROC_BIDI_CLASS_FSI = 22, {< First Strong Isolate }
    UTF8PROC_BIDI_CLASS_PDI = 23 {< Pop Directional Isolate });

  { Decomposition =. }
  utf8proc_decomp_type_t = byte;

const
  UTF8PROC_DECOMP_TYPE_FONT = 1; {< Font }
  UTF8PROC_DECOMP_TYPE_NOBREAK = 2; {< Nobreak }
  UTF8PROC_DECOMP_TYPE_INITIAL = 3; {< Initial }
  UTF8PROC_DECOMP_TYPE_MEDIAL = 4; {< Medial }
  UTF8PROC_DECOMP_TYPE_FINAL = 5; {< Final }
  UTF8PROC_DECOMP_TYPE_ISOLATED = 6; {< Isolated }
  UTF8PROC_DECOMP_TYPE_CIRCLE = 7; {< Circle }
  UTF8PROC_DECOMP_TYPE_SUPER = 8; {< Super }
  UTF8PROC_DECOMP_TYPE_SUB = 9; {< Sub }
  UTF8PROC_DECOMP_TYPE_VERTICAL = 10; {< Vertical }
  UTF8PROC_DECOMP_TYPE_WIDE = 11; {< Wide }
  UTF8PROC_DECOMP_TYPE_NARROW = 12; {< Narrow }
  UTF8PROC_DECOMP_TYPE_SMALL = 13; {< Small }
  UTF8PROC_DECOMP_TYPE_SQUARE = 14; {< Square }
  UTF8PROC_DECOMP_TYPE_FRACTION = 15; {< Fraction }
  UTF8PROC_DECOMP_TYPE_COMPAT = 16; {< Compat }

type
  T1Bit = 0..1;
  T2Bit = 0..3;
  T5Bit = 0..31;
  T6Bit = 0..63;
  T8Bit = 0..255;
  T10Bit = 0..1023;


  { Struct containing information about a codepoint. }
  Putf8proc_property_t = ^utf8proc_property_t;
  {$ifdef FPC}
utf8proc_property_t=bitpacked record
  {$else}

  utf8proc_property_t = record
  {$endif}
  {
   * Unicode category.
   * @see utf8proc_category_t.
   }
    category: utf8proc_category_t;
    combining_class: utf8proc_propval_t;
  {
   * Bidirectional class.
   * @see utf8proc_bidi_class_t.
   }
    bidi_class: utf8proc_bidi_class_t;
  {
   * @anchor Decomposition type.
   * @see utf8proc_decomp_type_t.
   }
    decomp_type: utf8proc_decomp_type_t;
    decomp_seqindex: utf8proc_uint16_t;
    casefold_seqindex: utf8proc_uint16_t;
    uppercase_seqindex: utf8proc_uint16_t;
    lowercase_seqindex: utf8proc_uint16_t;
    titlecase_seqindex: utf8proc_uint16_t;
  {
   * Character combining table.
   *
   * The character combining table is formally indexed by two
   * characters, the first and second character that might form a
   * combining pair. The table entry then contains the combined
   * character. Most character pairs cannot be combined. There are
   * about 1,000 characters that can be the first character in a
   * combining pair, and for most, there are only a handful for
   * possible second characters.
   *
   * The combining table is stored as sparse matrix in the CSR
   * (compressed sparse row) format. That is, it is stored as two
   * arrays, `utf8proc_uint32_t utf8proc_combinations_second[]` and
   * `utf8proc_uint32_t utf8proc_combinations_combined[]`. These
   * contain the second combining characters and the combined
   * character of every combining pair.
   *
   * - `comb_index`: Index into the combining table if this character
   *   is the first character in a combining pair, else $3ff
   *
   * - `comb_length`: Number of table entries for this first character
   *
   * - `comb_is_second`: As optimization we also record whether this
   *   character is the second combining character in any pair. If
   *   not, we can skip the table lookup.
   *
   * A table lookup starts from a given character pair. It first
   * checks whether the first character is stored in the table
   * (checking whether the index is $3ff) and whether the second
   * index is stored in the table (looking at `comb_is_second`). If
   * so, the `comb_length` table entries will be checked sequentially
   * for a match.
   }
    //    {$ifdef FPC}
    comb_index: T10Bit; //utf8proc_uint16_t comb_index:10;
    comb_length: T5Bit; //utf8proc_uint16_t comb_length:5;
    comb_issecond: boolean;//comb_issecond:T1Bit; //utf8proc_uint16_t comb_issecond:1;
    bidi_mirrored: boolean;//bidi_mirrored:T1Bit; //unsigned bidi_mirrored:1;
    comp_exclusion: boolean; //comp_exclusion:T1Bit; //unsigned comp_exclusion:1;
  {
   * Can this codepoint be ignored?
   *
   * Used by utf8proc_decompose_char() when @ref UTF8PROC_IGNORE is
   * passed as an option.
   }
    ignorable: boolean; //ignorable:T1Bit; //unsigned ignorable:1;
    control_boundary: boolean; //control_boundary:T1Bit; //unsigned control_boundary:1;
    { The width of the codepoint. }
    charwidth: T2Bit; //unsigned charwidth:2;
    { East Asian width class A }
    ambiguous_width: boolean; //ambiguous_width:T1Bit; //unsigned ambiguous_width:1;
    pad: T1Bit; //unsigned pad:1;
  {
   * Boundclass.
   * @see utf8proc_boundclass_t.
   }
    boundclass: T6Bit; //unsigned boundclass:6;
    indic_conjunct_break: T2Bit; //unsigned indic_conjunct_break:2;

    //  {$else}

    //  comb_index: utf8proc_uint16_t; //utf8proc_uint16_t comb_index:10;
    //  comb_length: byte; //utf8proc_uint16_t comb_length:5;
    //  comb_issecond: boolean; //utf8proc_uint16_t comb_issecond:1;
    //  bidi_mirrored: boolean; //unsigned bidi_mirrored:1;
    //  comp_exclusion: boolean; //unsigned comp_exclusion:1;
    //{
    // * Can this codepoint be ignored?
    // *
    // * Used by utf8proc_decompose_char() when @ref UTF8PROC_IGNORE is
    // * passed as an option.
    // }
    //  ignorable: boolean; //unsigned ignorable:1;
    //  control_boundary: boolean; //unsigned control_boundary:1;
    //  { The width of the codepoint. }
    //  charwidth: byte; //unsigned charwidth:2;
    //  { East Asian width class A }
    //  ambiguous_width: boolean; //unsigned ambiguous_width:1;
    //  pad: byte; //unsigned pad:1;
    //{
    // * Boundclass.
    // * @see utf8proc_boundclass_t.
    // }
    //  boundclass: utf8proc_boundclass_type_t; //unsigned boundclass:6;
    //  indic_conjunct_break: utf8proc_indic_conjunct_break_t; //unsigned indic_conjunct_break:2;
    //  {$endif}
  end;


{
 * Function pointer type passed to utf8proc_map_custom() and
 * utf8proc_decompose_custom(), which is used to specify a user-defined
 * mapping of codepoints to be applied in conjunction with other mappings.
 }
  //typedef utf8proc_int32_t ( *utf8proc_custom_func)(utf8proc_int32_t codepoint, void *data);
  utf8proc_custom_func = function(codepoint: utf8proc_int32_t; Data: Pointer): utf8proc_int32_t;

{
 * Array containing the byte lengths of a UTF-8 encoded codepoint based
 * on the first byte.
 }

  //UTF8PROC_DLLEXPORT extern const utf8proc_int8_t utf8proc_utf8class[256];

{
 * exits the utf8proc API version as a string MAJOR.MINOR.PATCH
 * (http://semver.org format), possibly with a "-dev" suffix for
 * development versions.
 }
//UTF8PROC_DLLEXPORT const char *utf8proc_version(void);
function utf8proc_version: rawbytestring;


{
 * exits the utf8proc supported Unicode version as a string MAJOR.MINOR.PATCH.
 }
//UTF8PROC_DLLEXPORT const char *utf8proc_unicode_version(void);
function utf8proc_unicode_version: rawbytestring;

{
 * exits an informative error string for the given utf8proc error code
 * (e.g. the error codes exited by utf8proc_map()).
 }
//UTF8PROC_DLLEXPORT const char *utf8proc_errmsg(utf8proc_ssize_t errcode);
function utf8proc_errmsg(errcode: utf8proc_ssize_t): rawbytestring;
{
 * Reads a single codepoint from the UTF-8 sequence being pointed to by `str`.
 * The maximum number of bytes read is `strlen`, unless `strlen` is
 * negative (in which case up to 4 bytes are read).
 *
 * If a valid codepoint could be read, it is stored in the variable
 * pointed to by `codepoint_ref`, otherwise that variable will be set to -1.
 * In case of success, the number of bytes read is exited; otherwise, a
 * negative error code is exited.
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_iterate(const utf8proc_uint8_t *str, utf8proc_ssize_t strlen, utf8proc_int32_t *codepoint_ref);
function utf8proc_iterate(str: pansichar; strlen: utf8proc_ssize_t; dst: Putf8proc_int32_t): utf8proc_ssize_t;
{
 * Check if a codepoint is valid (regardless of whether it has been
 * assigned a value by the current Unicode standard).
 *
 * @exit 1 if the given `codepoint` is valid and otherwise exit 0.
 }
//UTF8PROC_DLLEXPORT utf8proc_boolean utf8proc_codepoint_valid(utf8proc_int32_t codepoint);
function utf8proc_codepoint_valid(uc: utf8proc_int32_t): boolean;

{
 * Encodes the codepoint as an UTF-8 string in the byte array pointed
 * to by `dst`. This array must be at least 4 bytes long.
 *
 * In case of success the number of bytes written is exited, and
 * otherwise 0 is exited.
 *
 * This function does not check whether `codepoint` is valid Unicode.
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
function utf8proc_encode_char(uc: utf8proc_int32_t; dst: pansichar): utf8proc_ssize_t;

{
 * Look up the properties for a given codepoint.
 *
 * @param codepoint The Unicode codepoint.
 *
 * @exits
 * A pointer to a (constant) struct containing information about
 * the codepoint.
 * @par
 * If the codepoint is unassigned or invalid, a pointer to a special struct is
 * exited in which `category` is 0 (@ref UTF8PROC_CATEGORY_CN).
 }
//UTF8PROC_DLLEXPORT const utf8proc_property_t *utf8proc_get_property(utf8proc_int32_t codepoint);
function utf8proc_get_property(uc: utf8proc_int32_t): Putf8proc_property_t;

{ Decompose a codepoint into an array of codepoints.
 *
 * @param codepoint the codepoint.
 * @param dst the destination buffer.
 * @param bufsize the size of the destination buffer.
 * @param options one or more of the following flags:
 * - @ref UTF8PROC_REJECTNA  - exit an error if `codepoint` is unassigned
 * - @ref UTF8PROC_IGNORE    - strip "default ignorable" codepoints
 * - @ref UTF8PROC_CASEFOLD  - apply Unicode casefolding
 * - @ref UTF8PROC_COMPAT    - replace certain codepoints with their
 *                             compatibility decomposition
 * - @ref UTF8PROC_CHARBOUND - insert $FF bytes before each grapheme cluster
 * - @ref UTF8PROC_LUMP      - lump certain different codepoints together
 * - @ref UTF8PROC_STRIPMARK - remove all character marks
 * - @ref UTF8PROC_STRIPNA   - remove unassigned codepoints
 * @param last_boundclass
 * Pointer to an integer variable containing
 * the previous codepoint's (boundclass + indic_conjunct_break  shl  1) if the @ref UTF8PROC_CHARBOUND
 * option is used.  If the string is being processed in order, this can be initialized to 0 for
 * the beginning of the string, and is thereafter updated automatically.  Otherwise, this parameter is ignored.
 *
 * In the current version of utf8proc, the maximum destination buffer with the @ref UTF8PROC_DECOMPOSE
 * option is 4 elements (or double that with @ref UTF8PROC_CHARBOUND), so this is a good default size.
 * However, this may increase in future Unicode versions, so you should always check the exit value
 * as described below.
 *
 * @exit
 * In case of success, the number of codepoints written is exited; in case
 * of an error, a negative error code is exited (utf8proc_errmsg()).
 * @par
 * If the number of written codepoints would be bigger than `bufsize`, the
 * required buffer size is exited, while the buffer will be overwritten with
 * undefined data.
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose_char(
//  utf8proc_int32_t codepoint, utf8proc_int32_t *dst, utf8proc_ssize_t bufsize,
//  utf8proc_option_t options, int *last_boundclass
//);
function utf8proc_decompose_char(uc: utf8proc_int32_t; dst: Putf8proc_int32_t; bufsize: utf8proc_ssize_t; options: utf8proc_option_t;
  last_boundclass: PInteger): utf8proc_ssize_t;



{
 * The same as utf8proc_decompose_char(), but acts on a whole UTF-8
 * string and orders the decomposed sequences correctly.
 *
 * If the @ref UTF8PROC_NULLTERM flag in `options` is set, processing
 * will be stopped, when a nil byte is encountered, otherwise `strlen`
 * bytes are processed.  The result (in the form of 32-bit unicode
 * codepoints) is written into the buffer being pointed to by
 * `buffer` (which must contain at least `bufsize` entries).  In case of
 * success, the number of codepoints written is exited; in case of an
 * error, a negative error code is exited (utf8proc_errmsg()).
 * See utf8proc_decompose_custom() to supply additional transformations.
 *
 * If the number of written codepoints would be bigger than `bufsize`, the
 * required buffer size is exited, while the buffer will be overwritten with
 * undefined data.
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose(
//  const utf8proc_uint8_t *str, utf8proc_ssize_t strlen,
//  utf8proc_int32_t *buffer, utf8proc_ssize_t bufsize, utf8proc_option_t options
//);

// added _t  duplicate UTF8PROC_DECOMPOS pascal is case insensitive.
function utf8proc_decompose_utf8(str: pansichar; strlen: utf8proc_ssize_t; buffer: Putf8proc_int32_t; bufsize: utf8proc_ssize_t;
  options: utf8proc_option_t): utf8proc_ssize_t;


{
 * The same as utf8proc_decompose(), but also takes a `custom_func` mapping function
 * that is called on each codepoint in `str` before any other transformations
 * (along with a `custom_data` pointer that is passed through to `custom_func`).
 * The `custom_func` argument is ignored if it is `nil`.  See also utf8proc_map_custom().
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose_custom(
//  const utf8proc_uint8_t *str, utf8proc_ssize_t strlen,
//  utf8proc_int32_t *buffer, utf8proc_ssize_t bufsize, utf8proc_option_t options,
//  utf8proc_custom_func custom_func, void *custom_data
//);
function utf8proc_decompose_custom(str: pansichar; strlen: utf8proc_ssize_t; buffer: Putf8proc_int32_t; bufsize: utf8proc_ssize_t;
  options: utf8proc_option_t; custom_func: utf8proc_custom_func; custom_data: Pointer): utf8proc_ssize_t;

{
 * Normalizes the sequence of `length` codepoints pointed to by `buffer`
 * in-place (i.e., the result is also stored in `buffer`).
 *
 * @param buffer the (native-endian UTF-32) unicode codepoints to re-encode.
 * @param length the length (in codepoints) of the buffer.
 * @param options a bitwise or (` or `) of one or more of the following flags:
 * - @ref UTF8PROC_NLF2LS  - convert LF, CRLF, CR and NEL into LS
 * - @ref UTF8PROC_NLF2PS  - convert LF, CRLF, CR and NEL into PS
 * - @ref UTF8PROC_NLF2LF  - convert LF, CRLF, CR and NEL into LF
 * - @ref UTF8PROC_STRIPCC - strip or convert all non-affected control characters
 * - @ref UTF8PROC_COMPOSE - try to combine decomposed codepoints into composite
 *                           codepoints
 * - @ref UTF8PROC_STABLE  - prohibit combining characters that would violate
 *                           the unicode versioning stability
 *
 * @exit
 * In case of success, the length (in codepoints) of the normalized UTF-32 string is
 * exited; otherwise, a negative error code is exited (utf8proc_errmsg()).
 *
 * @warning The entries of the array pointed to by `str` have to be in the
 *          range `$0000` to `$10FFFF`. Otherwise, the program might crash not
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_normalize_utf32(utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);
function utf8proc_normalize_utf32(buffer: Putf8proc_int32_t; length: utf8proc_ssize_t; options: utf8proc_option_t): utf8proc_ssize_t;

{
 * Reencodes the sequence of `length` codepoints pointed to by `buffer`
 * UTF-8 data in-place (i.e., the result is also stored in `buffer`).
 * Can optionally normalize the UTF-32 sequence prior to UTF-8 conversion.
 *
 * @param buffer the (native-endian UTF-32) unicode codepoints to re-encode.
 * @param length the length (in codepoints) of the buffer.
 * @param options a bitwise or (` or `) of one or more of the following flags:
 * - @ref UTF8PROC_NLF2LS  - convert LF, CRLF, CR and NEL into LS
 * - @ref UTF8PROC_NLF2PS  - convert LF, CRLF, CR and NEL into PS
 * - @ref UTF8PROC_NLF2LF  - convert LF, CRLF, CR and NEL into LF
 * - @ref UTF8PROC_STRIPCC - strip or convert all non-affected control characters
 * - @ref UTF8PROC_COMPOSE - try to combine decomposed codepoints into composite
 *                           codepoints
 * - @ref UTF8PROC_STABLE  - prohibit combining characters that would violate
 *                           the unicode versioning stability
 * - @ref UTF8PROC_CHARBOUND - insert $FF bytes before each grapheme cluster
 *
 * @exit
 * In case of success, the length (in bytes) of the resulting nul-terminated
 * UTF-8 string is exited; otherwise, a negative error code is exited
 * (utf8proc_errmsg()).
 *
 * @warning The amount of free space pointed to by `buffer` must
 *          exceed the amount of the input data by one byte, and the
 *          entries of the array pointed to by `str` have to be in the
 *          range `$0000` to `$10FFFF`. Otherwise, the program might crash not
 }

//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_reencode(utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);
function utf8proc_reencode(buffer: Putf8proc_int32_t; length: utf8proc_ssize_t; options: utf8proc_option_t): utf8proc_ssize_t;

{
 * Given a pair of consecutive codepoints, exit whether a grapheme break is
 * permitted between them (as defined by the extended grapheme clusters in UAX#29).
 *
 * @param codepoint1 The first codepoint.
 * @param codepoint2 The second codepoint, occurring consecutively after `codepoint1`.
 * @param state Beginning with Version 29 (Unicode 9.0.0), this algorithm requires
 *              state to break graphemes. This state can be passed in as a pointer
 *              in the `state` argument and should initially be set to 0. If the
 *              state is not passed in (i.e. a nil pointer is passed), UAX#29 rules
 *              GB10/12/13 which require this state will not be applied, essentially
 *              matching the rules in Unicode 8.0.0.
 *
 * @warning If the state parameter is used, `utf8proc_grapheme_break_stateful` must
 *          be called IN ORDER on ALL potential breaks in a string.  However, it
 *          is safe to reset the state to zero after a grapheme break.
 }
//UTF8PROC_DLLEXPORT utf8proc_boolean utf8proc_grapheme_break_stateful(
//    utf8proc_int32_t codepoint1, utf8proc_int32_t codepoint2, utf8proc_int32_t *state);
function utf8proc_grapheme_break_stateful(c1: utf8proc_int32_t; c2: utf8proc_int32_t; state: Putf8proc_int32_t): boolean;
{
 * Same as utf8proc_grapheme_break_stateful(), except without support for the
 * Unicode 9 additions to the algorithm. Supported for legacy reasons.
 }
//UTF8PROC_DLLEXPORT utf8proc_boolean utf8proc_grapheme_break(
//    utf8proc_int32_t codepoint1, utf8proc_int32_t codepoint2);
function utf8proc_grapheme_break(c1, c2: utf8proc_int32_t): boolean;

{
 * Given a codepoint `c`, exit the codepoint of the corresponding
 * lower-case character, if any; otherwise (if there is no lower-case
 * variant, or if `c` is not a valid codepoint) exit `c`.
 }
//UTF8PROC_DLLEXPORT utf8proc_int32_t utf8proc_tolower(utf8proc_int32_t c);
function utf8proc_tolower(c: utf8proc_int32_t): utf8proc_int32_t;
{
 * Given a codepoint `c`, exit the codepoint of the corresponding
 * upper-case character, if any; otherwise (if there is no upper-case
 * variant, or if `c` is not a valid codepoint) exit `c`.
 }
//UTF8PROC_DLLEXPORT utf8proc_int32_t utf8proc_toupper(utf8proc_int32_t c);
function utf8proc_toupper(c: utf8proc_int32_t): utf8proc_int32_t;

{
 * Given a codepoint `c`, exit the codepoint of the corresponding
 * title-case character, if any; otherwise (if there is no title-case
 * variant, or if `c` is not a valid codepoint) exit `c`.
 }
//UTF8PROC_DLLEXPORT utf8proc_int32_t utf8proc_totitle(utf8proc_int32_t c);
function utf8proc_totitle(c: utf8proc_int32_t): utf8proc_int32_t;
{
 * Given a codepoint `c`, exit `1` if the codepoint corresponds to a lower-case character
 * and `0` otherwise.
 }
//UTF8PROC_DLLEXPORT int utf8proc_islower(utf8proc_int32_t c);
function utf8proc_islower(c: utf8proc_int32_t): boolean;
{
 * Given a codepoint `c`, exit `1` if the codepoint corresponds to an upper-case character
 * and `0` otherwise.
 }
//UTF8PROC_DLLEXPORT int utf8proc_isupper(utf8proc_int32_t c);
function utf8proc_isupper(c: utf8proc_int32_t): boolean;
{
 * Given a codepoint, exit a character width analogous to `wcwidth(codepoint)`,
 * except that a width of 0 is exited for non-printable codepoints
 * instead of -1 as in `wcwidth`.
 *
 * @note
 * If you want to check for particular types of non-printable characters,
 * (analogous to `isprint` or `iscntrl`), use utf8proc_category(). }
//UTF8PROC_DLLEXPORT int utf8proc_charwidth(utf8proc_int32_t codepoint);
function utf8proc_charwidth(c: utf8proc_int32_t): integer;
{
 * Given a codepoint, exit whether it has East Asian width class A (Ambiguous)
 *
 * Codepoints with this property are considered to have charwidth 1 (if they are printable)
 * but some East Asian fonts render them as double width.
 }
//UTF8PROC_DLLEXPORT utf8proc_boolean utf8proc_charwidth_ambiguous(utf8proc_int32_t codepoint);
function utf8proc_charwidth_ambiguous(c: utf8proc_int32_t): boolean;
{
 * exit the Unicode category for the codepoint (one of the
 * @ref utf8proc_category_t constants.)
 }
//UTF8PROC_DLLEXPORT utf8proc_category_t utf8proc_category(utf8proc_int32_t codepoint);
function utf8proc_category(c: utf8proc_int32_t): utf8proc_category_t;
{
 * exit the two-letter (nul-terminated) Unicode category string for
 * the codepoint (e.g. `"Lu"` or `"Co"`).
 }
//UTF8PROC_DLLEXPORT const char *utf8proc_category_string(utf8proc_int32_t codepoint);
function utf8proc_category_string(c: utf8proc_int32_t): ansistring;

{
 * Maps the given UTF-8 string pointed to by `str` to a new UTF-8
 * string, allocated dynamically by `malloc` and exited via `dstptr`.
 *
 * If the @ref UTF8PROC_NULLTERM flag in the `options` field is set,
 * the length is determined by a nil terminator, otherwise the
 * parameter `strlen` is evaluated to determine the string length, but
 * in any case the result will be nil terminated (though it might
 * contain nil characters with the string if `str` contained nil
 * characters). Other flags in the `options` field are passed to the
 * functions defined above, and regarded as described.  See also
 * utf8proc_map_custom() to supply a custom codepoint transformation.
 *
 * In case of success the length of the new string is exited,
 * otherwise a negative error code is exited.
 *
 * @note The memory of the new UTF-8 string will have been allocated
 * with `malloc`, and should therefore be deallocated with `free`.
 }




//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_map(
//  const utf8proc_uint8_t *str, utf8proc_ssize_t strlen, utf8proc_uint8_t **dstptr, utf8proc_option_t options
//);

{
 * Like utf8proc_map(), but also takes a `custom_func` mapping function
 * that is called on each codepoint in `str` before any other transformations
 * (along with a `custom_data` pointer that is passed through to `custom_func`).
 * The `custom_func` argument is ignored if it is `nil`.
 }
//UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_map_custom(
//  const utf8proc_uint8_t *str, utf8proc_ssize_t strlen, utf8proc_uint8_t **dstptr, utf8proc_option_t options,
//  utf8proc_custom_func custom_func, void *custom_data
//);
function utf8proc_map(str: pansichar; strlen: utf8proc_ssize_t; dstptr: PPAnsiChar; options: utf8proc_option_t): utf8proc_ssize_t;
function utf8proc_map_custom(str: pansichar; strlen: utf8proc_ssize_t; dstptr: PPAnsiChar; options: utf8proc_option_t;
  custom_func: utf8proc_custom_func; custom_data: Pointer): utf8proc_ssize_t; overload;
//avoid conversions and copys, Use the dststr string as buffer.
function utf8proc_map_custom(const str: rawbytestring; out dststr: rawbytestring; options: utf8proc_option_t;
  custom_func: utf8proc_custom_func = nil; custom_data: Pointer = nil): utf8proc_ssize_t; overload;

{ @name Unicode normalization
 *
 * exits a pointer to newly allocated memory of a NFD, NFC, NFKD, NFKC or
 * NFKC_Casefold normalized version of the nil-terminated string `str`.  These
 * are shortcuts to calling utf8proc_map() with @ref UTF8PROC_NULLTERM
 * combined with @ref UTF8PROC_STABLE and flags indicating the normalization.
 }

{ NFD normalization (@ref UTF8PROC_DECOMPOSE). }
//UTF8PROC_DLLEXPORT utf8proc_uint8_t *utf8proc_NFD(const utf8proc_uint8_t *str);
function utf8proc_NFD(str: pansichar): pansichar;
{ NFC normalization (@ref UTF8PROC_COMPOSE). }
//UTF8PROC_DLLEXPORT utf8proc_uint8_t *utf8proc_NFC(const utf8proc_uint8_t *str);
function utf8proc_NFC(str: pansichar): pansichar;
{ NFKD normalization (@ref UTF8PROC_DECOMPOSE and @ref UTF8PROC_COMPAT). }
//UTF8PROC_DLLEXPORT utf8proc_uint8_t *utf8proc_NFKD(const utf8proc_uint8_t *str);
function utf8proc_NFKD(str: pansichar): pansichar;
{ NFKC normalization (@ref UTF8PROC_COMPOSE and @ref UTF8PROC_COMPAT). }
//UTF8PROC_DLLEXPORT utf8proc_uint8_t *utf8proc_NFKC(const utf8proc_uint8_t *str);
function utf8proc_NFKC(str: pansichar): pansichar;
{
 * NFKC_Casefold normalization (@ref UTF8PROC_COMPOSE and @ref UTF8PROC_COMPAT
 * and @ref UTF8PROC_CASEFOLD and @ref UTF8PROC_IGNORE).
 *}
//UTF8PROC_DLLEXPORT utf8proc_uint8_t *utf8proc_NFKC_Casefold(const utf8proc_uint8_t *str);
function utf8proc_NFKC_Casefold(str: pansichar): pansichar;
procedure utf8proc_free(ptr: Pointer);

//high level function ready to use.
function utf8procNormalizeNFD(AStr: rawbytestring): rawbytestring;
function utf8procNormalizeNFC(AStr: rawbytestring): rawbytestring;
function utf8procNormalizeNFKD(AStr: rawbytestring): rawbytestring;
function utf8procNormalizeNFKC(AStr: rawbytestring): rawbytestring;
function utf8procNormalizeNFKDCaseFold(AStr: rawbytestring): rawbytestring;

//not used
{
const

    // * Array containing the byte lengths of a UTF-8 encoded codepoint based
    // * on the first byte.

   utf8proc_utf8class:array[0..255] of utf8proc_int8_t = (
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
      4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0 );
   }

implementation

const
  UINT16_MAX = 65535;
  SSIZE_MAX = high(utf8proc_size_t) div 2;

  UTF8PROC_HANGUL_SBASE = $AC00;
  UTF8PROC_HANGUL_LBASE = $1100;
  UTF8PROC_HANGUL_VBASE = $1161;
  UTF8PROC_HANGUL_TBASE = $11A7;
  UTF8PROC_HANGUL_LCOUNT = 19;
  UTF8PROC_HANGUL_VCOUNT = 21;
  UTF8PROC_HANGUL_TCOUNT = 28;
  UTF8PROC_HANGUL_NCOUNT = 588;
  UTF8PROC_HANGUL_SCOUNT = 11172;
  {* END is exclusive *}
  UTF8PROC_HANGUL_L_START = $1100;
  UTF8PROC_HANGUL_L_END = $115A;
  UTF8PROC_HANGUL_L_FILLER = $115F;
  UTF8PROC_HANGUL_V_START = $1160;
  UTF8PROC_HANGUL_V_END = $11A3;
  UTF8PROC_HANGUL_T_START = $11A8;
  UTF8PROC_HANGUL_T_END = $11FA;
  UTF8PROC_HANGUL_S_START = $AC00;
  UTF8PROC_HANGUL_S_END = $D7A4;


  {$I utf8proc_data.inc}

function utf8proc_version: rawbytestring;
begin
  Result := UTF8PROC_VERSION_STR;
end;

function utf8proc_unicode_version: rawbytestring;
begin
  Result := UTF8PROC_UNICODE_VERSION_STR;
end;

function utf8proc_errmsg(errcode: utf8proc_ssize_t): rawbytestring;
begin
  case errcode of
    UTF8PROC_ERROR_NOMEM:
      Result := 'Memory for processing UTF-8 data could not be allocated.';
    UTF8PROC_ERROR_OVERFLOW:
      Result := 'UTF-8 string is too long to be processed.';
    UTF8PROC_ERROR_INVALIDUTF8:
      Result := 'Invalid UTF-8 string';
    UTF8PROC_ERROR_NOTASSIGNED:
      Result := 'Unassigned Unicode code point found in UTF-8 string.';
    UTF8PROC_ERROR_INVALIDOPTS:
      Result := 'Invalid options for UTF-8 processing chosen.';
    else
      Result := 'An unknown error occurred while processing UTF-8 data.';
  end;
end;

function utf_cont(ch: ansichar): boolean; inline;
begin
  Result := (((Ord(ch)) and $C0) = $80);
end;

function utf8proc_iterate(str: pansichar; strlen: utf8proc_ssize_t; dst: Putf8proc_int32_t): utf8proc_ssize_t;
var
  uc: utf8proc_int32_t;
  lEnd: pansichar;
begin
  dst^ := -1;
  if strlen = 0 then
    exit(0);
  lEnd := str;
  if strlen < 0 then
    Inc(lEnd, 4)
  else
    Inc(lEnd, strlen);
  uc := Ord(str^);
  Inc(str);
  if (uc < $80) then
  begin
    dst^ := uc;
    exit(1);
  end;
  // Must be between $c2 and $f4 inclusive to be valid
  if (utf8proc_uint32_t((uc - $C2)) > ($F4 - $C2)) then
    exit(UTF8PROC_ERROR_INVALIDUTF8);
  if (uc < $E0) then         // 2-byte sequence
  begin
    // Must have valid continuation character
    if (str >= lEnd) or (not utf_cont(str^)) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
    dst^ := uint32((uint32(uc and $1F) shl 6)) or uint32((Ord(str^) and $3F));
    exit(2);
  end;
  if (uc < $F0) then        // 3-byte sequence
  begin
    if (((str + 1) >= lEnd) or (not utf_cont(str^)) or (not utf_cont(str[1]))) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
    // Check for surrogate chars
    if (uc = $ED) and (Ord(str^) > $9F) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
    uc := uint32(uint32(uc and $F) shl 12) or uint32(uint32(Ord(str^) and $3F) shl 6) or uint32(Ord(str[1]) and $3F);
    if (uc < $800) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
    dst^ := uc;
    exit(3);
  end;
  // 4-byte sequence
  // Must have 3 valid continuation characters
  if ((str + 2) >= lEnd) or (not utf_cont(str^)) or (not utf_cont(str[1])) or (not utf_cont(str[2])) then
    exit(UTF8PROC_ERROR_INVALIDUTF8);
  // Make sure in correct range ($10000 - $10ffff)
  if (uc = $F0) then
  begin
    if (Ord(str^) < $90) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
  end
  else if (uc = $F4) then
  begin
    if (Ord(str^) > $8F) then
      exit(UTF8PROC_ERROR_INVALIDUTF8);
  end;
  dst^ := uint32((uint32(uc and 7) shl 18)) or uint32((uint32(Ord(str^) and $3F) shl 12)) or uint32((uint32(Ord(str[1]) and $3F) shl 6)) or
    uint32((Ord(str[2]) and $3F));
  exit(4);
end;

function utf8proc_codepoint_valid(uc: utf8proc_int32_t): boolean;
var
  uuc: uint32;
  t2: uint32;
begin
  uuc := uint32(uc);
  //FPC 3.2 BUG EVALUATING ALL EXPRESION. WORKARROUND USING TEMPORAL.
  t2 := uuc - $D800;
  exit((t2 > $07ff) and (uuc < $110000));
  // maybe compiler evaluation error see asm generated.
  //exit( ((uuc-$D800) > $07FF) and (uuc < $110000)) ;
end;

function utf8proc_encode_char(uc: utf8proc_int32_t; dst: pansichar): utf8proc_ssize_t;
begin
  if (uc < $00) then
  begin
    exit(0);
  end
  else if (uc < $80) then
  begin
    dst[0] := ansichar(uc);
    exit(1);
  end
  else if (uc < $800) then
  begin
    dst[0] := ansichar(($C0 + (uint32(uc) shr 6)));
    dst[1] := ansichar($80 + (uint32(uc) and $3F));
    exit(2);
    // Note: we allow encoding $d800-$dfff here, so as not to change
    // the API, however, these are actually invalid in UTF-8
  end
  else if (uc < $10000) then
  begin
    dst[0] := ansichar(($E0 + (uint32(uc) shr 12)));
    dst[1] := ansichar(($80 + ((uint32(uc) shr 6) and $3F)));
    dst[2] := ansichar(($80 + (uint32(uc) and $3F)));
    exit(3);
  end
  else if (uc < $110000) then
  begin
    dst[0] := ansichar(($F0 + (uint32(uc) shr 18)));
    dst[1] := ansichar(($80 + ((uint32(uc) shr 12) and $3F)));
    dst[2] := ansichar(($80 + ((uint32(uc) shr 6) and $3F)));
    dst[3] := ansichar($80 + (uc and $3F));
    exit(4);
  end
  else
    exit(0);
end;


{* internal version used for inserting $ff bytes between graphemes *}
function charbound_encode_char(uc: utf8proc_int32_t; dst: pansichar): utf8proc_ssize_t;
begin
  if (uc < $00) then
  begin
    if (uc = -1) then  {* internal value used for grapheme breaks *}
    begin
      dst[0] := ansichar($FF);
      exit(1);
    end;
    exit(0);
  end
  else if (uc < $80) then
  begin
    dst[0] := ansichar(uc);
    exit(1);
  end
  else if (uc < $800) then
  begin
    dst[0] := ansichar($C0 + (uint32(uc) shr 6));
    dst[1] := ansichar($80 + (uc and $3F));
    exit(2);
  end
  else if (uc < $10000) then
  begin
    dst[0] := ansichar($E0 + (uint32(uc) shr 12));
    dst[1] := ansichar($80 + ((uint32(uc) shr 6) and $3F));
    dst[2] := ansichar($80 + (uc and $3F));
    exit(3);
  end
  else if (uc < $110000) then
  begin
    dst[0] := ansichar($F0 + (uint32(uc) shr 18));
    dst[1] := ansichar($80 + ((uint32(uc) shr 12) and $3F));
    dst[2] := ansichar($80 + ((uint32(uc) shr 6) and $3F));
    dst[3] := ansichar($80 + (uc and $3F));
    exit(4);
  end
  else
    exit(0);
end;


{* internal "unsafe" version that does not check whether uc is in range *}
function unsafe_get_property(uc: utf8proc_int32_t): Putf8proc_property_t;
var
  index: integer;
begin
  {* ASSERT: uc >= 0  and  uc < $110000 *}
  index := utf8proc_stage2table[utf8proc_stage1table[uint32(uc) shr 8] + (uc and $FF)];
  Result := @utf8proc_properties[index];
end;

function utf8proc_get_property(uc: utf8proc_int32_t): Putf8proc_property_t;
begin
  if (uc < 0) or (uc >= $110000) then
    exit(@utf8proc_properties[0]);
  Result := unsafe_get_property(uc);
end;


{* return whether there is a grapheme break between boundclasses lbc and tbc
   (according to the definition of extended grapheme clusters)

  Rule numbering refers to TR29 Version 29 (Unicode 9.0.0):
  http://www.unicode.org/reports/tr29/tr29-29.html

  CAVEATS:
   Please note that evaluation of GB10 (grapheme breaks between emoji zwj sequences)
   and GB 12/13 (regional indicator code points) require knowledge of previous characters
   and are thus not handled by this function. This may result in an incorrect break before
   an E_Modifier class codepoint and an incorrectly missing break between two
   REGIONAL_INDICATOR class code points if such support does not exist in the caller.

   See the special support in grapheme_break_extended, for required bookkeeping by the caller.
*}
function grapheme_break_simple(lbc: integer; tbc: integer): boolean;
begin
  if lbc = UTF8PROC_BOUNDCLASS_START then exit(True);       // GB1
  if (lbc = UTF8PROC_BOUNDCLASS_CR) and                 // GB3
    (tbc = UTF8PROC_BOUNDCLASS_LF) then exit(False);   // ---
  if (lbc >= UTF8PROC_BOUNDCLASS_CR) and (lbc <= UTF8PROC_BOUNDCLASS_CONTROL) then exit(True);  // GB4
  if (tbc >= UTF8PROC_BOUNDCLASS_CR) and (tbc <= UTF8PROC_BOUNDCLASS_CONTROL) then exit(True);  // GB5

  if (lbc = UTF8PROC_BOUNDCLASS_L) and                  // GB6
    ((tbc = UTF8PROC_BOUNDCLASS_L) or                 // ---
    (tbc = UTF8PROC_BOUNDCLASS_V) or                 // ---
    (tbc = UTF8PROC_BOUNDCLASS_LV) or                // ---
    (tbc = UTF8PROC_BOUNDCLASS_LVT)) then exit(False); // ---

  if ((lbc = UTF8PROC_BOUNDCLASS_LV) or                // GB7
    (lbc = UTF8PROC_BOUNDCLASS_V)) and                // ---
    ((tbc = UTF8PROC_BOUNDCLASS_V) or                 // ---
    (tbc = UTF8PROC_BOUNDCLASS_T)) then exit(False);        // ---

  if ((lbc = UTF8PROC_BOUNDCLASS_LVT) or               // GB8
    (lbc = UTF8PROC_BOUNDCLASS_T)) and                // ---
    (tbc = UTF8PROC_BOUNDCLASS_T) then exit(False);          // ---

  if (tbc = UTF8PROC_BOUNDCLASS_EXTEND) or             // GB9
    (tbc = UTF8PROC_BOUNDCLASS_ZWJ) or                // ---
    (tbc = UTF8PROC_BOUNDCLASS_SPACINGMARK) or        // GB9a
    (lbc = UTF8PROC_BOUNDCLASS_PREPEND) then exit(False);    // GB9b

  if (lbc = UTF8PROC_BOUNDCLASS_E_ZWG) and              // GB11 (requires additional handling below)
    (tbc = UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC) then exit(False); // ----

  if (lbc = UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR) and          // GB12/13 (requires additional handling below)
    (tbc = UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR) then exit(False);  // ----
  exit(True); // GB999
end;

function grapheme_break_extended(lbc, tbc, licb, ticb: integer; state: Putf8proc_int32_t): boolean;
var
  state_bc, state_icb: integer; {* boundclass and indic_conjunct_break state *}
  break_permitted: boolean;
begin
  if (state <> nil) then
  begin
    if (state^ = 0) then  {* state initialization *}
    begin
      state_bc := lbc;
      if licb = UTF8PROC_INDIC_CONJUNCT_BREAK_CONSONANT then
        state_icb := licb
      else
        state_icb := UTF8PROC_INDIC_CONJUNCT_BREAK_NONE;
    end
    else  {* lbc and licb are already encoded in *state *}
    begin
      state_bc := state^ and $ff;  // 1st byte of state is bound class
      state_icb := uint32(state^) shr 8;   // 2nd byte of state is indic conjunct break
    end;

    break_permitted := grapheme_break_simple(state_bc, tbc) and (not ((state_icb = UTF8PROC_INDIC_CONJUNCT_BREAK_LINKER) and
      (ticb = UTF8PROC_INDIC_CONJUNCT_BREAK_CONSONANT))); // GB9c

    // Special support for GB9c.  Don't break between two consonants
    // separated 1+ linker characters and 0+ extend characters in any order.
    // After a consonant, we enter LINKER state after at least one linker.
    if (ticb = UTF8PROC_INDIC_CONJUNCT_BREAK_CONSONANT) or (state_icb = UTF8PROC_INDIC_CONJUNCT_BREAK_CONSONANT) or
      (state_icb = UTF8PROC_INDIC_CONJUNCT_BREAK_EXTEND) then
      state_icb := ticb
    else if (state_icb = UTF8PROC_INDIC_CONJUNCT_BREAK_LINKER) then
    begin
      if ticb = UTF8PROC_INDIC_CONJUNCT_BREAK_EXTEND then
        state_icb := UTF8PROC_INDIC_CONJUNCT_BREAK_LINKER
      else
        state_icb := ticb;
    end;
    // Special support for GB 12/13 made possible by GB999. After two RI
    // class codepoints we want to force a break. Do this by resetting the
    // second RI's bound class to UTF8PROC_BOUNDCLASS_OTHER, to force a break
    // after that character according to GB999 (unless of course such a break is
    // forbidden by a different rule such as GB9).
    if (state_bc = tbc) and (tbc = UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR) then
      state_bc := UTF8PROC_BOUNDCLASS_OTHER
    // Special support for GB11 (emoji extend* zwj / emoji)
    else if state_bc = UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC then
    begin
      if tbc = UTF8PROC_BOUNDCLASS_EXTEND then// fold EXTEND codepoints into emoji
        state_bc := UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC
      else if tbc = UTF8PROC_BOUNDCLASS_ZWJ then
        state_bc := UTF8PROC_BOUNDCLASS_E_ZWG // state to record emoji+zwg combo
      else
        state_bc := tbc;
    end
    else
      state_bc := tbc;

    state^ := state_bc + (state_icb shl 8);
    exit(break_permitted);
  end
  else
    exit(grapheme_break_simple(lbc, tbc));
end;

function utf8proc_grapheme_break_stateful(c1: utf8proc_int32_t; c2: utf8proc_int32_t; state: Putf8proc_int32_t): boolean;
var
  p1: Putf8proc_property_t;
  p2: Putf8proc_property_t;
begin
  p1 := utf8proc_get_property(c1);
  p2 := utf8proc_get_property(c2);
  Result := grapheme_break_extended(Ord(p1^.boundclass), Ord(p2^.boundclass), Ord(p1^.indic_conjunct_break), Ord(p2^.indic_conjunct_break), state);
end;

function utf8proc_grapheme_break(c1, c2: utf8proc_int32_t): boolean;
begin
  Result := utf8proc_grapheme_break_stateful(c1, c2, nil);
end;

function seqindex_decode_entry(entry: PPutf8proc_uint16_t): utf8proc_int32_t;
var
  entry_cp: utf8proc_int32_t;
begin
  entry_cp := entry^^;
  if (entry_cp and $F800) = $D800 then
  begin
    Inc(entry^, 1);
    entry_cp := ((entry_cp and $03FF) shl 10) or ((entry^^) and $03FF);
    Inc(entry_cp, $10000);
  end;
  Result := entry_cp;
end;

function seqindex_decode_index(seqindex: utf8proc_uint32_t): utf8proc_int32_t;
var
  entry: Putf8proc_uint16_t;
begin
  entry := @utf8proc_sequences[seqindex];
  Result := seqindex_decode_entry(@entry);
end;

function seqindex_write_char_decomposed(seqindex: utf8proc_uint16_t; dst: Putf8proc_int32_t; bufsize: utf8proc_ssize_t;
  options: utf8proc_option_t; last_boundclass: PInteger): utf8proc_ssize_t;
var
  written: utf8proc_ssize_t;
  entry: Putf8proc_uint16_t;
  len: integer;
  entry_cp: utf8proc_int32_t;
  lsize: utf8proc_ssize_t;
  ldst: Putf8proc_int32_t;
begin
  written := 0;
  entry := @utf8proc_sequences[seqindex and $3FFF];
  len := seqindex shr 14;
  if len >= 3 then
  begin
    len := entry^;
    Inc(entry);
  end;

  while len >= 0 do
  begin
    entry_cp := seqindex_decode_entry(@entry);

    ldst := dst;
    if dst <> nil then
      Inc(ldst, written);

    lsize := 0;
    if bufsize > written then
      lsize := bufsize - written;
    Inc(written, utf8proc_decompose_char(entry_cp, ldst, lsize, options, last_boundclass));
    if (written < 0) then
      exit(UTF8PROC_ERROR_OVERFLOW);
    Inc(entry);
    Dec(len);
  end;
  Result := written;
end;

function utf8proc_tolower(c: utf8proc_int32_t): utf8proc_int32_t;
var
  cl: utf8proc_int32_t;
begin
  cl := utf8proc_get_property(c)^.lowercase_seqindex;
  if cl <> UINT16_MAX then
    Result := seqindex_decode_index(utf8proc_uint32_t(cl))
  else
    Result := c;  //Domingo Maybe better return $FFFD REPLACEMENT CHARACTER
end;

function utf8proc_toupper(c: utf8proc_int32_t): utf8proc_int32_t;
var
  cu: utf8proc_int32_t;
begin
  cu := utf8proc_get_property(c)^.uppercase_seqindex;
  if cu <> UINT16_MAX then
    Result := seqindex_decode_index(utf8proc_uint32_t(cu))
  else
    Result := c;  //Domingo Maybe better return $FFFD REPLACEMENT CHARACTER
end;

function utf8proc_totitle(c: utf8proc_int32_t): utf8proc_int32_t;
var
  cu: utf8proc_int32_t;
begin
  cu := utf8proc_get_property(c)^.titlecase_seqindex;
  if cu <> UINT16_MAX then
    Result := seqindex_decode_index(utf8proc_uint32_t(cu))
  else
    Result := c;   //Domingo Maybe better return $FFFD REPLACEMENT CHARACTER
end;


function utf8proc_islower(c: utf8proc_int32_t): boolean;
var
  P: Putf8proc_property_t;
begin
  p := utf8proc_get_property(c);
  Result := (p^.lowercase_seqindex <> p^.uppercase_seqindex) and (p^.lowercase_seqindex = UINT16_MAX);
end;

function utf8proc_isupper(c: utf8proc_int32_t): boolean;
var
  P: Putf8proc_property_t;
begin
  p := utf8proc_get_property(c);
  Result := (p^.lowercase_seqindex <> p^.uppercase_seqindex) and (p^.uppercase_seqindex = UINT16_MAX) and (p^.category <> UTF8PROC_CATEGORY_LT);
end;


{* return a character width analogous to wcwidth (except portable and
   hopefully less buggy than most system wcwidth functions). *}
function utf8proc_charwidth(c: utf8proc_int32_t): integer;
begin
  Result := utf8proc_get_property(c)^.charwidth;
end;

function utf8proc_charwidth_ambiguous(c: utf8proc_int32_t): boolean;
begin
  Result := utf8proc_get_property(c)^.ambiguous_width;
end;

function utf8proc_category(c: utf8proc_int32_t): utf8proc_category_t;
begin
  Result := utf8proc_category_t(utf8proc_get_property(c)^.category);
end;

const
  cat_str: array[0..29] of string = ('Cn', 'Lu', 'Ll', 'Lt', 'Lm', 'Lo', 'Mn', 'Mc', 'Me', 'Nd', 'Nl', 'No', 'Pc', 'Pd', 'Ps', 'Pe', 'Pi',
    'Pf', 'Po', 'Sm', 'Sc', 'Sk', 'So', 'Zs', 'Zl', 'Zp', 'Cc', 'Cf', 'Cs', 'Co');

function utf8proc_category_string(c: utf8proc_int32_t): ansistring;
begin
  if (c >= 0) and (c <= 29) then
    Result := cat_str[Ord(utf8proc_category(c))]
  else
    Result := '';
end;

function utf8proc_decompose_char(uc: utf8proc_int32_t; dst: Putf8proc_int32_t; bufsize: utf8proc_ssize_t; options: utf8proc_option_t;
  last_boundclass: PInteger): utf8proc_ssize_t;
var
  lproperty: Putf8proc_property_t;
  category: utf8proc_category_t;
  hangul_sindex: utf8proc_int32_t;
  hangul_tindex: utf8proc_int32_t;
  boundary: boolean;

  function utf8proc_decompose_lump(replacement_uc: integer): integer;
  begin
    Result := utf8proc_decompose_char(replacement_uc, dst, bufsize, options, last_boundclass);
  end;

begin
  if (uc < 0) or (uc >= $110000) then
    exit(UTF8PROC_ERROR_NOTASSIGNED);
  lproperty := unsafe_get_property(uc);
  category := lproperty^.category;
  hangul_sindex := uc - UTF8PROC_HANGUL_SBASE;
  if (options and (UTF8PROC_COMPOSE or UTF8PROC_DECOMPOSE)) <> 0 then
  begin
    if (hangul_sindex >= 0) and (hangul_sindex < UTF8PROC_HANGUL_SCOUNT) then
    begin
      if (bufsize >= 1) then
      begin
        dst[0] := UTF8PROC_HANGUL_LBASE + hangul_sindex div UTF8PROC_HANGUL_NCOUNT;
        if (bufsize >= 2) then
          dst[1] := UTF8PROC_HANGUL_VBASE + (hangul_sindex mod UTF8PROC_HANGUL_NCOUNT) div UTF8PROC_HANGUL_TCOUNT;
      end;
      hangul_tindex := hangul_sindex mod UTF8PROC_HANGUL_TCOUNT;
      if (hangul_tindex = 0) then
        exit(2);
      if (bufsize >= 3) then
        dst[2] := UTF8PROC_HANGUL_TBASE + hangul_tindex;
      exit(3);
    end;
  end;
  if (options and UTF8PROC_REJECTNA) <> 0 then
  begin
    if (Ord(category) <> 0) then
      exit(UTF8PROC_ERROR_NOTASSIGNED);
  end;
  if (options and UTF8PROC_IGNORE) <> 0 then
  begin
    if (lproperty^.ignorable) then
      exit(0);
  end;
  if (options and UTF8PROC_STRIPNA) <> 0 then
  begin
    if Ord(category) = 0 then
      exit(0);
  end;
  if (options and UTF8PROC_LUMP) <> 0 then
  begin
    if (category = UTF8PROC_CATEGORY_ZS) then
      utf8proc_decompose_lump($0020);
    if (uc = $2018) or (uc = $2019) or (uc = $02BC) or (uc = $02C8) then
      utf8proc_decompose_lump($0027);
    if (category = UTF8PROC_CATEGORY_PD) or (uc = $2212) then
      utf8proc_decompose_lump($002D);
    if (uc = $2044) or (uc = $2215) then
      utf8proc_decompose_lump($002F);
    if (uc = $2236) then
      utf8proc_decompose_lump($003A);
    if (uc = $2039) or (uc = $2329) or (uc = $3008) then
      utf8proc_decompose_lump($003C);
    if (uc = $203A) or (uc = $232A) or (uc = $3009) then
      utf8proc_decompose_lump($003E);
    if (uc = $2216) then
      utf8proc_decompose_lump($005C);
    if (uc = $02C4) or (uc = $02C6) or (uc = $2038) or (uc = $2303) then
      utf8proc_decompose_lump($005E);
    if (category = UTF8PROC_CATEGORY_PC) or (uc = $02CD) then
      utf8proc_decompose_lump($005F);
    if (uc = $02CB) then
      utf8proc_decompose_lump($0060);
    if (uc = $2223) then
      utf8proc_decompose_lump($007C);
    if (uc = $223C) then
      utf8proc_decompose_lump($007E);
    if (((options and UTF8PROC_NLF2LS) <> 0) and ((options and UTF8PROC_NLF2PS) <> 0)) then
    begin
      if (category = UTF8PROC_CATEGORY_ZL) or (category = UTF8PROC_CATEGORY_ZP) then
        utf8proc_decompose_lump($000A);
    end;
  end;
  if (options and UTF8PROC_STRIPMARK) <> 0 then
  begin
    if (category = UTF8PROC_CATEGORY_MN) or (category = UTF8PROC_CATEGORY_MC) or (category = UTF8PROC_CATEGORY_ME) then
      exit(0);
  end;
  if (options and UTF8PROC_CASEFOLD) <> 0 then
  begin
    if (lproperty^.casefold_seqindex <> UINT16_MAX) then
    begin
      exit(seqindex_write_char_decomposed(lproperty^.casefold_seqindex, dst, bufsize, options, last_boundclass));
    end;
  end;
  if (options and (UTF8PROC_COMPOSE or UTF8PROC_DECOMPOSE)) <> 0 then
  begin
    if (lproperty^.decomp_seqindex <> UINT16_MAX) and ((lproperty^.decomp_type = 0) or ((options and UTF8PROC_COMPAT) <> 0)) then
    begin
      exit(seqindex_write_char_decomposed(lproperty^.decomp_seqindex, dst, bufsize, options, last_boundclass));
    end;
  end;
  if (options and UTF8PROC_CHARBOUND) <> 0 then
  begin
    boundary := grapheme_break_extended(0, Ord(lproperty^.boundclass), 0, Ord(lproperty^.indic_conjunct_break), last_boundclass);
    if boundary then
    begin
      if (bufsize >= 1) then
        dst[0] := -1; //* sentinel value for grapheme break
      if (bufsize >= 2) then
        dst[1] := uc;
      exit(2);
    end;
  end;
  if (bufsize >= 1) then
    dst^ := uc;
  exit(1);
end;

function utf8proc_decompose_utf8(str: pansichar; strlen: utf8proc_ssize_t; buffer: Putf8proc_int32_t; bufsize: utf8proc_ssize_t;
  options: utf8proc_option_t): utf8proc_ssize_t;
begin
  Result := utf8proc_decompose_custom(str, strlen, buffer, bufsize, options, nil, nil);
end;

function utf8proc_decompose_custom(str: pansichar; strlen: utf8proc_ssize_t; buffer: Putf8proc_int32_t; bufsize: utf8proc_ssize_t;
  options: utf8proc_option_t; custom_func: utf8proc_custom_func; custom_data: Pointer): utf8proc_ssize_t;
var
  wpos: utf8proc_ssize_t;
  uc: utf8proc_int32_t;
  rpos: utf8proc_ssize_t;
  decomp_result: utf8proc_ssize_t;
  boundclass: integer;
  uc1, uc2: utf8proc_int32_t;
  pr: Putf8proc_int32_t;
  ps: utf8proc_ssize_t;
  property1, property2: Putf8proc_property_t;
  pos: utf8proc_ssize_t;
begin
  {* strlen will be ignored, if UTF8PROC_NULLTERM is set in options *}
  wpos := 0;
  if ((options and UTF8PROC_COMPOSE) <> 0) and ((options and UTF8PROC_DECOMPOSE) <> 0) then
    exit(UTF8PROC_ERROR_INVALIDOPTS);
  if ((options and UTF8PROC_STRIPMARK) <> 0) and ((options and UTF8PROC_COMPOSE) = 0) and ((options and UTF8PROC_DECOMPOSE) = 0) then
    exit(UTF8PROC_ERROR_INVALIDOPTS);

  rpos := 0;
  boundclass := Ord(UTF8PROC_BOUNDCLASS_START);
  while True do
  begin
    if (options and UTF8PROC_NULLTERM) <> 0 then
    begin
      Inc(rpos, utf8proc_iterate(str + rpos, -1, @uc));
      {* checking of return value is not necessary,
         as 'uc' is < 0 in case of error *}
      if (uc < 0) then
        exit(UTF8PROC_ERROR_INVALIDUTF8);
      if (rpos < 0) then
        exit(UTF8PROC_ERROR_OVERFLOW);
      if (uc = 0) then
        break;
    end
    else
    begin
      if (rpos >= strlen) then
        break;
      Inc(rpos, utf8proc_iterate(str + rpos, strlen - rpos, @uc));
      if (uc < 0) then
        exit(UTF8PROC_ERROR_INVALIDUTF8);
    end;
    if assigned(custom_func) then
      uc := custom_func(uc, custom_data);   {* user-specified custom mapping *}
    pr := buffer;
    if buffer <> nil then
      Inc(pr, wpos);
    if bufsize > wpos then
      ps := bufsize - wpos
    else
      ps := 0;
    decomp_result := utf8proc_decompose_char(uc, pr, ps, options, @boundclass);
    if (decomp_result < 0) then
      exit(decomp_result);
    Inc(wpos, decomp_result);
    {/* prohibiting integer overflows due to too long strings: *}
    if (wpos < 0) or (wpos > utf8proc_ssize_t((SSIZE_MAX div sizeof(utf8proc_int32_t) div 2))) then
      exit(UTF8PROC_ERROR_OVERFLOW);
  end;

  if ((options and (UTF8PROC_COMPOSE or UTF8PROC_DECOMPOSE)) <> 0) and (bufsize >= wpos) then
  begin
    pos := 0;
    while pos < (wpos - 1) do
    begin
      uc1 := buffer[pos];
      uc2 := buffer[pos + 1];
      property1 := unsafe_get_property(uc1);
      property2 := unsafe_get_property(uc2);
      if (property1^.combining_class > property2^.combining_class) and (property2^.combining_class > 0) then
      begin
        buffer[pos] := uc2;
        buffer[pos + 1] := uc1;
        if (pos > 0) then
          Dec(pos)
        else
          Inc(pos);
      end
      else
        Inc(pos);
    end;
  end;
  exit(wpos);
end;


function utf8proc_normalize_utf32(buffer: Putf8proc_int32_t; length: utf8proc_ssize_t; options: utf8proc_option_t): utf8proc_ssize_t;
var
  rpos: utf8proc_ssize_t;
  wpos: utf8proc_ssize_t;
  uc: utf8proc_int32_t;

  starter: Putf8proc_int32_t;
  starter_property: Putf8proc_property_t;
  max_combining_class: utf8proc_propval_t;
  current_char: utf8proc_int32_t;
  current_property: Putf8proc_property_t;
  hangul_lindex: utf8proc_int32_t;
  hangul_sindex: utf8proc_int32_t;
  hangul_vindex: utf8proc_int32_t;
  hangul_tindex: utf8proc_int32_t;

  len: integer;
  max_second: utf8proc_int32_t;
  off: integer;
  second: utf8proc_int32_t;
  composition: utf8proc_int32_t;
  idx: integer;
begin
  {* UTF8PROC_NULLTERM option will be ignored, 'length' is never ignored *}
  if (options and (UTF8PROC_NLF2LS or UTF8PROC_NLF2PS or UTF8PROC_STRIPCC) <> 0) then
  begin
    wpos := 0;
    rpos := 0;
    while rpos < length do
    begin
      uc := buffer[rpos];
      if (uc = $000D) and (rpos < (length - 1)) and (buffer[rpos + 1] = $000A) then
        Inc(rpos);
      if (uc = $000A) or (uc = $000D) or (uc = $0085) or (((options and UTF8PROC_STRIPCC) <> 0) and (((uc = $000B) or (uc = $000C)))) then
      begin
        if (options and UTF8PROC_NLF2LS) <> 0 then
        begin
          if (options and UTF8PROC_NLF2PS) <> 0 then
          begin
            buffer[wpos] := $000A;
            Inc(wpos);
          end
          else
          begin
            buffer[wpos] := $2028;
            Inc(wpos);
          end;
        end
        else
        begin
          if (options and UTF8PROC_NLF2PS) <> 0 then
          begin
            buffer[wpos] := $2029;
            Inc(wpos);
          end
          else
          begin
            buffer[wpos] := $0020;
            Inc(wpos);
          end;
        end;
      end
      else if (((options and UTF8PROC_STRIPCC) <> 0) and ((uc < $0020) or ((uc >= $007F) and (uc < $00A0)))) then
      begin
        if (uc = $0009) then
        begin
          buffer[wpos] := $0020;
          Inc(wpos);
        end;
      end
      else
      begin
        buffer[wpos] := uc;
        Inc(wpos);
      end;
      Inc(rpos);
    end;
    length := wpos;
  end;
  if (options and UTF8PROC_COMPOSE) <> 0 then
  begin
    starter := nil;
    starter_property := nil;
    max_combining_class := -1;
    wpos := 0;
    rpos := 0;
    while rpos < length do
    begin
      current_char := buffer[rpos];
      current_property := unsafe_get_property(current_char);
      if (starter <> nil) and (current_property^.combining_class > max_combining_class) then
      begin
        {* combination perhaps possible *}
        hangul_lindex := starter^ - UTF8PROC_HANGUL_LBASE;
        if (hangul_lindex >= 0) and (hangul_lindex < UTF8PROC_HANGUL_LCOUNT) then
        begin
          hangul_vindex := current_char - UTF8PROC_HANGUL_VBASE;
          if (hangul_vindex >= 0) and (hangul_vindex < UTF8PROC_HANGUL_VCOUNT) then
          begin
            starter^ := UTF8PROC_HANGUL_SBASE + (hangul_lindex * UTF8PROC_HANGUL_VCOUNT + hangul_vindex) * UTF8PROC_HANGUL_TCOUNT;
            starter_property := nil;
            Inc(rpos);
            continue;
          end;
        end;
        hangul_sindex := starter^ - UTF8PROC_HANGUL_SBASE;
        if (hangul_sindex >= 0) and (hangul_sindex < UTF8PROC_HANGUL_SCOUNT) and ((hangul_sindex mod UTF8PROC_HANGUL_TCOUNT) = 0) then
        begin
          hangul_tindex := current_char - UTF8PROC_HANGUL_TBASE;
          if (hangul_tindex >= 0) and (hangul_tindex < UTF8PROC_HANGUL_TCOUNT) then
          begin
            starter^ := starter^ + hangul_tindex;
            starter_property := nil;
            Inc(rpos);
            continue;
          end;
        end;
        if starter_property = nil then
        begin
          starter_property := unsafe_get_property(starter^);
        end;
        idx := starter_property^.comb_index;
        if (idx < $3FF) and (current_property^.comb_issecond) then
        begin
          len := starter_property^.comb_length;
          max_second := utf8proc_combinations_second[idx + len - 1];
          if (current_char <= max_second) then
          begin
            // TODO: binary search? arithmetic search?
            off := 0;
            while off < len do
            begin
              second := utf8proc_combinations_second[idx + off];
              if (current_char < second) then
              begin
                {* not found *}
                break;
              end;
              if (current_char = second) then
              begin
                {* found *}
                composition := utf8proc_combinations_combined[idx + off];
                starter^ := composition;
                starter_property := nil;
                break;
              end;
              Inc(off);
            end;
            if (starter_property = nil) then
            begin
              {* found *}
              Inc(rpos);
              continue;
            end;
          end;
        end;
      end;
      buffer[wpos] := current_char;
      if Ord(current_property^.combining_class) <> 0 then
      begin
        if (current_property^.combining_class > max_combining_class) then
        begin
          max_combining_class := current_property^.combining_class;
        end;
      end
      else
      begin
        starter := buffer + wpos;
        starter_property := nil;
        max_combining_class := -1;
      end;
      Inc(wpos);
      Inc(rpos);
    end;
    length := wpos;
  end;
  exit(length);
end;

function utf8proc_reencode(buffer: Putf8proc_int32_t; length: utf8proc_ssize_t; options: utf8proc_option_t): utf8proc_ssize_t;
var
  rpos, wpos: utf8proc_ssize_t;
  uc: utf8proc_int32_t;
begin
  {* UTF8PROC_NULLTERM option will be ignored, 'length' is never ignored
     ASSERT: 'buffer' has one spare byte of free space at the end not  *}
  length := utf8proc_normalize_utf32(buffer, length, options);
  if (length < 0) then
    exit(length);
  wpos := 0;
  if (options and UTF8PROC_CHARBOUND) <> 0 then
  begin
    rpos := 0;
    while rpos < length do
    begin
      uc := buffer[rpos];
      Inc(wpos, charbound_encode_char(uc, pointer(buffer) + wpos));
      Inc(rpos);
    end;
  end
  else
  begin
    rpos := 0;
    while rpos < length do
    begin
      uc := buffer[rpos];
      Inc(wpos, utf8proc_encode_char(uc, pointer(buffer) + wpos));
      Inc(rpos);
    end;
  end;
  pbyte(buffer)[wpos] := 0;
  exit(wpos);
end;

function utf8proc_map(str: pansichar; strlen: utf8proc_ssize_t; dstptr: PPAnsiChar; options: utf8proc_option_t): utf8proc_ssize_t;
begin
  exit(utf8proc_map_custom(str, strlen, dstptr, options, nil, nil));
end;

function utf8proc_map_custom(str: pansichar; strlen: utf8proc_ssize_t; dstptr: PPAnsiChar; options: utf8proc_option_t;
  custom_func: utf8proc_custom_func; custom_data: Pointer): utf8proc_ssize_t; overload;
var
  buffer: Putf8proc_int32_t;
  //utf8proc_ssize_t result;
  newptr: Putf8proc_int32_t;
begin
  dstptr^ := nil;
  Result := utf8proc_decompose_custom(str, strlen, nil, 0, options, custom_func, custom_data);
  if (Result < 0) then
    exit(Result);
  try
    buffer := GetMem(utf8proc_size_t(Result) * sizeof(utf8proc_int32_t) + 1);
    if buffer = nil then
      exit(UTF8PROC_ERROR_NOMEM);
    Result := utf8proc_decompose_custom(str, strlen, buffer, Result, options, custom_func, custom_data);
    if Result < 0 then
    begin
      FreeMem(buffer);
      exit(Result);
    end;
    Result := utf8proc_reencode(buffer, Result, options);
    if Result < 0 then
    begin
      FreeMem(buffer);
      exit(Result);
    end;
    newptr := Putf8proc_int32_t(ReallocMem(buffer, size_t(Result) + 1));
    //newptr := Putf8proc_int32_t( realloc(buffer, size_t(result)+1) );
    if newptr <> nil then
      buffer := newptr;
    dstptr^ := pointer(buffer);
    exit(Result);
  except
    Result := UTF8PROC_ERROR_NOMEM;
  end;
end;

function utf8proc_NFD(str: pansichar): pansichar;
var
  retval: pansichar;
begin
  utf8proc_map(str, 0, @retval, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_DECOMPOSE);
  exit(retval);
end;

function utf8proc_NFC(str: pansichar): pansichar;
var
  retval: pansichar;
begin
  utf8proc_map(str, 0, @retval, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_COMPOSE);
  exit(retval);
end;

function utf8proc_NFKD(str: pansichar): pansichar;
var
  retval: pansichar;
begin
  utf8proc_map(str, 0, @retval, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_DECOMPOSE or UTF8PROC_COMPAT);
  exit(retval);
end;

function utf8proc_NFKC(str: pansichar): pansichar;
var
  retval: pansichar;
begin
  utf8proc_map(str, 0, @retval, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT);
  exit(retval);
end;

function utf8proc_NFKC_Casefold(str: pansichar): pansichar;
var
  retval: pansichar;
begin
  utf8proc_map(str, 0, @retval, UTF8PROC_NULLTERM or UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT or UTF8PROC_CASEFOLD or UTF8PROC_IGNORE);
  exit(retval);
end;


// ADDED TO THE PASCAL VERSION.


procedure utf8proc_free(ptr: Pointer);
begin
  FreeMem(ptr);
end;


{$ifdef OLD_IMPLEMENTATION}
// needs more buffer copy than new implementation.
function utf8procNormalizeNFD(AStr: rawbytestring): rawbytestring;
var
  tmp: pansichar;
begin
  tmp := utf8proc_NFD(pansichar(AStr));
  Result := tmp;
  FreeMem(tmp);
end;

function utf8procNormalizeNFC(AStr: rawbytestring): rawbytestring;
var
  tmp: pansichar;
begin
  tmp := utf8proc_NFC(pansichar(AStr));
  Result := tmp;
  FreeMem(tmp);
end;

function utf8procNormalizeNFKD(AStr: rawbytestring): rawbytestring;
var
  tmp: pansichar;
begin
  tmp := utf8proc_NFKD(pansichar(AStr));
  Result := tmp;
  FreeMem(tmp);
end;

function utf8procNormalizeNFKC(AStr: rawbytestring): rawbytestring;
var
  tmp: pansichar;
begin
  tmp := utf8proc_NFKC(pansichar(AStr));
  Result := tmp;
  FreeMem(tmp);
end;

function utf8procNormalizeNFKDCaseFold(AStr: rawbytestring): rawbytestring;
var
  tmp: pansichar;
begin
  tmp := utf8proc_NFKC_casefold(pansichar(AStr));
  Result := tmp;
  FreeMem(tmp);
end;

{$else}

function utf8procNormalizeNFD(AStr: rawbytestring): rawbytestring;
begin
  utf8proc_map_custom(Astr, Result, UTF8PROC_STABLE or UTF8PROC_DECOMPOSE);
end;

function utf8procNormalizeNFC(AStr: rawbytestring): rawbytestring;
begin
  utf8proc_map_custom(Astr, Result, UTF8PROC_STABLE or UTF8PROC_COMPOSE);
end;

function utf8procNormalizeNFKD(AStr: rawbytestring): rawbytestring;
begin
  utf8proc_map_custom(Astr, Result, UTF8PROC_STABLE or UTF8PROC_DECOMPOSE or UTF8PROC_COMPAT);
end;

function utf8procNormalizeNFKC(AStr: rawbytestring): rawbytestring;
begin
  utf8proc_map_custom(Astr, Result, UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT);
end;

function utf8procNormalizeNFKDCaseFold(AStr: rawbytestring): rawbytestring;
begin
  utf8proc_map_custom(Astr, Result, UTF8PROC_STABLE or UTF8PROC_COMPOSE or UTF8PROC_COMPAT or UTF8PROC_CASEFOLD or UTF8PROC_IGNORE);
end;

{$endif}

//avoid conversions and copys, Use the dststr string as buffer.
function utf8proc_map_custom(const str: rawbytestring; out dststr: rawbytestring; options: utf8proc_option_t;
  custom_func: utf8proc_custom_func = nil; custom_data: Pointer = nil): utf8proc_ssize_t; overload;
var
  strlen: utf8proc_ssize_t;
  buffer: Putf8proc_int32_t;
begin
  strlen := Length(str);
  if strlen <= 0 then
  begin
    dststr := '';
    exit(strlen);
  end;
  Result := utf8proc_decompose_custom(Pointer(str), strlen, nil, 0, options, custom_func, custom_data);
  if (Result < 0) then
    exit(Result);
  try
    uniquestring(dststr);
    SetLength(dststr, utf8proc_size_t(Result) * sizeof(utf8proc_int32_t) {+ 1});
    buffer := @dststr[1];
    if buffer = nil then
      exit(UTF8PROC_ERROR_NOMEM);
    Result := utf8proc_decompose_custom(Pointer(str), strlen, buffer, Result, options, custom_func, custom_data);
    if Result >= 0 then
      Result := utf8proc_reencode(buffer, Result, options);
    if Result < 0 then
    begin
      dststr := '';
      exit(Result);
    end;
    SetLength(dststr, Result);
    exit(Result);
  except
    Result := UTF8PROC_ERROR_NOMEM;
  end;
end;

end.
