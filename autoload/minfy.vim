let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" set_filer
"---------------------------------------------------------------
function! s:set_filer(filer) abort
	let b:minfy = a:filer
endfunction

"---------------------------------------------------------------
" get_filer
"---------------------------------------------------------------
function! s:get_filer() abort
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
" get_full_path
"---------------------------------------------------------------
function! s:get_full_path(path) abort
	if a:path ==? '/'
		return '/'
	else
		" Remove trailing path separator
		let result = resolve(a:path)
		return (match(result, '\(/\|\\\)$') >= 0) ? fnamemodify(result, ':h') : result
	endif
endfunction

"---------------------------------------------------------------
" get_items_from_dir
"---------------------------------------------------------------
function! s:get_items_from_dir(dir, includes_hidden_files) abort
	" get items (xxxx/xxxx/xxxx/abc.txt)
	let escaped_dir = fnameescape(fnamemodify(a:dir, ':p'))
	let paths = glob(escaped_dir.'*', 1, 1)

	" if include hidden, add hidden items to item list
	if a:includes_hidden_files
		let hidden_paths = glob(escaped_dir.'.*', 1, 1)
		" Exclude '.' & '..'
		call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')
		call extend(paths, hidden_paths)
	end

	" get item info from path
	let items =  map(copy(paths),'s:get_item_info_from_path(v:val)')
	call sort(items, 's:compare')

	let index = 0
	for item in items
		let item.index = index
		let index += 1
	endfor

	return items
endfunction

"---------------------------------------------------------------
" keep_buffer_singularity
"---------------------------------------------------------------
function! s:keep_buffer_singularity() abort
	let related_win_ids = !exists('*win_findbuf') ? [] : win_findbuf(bufnr('%'))
	if len(related_win_ids) > 1
		" Detected multiple windows for single buffer:
		" Duplicate the buffer to avoid unwanted sync between different windows
		let pos = getcurpos()
		let filer = s:get_filer()
		enew
		call s:open_minfy(filer)

		" Restores cursor completely
		call setpos('.', pos)
	endif
endfunction

"---------------------------------------------------------------
" get_cursor_item
"---------------------------------------------------------------
function! s:get_cursor_item(filer) abort
	return get(a:filer.items, line('.') - 1, "")
endfunction

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
" set_keymap
"---------------------------------------------------------------
function! s:set_keymap(map_type) abort
	if a:map_type == s:current_map_type
		return
	endif

	if a:map_type == "FILER"
		nnoremap <buffer> <silent> <CR> :<C-u>call <SID>open_current('edit', 0)<CR>
		nnoremap <buffer> <silent> <S-CR> :<C-u>call <SID>open_current('edit', 1)<CR>
		nnoremap <buffer> <silent> l :<C-u>call <SID>open_current('edit', 0)<CR>
		nnoremap <buffer> <silent> L :<C-u>call <SID>open_current('edit', 1)<CR>
		nnoremap <buffer> <silent> v :<C-u>call <SID>open_current('vsplit', 0)<CR>
		nnoremap <buffer> <silent> . :<C-u>call <SID>toggle_hidden()<CR>
		nnoremap <buffer> <silent> b :<C-u>call <SID>bookmark_open()<CR>
		nnoremap <buffer> <silent> h :<C-u>call <SID>open_parent()<CR>
		nnoremap <buffer> <silent> q :<C-u>call <SID>quit()<CR>
		nnoremap <buffer> <silent> a :<C-u>call <SID>bookmark_add()<CR>
		nnoremap <buffer> <silent> r <nop>
		nnoremap <buffer> <silent> u <nop>
		nnoremap <buffer> <silent> d <nop>
		nnoremap <buffer> <silent><DEL> <nop>
	else
		nnoremap <buffer> <silent> <CR> :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> <S-CR> :<C-u>call <SID>bookmark_selected('edit', 1)<CR>
		nnoremap <buffer> <silent> l :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> L :<C-u>call <SID>bookmark_selected('edit', 1)<CR>
		nnoremap <buffer> <silent> v :<C-u>call <SID>bookmark_selected('vsplit', 0)<CR>
		nnoremap <buffer> <silent> . <nop>
		nnoremap <buffer> <silent> b <nop>
		nnoremap <buffer> <silent> h <nop>
		nnoremap <buffer> <silent> q :<C-u>call <SID>bookmark_close()<CR>
		nnoremap <buffer> <silent> a <nop>
		nnoremap <buffer> <silent> r :<C-u>call <SID>bookmark_rename()<CR>
		nnoremap <buffer> <silent> u :<C-u>call <SID>bookmark_updown('up')<CR>
		nnoremap <buffer> <silent> d :<C-u>call <SID>bookmark_updown('down')<CR>
		nnoremap <buffer> <silent><DEL> :<C-u>call <SID>bookmark_delete()<CR>
	endif

	let s:current_map_type = a:map_type
