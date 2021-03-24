update_description=$1

pandoc -f markdown README.md > README.html

# COPY AND ZIP
mkdir plugin_files
cp -R plugin/. plugin_files/
tar -czvf plugin_files/primary_domain.tar.gz primary_domain
tar -czvf plugin.tar.gz plugin_files
rm -rf plugin_files

# GIT
git add .
git commit -m "${update_description}"
git status
git push -u origin main