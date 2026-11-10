if exists("b:current_syntax")
  finish
endif

syntax match httpComment /^\s*#.*/
syntax match httpSeparator /^###.*/
syntax match httpRequest /^\u\+\s\+\S\+.*/ transparent contains=httpMethod,httpUrl
syntax match httpMethod /^\u\+/ contained
syntax match httpUrl /\s\+\zs\S\+/ contained contains=httpVariable
syntax match httpHeader /^\s*\zs[A-Za-z0-9-]\+\ze:/
syntax match httpParameter /^\s*\zs[A-Za-z0-9_.-]\+\ze=/
syntax match httpVariableDefinition /^\s*\zs@[A-Za-z0-9_-]\+\ze\s*=/

syntax region httpString start=/"/ skip=/\\./ end=/"/ oneline contains=httpVariable
syntax match httpJsonKey /"\%(\\.\|[^"\\]\)*"\ze\s*:/
syntax match httpNumber /\<\d\+\%(\.\d\+\)\?\%([eE][+-]\?\d\+\)\?\>/
syntax keyword httpBoolean true false null
syntax match httpVariable /{{[^{}]*}}/ containedin=ALLBUT,httpComment,httpSeparator,httpRequest

highlight default link httpComment Comment
highlight default link httpSeparator Title
highlight default link httpMethod Keyword
highlight default link httpUrl Underlined
highlight default link httpHeader Type
highlight default link httpParameter Identifier
highlight default link httpVariableDefinition Identifier
highlight default link httpVariable Special
highlight default link httpString String
highlight default link httpJsonKey Identifier
highlight default link httpNumber Number
highlight default link httpBoolean Constant

let b:current_syntax = "http"