endfunction

"---------------------------------------------------------------
" open_minfy
"---------------------------------------------------------------
function! s:open_minfy(filer) abort
	" Give unique name to buffer to avoid unwanted sync between different windows
	execute printf('silent keepalt file %s', s:generate_unique_bufname(a:filer.dir))

	" Mapping
	call s:set_keymap('FILER')

	if &filetype != 'minfy'
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
		syn match minfyBookmark '^.*\t'
		hi! def link minfyDirectory Directory
		hi! def link minfyHidden Comment
		hi! def link minfyNoItems Comment
		hi! def link minfyBookmark Directory
	endif

	call s:redraw()
endfunction

"---------------------------------------------------------------
" redraw
"---------------------------------------------------------------
function! s:redraw() abort
	setlocal modifiable

	" Clear buffer before drawing items
	silent keepjumps %delete _

	let filer = s:get_filer()
	if empty(filer.items)
		let text = ['  (no items)']
	else
		let text = map(copy(filer.items), 'printf("  %s", v:val.basename.(v:val.is_dir ? "/" : ""))')
	endif
	call setline(1, text)

	setlocal nomodifiable
	setlocal nomodified

	call s:restore_cursor()
endfunction

"---------------------------------------------------------------
" restore_cursor
"---------------------------------------------------------------
function! s:restore_cursor() abort
	let filer = s:get_filer()
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

"--------------
"-------------------------------------------------
" save_cursor
"---------------------------------------------------------------
function! s:save_cursor(item) abort
	if empty(a:item) | return | endif
	let filer = s:get_filer()
	let filer.cursor_paths[filer.dir] = a:item.path
	call s:set_filer(filer)
endfunction

"---------------------------------------------------------------
" compare
"---------------------------------------------------------------
function! s:compare(r1, r2) abort
	if a:r1.is_dir != a:r2.is_dir
		" Show directory in first
		return a:r1.is_dir ? -1 : +1
	endif

	return char2nr(a:r1.basename) - char2nr(a:r2.basename)
endfunction

"---------------------------------------------------------------
" file_open
"---------------------------------------------------------------
function! s:file_open(item, open_cmd) abort
 	if isdirectory(a:item.path)
		call s:init_minfy(a:item.path)
	else
		call s:quit()
		execute printf('keepalt %s %s', a:open_cmd, fnameescape(a:item.path))
	endif
endfunction

"---------------------------------------------------------------
" get_item_info_from_path
"---------------------------------------------------------------
function! s:get_item_info_from_path(path) abort
	let item = {}
	let item.index = -1
	let item.path = s:get_full_path(a:path)
	let item.is_dir = isdirectory(a:path)
	let item.basename = fnamemodify(a:path, isdirectory(a:path) ? ':t' : ':p:t')

	return item
endfunction

