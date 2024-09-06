let s:save_cpo = &cpoptions
set cpoptions&vim


if exists('g:loaded_minfy')
	finish
endif
let g:loaded_minfy = 1

command! -bar -nargs=? -complete=dir Minfy call minfy#start(<f-args>)

let g:minfy_bookmark_file = has('unix') || has('macunix') ? $HOME.'/.' : $HOME.'\_'
let g:minfy_bookmark_file .= 'minfy_bookmark'

if !exists('g:Minfy_use_easymotion')
	let g:Minfy_use_easymotion = 0
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
