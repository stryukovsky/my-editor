local trouble_main = require "trouble"
return function()
  if trouble_main.is_open "lsp" then
    trouble_main.close "lsp"
  end
  if trouble_main.is_open "diagnostics" then
    trouble_main.close "diagnostics"
  end
  if trouble_main.is_open "telescope" then
    trouble_main.close "telescope"
  end
  if trouble_main.is_open "telescope_files" then
    trouble_main.close "telescope_files"
  end
  if trouble_main.is_open "qflist" then
    trouble_main.close "qflist"
  end
  if trouble_main.is_open "quickfix" then
    trouble_main.close "quickfix"
  end
end
