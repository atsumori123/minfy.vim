let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" minfy#util#normalize_path
"---------------------------------------------------------------
function! minfy#util#normalize_path(path) abort
	if a:path ==? '/'
		return '/'
	else
		let result = resolve(a:path)

		" Remove trailing path separator
		return (match(result, '\(/\|\\\)$') >= 0) ? fnamemodify(result, ':h') : result
	endif
endfunction

"---------------------------------------------------------------
" minfy#util#from_path
"---------------------------------------------------------------
function! minfy#util#from_path(path) abort
	let item = {}
	let item.index = -1
	let item.path = minfy#util#normalize_path(a:path)
	let item.is_dir = isdirectory(a:path)
	let item.basename = fnamemodify(a:path, isdirectory(a:path) ? ':t' : ':p:t')

	return item
endfunction

"---------------------------------------------------------------
" minfy#util#error
"---------------------------------------------------------------
function! minfy#util#error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
