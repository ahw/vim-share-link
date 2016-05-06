let s:REPOSITORY_NAME_PLACEHOLDER = '<REPOSITORY_NAME>'
let s:PATH_TO_FILE_PLACEHOLDER = '<PATH_TO_FILE>'
let s:LINE_1_PLACEHOLDER = '<LINE1>'
let s:LINE_2_PLACEHOLDER = '<LINE2>'
let g:vim_share_link_template = 'https://www.example.com/repos/<REPOSITORY_NAME>/browse/<PATH_TO_FILE><IFLINES>#<LINE1>-<LINE2></IFLINES>'

function! s:getVisualSelection()
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][:col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return lines
endfunction

function! s:findRepositoryRoot()
    let workspaceInfo = {}
    let expandExpr = "%:p:h"
    let foundRoot = 0

    let workspaceInfo.absolutePathToFile = expand("%:p")
    let workspaceInfo.absolutePathToDir = expand("%:p:h")

    while !foundRoot
        let pathToGit = expand(expandExpr) . "/.git"
        if isdirectory(pathToGit) || filereadable(pathToGit)
            let foundRoot = 1
        elseif expand(expandExpr) == "/"
            " Recursed all the way up and found no repo
            let foundRoot = 0
            break
        else
            " Keep recursing up
            let expandExpr .= ":h"
        endif
    endwhile

    if foundRoot
        " Path to file relative to git root. Take the absolute path to the
        " file and remove out the path to the git repo dir.
        let workspaceInfo.relativePathToFile = substitute(workspaceInfo.absolutePathToFile, substitute(pathToGit, '\v.git$', "", ""), "", "")
        let workspaceInfo.isGitRepo = 1
        let gitConfigLines = []

        let remoteOriginUrl = system('git --git-dir ' . pathToGit . ' config --get remote.origin.url')
        " Match against zero or more \W characters at the end since this
        " command will print a newline after the remote origin url
        let workspaceInfo.repositoryName = get(matchlist(remoteOriginUrl, '\v([^/]+).git\W*$'), 1, "")
        let workspaceInfo.isRemoteRepository = 1
    endif

    return workspaceInfo

endfunction

function! s:printDictionary(dict)
    " For debugging
    for key in keys(a:dict)
        echo key . ": " . a:dict[key]
    endfor
endfunction

function! s:generateCodeBrowserBlobUrl(startLine, endLine)
    let url = g:vim_share_link_template

    let info = s:findRepositoryRoot()

    if !has_key(info, 'isGitRepo')
        echohl Error
        echo "No git repository found!"
        echohl NONE
        return
    endif

    if !has_key(info, 'isRemoteRepository')
        echohl Error
        echo 'Could not determine remote repository name. Is this really a remote code repository? Expected to find a line matching the form "url = URL_TO_REPOSITORY_ORIGIN/repository-name.git" in the .git/config file of this repo.'
        echohl NONE
        return
    endif

    if a:startLine != a:endLine
        " Include line info
        let lineInfo = get(matchlist(url, '\v\<IFLINES\>(.*)\<\/IFLINES\>'), 1, "")
        let lineInfo = substitute(lineInfo, s:LINE_1_PLACEHOLDER, a:startLine, "")
        let lineInfo = substitute(lineInfo, s:LINE_2_PLACEHOLDER, a:endLine, "")
    else
        " If the line numbers are equal, which occurs when
        " :CodeBrowserBlobUrl is run without a visual selection argument, do
        " not include line info.
        let lineInfo = ""
    endif

    " Now start actually mutating the url template string
    let url = substitute(url, '\v\<IFLINES\>.*\<\/IFLINES\>', lineInfo, "")
    let url = substitute(url, s:REPOSITORY_NAME_PLACEHOLDER , info.repositoryName, "")
    let url = substitute(url, s:PATH_TO_FILE_PLACEHOLDER , info.relativePathToFile, "")

    echohl Special
    " call s:printDictionary(info)
    echo "\n" . url
    echohl NONE
endfunction

command! -nargs=0 -range CodeBrowserBlobUrl call <SID>generateCodeBrowserBlobUrl(<line1>, <line2>)
