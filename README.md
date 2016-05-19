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
### Set the code browsing URL template string

    let g:vim_share_link_template = "https://www.example.com/repos/<REPOSITORY_NAME>/browse/<PATH_TO_FILE><IFLINES>#<LINE1>-<LINE2></IFLINES>"

The template string includes a number of macros that look kind of like XML
tags. Most of these "tags" are void tags, meaning they exist entirely on
their own without "stuff" inside. The exception is *&lt;IFLINES&gt;*, which is
detailed below.

Macro | Definition
--- | ---
&lt;REPOSITORY\_NAME&gt; | The name of the repository. This will default to all the non-slash characters before `.git` in the remote.origin.url name. The exception is GitHub, for which special logic is in place to also parse out the username portion of the repo name so that the link works correctly.
&lt;PATH\_TO\_FILE&gt; | The relative path to a file starting from the repository root.
&lt;IFLINES&gt; | Everything between the opening and closing *&lt;IFLINES&gt;* tag will appear whenever the `:CodeBrowserBlobUrl` command is run with a visual selection (i.e., `'<,'>CodeBrowserBlobUrl`).
&lt;LINE1&gt; | The smaller line number of the visually-selected range.
&lt;LINE2&gt; | The larger line number of the visually-selected range.

### Generate the code browser URL

    :CodeBrowserBlobUrl