"---------------------------------------------------------------
" init_minfy
"---------------------------------------------------------------
function! s:init_minfy(path) abort
	" directory chek. if not exist, then terminate
	let path = fnamemodify(a:path, ':p')
	if !isdirectory(path)
		echohl Error | echomsg "E36: Directory ".path." doesn't exist" | echohl None
		return
	endif

	"minfy buffer clean up
	let all_bufnrs = range(1, bufnr('$'))
	let del_bufnrs = filter(all_bufnrs, 'bufexists(v:val) && !buflisted(v:val) && !bufloaded(v:val)')
	let del_bufnrs = filter(del_bufnrs, 'bufname(v:val) =~ "^minfy://[0-9]*/.*$"')
	for bufnr in del_bufnrs
		execute printf('silent bwipeout %d', bufnr)
	endfor

	" if minfy buffer not exist, then create buffer
	if bufname('%') !~ "^minfy://[0-9]*/.*$"
		enew
	endif

	" create filer
	let filer = s:get_filer()
	let filer['dir'] = s:get_full_path(path)
	let filer['items'] = s:get_items_from_dir(filer.dir, filer.show_hidden)
	call s:set_filer(filer)

	" open minfy
	call s:open_minfy(filer)
endfunction

"---------------------------------------------------------------
" open_current
"---------------------------------------------------------------
function! s:open_current(open_cmd, close_and_open) abort
	call s:keep_buffer_singularity()

	" get cursor item
	let filer = s:get_filer()
	let item = s:get_cursor_item(filer)
	if empty(item) | return | endif

	" save cursor position
	call s:save_cursor(item)

	" next directory open or file open
	call s:file_open(item, a:open_cmd)

	" close and open (file open only)
	if a:close_and_open && !item.is_dir
		if bufexists(s:save_bufnr) && bufnr("%") != s:save_bufnr
			execute 'bdelete! '.s:save_bufnr
		endif
	endif
endfunction

"---------------------------------------------------------------
" open_parent
"---------------------------------------------------------------
function! s:open_parent() abort
	call s:keep_buffer_singularity()

	let filer = s:get_filer()
	let parent_dir = fnameescape(fnamemodify(filer.dir, ':h'))

	" save cursor position
	let cursor_item = s:get_cursor_item(filer)
	call s:save_cursor(cursor_item)

	" directory exist check, if not exist, then head directory
	let new_dir = isdirectory(expand(parent_dir)) ?
					\ expand(parent_dir) :
					\ fnamemodify(expand(parent_dir), ':h')

	" get item of parent directory
	let new_item = s:get_item_info_from_path(new_dir)

	" next directory open or file open
	call s:file_open(new_item, '')

	" Move cursor to previous current directory
	let prev_dir_item =s:get_item_info_from_path(filer.dir)
	call s:save_cursor(prev_dir_item)
endfunction

"---------------------------------------------------------------
" quit
"---------------------------------------------------------------
function! s:quit() abort
	call s:keep_buffer_singularity()

	" Try restoring alternate buffer
	let last = bufnr('#')
	if bufexists(last) && bufnr('%') != last
		execute printf('buffer! %d', last) 
	else
		enew
	endif
endfunction

"---------------------------------------------------------------
" toggle_hidden
"---------------------------------------------------------------
function! s:toggle_hidden() abort
	call s:keep_buffer_singularity()

	" get cursor itemm
	let filer = s:get_filer()
	let item = s:get_cursor_item(filer)

	" save cursor position
	call s:save_cursor(item)

	" toggle hidden setting, and get item
	let filer.show_hidden = !filer.show_hidden
	let filer.items = s:get_items_from_dir(filer.dir, filer.show_hidden)
	call s:set_filer(filer)

	call s:redraw()
endfunction

