update_description=$1

# COPY AND ZIP
mkdir plugin_compressed
cp -R plugin/. plugin_compressed/
tar -czvf plugin_compressed/change_primary_domain.tar.gz change_primary_domain
tar -czvfC plugin.tar.gz plugin_compressed
rm -rf plugin_compressed

# GIT
git add .
git commit -m "${update_description}"
git status
git push -u origin main