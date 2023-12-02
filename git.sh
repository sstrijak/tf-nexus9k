git add --all -- :!./terraform/.terraform
NOW=$(date +"%Y%m%d-%H%M%S")
git commit -m "${NOW}"
git push -u origin main

