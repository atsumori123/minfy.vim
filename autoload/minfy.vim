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
	let b:minfy['current_dir'] = fnamemodify(b:minfy['last_dir'], ':h')
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
		let item .= item =~ '/$' ? "" : "/"
	else
		let item = ''
	endif
	let item .= get(s:filer_get_param("items"), line('.') - 2, "")
	return substitute(item, "\[\\/\]$", "", "g")
endfunction

"---------------------------------------------------------------
" 1文字入力
"---------------------------------------------------------------
function! s:get_char(prompt) abort
	try
		echo a:prompt
		let char = call('getchar', a:000)
	catch /^Vim:Interrupt$/
		let char = 3 " <C-c>
	endtry
	redraw | echo ""

	if char == 27 || char == 3
		" ESC or <C-c> key pressed
		redraw | echo "Cancelled."
		return ''
	endif

	return type(char) == v:t_number ? nr2char(char) : char
endfunction

"---------------------------------------------------------------
" キャンセル判定付き入力
"---------------------------------------------------------------
function! s:safe_input(prompt, text, completion)
	" 事前に現在の入力状態を保存する
	call inputsave()
  
	" input()の入力欄でESCが押されたら、特殊な文字列を入れてEnterを叩くマッピングを動的に定義
	cnoremap <silent><buffer> <Esc> <C-u>__CANCEL__<CR>

	let str = ""
	let is_cancelled = 0

	try
		" 入力プロンプトを表示
		if empty(a:completion)
			let str = input(a:prompt, a:text)
		else
			let str = input(a:prompt, a:text, a:completion)
		endif
	catch /^Vim:Interrupt$/
		" Esc や Ctrl-C が押された場合、このブロックに入ります
		let is_cancelled = 1
	finally
		" 定義した一時的なマッピングを削除する
		cunmap <buffer> <Esc>
		" 入力状態を元に戻す
		call inputrestore()
	endtry

	" キャンセル判定
	if is_cancelled || str == '__CANCEL__'
		redraw | echo "Cancelled."
		return [0, ""]
	endif

	return [1, str]
endfunction

