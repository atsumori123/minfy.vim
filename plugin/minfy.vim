let s:save_cpo = &cpoptions
set cpoptions&vim


if exists('g:loaded_minfy')
	finish
endif
let g:loaded_minfy = 1

command! -bar -nargs=? -complete=dir Minfy call minfy#start(<f-args>)

nnoremap <silent> <Plug>(minfy-toggle-hidden)        :<C-u>call minfy#toggle_hidden()<CR>
nnoremap <silent> <Plug>(minfy-open-current)         :<C-u>call minfy#open_current(0)<CR>
nnoremap <silent> <Plug>(minfy-close-open-current)   :<C-u>call minfy#open_current(1)<CR>
nnoremap <silent> <Plug>(minfy-open-parent)          :<C-u>call minfy#open_parent()<CR>
nnoremap <silent> <Plug>(minfy-quit)                 :<C-u>call minfy#quit()<CR>
nnoremap <silent> <Plug>(minfy-bookmark-open)        :<C-u>call minfy#bookmark_open()<CR>
nnoremap <silent> <Plug>(minfy-bookmark-add)         :<C-u>call minfy#bookmark_add()<CR>
nnoremap <silent> <Plug>(minfy-bookmark-selected)    :<C-u>call minfy#bookmark_selected()<CR>
nnoremap <silent> <Plug>(minfy-bookmark-delete)      :<C-u>call minfy#bookmark_delete()<CR>
nnoremap <silent> <Plug>(minfy-bookmark-close)       :<C-u>call minfy#bookmark_close()<CR>

let g:minfy_bookmark_file = has('unix') || has('macunix') ? $HOME.'/.' : $HOME.'\_'
let g:minfy_bookmark_file .= 'minfy_bookmark'


let &cpoptions = s:save_cpo
unlet s:save_cpo
