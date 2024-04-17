local prettier = require('prettier')

prettier.setup({
    bin = 'prettierd',
    filetypes={
        'css',
        'javascript',
        'javascriptreact',
        'json',
        'html',
        'typescript',
        'typescriptreact',
        'scss',
    }
})