"---------------------------------------------------------------
" set_keymap
"---------------------------------------------------------------
function! s:set_keymap(map_type) abort
	mapclear <buffer>

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
		nnoremap <buffer> <silent> rm :<C-u>call <SID>file_delete()<CR>
		nnoremap <buffer> <silent> cp :<C-u>call <SID>file_copy()<CR>
		nnoremap <buffer> <silent> mv :<C-u>call <SID>file_move()<CR>
		nnoremap <buffer> <silent> mk :<C-u>call <SID>file_mkdir()<CR>
		nnoremap <buffer> <silent> s :<C-u>call <SID>skip_cursor()<CR>
		nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>skip_cursor_n(1, ">")<CR>
		nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>skip_cursor_n(-1, ">")<CR>
	else
		nnoremap <buffer> <silent> <CR> :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> l :<C-u>call <SID>bookmark_selected('edit', 0)<CR>
		nnoremap <buffer> <silent> L :<C-u>call <SID>bookmark_selected('edit', 1)<CR>
		nnoremap <buffer> <silent> v :<C-u>call <SID>bookmark_selected('vsplit', 0)<CR>
		nnoremap <buffer> <silent> q :<C-u>call <SID>bookmark_close()<CR>
		nnoremap <buffer> <silent> s :<C-u>call <SID>bookmark_separator()<CR>
		nnoremap <buffer> <silent> e :<C-u>call <SID>bookmark_edit()<CR>
		nnoremap <buffer> <silent> K :<C-u>call <SID>bookmark_updown('up')<CR>
		nnoremap <buffer> <silent> J :<C-u>call <SID>bookmark_updown('down')<CR>
		nnoremap <buffer> <silent> rm :<C-u>call <SID>bookmark_delete()<CR>
		nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>skip_cursor_n(1, "-")<CR>
		nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>skip_cursor_n(-1, "-")<CR>
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
	let match_char = char == "" ? ">" : escape(char, '^$.*[]/~\')
	let replace_char = char == "" ? " " : ">"

	setlocal modifiable

	let n = line(".") + 1
	for i in range(1, len)
		if n > len | let n = 1 | endif
		let str = getline(n)
		if str =~ "^. ".match_char
			call setline(n, replace_char.str[1:])
			if first_match == -1 | let first_match = n | endif
		elseif str =~ "^>"
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
function! s:skip_cursor_n(direction, char) abort
	let n = line(".") + a:direction
	let len = line('$')
	for i in range(1, len)
		if n > len | let n = 2 | endif
		if n < 2 | let n = len | endif
		if getline(n) =~ "^".a:char
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

		let winnum = bufwinnr('^' . a:path . '$')
		if winnum != -1
			" 開こうとしているファイルがどこかのウィンドウで表示している
			execute winnum . 'wincmd w'
		else
"			execute a:open_cmd
"			execute 'edit ' . fnameescape(a:path)
			execute printf('%s %s', a:open_cmd, fnameescape(a:path))
		endif

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
	syn match minfyMatch '^>.*'
 	syn match minfySeparator '^-\ .*'
	syn match minfyCurrentPath '^[^\ \->].*'
	hi! def link minfyDirectory Directory
	hi! def link minfyHidden Comment
	hi! def link minfyNoItems Comment
	hi! def link minfyMatch Special
	hi! def link minfySeparator Label
	hi! def link minfyCurrentPath Title

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
	" minfy起動前に表示していたバッファにスイッチ
	if s:save_bufnr == bufnr("%")
		bdelete
	elseif bufexists(s:save_bufnr)
		execute printf('buffer! %d', s:save_bufnr)
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
	redraw
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
	if s:get_char("Delete '".item."' ? [y/n] ") != 'y'
		echo "Cancelled."
		return
	endif

	"delete option set
	let delete_path = s:filer_get_param('current_dir').'/'.item
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
		echo "\rCannot delete: " . delete_path
	else
		echo "\rDeleted: ". delete_path
	endif

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_copy
"---------------------------------------------------------------
function! s:file_copy() abort
	if line('.') == 1 | return | endif
	let src_name = s:get_cursor_item(0)
	if empty(src_name) | return | endif

	"ディレクトリはコピーさせない
	let src = s:get_cursor_item(1)
	if isdirectory(src)
		call s:err_msg("Directory cannot be copied.") | return
	endif

	"コピー先を入力
	let dst = resolve(input("Copy to ", s:filer_get_param('current_dir'), 'dir'))
	if empty(dst) | echo "\rCancelled." | return | endif

	"入力したコピー先が存在するかチェック
	if !isdirectory(dst)
		call s:err_msg("Destination is not exists.") | return
	endif

	"コピー元とコピー先が同じディレクトリの場合はファイル名を入力する
	let dst_name = src_name
	if s:filer_get_param('current_dir') ==# dst
		let dst_name = input("Copy destinatin name: ", src_name)
		if empty(dst_name) || src_name ==# dst_name | call s:err_msg("Copy destination name is NULL or duplicate.") | return | endif
	endif

	"Make distination path
	let dst = substitute(dst, '[/|\\]$', "", "") . '/' . dst_name

	"When destination is read only or already exists, not excutable
	if filereadable(dst) || isdirectory(dst)
		call s:err_msg("Destination already has the same file.") | return
	endif

	"Copy
	call writefile(readfile(src, 'b'), dst, 'b')
	echo printf("\rCopyed. '%s' --> '%s'", src_name, dst)

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_move
"---------------------------------------------------------------
function! s:file_move() abort
	if line('.') == 1 | return | endif

	"選択項目
	let src_name = s:get_cursor_item(0)
	if empty(src_name) | return | endif

	"選択項目のフルパス
	let src = s:get_cursor_item(1)

	"移動先ディレクトリの入力
	let dst_dir = resolve(input("Move to ", s:filer_get_param('current_dir'), 'dir'))
	if empty(dst_dir) | echo "\rCancelled." | return | endif

	"移動先が存在しないディレクトリの場合はエラーとする
	if !isdirectory(dst_dir)
		call s:err_msg("Destination is not exists.") | return
	endif

	"移動先のフルパスを作成
	let dst = substitute(dst_dir, '[/|\\]$', "", "") . '/' . src_name

	"移動先が選択項目が同じ場所の場合は新しい名前をつける
	if src == dst
	 	let dst_name = input('Input new name: ', src_name)
		if empty(dst_name) | echo "\rCancelled." | return | endif

		let dst = substitute(dst_dir, '[/|\\]$', "", "") . '/' . dst_name
		if src == dst | call s:err_msg("Destination already has the same object.") | return | endif
	endif

	"Move
	call rename(src, dst)
	echo printf("\rMoved. '%s' --> '%s'", src_name, dst)

	"Refresh minfy
	call s:refresh()
endfunction

"---------------------------------------------------------------
" file_mkdir
"---------------------------------------------------------------
function! s:file_mkdir() abort
	let name = input('Create directory name: ')
	if empty(name) | echo "\rCancelled." | return | endif

	"Input new directory name
	let path = resolve(s:filer_get_param("current_dir").'/'.name)

	"When destination is read only or already exists, not excutable
	if filereadable(path) || isdirectory(path)
		call s:err_msg("Destination already has the same directory.") | return
	endif

	" Make new directory
	call mkdir(path, '')
	echo 'Created. ' . name

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
			if len(wk) > 1
				call add(output, "- " . wk[1])
			else
				call add(output, "")
			endif
		else
			call add(output, "  " . wk[len(wk) > 1 ? 1 : 0])
		endif
	endfor

	" Delete the contents of the buffer to the black-hole register
	setlocal modifiable
	silent! %delete _
	call setline(1, "bookmarks")
	call setline(2, output)
	setlocal nomodifiable

	" Move the cursor to the beginning of the file
	call cursor([2, 1, 0, 1])
endfunction

"---------------------------------------------------------------
" bookmark_load
"---------------------------------------------------------------
function! s:bookmark_load() abort
	return filereadable(s:bookmark_file) ? readfile(s:bookmark_file) : []
endfunction

"---------------------------------------------------------------
" bookmark_save
"---------------------------------------------------------------
function! s:bookmark_save() abort
	call writefile(s:bookmark, s:bookmark_file)
endfunction

"---------------------------------------------------------------
" bookmark_selected
"---------------------------------------------------------------
function! s:bookmark_selected(open_cmd, close_and_open) abort
	" 1st line and separaotr are invalid
	if line('.') == 1 || getline(".")[0] !=# " "
		  return
	endif

	" If Bookmark changed, it is save
	if s:bookmark_modified
		call s:bookmark_save()
		let s:bookmark_modified = 0
	endif

	" open selected item
	let path = split(s:bookmark[line(".") - 2], "\t")[0]
	if isdirectory(path)
		call s:set_keymap('FILER')
	endif
	call s:file_open(path, a:open_cmd, a:close_and_open)
endfunction

"---------------------------------------------------------------
" bookmark_add
"---------------------------------------------------------------
function! s:bookmark_add() abort
	let item = s:get_cursor_item(1)
	if empty(item) | return | endif

	" ブックマークの先頭に追加
	let s:bookmark = s:bookmark_load()
	call insert(s:bookmark, item, 0)
	call s:bookmark_save()

	echo "\rAdd to bookmark. (".item.")"
endfunction

"---------------------------------------------------------------
" bookmark_separator
"---------------------------------------------------------------
function! s:bookmark_separator() abort
	let [res, sep_name] = s:safe_input("Input separaotr name: ", "", "")
	if !res | return | endif

	" カーソル位置にセパレータを追加
	call insert(s:bookmark, "&sep\t".sep_name, line(".") - 1)
	setlocal modifiable
	call append(line("."), sep_name)
	setlocal nomodifiable

	let s:bookmark_modified = 1
endfunction

"---------------------------------------------------------------
" bookmark_edit
"---------------------------------------------------------------
function! s:bookmark_edit() abort
	if line('.') == 1 | return | endif

	let wk = split(s:bookmark[line(".") - 2], "\t")
	let name = len(wk) > 1 ? wk[1] : ""

	if wk[0] == "&sep"
		let [res, new_name] = s:safe_input('Input name: ', name, "")
		if !res | return | endif
		let s:bookmark[line(".") - 2] = "&sep\t".new_name
		let item = '- ' . new_name
	else
		let [res, new_path] = s:safe_input('Input path: ', wk[0], 'dir')
		if !res || !len(new_path) | return | endif
		let new_path = substitute(new_path, '[/|\\]$', "", "")

		let [res, new_name] = s:safe_input('Input name: ', name, "")
		if !res | return | endif
		if new_name == ""
			let s:bookmark[line(".") - 2] = new_path
			let item = "  " . new_path
		else
			let s:bookmark[line(".") - 2] = new_path . "\t" . new_name
			let item = "  " . new_name
		endif
	endif

	setlocal modifiable
	call setline(line("."), item)
	setlocal nomodifiable

	let s:bookmark_modified = 1
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

	let s:bookmark_modified = 1
endfunction

"---------------------------------------------------------------
" bookmark_delete
"---------------------------------------------------------------
function! s:bookmark_delete() abort
	let lnum = line(".")

	if lnum == 1
		return
	endif

	if s:get_char("Delete selected item ? [y/n] ") != 'y'
		return
	endif

	call remove(s:bookmark, lnum - 2)
	setlocal modifiable
	del _
	setlocal nomodifiable

	let s:bookmark_modified = 1
endfunction

"---------------------------------------------------------------
" bookmark_close
"---------------------------------------------------------------
function! s:bookmark_close() abort
	if s:bookmark_modified
		call s:bookmark_save()
		let s:bookmark_modified = 0
	endif

	call s:set_keymap('FILER')
	call s:draw_items()
endfunction

"---------------------------------------------------------------
" minfy#start
"---------------------------------------------------------------
function! minfy#start(...) abort
	" get directory path. if nothing then current directory path
	let dir = resolve(get(a:000, 0, getcwd()))
	if !isdirectory(dir)
		call s:err_msg("E01: Directory ".dir."doesn't exist.") | return
	endif

	" 特殊バッファ上では無効
	if &buftype != ''
		call s:err_msg("E02: Cannot be executed due to a special buffer.") | return
	endif

	" 現在のバッファ番号を退避
	let s:save_bufnr = bufnr("%")

	" ブックマーク関連の初期化（ファイルパス、変更有無）
	let s:bookmark_file = has('unix') || has('macunix') ? $HOME.'/.' : $HOME.'\_'
	let s:bookmark_file .= 'minfy_bookmark'
	let s:bookmark_modified = 0

	call s:init_minfy(dir)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
