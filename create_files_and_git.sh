update_description=$1

# COPY AND ZIP
mkdir plugin
cp update_primary_domain.pl plugin/update_primary_domain.pl
tar -czvf plugin/update_primary_domain.tar.gz update_primary_domain
tar -czvf plugin.tar.gz plugin
rm -rf plugin

# GIT
git add .
git commit -m "${update_description}"
git status
git push --force -u origin main