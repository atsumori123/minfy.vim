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

"get items from dir
function! s:filer_get_items(dir) abort
	let b:minfy['items'] = s:get_items_from_dir(a:dir, b:minfy['show_hidden'])
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
function! s:get_cursor_item(fullpath) abort
	if a:fullpath
		let item = s:filer_get_param("current_dir")
		let item .= item =~ escape(s:separator, '\').'$' ? '' : s:separator
	else
		let item = ''
	endif
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
		nnoremap <buffer> <silent> b :<C-u>call <SID>bookmark_open()<CR>
		nnoremap <buffer> <silent> h :<C-u>call <SID>open_parent()<CR>
		nnoremap <buffer> <silent> q :<C-u>call <SID>quit()<CR>
		nnoremap <buffer> <silent> a :<C-u>call <SID>bookmark_add()<CR>
		nnoremap <buffer> <silent> s <nop>
		nnoremap <buffer> <silent> dd :<C-u>call <SID>file_delete()<CR>
		nnoremap <buffer> <silent> <F2> :<C-u>call <SID>file_rename()<CR>
		nnoremap <buffer> <silent> mv :<C-u>call <SID>file_move()<CR>
		nnoremap <buffer> <silent> mk :<C-u>call <SID>file_mkdir()<CR>
		nnoremap <buffer> <silent> e <nop>
		nnoremap <buffer> <silent> K <nop>
		nnoremap <buffer> <silent> J <nop>
		nnoremap <buffer> <silent> d <nop>
		if g:Minfy_use_easymotion == 0
			nnoremap <buffer> <silent> f :<C-u>call <SID>skip_cursor()<CR>
			nnoremap <buffer> <silent> n :<C-u>call <SID>skip_cursor_n(1)<CR>
			nnoremap <buffer> <silent> N :<C-u>call <SID>skip_cursor_n(-1)<CR>
		endif
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
		nnoremap <buffer> <silent> s :<C-u>call <SID>bookmark_separator()<CR>
		nnoremap <buffer> <silent> e :<C-u>call <SID>bookmark_edit()<CR>
		nnoremap <buffer> <silent> K :<C-u>call <SID>bookmark_updown('up')<CR>
		nnoremap <buffer> <silent> J :<C-u>call <SID>bookmark_updown('down')<CR>
		nnoremap <buffer> <silent> dd :<C-u>call <SID>bookmark_delete()<CR>
		nnoremap <buffer> <silent> <F2> :<nop>
		nnoremap <buffer> <silent> mv :<nop>
		nnoremap <buffer> <silent> mk :<nop>
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
"	echohl Directory | echomsg printf("%s   [%d items]", path, len(items)) | echohl None
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
		elseif str =~ "^|"
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
" skip_cursor_n
"---------------------------------------------------------------
function! s:skip_cursor_n(direction) abort
	let n = line(".") + a:direction
	let len = line('$')
	for i in range(1, len)
		if n > len | let n = 2 | endif
		if n < 2 | let n = len | endif
		if getline(n) =~ "^|"
			call cursor([n, 1, 0, 1])
			break
		endif
		let n += a:direction
	endfor
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
	syn match minfyBookmark '^.\{-}\ze('
	syn match minfyCurrentPath '^[^ |].*'
	syn match minfyMatch '^|.*'
	syn match minfySeparator '^\[.\{-}]'
	hi! def link minfyDirectory Directory
	hi! def link minfyHidden Comment
	hi! def link minfyNoItems Comment
	hi! def link minfyBookmark Directory
	hi! def link minfyMatch Title
	hi! def link minfyCurrentPath Identifier
	hi! def link minfySeparator Label

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
	let item_path = s:get_cursor_item(1)
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
" get_last_component
"---------------------------------------------------------------
function! s:get_last_component(path) abort
	return isdirectory(a:path) ? fnamemodify(a:path, ':t') : fnamemodify(a:path, ':p:t')
endfunction

"---------------------------------------------------------------
" err_msg
"---------------------------------------------------------------
function! s:err_msg(msg) abort
	echo "\r"
	echohl Error | echomsg a:msg | echohl None
	return
endfunction

"---------------------------------------------------------------
" refresh
"---------------------------------------------------------------
function! s:refresh() abort
	call s:filer_get_items(s:filer_get_param('current_dir'))
	call s:draw_items()
endfunction

"---------------------------------------------------------------
" file_delete
"---------------------------------------------------------------
function! s:file_delete() abort
	if line('.') == 1 | return | endif
	let item = s:get_cursor_item(0)
	if empty(item) | return | endif

	"confirmation
	let yn = input("Delete '".item."' (y/n)? ")
	if empty(yn) || yn !=? 'y' |  echo "\rCancelled." | return | endif

	"delete option set
	let delete_path = s:filer_get_param('current_dir').s:separator.item
	if !isdirectory(delete_path)
		let flag = ''
	elseif len(s:get_items_from_dir(delete_path, 1)) == 0
		let flag = 'd'
	else
		let yn = input("Directory is not empty. Force delete (y/n)? ")
		if yn ==? 'y'
			let flag = 'rf'
		else
			echo "\rCancelled." | return
		endif
	endif

	"Delete
	if delete(delete_path, flag) < 0
		echo "\rCannot delete file: " . delete_path
	else
		echo "\rDeleted file: ". delete_path
	endif

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_rename
"---------------------------------------------------------------
function! s:file_rename() abort
	if line('.') == 1 | return | endif
	let org_name = s:get_cursor_item(0)
	if empty(org_name) | return | endif

	"Input new filename
	let new_name = input('Input new name: ', org_name)
	if empty(new_name) | echo "\rCancelled." | return | endif

	"Get direcotry (Get parent directory if direcotry)
	let dir = s:filer_get_param('current_dir').s:separator

	"When destination is read only or already exists, not excutable
	if getftype(dir.new_name) != ""
		call s:err_msg("File already exists: ".dir.new_name) | return
	endif

	"Rename
	call rename(dir.org_name, dir.new_name)
	echo 'Renamed file: ' . org_name . ' -> ' . new_name

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_move
"---------------------------------------------------------------
function! s:file_move() abort
	if line('.') == 1 | return | endif
	let src_name = s:get_cursor_item(0)
	if empty(src_name) | return | endif

	"Input destination path
	let src = s:get_cursor_item(1)
	let dst = resolve(input("Move '".src_name."' to: ", s:filer_get_param('current_dir'), 'dir'))
	if empty(dst) | echo "\rCancelled." | return | endif

	"When destination path is not directory, not excutable
	if !isdirectory(dst)
		call s:err_msg("Destination is not a directory: ".dst) | return
	endif

	"Make distination path
	let dst = substitute(dst, '[/|\\]$', "", "")
	let dst .= s:separator.src_name

	"When destination is read only or already exists, not excutable
	if filereadable(dst) || isdirectory(dst)
		call s:err_msg("File already exists: ".dst) | return
	endif

	"Move
	call rename(src, dst)
	echo printf("\rMoved file: '%s' -> '%s'", src_name, dst)

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_mkdir
"---------------------------------------------------------------
function! s:file_mkdir() abort
	let name = input('Input new directory name: ')
	if empty(name) | echo "\rCancelled." | return | endif

	"Input new directory name
	let path = resolve(s:filer_get_param("current_dir").s:separator.name)

	"When destination is read only or already exists, not excutable
	if filereadable(path) || isdirectory(path)
		call s:err_msg("File already exists: ".path) | return
	endif

	" Make new directory
	call mkdir(path, '')
	echo 'Created new directory: '.name

	"Refresh minfy
	call s:refresh()
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
		if wk[0] == "&sep"
			call add(output, "[ ".wk[1]." ]")
		else
			call add(output, "  ".wk[0]." (".wk[1].")")
		endif
	endfor

	" Delete the contents of the buffer to the black-hole register
	setlocal modifiable
	silent! %delete _
	call setline(1, "bookmarks")
	call setline(2, output)

	" Delete the empty line at the end of the buffer
"	silent! $delete _
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
	" 1st line and separaotr are invalid
	if line('.') == 1 || getline(".")[0] == "["
		  return
	endif

	" If Bookmark changed, it is save
	if s:bookmark_status == 2
		call s:bookmark_save()
	endif

	" open selected item
	let path = split(s:bookmark[line(".") - 2], "\t")[1]
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
	let item = s:get_cursor_item(1)
	if empty(item) | return | endif

	let name = input('Input bookmark name: ')
	let name = name[:19]
	if !len(name)
		return
	endif

	let s:bookmark = s:bookmark_load()

	" Remove the new file name from the existing RF list (if already present)
	call filter(s:bookmark, 'substitute(v:val, ".*\t", "", "") !=# item')

	" Add the new file list to the beginning of the updated old file list
	call insert(s:bookmark, name."\t".item, 0)

	" Save bookmark file
	call s:bookmark_save()

	echo "\rAdd to bookmark. (".item.")"
endfunction

"---------------------------------------------------------------
" bookmark_separator
"---------------------------------------------------------------
function! s:bookmark_separator() abort
	let sep_name = input('Input separaotr name: ')
	if !len(sep_name) | return | endif
	call insert(s:bookmark, "&sep\t".sep_name, line(".") - 1)

	setlocal modifiable
	call append(line("."), "[ ".sep_name." ]")
	setlocal nomodifiable

	let s:bookmark_status = 2
endfunction

"---------------------------------------------------------------
" bookmark_edit
"---------------------------------------------------------------
function! s:bookmark_edit() abort
	if line('.') == 1 | return | endif

	let wk = split(s:bookmark[line(".") - 2], "\t")
	if wk[0] == "&sep"
		let new_sep_name = input('Input new separator name: ', wk[1])
		if !len(new_sep_name) | return | endif
		let s:bookmark[line(".") - 2] = "&sep\t".new_sep_name
		let temp = "[ ".new_sep_name." ]"
	else
		let new_path = input('Input new path: ', wk[1], 'dir')
		let new_path = substitute(new_path, '[/|\\]$', "", "")
		if !len(new_path) | return | endif

		let new_name = input('Input new bookmark name: ', wk[0])
		if !len(new_name) | return | endif

		let s:bookmark[line(".") - 2] = new_name."\t".new_path
		let temp = "  ".new_name." (".new_path.")"
	endif

	setlocal modifiable
	call setline(line("."), temp)
	setlocal nomodifiable

	let s:bookmark_status = 2
endfunction

"---------------------------------------------------------------
" bookmark_updown
"---------------------------------------------------------------
function! s:bookmark_updown(updown) abort
	let lnum = line(".")
	let next = lnum + (a:updown == 'up' ? -1 : 1)
	if lnum == 1 || next < 2 || next > len(s:bookmark) + 1
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
		call s:err_msg("E01: Directory ".dir."doesn't exist") | return
	endif

	" if already minfy exist, return
	if bufwinnr("-minfy-") != -1
		call s:err_msg("E02: Already minfy buffer exist") | return
	endif

	let s:separator = has('unix') ? '/' : '\'
	let s:save_bufnr = bufnr("%")
	let s:bookmark_status = 0
	call s:init_minfy(dir)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
