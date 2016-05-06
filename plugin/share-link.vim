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
        let pathToGitParent = expand(expandExpr)
        if isdirectory(pathToGitParent . "/.git") || filereadable(pathToGitParent . "/.git")
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
        " Path to file relative to git root
        let workspaceInfo.relativePathToFile = substitute(workspaceInfo.absolutePathToFile, pathToGitParent, "", "")
        " Remove the leading / from the relative path, if it exists (it
        " almost definitely will)
        let workspaceInfo.relativePathToFile = substitute(workspaceInfo.relativePathToFile, '\v^/', "", "")
        let workspaceInfo.absolutePathToGitParent = system('git rev-parse --show-toplevel')
        let workspaceInfo.absolutePathToGit = workspaceInfo.absolutePathToGitParent . "/.git"
        let workspaceInfo.isGitRepo = 1
        let gitConfigLines = []


        " if !isdirectory(workspaceInfo.absolutePathToGit) && filereadable(workspaceInfo.absolutePathToGit)
        "     " Assert: .git is not a directory. Possibly a git submodule.
        "     let gitModuleConfigLines = readfile(workspaceInfo.absolutePathToGit)
        "     for line in gitModuleConfigLines
        "         if line =~ '\v^gitdir:'
        "             " Update the absolute path to git variable to reflect
        "             " where the git repo actually is.
        "             let workspaceInfo.absolutePathToGit = workspaceInfo.absolutePathToGitParent . "/" . get(matchlist(line, '\v^gitdir:\s*(.*)$'), 1, "")
        "         endif
        "     endfor
        " endif

        let remoteOriginUrl = system('git config --get remote.origin.url')
        let workspaceInfo.repositoryName = get(matchlist(remoteOriginUrl, '\v([^/]+).git$'), 1, "")
        let workspaceInfo.isRemoteRepository = 1

        " if isdirectory(workspaceInfo.absolutePathToGit) && filereadable(workspaceInfo.absolutePathToGit . "/config")
        "     " Assert: a regular git repo
        "     let gitConfigLines = readfile(workspaceInfo.absolutePathToGit . "/config")

        "     for line in gitConfigLines
        "         if line =~ '\vurl.?\='
        "             let workspaceInfo.repositoryName = get(matchlist(line, '\v([^/]+).git$'), 1, "")
        "             let workspaceInfo.isRemoteRepository = 1
        "         endif
        "     endfor
        " else
        "     echohl Error
        "     echo "Could not read the git config at location " . workspaceInfo.absolutePathToGit . "/config"
        "     echohl NONE
        " endif
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

    echohl Error
    call s:printDictionary(info)
    echo "\n" . url
    echohl NONE
endfunction

command! -nargs=0 -range CodeBrowserBlobUrl call <SID>generateCodeBrowserBlobUrl(<line1>, <line2>)
