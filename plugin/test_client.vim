if !exists("g:test_server_pipe")
  let g:test_server_pipe = $HOME . "/test_server_pipe"
endif

let g:test_cmd_for_test_pattern = {
      \ '_spec.rb$': 'rspec',
      \ '\.feature$': 'cucumber',
      \}

let g:test_cmd_for_src_pattern = {
      \ '\.rb$': 'rspec',
      \ '\.haml$': 'rspec',
      \}

let g:non_test_filename_replacements = [
      \ ['lib/', 'spec/lib/'],
      \ ['app/', 'spec/'],
      \ ['.rb', '_spec.rb'],
      \ ['.haml', '.haml_spec.rb'],
      \]

command! RunTest call s:RunTest()
command! RunTestLine call s:RunTestLine()
command! RunTestAgain call s:RunTestAgain()
command! RunTestPrevious call s:RunTestPrevious()

function! s:RunTest()
if s:TestIsExecutable()
  call s:SendToTestServer(s:AppropriateTestFilename())
endif
endf

function! s:RunTestLine()
if s:InTestFile()
  call s:SendToTestServer(s:AppropriateTestFilename() . ':' . line('.'))
else
  echom "Focused test doesn't make sense (not in a test)."
endif
endf

function! s:RunTestAgain()
if exists("s:last_test_run")
  call s:SendToTestServer(s:last_test_run)
else
  echom "No previous test run"
endif
endf

function! s:RunTestPrevious()
if exists("s:previous_test_run")
  call s:SendToTestServer(s:previous_test_run)
else
  echom "No previous test run"
endif
endf

function! s:AppropriateTestFilename()
let l:filename = expand('%')

if s:InTestFile()
  return s:GetCommand(g:test_cmd_for_test_pattern) . ' ' . l:filename
elseif s:InSrcFile()
  return s:GetCommand(g:test_cmd_for_src_pattern) . ' ' . s:AssociatedTestFilename(l:filename)
endif
endf

function! s:SendToTestServer(command)
if exists("s:last_test_run")
  let s:previous_test_run = s:last_test_run
endif
call writefile([a:command], g:test_server_pipe)
echom "Sent " . a:command
let s:last_test_run = a:command
endf

function! s:GetCommand(dict)
for pattern in keys(a:dict)
  if s:CurrentFileMatches(pattern)
    return a:dict[pattern]
  endif
endfor
endf

function! s:InTestFile()
for pattern in keys(g:test_cmd_for_test_pattern)
  if s:CurrentFileMatches(pattern)
    return 1
  endif
endfor
endf

function! s:InSrcFile()
for pattern in keys(g:test_cmd_for_src_pattern)
  if s:CurrentFileMatches(pattern)
    return 1
  endif
endfor
endf

function! s:CurrentFileMatches(pattern)
return match(expand('%'), a:pattern) > -1
endf

function! s:TestIsExecutable()
return s:InTestFile() || s:InSrcFile()
endf

function! s:AssociatedTestFilename(src_filename)
return s:MultiSubString(a:src_filename, g:non_test_filename_replacements)
endf

function! s:MultiSubString(string, substitutions)
let l:substituted = substitute(a:string, a:substitutions[0][0], a:substitutions[0][1], '')

if len(a:substitutions) == 1
  return l:substituted
else
  return s:MultiSubString(l:substituted, a:substitutions[1:-1])
endif
endf

