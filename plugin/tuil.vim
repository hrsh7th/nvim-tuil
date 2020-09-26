if exists('g:loaded_tuil')
  finish
endif
let g:loaded_tuil = v:true

let s:tuil_dir = fnamemodify(expand('<sfile>'), ':p:h:h')

command! TuilEmbed call s:embed()
function s:embed()
  let l:path = input('target-dir: ', '', 'file')
  let l:path = fnamemodify(l:path, ':p')
  let l:path = substitute(l:path, '\/$', '', 'g')
  let l:name = input('namespace: ', '')

  if !isdirectory(l:path)
    throw printf('`%s` does not exists', l:path)
  endif
  if !isdirectory(l:path . '/lua')
    throw printf('`%s/lua` does not exists', l:path)
  endif

  let l:from = s:tuil_dir . '/lua/tuil'
  for l:file in glob(l:from . '**/*.lua', v:false, v:true, v:true)
    let l:body = readfile(l:file)
    let l:body = type(l:body) == type([]) ? l:body : split(l:body, "\n")
    for l:i in range(0, len(l:body) - 1)
      let l:body[l:i] = substitute(l:body[l:i], 'require.*\zs\(tuil\.\%(%s\|\w\|\.\)*\)', l:name . '.\1', 'g')
    endfor
    let l:dist = printf('%s/lua/%s/tuil/%s', l:path, l:name, substitute(l:file, '\V' . escape(l:from, '\/?') . '/', '', 'g'))
    call mkdir(fnamemodify(l:dist, ':p:h'), 'p')
    call writefile(l:body, l:dist)
  endfor
endfunction

