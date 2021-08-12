if exists('*list2str') && exists('*str2list')
  fun! s:list2str(list)
    return list2str(a:list)
  endfun
  fun! s:str2list(str)
    return str2list(a:str)
  endfun
else
  fun! s:list2str(list)
    return join(map(a:list, {_, v -> nr2char(v)}), '')
  endfun
  fun! s:str2list(str)
    return map(split(a:str, '\zs'), {_, v -> char2nr(v)})
  endfun
endif

let s:LOWER1 = 'abcdefghijklmnopqrstuvwxyz'
let s:UPPER1 = toupper(s:LOWER1)
let s:LOWER2 = s:str2list(s:LOWER1.'`1234567890-=[]\;'',./')
let s:UPPER2 = s:str2list(s:UPPER1.'~!@#$%^&*()_+{}|:"<>?')
let s:LOWER1 = s:str2list(s:LOWER1)
let s:UPPER1 = s:str2list(s:UPPER1)

fun! s:getoptions() abort
  let chars = get(g:, 'bufjump_chars', 'fjghdkslaeiruwoqpytbnvmcxz')
  if type(chars) != v:t_string
    throw 'g:bufjump_chars is not a string'
  endif
  if len(chars) <= 0
    throw 'g:bufjump_chars is an empty string'
  endif
  let s:chars = chars
  let s:charl = strlen(chars)

  let algo = get(g:, 'bufjump_algorithm', 2)
  if type(algo) != v:t_number
    throw 'g:bufjump_algorithm is not a number'
  endif
  if algo < 0
    throw 'invalid g:bufjump_algorithm value'
  endif
  let s:algo = algo

  let ignorecase = get(g:, 'bufjump_ignorecase', 1)
  if type(ignorecase) != v:t_number
    throw 'g:bufjump_ignorecase is not a number'
  endif
  if ignorecase < 0 || ignorecase > 2
    throw 'invalid g:bufjump_ignorecase value'
  endif
  let s:ignorecase = ignorecase
endfun

fun! s:tolowerchar(char) abort
  if s:ignorecase == 1
    let i = index(s:UPPER1, a:char)
    return i < 0 ? a:char : s:LOWER1[i]
  elseif s:ignorecase == 2
    let i = index(s:UPPER2, a:char)
    return i < 0 ? a:char : s:LOWER2[i]
  else
    return a:char
  endif
endfun

fun! s:tolower(str) abort
  if type(a:str) != v:t_string
    throw 'a:str is not a string'
  endif
  return s:list2str(map(s:str2list(a:str), {_,v -> s:tolowerchar(v)}))
endfun

fun! s:hash(num) abort
  let x = a:num
  if s:algo == 0
    let s = ''
    while 1
      let r = x % s:charl
      let x = x / s:charl
      let s = s:chars[r].s
      if x == 0
        break
      endif
      let x = x - 1
    endwhile
    return s
  elseif s:algo > 0
    let s = ''
    while 1
      let r = x % s:charl
      let x = x / s:charl
      let s = s:chars[r].s
      if x == 0
        break
      endif
    endwhile
    let i = s:algo - len(s)
    while i > 0
      let s = s:chars[0].s
      let i = i - 1
    endwhile
    return s
  else
    throw 'unknown algorithm'
  endif
endfun

fun! s:unhash(str) abort
  let l = s:str2list(s:chars)
  let s = s:str2list(a:str)
  let x = 0
  if s:algo == 0
    for c in s
      let i = index(l, c)
      if i < 0
        throw 'invalid character'
      endif
      let x = x * s:charl
      let x = x + i + 1
    endfor
    let x = x - 1
    return x
  elseif s:algo > 0
    for c in s
      let i = index(l, c)
      if i < 0
        throw 'invalid character'
      endif
      let x = x * s:charl
      let x = x + i
    endfor
    return x
  else
    throw 'unknown algorithm'
  endif
endfun

fun! s:renderbuffers() abort
  let bufs = []
  let width = 0
  for b in getbufinfo({'buflisted': 1})
    let hash = s:hash(b.bufnr - 1)
    let name = fnamemodify(b.name, ':~:.')
    let w = len(hash) + len(name) + 3
    if w > width
      let width = w
    endif
    call add(bufs, [hash, name])
  endfor
  let cols = &columns / width
  let col = &columns / cols - 1
  let i = len(bufs)
  let l = ''
  while i > 0
    let i = i - 1
    let n = (bufs[i][0]).' '.(bufs[i][1])
    let p = repeat(' ', col - len(n))
    let l = n.p.l
    if i % cols == 0
      echo l
      let l = ''
    endif
  endwhile
  if l !=# ''
    echo l
  endif
endfun

fun! bufjump#select() abort
  call s:getoptions()
  call s:renderbuffers()

  let chars = s:str2list(s:chars)

  if s:algo == 0
    let res = s:tolower(input(':'))
    for x in s:str2list(res)
      if index(chars, x) < 0
        echohl ErrorMsg
        echomsg 'Invalid input'
        echohl None
        return
      endif
    endfor
  else
    echo ':'
    let i = s:algo
    let res = ''
    while i > 0
      let c = s:tolowerchar(getchar())
      if index(chars, c) < 0
        redraw
        return
      endif
      let c = nr2char(c)
      echon c
      let res = res . c
      let i = i - 1
    endwhile
  endif

  redraw
  if len(res) == 0
    return
  endif

  let b = s:unhash(res) + 1
  if !bufexists(b)
    echohl ErrorMsg
    echomsg 'Invalid buffer'
    echohl None
    return
  endif
  exe 'b'.b
endfun

" fun! HashTest() abort
"   for a in range(0, 500)
"     let b = s:unhash(s:hash(a))
"     if a != b
"       throw a.' != '.b
"     endif
"   endfor
" endfun

" vim: tw=80 sw=2 et
