## STATUS
Refactor has been rebased on Main and pushed to origin (github), and from there applied to other machines of mine. I have three tasks for you, and and one for me, please come up with a staged plan.

## TO-DO
1. Review Test and ensure functionality and safety of @setup.ps1 to an existing userprofile (as opposed to applying to a new userprofile, or new windows installation). Check for any localisations such as using C:\User\Mike which should be replaced with a $HOME. 
2. Currently, legacy code snippets that are now under @directory

Always use git config --global core.longpaths true