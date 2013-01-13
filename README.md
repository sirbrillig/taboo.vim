## Taboo.vim

**v1.3**

Taboo is a simple plugin for easily customize and rename tabs in vim.


### Installation

Vim 7.3+ is required.

Install into `.vim/plugin/taboo.vim` or better, use Pathogen.

**NOTE**: tabs look different in terminal vim than in gui versions. If you wish
having terminal style tabs even in gui versions you have to add the following
line to your .vimrc file:  

```
set guioptions-=e
```


### Commands

Here all the available commands:

* `TabooRenameTab <name>`: Renames the current tab with the name provided.
* `TabooOpenTab <name>`: Opens a new tab and and gives it the name provided. 
* `TabooResetName`: Removes the custom label associated with the current tab.


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

    **NOTE**: in renamed tabs, the items `%f`, `%F`, `%a` and `%[n]a` will be avaluated to the custom label associated to that tab.

* `g:taboo_renamed_tab_format`: Same as `g:taboo_format` but for renamed tabs.

    default: `[%f]%m` 

For other available settings type `:help taboo`


### Changelog

* **v1.3** some settings have been renamed.
* **v1.2**: removed superfluous commands TabooOpenTabPrompt and TabooRenameTabPrompt.
* **v1.1**: added gui support and simplified installation
* **v1.0**: first stable release
