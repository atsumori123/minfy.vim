let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" minfy#file#compare
"---------------------------------------------------------------
function! minfy#file#compare(r1, r2) abort
	if a:r1.is_dir != a:r2.is_dir
		" Show directory in first
		return a:r1.is_dir ? -1 : +1
	endif

	return char2nr(a:r1.basename) - char2nr(a:r2.basename)
endfunction

"---------------------------------------------------------------
" minfy#file#create_items_from_dir
"---------------------------------------------------------------
function! minfy#file#create_items_from_dir(dir, includes_hidden_files) abort
	let escaped_dir = fnameescape(fnamemodify(a:dir, ':p'))
	let paths = glob(escaped_dir.'*', 1, 1)
	if a:includes_hidden_files
		let hidden_paths = glob(escaped_dir.'.*', 1, 1)
		" Exclude '.' & '..'
		call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')
		call extend(paths, hidden_paths)
	end

	let items =  map(copy(paths),'minfy#util#from_path(v:val)')
	call sort(items, 'minfy#file#compare')

	let index = 0
	for item in items
		let item.index = index
		let index += 1
	endfor

	return items
endfunction

"---------------------------------------------------------------
" minfy#file#open
"---------------------------------------------------------------
function! minfy#file#open(item) abort
 	if isdirectory(a:item.path)
		call minfy#init(a:item.path)
	else
		execute printf('keepalt edit %s', fnameescape(a:item.path))
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
