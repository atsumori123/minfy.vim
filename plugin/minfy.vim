if exists('g:loaded_minfy')
	finish
endif
let g:loaded_minfy = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -bar -nargs=? -complete=dir Minfy call minfy#start(<f-args>)

let &cpoptions = s:save_cpo
unlet s:save_cpo
