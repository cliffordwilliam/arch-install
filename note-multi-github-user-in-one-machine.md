So to summarize its better this way since we are flexible, 1 machine holds many namespace for many github accounts

Make key for this account
ssh-keygen -t ed25519 -C "you@accountemail.com"

Make namespace for this account
Create ~/.ssh/config

Host github-accountname
HostName github.com
User git
IdentityFile ~/.ssh/id_ed25519_accountname

Go to FE github and
Settings → SSH and GPG Keys → New SSH Key
name key with machine, so you know which machine has this in their disk

Then either clone or push existing

Clone?
git clone git@github-accountname:accountname/your-repo-name.git

then go in and set commit maker credentials
git config user.name "accountname"
git config user.email "you@accountemail.com"

Push existing?
Go in and set commit maker creds
git config user.name "accountname"
git config user.email "you@accountemail.com"

set remote
git remote add origin git@github-accountname:accountname/your-repo-name.git

push
git push -u origin main

assuming main branch in called main

