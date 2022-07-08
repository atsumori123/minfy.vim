let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" keep_buffer_singularity
"---------------------------------------------------------------
function! s:keep_buffer_singularity() abort
	let related_win_ids = !exists('*win_findbuf') ? [] : win_findbuf(bufnr('%'))
	if len(related_win_ids) > 1
		" Detected multiple windows for single buffer:
		" Duplicate the buffer to avoid unwanted sync between different windows
		let pos = getcurpos()
		let filer = minfy#buffer#get_filer()
		enew
		call minfy#buffer#init(filer)

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
" minfy#start
"---------------------------------------------------------------
function! minfy#start(...) abort
	" duplicate open is nop
	if bufname('%') =~ "^minfy://[0-9]*/.*$"
		return
	endif

	" get directory path. if nothing then current directory path
	let path = get(a:000, 0, getcwd())

	" save current buffer number. use with 'close and open' function
	let s:save_bufnr = bufnr("%")
	call minfy#init(path)
endfunction

"---------------------------------------------------------------
" minfy#init
"---------------------------------------------------------------
function! minfy#init(path) abort
	" directory chek. if not exist, then terminate
	let path = fnamemodify(a:path, ':p')
	if !isdirectory(path)
		call minfy#util#error("E36: Directory ".path."doesn't exist")
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
	let filer = minfy#buffer#get_filer()
	let filer['dir'] = minfy#util#normalize_path(path)
	let filer['items'] = minfy#file#create_items_from_dir(filer.dir, filer.show_hidden)
	call minfy#buffer#set_filer(filer)

	" open minfy
	call minfy#buffer#init(filer)
endfunction

"---------------------------------------------------------------
" minfy#open_bookmark
"---------------------------------------------------------------
function! minfy#open_bookmark() abort
	call minfy#quit()
	execute ":MinfyBookmark ".expand("%:p:h")
endfunction

"---------------------------------------------------------------
" minfy#add_bookmark
"---------------------------------------------------------------
function! minfy#add_bookmark() abort
	let filer = minfy#buffer#get_filer()
	execute ":MinfyAddBookmark ".filer.dir
endfunction


"---------------------------------------------------------------
" minfy#open_current
"---------------------------------------------------------------
function! minfy#open_current(close_and_open) abort
	call s:keep_buffer_singularity()

	" get cursor item
	let filer = minfy#buffer#get_filer()
	let item = s:get_cursor_item(filer)
	if empty(item) | return | endif

	" save cursor position
	call minfy#buffer#save_cursor(item)

	" next directory open or file open
	call minfy#file#open(item)

	" close and open (file open only)
	if a:close_and_open && !item.is_dir
		if bufexists(s:save_bufnr) && bufnr("%") != s:save_bufnr
			execute 'bdelete! '.s:save_bufnr
		endif
	endif
endfunction

"---------------------------------------------------------------
" minfy#open_parent
"---------------------------------------------------------------
function! minfy#open_parent() abort
	call s:keep_buffer_singularity()

	let filer = minfy#buffer#get_filer()
	let parent_dir = fnameescape(fnamemodify(filer.dir, ':h'))

	" save cursor position
	let cursor_item = s:get_cursor_item(filer)
	call minfy#buffer#save_cursor(cursor_item)

	" directory exist check, if not exist, then head directory
	let new_dir = isdirectory(expand(parent_dir)) ?
					\ expand(parent_dir) :
					\ fnamemodify(expand(parent_dir), ':h')

	" get item of parent directory
	let new_item = minfy#util#from_path(new_dir)

	" next directory open or file open
	call minfy#file#open(new_item)

	" Move cursor to previous current directory
	let prev_dir_item =minfy#util#from_path(filer.dir)
	call minfy#buffer#save_cursor(prev_dir_item)
endfunction

"---------------------------------------------------------------
" minfy#quit
"---------------------------------------------------------------
function! minfy#quit() abort
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
" minfy#toggle_hidden
"---------------------------------------------------------------
function! minfy#toggle_hidden() abort
	call s:keep_buffer_singularity()

	" get cursor itemm
	let filer = minfy#buffer#get_filer()
	let item = s:get_cursor_item(filer)

	" save cursor position
	call minfy#buffer#save_cursor(item)

	" toggle hidden setting, and get item
	let filer.show_hidden = !filer.show_hidden
	let filer.items = minfy#file#create_items_from_dir(filer.dir, filer.show_hidden)
	call minfy#buffer#set_filer(filer)

	call minfy#buffer#redraw()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
