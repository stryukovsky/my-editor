## Implementation

- [x] 3. Implement the integration helper under `lua/integrations/`, call the
      plugin's direct will/did rename APIs through the fork callbacks, and map
      only filesystem `r` to the explicit command in `lua/configs/neotree.lua`.
- [x] 4. Merge the needed client capabilities into named supporting servers and
      rustaceanvim before startup; preserve existing capabilities and avoid
      global defaults.
- [x] 5. Link the verified server-support inventory from README near
      `MasonInstall`; describe will/did methods and the configured
      Solidity-server mismatch.
- [x] 5. when r is clicked, check whether lsp are connected, 

if no lsp connected then just regular renaming
if at least one lsp connected, use rename via plugin of lsp integration 
if two or more then before show picker to select many items every lsp to notify about rename
      

