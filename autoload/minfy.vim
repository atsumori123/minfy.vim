let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" filer manage function
"---------------------------------------------------------------
" initialize minfy
function! s:filer_init(dir) abort
	let b:minfy = {}
	let b:minfy['current_dir'] = a:dir
	let b:minfy['last_dir'] = ""
	let b:minfy['show_hidden'] = 0
	let b:minfy['items'] = []
endfunction

" move to parent directory
function! s:filer_to_parent() abort
	let b:minfy['last_dir'] = b:minfy['current_dir']
	let b:minfy['current_dir'] = fnameescape(fnamemodify(b:minfy['last_dir'], ':h'))
	let b:minfy['items'] = s:get_items_from_dir(b:minfy['current_dir'], b:minfy['show_hidden'])
endfunction

" move to child directory
function! s:filer_to_child(dir) abort
	let b:minfy['last_dir'] = b:minfy['current_dir']
	let b:minfy['current_dir'] = a:dir
	let b:minfy['items'] = s:get_items_from_dir(a:dir, b:minfy['show_hidden'])
endfunction

" set toggle hidden
function! s:filer_toggle_hidden() abort
	let b:minfy['show_hidden'] = !b:minfy['show_hidden']
	let b:minfy['items'] = s:get_items_from_dir(b:minfy['current_dir'], b:minfy['show_hidden'])
endfunction

" get minfy param
function! s:filer_get_param(key) abort
	return b:minfy[a:key]
endfunction

