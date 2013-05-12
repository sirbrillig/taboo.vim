## taboo.vim

**v1.4**

Taboo is a simple plugin for easily customize and rename tabs in vim. THis
plugin aims to provide an easy way to manage tab labels mainly in terminal vim
but it is compatible with gui versions too.


### Requirements
* Vim 7.3+


### Installation
You can either extract the content of the folder into the `$HOME/.vim`
directory or use plugin managers such as Vundle or Pathogen.

**NOTE**: tabs look different in terminal vim than in gui versions. If you wish
having terminal style tabs even in gui versions you have to add the following
line to your .vimrc file:  

```
set guioptions-=e
```


### Commands

Here all the available commands:

* `TabooRename <name>`: Renames the current tab with the name provided.
* `TabooOpen <name>`: Opens a new tab and and gives it the name provided. 
* `TabooReset`: Removes the custom label associated with the current tab.


### Settings

Here the most important available settings:

* `g:taboo_tab_format`: With this option you can customize the way normal tabs (not
  renamed tabs) are displayed. Below all the available items: 

    - `%f`: file name
    - `%F`: path relative to $HOME
    - `%a`: absolute path
    - `%[n]a` : custom level of path depth
    - `%n`: show tab number only on the active tab
    - `%N`: show always tab number
    - `%m`: modified flag
    - `%w`: number of windows opened into the tab

    default: `%f%m` 

    **NOTE**: in renamed tabs, the items `%f`, `%F`, `%a` and `%[n]a` will be evaluated to the custom label associated to that tab.

* `g:taboo_renamed_tab_format`: Same as `g:taboo_tab_format` but for renamed tabs.

    default: `[%f]%m` 

For other available settings type `:help taboo`


### Changelog

* **v1.4** Added support for sessions. Commands names have been simplified. Minor fixes (thanks to ajpaulson).  
* **v1.3** Some settings have been renamed.
* **v1.2** Removed superfluous commands TabooOpenTabPrompt and TabooRenameTabPrompt.
* **v1.1** Added gui support and simplified installation
* **v1.0** First stable release
