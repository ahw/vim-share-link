vim-share-link
==============
This is a Vim plugin that exposes a `:CodeBrowserBlobUrl` command,
optionally taking a visually-selected range of lines. It outputs the URL to
your favorite code browsing website (GitHub, or maybe your company's
internal repo tool&mdash;whatever you may have configured).

Installation
------------
If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone https://github.com/ahw/vim-share-link.git

Usage
-----

    :CodeBrowserBlobUrl
