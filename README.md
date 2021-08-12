# bufjump.vim

Experimental buffer navigation. Basically EasyMotion for buffers.

![demo](demo.gif)

Example mappings:

```vim
nnoremap <leader>b  :call bufjump#select()<CR>
nnoremap <CR>       :call bufjump#select()<CR>
nnoremap \          :call bufjump#select()<CR>
nnoremap <nowait> Z :call bufjump#select()<CR>
```
