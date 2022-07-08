"---------------------------------------------------------------
" Load bookmark
"---------------------------------------------------------------
function! minfy#bookmark#load() abort
	return filereadable(g:minfy_bookmark_file) ? readfile(g:minfy_bookmark_file) : []
endfunction

"---------------------------------------------------------------
" Save bookmark
"---------------------------------------------------------------
function! minfy#bookmark#save() abort
	call writefile(s:bookmark, g:minfy_bookmark_file)
endfunction

"---------------------------------------------------------------
" Add bookmark
"---------------------------------------------------------------
function! minfy#bookmark#add(dir) abort
	let abbreviation = input('abbreviation: ')
	let abbreviation = abbreviation[:19]

	" Load bookmark
	let s:bookmark = minfy#bookmark#load()

	" Remove the new file name from the existing RF list (if already present)
	call filter(s:bookmark, 'substitute(v:val, ".*\t", "", "") !=# a:dir')
	
	" Add the new file list to the beginning of the updated old file list
	call insert(s:bookmark, abbreviation."\t".a:dir, 0)
	
	" Save bookmark file
	call minfy#bookmark#save()
	
	echo "\rAdd to bookmark. (".a:dir.")"
endfunction

"---------------------------------------------------------------
" Selected from bookmark
"---------------------------------------------------------------
function! minfy#bookmark#selected() abort
	" Get selected line
	let dir = substitute(getline("."), ".*\t", "", "")

	" Automatically close the RF window
	silent! bd

	" Directory exist check
	if !isdirectory(dir)
		echohl WarningMsg | echomsg 'Error: Directory ' . dir. " doesn't exist" | echohl None
		let dir = s:path
	endif

	" Run minfy
	execute ":Minfy ".dir
endfunction

"---------------------------------------------------------------
" Open bookmark
"---------------------------------------------------------------
function! minfy#bookmark#open() abort
	let winnum = bufwinnr('-Minfy-Bookmark-')
	if winnum != -1
		" Already in the window, jump to it
		execute winnum . 'wincmd w'
	else
		" Open a new window at the bottom
		"execute 'silent! botright split -Minfy-Bookmark-'
		execute 'silent! edit -Minfy-Bookmark-'
	endif

	setlocal modifiable
	
	" Delete the contents of the buffer to the black-hole register
	silent! %delete _

	" Mark the buffer as scratch
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap

	" Set the 'filetype' to 'minfyBookmark'. This allows the user to apply custom
	" syntax highlighting or other changes to the RF bufer.
	setlocal filetype=minfyBookmark

	" Setup the cpoptions properly for the maps to work
	let old_cpoptions = &cpoptions
	set cpoptions&vim

	" Create mappings to select and edit a file from the bookmark list
	execute "nmap <buffer> <silent> <CR> <plug>(minfy-bookmark-selected)"
	execute "nmap <buffer> <silent> l <plug>(minfy-bookmark-selected)"
	execute "nmap <buffer> <silent> d <plug>(minfy-bookmark-delete)"
	execute "nmap <buffer> <silent> q <plug>(minfy-bookmark-close)"

	" Restore the previous cpoptions settings
	let &cpoptions = old_cpoptions

	let output = []
	for bk in s:bookmark
		let wk = split(bk, "\t")
		call add(output, printf("%-20s\t%s", wk[0], wk[1]))
	endfor
	silent! 0put = output

	" Delete the empty line at the end of the buffer
	silent! $delete _

	" Move the cursor to the beginning of the file
	normal! gg

	execute 'syntax match minfyBookmark "^.*\t"'
	highlight link minfyBookmark Directory

	setlocal nomodifiable
endfunction

"---------------------------------------------------------------
" Delete bookmark
"---------------------------------------------------------------
function! minfy#bookmark#delete() abort
	let pos = getpos(".")
	call remove(s:bookmark, pos[1] - 1)
	setlocal modifiable
	del _
	setlocal nomodifiable
	call minfy#bookmark#save()
endfunction

"---------------------------------------------------------------
" Close bookmark
"---------------------------------------------------------------
function! minfy#bookmark#close() abort
	"silent! close
	silent! bd

	" Back to minfy
	execute ":Minfy ".s:path
endfunction

"---------------------------------------------------------------
"  minfy Bookmark
"---------------------------------------------------------------
function! minfy#bookmark#start(...) abort
	if a:0 >= 1
		let s:path = a:1
	else
		let s:path = expand("%:p:h")
	endif

	" Load bookmark
	let s:bookmark = minfy#bookmark#load()

	" Open bookmark buffer
	call minfy#bookmark#open()
endfunction

"---------------------------------------------------------------
"  minfy add bookmark
"---------------------------------------------------------------
function! minfy#bookmark#add_start(...) abort
	" Check argument
	if a:0 < 1
		echohl WarningMsg | echomsg 'Error: Invalid argument' | echohl None
		return
	endif

	" Directory exist check
	if !isdirectory(a:1)
		echohl WarningMsg | echomsg 'Error: Directory ' . a:1. " doesn't exist" | echohl None
		return
	endif
	
	" Add bookmark
	call minfy#bookmark#add(a:1)
endfunction
