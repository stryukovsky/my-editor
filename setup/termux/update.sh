cd /storage/emulated/0/Documents/
if [ -d "/storage/emulated/0/Documents/my-vault" ]; then
    echo "Directory exists"
else
    echo "Directory does not exist"
    git clone git@github.com:stryukovsky/my-vault.git
fi
cd my-vault
git config --global --add safe.directory /storage/emulated/0/Documents/my-vault
git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"
git pull
git add .
git commit -m "chore: update"
git push
