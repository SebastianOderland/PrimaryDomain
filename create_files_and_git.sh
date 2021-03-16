update_description=$1

tar -czvf plugin_files/update_primary_domain.tar.gz update_primary_domain
tar -czvf plugin_files.tar.gz plugin_files
git add .
git commit -m "${update_description}"
git status
git push --force -u origin main