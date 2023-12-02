git config --global user.email "stan@strijakov.com"
git config --global user.name "Stan Strijakov"
echo "# tf-nexus9k" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/sstrijak/tf-nexus9k.git
git push -u origin main