"---------------------------------------------------------------
" bookmark_open
"---------------------------------------------------------------
function! s:bookmark_open() abort
	" Give unique name to buffer to avoid unwanted sync between different windows
	execute printf('silent keepalt file %s', s:generate_unique_bufname('bookmark'))

	" save cursor position
	let filer = s:get_filer()
	let item = s:get_cursor_item(filer)
	call s:save_cursor(item)

	" Mapping
	call s:set_keymap('BOOKMARK')

	" Load bookmark
	let s:bookmark = s:bookmark_load()
	let output = []
	for bk in s:bookmark
		let wk = split(bk, "\t")
		call add(output, printf("%-20s\t%s", wk[0], wk[1]))
	endfor

	" Delete the contents of the buffer to the black-hole register
	setlocal modifiable
	silent! %delete _
	silent! 0put = output

	" Delete the empty line at the end of the buffer
	silent! $delete _
	setlocal nomodifiable

	" Move the cursor to the beginning of the file
	normal! gg

	let s:change_bookmark = 0
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
	" If Bookmark changed, it is save
	if s:change_bookmark
		call s:bookmark_save()
	endif

	" Get selected line
	let path = substitute(getline("."), ".*\t", "", "")

	" create filer
	unlet b:minfy

	let item = s:get_item_info_from_path(path)
	call s:file_open(item, a:open_cmd)

	if a:close_and_open && !item.is_dir
		if bufexists(s:save_bufnr) && bufnr("%") != s:save_bufnr
			execute 'bdelete! '.s:save_bufnr
		endif
	endif
endfunction

"---------------------------------------------------------------
" bookmark_add
"---------------------------------------------------------------
function! s:bookmark_add() abort
	let filer = s:get_filer()
	let item = s:get_cursor_item(filer)
	if empty(item.path) | return | endif

	echo item.path
	let abbreviation = input('abbreviation: ')
	let abbreviation = abbreviation[:19]
	if !len(abbreviation)
		return
	endif

	" Remove the new file name from the existing RF list (if already present)
	call filter(s:bookmark, 'substitute(v:val, ".*\t", "", "") !=# item.path')
	
	" Add the new file list to the beginning of the updated old file list
	call insert(s:bookmark, abbreviation."\t".item.path, 0)
	
	" Save bookmark file
	call s:bookmark_save()

	echo "\rAdd to bookmark. (".item.path.")"
endfunction

"---------------------------------------------------------------
" bookmark_rename
"---------------------------------------------------------------
function! s:bookmark_rename() abort
	let new_abbreviation = input('new abbreviation: ')
	let new_abbreviation = new_abbreviation[:19]
	if !len(new_abbreviation) | return | endif

	let wk = split(s:bookmark[line(".") - 1], "\t")
	let s:bookmark[line(".") - 1] = new_abbreviation."\t".wk[1]
	setlocal modifiable
	call setline(line("."), printf("%-20s\t%s", new_abbreviation, wk[1]))
	setlocal nomodifiable

	let s:change_bookmark = 1
endfunction

"---------------------------------------------------------------
" bookmark_updown
"---------------------------------------------------------------
function! s:bookmark_updown(updown) abort
	let pos = getpos(".")
	let y = pos[1] - 1
	let pos[1] += a:updown == 'up' ? -1 : 1
	if pos[1] < 1 || pos[1] > len(s:bookmark)
		return
	endif
	
	setlocal modifiable
	let temp1 = remove(s:bookmark, y)
	let temp2 = getline(".")
	del _

	call insert(s:bookmark, temp1, pos[1] - 1)
	call append(pos[1] - 1, temp2)
	call setpos(".", pos)
	setlocal nomodifiable

	let s:change_bookmark = 1
endfunction

"---------------------------------------------------------------
" bookmark_delete
"---------------------------------------------------------------
function! s:bookmark_delete() abort
	let pos = getpos(".")
	call remove(s:bookmark, pos[1] - 1)
	setlocal modifiable
	del _
	setlocal nomodifiable

	let s:change_bookmark = 1
endfunction

"---------------------------------------------------------------
" bookmark_close
"---------------------------------------------------------------
function! s:bookmark_close() abort
	if s:change_bookmark
		call s:bookmark_save()
	endif

	let filer = s:get_filer()
	call s:open_minfy(filer)
endfunction

"---------------------------------------------------------------
" minfy#start
"---------------------------------------------------------------
function! minfy#start(...) abort
	" duplicate open is nop
	if bufname('%') =~ "^minfy://[0-9]*/.*$"
		return
	endif

	" get directory path. if nothing then current directory path
	let path = get(a:000, 0, getcwd())

	let s:current_map_type = 'UNDEF'

 	" save current buffer number. use with 'close and open' function
	let s:save_bufnr = bufnr("%")
	call s:init_minfy(path)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
