" Copyright (c) 2014 Marco Hinz
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" - Redistributions of source code must retain the above copyright notice, this
"   list of conditions and the following disclaimer.
" - Redistributions in binary form must reproduce the above copyright notice,
"   this list of conditions and the following disclaimer in the documentation
"   and/or other materials provided with the distribution.
" - Neither the name of the author nor the names of its contributors may be
"   used to endorse or promote products derived from this software without
"   specific prior written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists('g:loaded_matchparenalways') || &cp || !exists('##CursorMoved') || !exists('##CursorMovedI')
  finish
endif
let g:loaded_matchparenalways = 1

let s:group      = get(g:, 'matchparenalways_hl_group', 'MatchParen')
let s:hl_all     = get(g:, 'matchparenalways_hl_all')
let s:priority   = get(g:, 'matchparenalways_hl_priority', -1)
let s:default    = [[ '{', '}' ], [ '(', ')' ], [ '\[', '\]' ]]

let s:pairs = {
      \ 'vim':      extend([['\<if\>','\<endif\>'], ['\<for\>','\<endfor\>']], s:default),
      \ 'clojure':  [[ '(', ')' ], [ '\[', '\]' ], [ '{', '}' ]],
      \}

call extend(s:pairs, get(g:, 'matchparenalways_pairs', {}))

function! s:set_at_enter_buf() abort
  if &filetype !=# 'help'
    augroup matchparenalways
      autocmd! CursorMoved,CursorMovedI
      autocmd CursorMoved,CursorMovedI <buffer> call <sid>highlight_block()
    augroup END
  endif
endfunction

augroup matchparenalways
  autocmd!
  autocmd BufEnter * call s:set_at_enter_buf()
augroup END

function! s:highlight_block() abort
  silent! call matchdelete(w:matchparenalways_hl_id)

  if getchar(1) != 0  "debounce
    return
  endif

  let s:matchpairs = get(s:pairs, &ft, s:default)
  let [pos_open, pos_close]  = [[0,0],[0,0]]

  for [char_open, char_close] in s:matchpairs
    let curchar = matchstr(getline('.'), '.', col('.')-1)
    if curchar != char_open
      let pos_open = searchpairpos(char_open, '', char_close, 'Wnb', '', 0, 20)
      if pos_open[0] >= pos_open[0] && pos_open[1] >= pos_open[1]
        if curchar != char_close
          let pos_close = searchpairpos(char_open, '', char_close, 'Wn', '', 0, 20)
          if pos_close[0] > 0 && pos_close[1] > 0
            let [pos_open, pos_close] = [pos_open, pos_close]
            break
          endif
        endif
      endif
    endif
  endfor

  if pos_open == [0,0] || pos_close == [0,0]
    return
  endif

  let line1 = pos_open[0]
  let col1  = pos_open[1]
  let line2 = pos_close[0]
  let col2  = pos_close[1]

  if s:hl_all
    let col2 += 1
    let w:matchparenalways_hl_id = matchadd(s:group, '\%'.line1.'l\%'.col1.'c.*\_.\+\%'.line2.'l\%'.col2.'c', s:priority)
  else
    let leftmostcol = col1 > col2 ? col2 : col1
    if (line2 - line1) > 2
      " Highlight the leftmost column instead of the actual delimiters.
      let w:matchparenalways_hl_id = matchadd(s:group, '\%>'.line1.'l\%'.leftmostcol.'c\%<'.line2 .'l', s:priority)
    elseif !(exists('w:paren_hl_on') && w:paren_hl_on)
      "    ^ Skip if MatchParen plugin is active (i.e. cursor is on a paren).
      let w:matchparenalways_hl_id = matchadd(s:group, '\%(\%'.line1.'l\%'.col1.'c\)\|\(\%'.line2.'l\%'.col2.'c\)', s:priority)
    endif
  endif
endfunction

" vim:set et sw=2 sts=2:
