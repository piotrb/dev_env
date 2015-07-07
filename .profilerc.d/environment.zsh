setopt NOTIFY PUSHD_TO_HOME BASH_AUTO_LIST LIST_AMBIGUOUS
setopt LONG_LIST_JOBS NO_CLOBBER
setopt PUSHD_SILENT AUTO_PUSHD PUSHD_MINUS
setopt EXTENDED_GLOB RC_QUOTES MAIL_WARNING
setopt ALL_EXPORT

unsetopt BG_NICE AUTO_PARAM_SLASH MENU_COMPLETE AUTO_CD AUTO_RESUME GLOB_DOTS CORRECT CORRECT_ALL CDABLE_VARS AUTO_MENU
unsetopt REC_EXACT

setopt MENU_COMPLETE

# cd not select parent dir.
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# fix forward delete
bindkey "^[[3~" delete-char
