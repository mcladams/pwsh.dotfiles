# ~/.dotfiles/powershell/psreadline.ps1
# PSReadLine configuration: git predictor, prefix history search, ListView by default, right-arrow accept.

# Use history + plugin predictors (CompletionPredictor provides git-aware suggestions)
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# Default view: ListView (drop-down). To use inline ghost text, comment the next line and uncomment the InlineView line.
Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineOption -PredictionViewStyle InlineView

# Key bindings
Set-PSReadLineKeyHandler -Key RightArrow -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key Tab        -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab  -Function TabCompletePrevious

# Prefix-based history search (Up/Down)
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Use Windows-friendly edit mode (preserves Ctrl+C/Ctrl+V behavior)
Set-PSReadLineOption -EditMode Windows

# Import CompletionPredictor if installed (silently)
Import-Module CompletionPredictor -ErrorAction SilentlyContinue
