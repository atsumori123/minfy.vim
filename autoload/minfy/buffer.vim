let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" generate_unique_bufname
"---------------------------------------------------------------
function! s:generate_unique_bufname(path) abort
	let bufname = ''
	let index = 0

	while 1
		" Add index to avoid duplicated buffer name
		let bufname = fnameescape(printf('minfy://%d/%s', index, a:path))
		if bufnr(bufname) < 0
			break
		endif
		let index += 1
	endwhile

	return bufname
endfunction

"---------------------------------------------------------------
" minfy#buffer#init
"---------------------------------------------------------------
function! minfy#buffer#init(filer) abort
	" Give unique name to buffer to avoid unwanted sync between different windows
	execute printf('silent keepalt file %s', s:generate_unique_bufname(a:filer.dir))

	" Mapping
	execute "nmap <buffer> <silent> <CR> <plug>(minfy-open-current)"
	execute "nmap <buffer> <silent> <S-CR> <plug>(minfy-close-open-current)"
	execute "nmap <buffer> <silent> . <plug>(minfy-toggle-hidden)"
	execute "nmap <buffer> <silent> b <plug>(minfy-open-bookmark)"
	execute "nmap <buffer> <silent> a <plug>(minfy-add-bookmark)"
	execute "nmap <buffer> <silent> l <plug>(minfy-open-current)"
	execute "nmap <buffer> <silent> L <plug>(minfy-close-open-current)"
	execute "nmap <buffer> <silent> h <plug>(minfy-open-parent)"
	execute "nmap <buffer> <silent> q <plug>(minfy-quit)"

	setlocal bufhidden=delete
	setlocal buftype=nowrite
	setlocal filetype=minfy
	setlocal matchpairs=
	setlocal noswapfile
	setlocal nowrap

	" hiligh
	syn match minfyDirectory '^  .\+/$'
	syn match minfyHidden '^  \..\+$'
	syn match minfyNoItems '^  (no items)$'
	hi! def link minfyDirectory Directory
	hi! def link minfyHidden Comment
	hi! def link minfyNoItems Comment

	call minfy#buffer#redraw()
endfunction

"---------------------------------------------------------------
" minfy#buffer#redraw
"---------------------------------------------------------------
function! minfy#buffer#redraw() abort
	setlocal modifiable

	" Clear buffer before drawing items
	silent keepjumps %delete _

	let filer = minfy#buffer#get_filer()
	if empty(filer.items)
		let text = ['  (no items)']
	else
		let text = map(copy(filer.items), 'printf("  %s", v:val.basename.(v:val.is_dir ? "/" : ""))')
	endif
	call setline(1, text)

	setlocal nomodifiable
	setlocal nomodified

	call minfy#buffer#restore_cursor()
endfunction

"---------------------------------------------------------------
" minfy#buffer#restore_cursor
"---------------------------------------------------------------
function! minfy#buffer#restore_cursor() abort
	let filer = minfy#buffer#get_filer()
	let cursor_path = get(filer.cursor_paths, filer.dir, '')

	let lnum = 1
	if !empty(cursor_path)
		let items = filter(copy(filer.items), 'v:val.path ==# cursor_path')
		if !empty(items)
			let lnum = index(filer.items, items[0]) + 1
		endif
	endif
	call cursor([lnum, 1, 0, 1])
endfunction

"---------------------------------------------------------------
" minfy#buffer#save_cursor
"---------------------------------------------------------------
function! minfy#buffer#save_cursor(item) abort
	if empty(a:item) | return | endif
	let filer = minfy#buffer#get_filer()
	let filer.cursor_paths[filer.dir] = a:item.path
	call minfy#buffer#set_filer(filer)
endfunction

"---------------------------------------------------------------
" minfy#buffer#get_filer
"---------------------------------------------------------------
function! minfy#buffer#get_filer() abort
	if !exists('b:minfy')
		let b:minfy = {}
		let b:minfy['cursor_paths'] = {}
		let b:minfy['dir'] = ""
		let b:minfy['show_hidden'] = 0
		let b:minfy['items'] = []
	endif
	return b:minfy
endfunction

"---------------------------------------------------------------
" minfy#buffer#set_filer
"---------------------------------------------------------------
function! minfy#buffer#set_filer(filer) abort
	let b:minfy = a:filer
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