"---------------------------------------------------------------
" name
"---------------------------------------------------------------
function! s:name(base, v) abort
	let type = a:v['type']
	if type ==# 'link' || type ==# 'junction'
		if isdirectory(resolve(a:base .. a:v['name']))
			let type = 'dir'
		endif
	elseif type ==# 'linkd'
		let type = 'dir'
	endif
	return a:v['name'] .. (type ==# 'dir' ? '/' : '')
endfunction

"---------------------------------------------------------------
" compare
"---------------------------------------------------------------
function! s:compare(r1, r2) abort
	let r1_is_dir = a:r1[-1:] ==# '/' ? 1 : 0
	let r2_is_dir = a:r2[-1:] ==# '/' ? 1 : 0
	if r1_is_dir != r2_is_dir
		" Show directory in first
		return r1_is_dir ? -1 : +1
	endif
	return char2nr(a:r1) - char2nr(a:r2)
endfunction

"---------------------------------------------------------------
" get_items_from_dir
"---------------------------------------------------------------
function! s:get_items_from_dir(dir, includes_hidden_files) abort
	if exists('*readdirex')
		let items = map(readdirex(a:dir, '1', {'sort': 'none'}), {_, v -> s:name(a:dir, v)})
	else
		let items = map(readdir(a:dir, '1'), {_, v -> s:name(a:dir, {'type': getftype(a:dir .. '/' .. v), 'name': v})})
	endif
	if !a:includes_hidden_files
		call filter(items, 'v:val =~# "^[^.]"')
	endif
	call sort(items, function('s:compare'))
	return items
endfunction

"---------------------------------------------------------------
" get_cursor_item
"---------------------------------------------------------------
function! s:get_cursor_item() abort
	let sep = has('unix') ? '/' : '\'
	let item = s:filer_get_param("current_dir")
	let item .= item =~ escape(sep, '\').'$' ? '' : sep
	let item .= get(s:filer_get_param("items"), line('.') - 2, "")
	return substitute(item, "\[\\/\]$", "", "g")
endfunction

"---------------------------------------------------------------
" set_keymap
"---------------------------------------------------------------
function! s:set_keymap(map_type) abort
	if a:map_type == "FILER"
		nnoremap <buffer> <silent> <CR> :<C-u>call <SID>open_current('edit', 0)<CR>
		nnoremap <buffer> <silent> l :<C-u>call <SID>open_current('edit', 0)<CR>
		nnoremap <buffer> <silent> L :<C-u>call <SID>open_current('edit', 1)<CR>
		nnoremap <buffer> <silent> v :<C-u>call <SID>open_current('vsplit', 0)<CR>
		nnoremap <buffer> <silent> . :<C-u>call <SID>toggle_hidden()<CR>
		nnoremap <buffer> <silent> f :<C-u>call <SID>skip_cursor()<CR>
		nnoremap <buffer> <silent> b :<C-u>call <SID>bookmark_open()<CR>
		nnoremap <buffer> <silent> h :<C-u>call <SID>open_parent()<CR>
		nnoremap <buffer> <silent> q :<C-u>call <SID>quit()<CR>
		nnoremap <buffer> <silent> a :<C-u>call <SID>bookmark_add()<CR>
		nnoremap <buffer> <silent> e <nop>
		nnoremap <buffer> <silent> K <nop>
		nnoremap <buffer> <silent> J <nop>
		nnoremap <buffer> <silent> d <nop>
	else
		nnoremap <buffer> <silent> <CR> :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> l :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> L :<C-u>call <SID>bookmark_selected('edit', 1)<CR>
		nnoremap <buffer> <silent> v :<C-u>call <SID>bookmark_selected('vsplit', 0)<CR>
		nnoremap <buffer> <silent> . <nop>
		nnoremap <buffer> <silent> b <nop>
		nnoremap <buffer> <silent> h <nop>
		nnoremap <buffer> <silent> q :<C-u>call <SID>bookmark_close()<CR>
		nnoremap <buffer> <silent> a <nop>
		nnoremap <buffer> <silent> e :<C-u>call <SID>bookmark_edit()<CR>
		nnoremap <buffer> <silent> K :<C-u>call <SID>bookmark_updown('up')<CR>
		nnoremap <buffer> <silent> J :<C-u>call <SID>bookmark_updown('down')<CR>
		nnoremap <buffer> <silent> d :<C-u>call <SID>bookmark_delete()<CR>
	endif
endfunction

"---------------------------------------------------------------
" draw_items
"---------------------------------------------------------------
function! s:draw_items() abort
	setlocal modifiable

	" Draw items
	silent! %delete _
	let items = s:filer_get_param('items')
	if empty(items)
		let text = ['  (no items)']
	else
		let text = map(copy(items), 'printf("  %s", v:val)')
	endif

	let path = s:filer_get_param('current_dir')
	let dellen = strlen(path) - (&columns - 10)
	if dellen > 0 | let path = "..".path[dellen:] | endif
	call setline(1, path)
	call setline(2, text)

	setlocal nomodifiable
	setlocal nomodified

	call s:restore_cursor()
	echohl Directory | echomsg printf("%s   [%d items]", path, len(items)) | echohl None
endfunction

"---------------------------------------------------------------
" restore_cursor
"---------------------------------------------------------------
function! s:restore_cursor() abort
	let last_dir = s:filer_get_param("last_dir")
	let last_dir = last_dir ==# "/" ? "/" : split(last_dir, "\[\\/\]")[-1]."/"
	let idx = index(s:filer_get_param('items'), last_dir)
	let lnum = idx == -1 ? 2 : idx + 2
	call cursor([lnum, 1, 0, 1])
endfunction

"---------------------------------------------------------------
" skip_cursor
"---------------------------------------------------------------
function! s:skip_cursor() abort
	let first_match = -1
	let len = line('$')
	let char = nr2char(getchar())
	let match_char = char == "" ? "|" : escape(char, '^$.*[]/~\')
	let replace_char = char == "" ? " " : "|"

	setlocal modifiable

	let n = line(".") + 1
	for i in range(1, len)
		if n > len | let n = 1 | endif
		let str = getline(n)
		if str =~ "^. ".match_char
			call setline(n, replace_char.str[1:])
			if first_match == -1 | let first_match = n | endif
		elseif str =~ "^!"
			call setline(n, " ".str[1:])
		endif
		let n += 1
	endfor

	setlocal nomodifiable

	if char != "" && first_match != -1
		call cursor([first_match, 1, 0, 1])
	endif
endfunction

"---------------------------------------------------------------
" file_open
"---------------------------------------------------------------
function! s:file_open(path, open_cmd, close_and_open) abort
	if isdirectory(a:path)
		call s:filer_to_child(a:path)
		call s:draw_items()
	else
		call s:quit()
		execute printf('%s %s', a:open_cmd, fnameescape(a:path))
		if a:close_and_open
			if bufexists(s:save_bufnr) && bufnr("%") != s:save_bufnr
				if getbufinfo(s:save_bufnr)[0].changed
					echohl WarningMsg
					echomsg 'Unsaved changes in buffer '.s:save_bufnr.'.'
					echohl None
				else
					execute 'bdelete! '.s:save_bufnr
				endif
			endif
		endif
	endif
endfunction

"---------------------------------------------------------------
" init_minfy
"---------------------------------------------------------------
function! s:init_minfy(dir) abort
	enew
	execute printf('silent keepalt file %s', '-minfy-')
	setlocal modifiable
	setlocal filetype=minfy
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nowrap
	setlocal cursorline

	"  keymap
	call s:set_keymap('FILER')

	" hiligh
	syn match minfyDirectory '^  .\+/$'
	syn match minfyHidden '^  \..\+$'
	syn match minfyNoItems '^  (no items)$'
	syn match minfyBookmark '^.*\t'
	syn match minfyCurrentPath '^[^ |].*'
	syn match minfyMatch '^|.*'
	hi! def link minfyDirectory Directory
	hi! def link minfyHidden Comment
	hi! def link minfyNoItems Comment
	hi! def link minfyBookmark Directory
	hi! def link minfyMatch Title
	hi! def link minfyCurrentPath Identifier

	" create first filer
	call s:filer_init(a:dir)
	call s:filer_to_child(a:dir)

	" draw items to buffer
	call s:draw_items()
endfunction

"---------------------------------------------------------------
" open_current
"---------------------------------------------------------------
function! s:open_current(open_cmd, close_and_open) abort
	" next directory open or file open
	if line('.') == 1 | return | endif
	let item_path = s:get_cursor_item()
	if empty(item_path) | return | endif
	call s:file_open(item_path, a:open_cmd, a:close_and_open)
endfunction

"---------------------------------------------------------------
" open_parent
"---------------------------------------------------------------
function! s:open_parent() abort
	call s:filer_to_parent()
	call s:draw_items()
endfunction

"---------------------------------------------------------------
" quit
"---------------------------------------------------------------
function! s:quit() abort
	" Try restoring alternate buffer
	if bufexists(s:save_bufnr) && bufnr('%') != s:save_bufnr
		execute printf('buffer! %d', s:save_bufnr)
	else
		enew
	endif
endfunction

"---------------------------------------------------------------
" toggle_hidden
"---------------------------------------------------------------
function! s:toggle_hidden() abort
	call s:filer_toggle_hidden()
	call s:draw_items()
endfunction

"---------------------------------------------------------------
" bookmark_open
"---------------------------------------------------------------
function! s:bookmark_open() abort
	" Mapping
	call s:set_keymap('BOOKMARK')

	" Load bookmark
	let s:bookmark = s:bookmark_load()
	let output = []
	for bk in s:bookmark
		let wk = split(bk, "\t")
		call add(output, printf("  %-20s\t%s", wk[0], wk[1]))
	endfor

	" Delete the contents of the buffer to the black-hole register
	setlocal modifiable
	silent! %delete _
	call setline(1, "bookmarks")
	call setline(2, output)

	" Delete the empty line at the end of the buffer
	silent! $delete _
	setlocal nomodifiable

	" Move the cursor to the beginning of the file
	call cursor([2, 1, 0, 1])

	let s:bookmark_status = 1
endfunction

"---------------------------------------------------------------
" bookmark_load
"---------------------------------------------------------------
function! s:bookmark_load() abort
	return filereadable(g:minfy_bookmark_file) ? readfile(g:minfy_bookmark_file) : []
endfunction

"---------------------------------------------------------------
" bookmark_save
"---------------------------------------------------------------
function! s:bookmark_save() abort
	call writefile(s:bookmark, g:minfy_bookmark_file)
endfunction

"---------------------------------------------------------------
" bookmark_selected
"---------------------------------------------------------------
function! s:bookmark_selected(open_cmd, close_and_open) abort
	if line('.') == 1 | return | endif

	" If Bookmark changed, it is save
	if s:bookmark_status == 2
		call s:bookmark_save()
	endif

	" open selected item
	let path = substitute(getline("."), ".*\t", "", "")
	if isdirectory(path)
		call s:set_keymap('FILER')
	endif
	call s:file_open(path, a:open_cmd, a:close_and_open)
	let s:bookmark_status = 0
endfunction

"---------------------------------------------------------------
" bookmark_add
"---------------------------------------------------------------
function! s:bookmark_add() abort
	let item = s:get_cursor_item()
	if empty(item) | return | endif

	let abbreviation = input('abbreviation: ')
	let abbreviation = abbreviation[:19]
	if !len(abbreviation)
		return
	endif

	let s:bookmark = s:bookmark_load()

	" Remove the new file name from the existing RF list (if already present)
	call filter(s:bookmark, 'substitute(v:val, ".*\t", "", "") !=# item')

	" Add the new file list to the beginning of the updated old file list
	call insert(s:bookmark, abbreviation."\t".item, 0)

	" Save bookmark file
	call s:bookmark_save()

	echo "\rAdd to bookmark. (".item.")"
endfunction

"---------------------------------------------------------------
" bookmark_edit
"---------------------------------------------------------------
function! s:bookmark_edit() abort
	if line('.') == 1 | return | endif

	let wk = split(s:bookmark[line(".") - 2], "\t")
	let new_path = input('new path: ', wk[1], 'dir')
	let new_path = substitute(new_path, '[/|\\]$', "", "")
	if !len(new_path) | return | endif

	let new_abbreviation = input('new abbreviation: ', wk[0])
	let new_abbreviation = new_abbreviation[:19]
	if !len(new_abbreviation) | return | endif

	let s:bookmark[line(".") - 2] = new_abbreviation."\t".new_path
	setlocal modifiable
	call setline(line("."), printf("  %-20s\t%s", new_abbreviation, new_path))
	setlocal nomodifiable

	let s:bookmark_status = 2
endfunction

"---------------------------------------------------------------
" bookmark_updown
"---------------------------------------------------------------
function! s:bookmark_updown(updown) abort
	let lnum = line(".")
	let next = lnum + (a:updown == 'up' ? -1 : 1)
	if lnum == 1 || next < 2 || next > len(s:bookmark)
		return
	endif

	setlocal modifiable
	let temp1 = remove(s:bookmark, lnum - 2)
	let temp2 = getline(".")
	del _

	call insert(s:bookmark, temp1, next - 2)
	call append(next - 1, temp2)
	call cursor([next, 1, 0, 1])
	setlocal nomodifiable

	let s:bookmark_status = 2
endfunction

"---------------------------------------------------------------
" bookmark_delete
"---------------------------------------------------------------
function! s:bookmark_delete() abort
	if line('.') == 1 | return | endif

	let key = input("Can I delete ? [y/n] ")
	if key != 'y' | return | endif

	let lnum = line(".")
	call remove(s:bookmark, lnum - 2)
	setlocal modifiable
	del _
	setlocal nomodifiable

	let s:bookmark_status = 2
endfunction

"---------------------------------------------------------------
" bookmark_close
"---------------------------------------------------------------
function! s:bookmark_close() abort
	if s:bookmark_status == 2
		call s:bookmark_save()
	endif

	call s:set_keymap('FILER')
	call s:draw_items()

	let s:bookmark_status = 0
endfunction

"---------------------------------------------------------------
" minfy#start
"---------------------------------------------------------------
function! minfy#start(...) abort
	" get directory path. if nothing then current directory path
	let dir = resolve(get(a:000, 0, getcwd()))
	if !isdirectory(dir)
		echohl Error | echomsg "E01: Directory ".dir."doesn't exist" | echohl None
		return
	endif

	" if already minfy exist, return
	if bufwinnr("-minfy-") != -1
		echohl Error | echomsg "E02: Already minfy buffer exist" | echohl None
		return
	endif

	let s:save_bufnr = bufnr("%")
	let s:bookmark_status = 0
	call s:init_minfy(dir)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
